---
name: sticky
version: "2.0.0"
description: >
  Persistent file-based planning across Claude Code sessions. Creates namespaced
  ephemeral files (task_plan, findings) in docs/ that survive /clear and session
  boundaries. Hooks inject plan state into every tool call. Orchestration-agnostic —
  works with any brainstorm/plan/execute/review tools.
user-invocable: false
hooks:
  PreToolUse:
    - matcher: "Write|Edit|Bash|Read|Glob|Grep"
      hooks:
        - type: command
          command: "cat docs/task_plan-*.md 2>/dev/null | head -50 || true"
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "ls docs/task_plan-*.md >/dev/null 2>&1 && echo '[sticky] File updated. If this completes a phase, update the task_plan status.' || true"
  Stop:
    - hooks:
        - type: command
          command: |
            SCRIPT_DIR="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/skills/sticky}/scripts"

            # Guard: only run if planning files exist
            PLAN_FILES=$(ls docs/task_plan-*.md 2>/dev/null || ls task_plan*.md 2>/dev/null || true)
            if [ -z "$PLAN_FILES" ]; then
              exit 0
            fi

            IS_WINDOWS=0
            if [ "${OS-}" = "Windows_NT" ]; then
              IS_WINDOWS=1
            else
              UNAME_S="$(uname -s 2>/dev/null || echo '')"
              case "$UNAME_S" in
                CYGWIN*|MINGW*|MSYS*) IS_WINDOWS=1 ;;
              esac
            fi

            if [ "$IS_WINDOWS" -eq 1 ]; then
              if command -v pwsh >/dev/null 2>&1; then
                pwsh -ExecutionPolicy Bypass -File "$SCRIPT_DIR/check-complete.ps1" 2>/dev/null ||
                powershell -ExecutionPolicy Bypass -File "$SCRIPT_DIR/check-complete.ps1" 2>/dev/null ||
                sh "$SCRIPT_DIR/check-complete.sh"
              else
                powershell -ExecutionPolicy Bypass -File "$SCRIPT_DIR/check-complete.ps1" 2>/dev/null ||
                sh "$SCRIPT_DIR/check-complete.sh"
              fi
            else
              sh "$SCRIPT_DIR/check-complete.sh"
            fi
---

# Sticky — Shared Reference

This is the shared context for all sticky commands. It is not directly invocable.

## Available Commands

- **`/sticky:start`** — Start or resume a work stream
- **`/sticky:checkpoint`** — Sync planning files before /clear
- **`/sticky:done`** — Compound, verify, clean up

## How It Works

Hooks keep planning files in Claude's attention automatically:
- **PreToolUse** injects the task_plan into context before every tool call
- **PostToolUse** reminds to update phase status after file writes
- **Stop** checks overall completion at end of turn

## Creating Files

Use the Write tool to create two ephemeral files in `docs/`:

```
docs/task_plan-YYYY-MM-DD-keyword-slug.md
docs/findings-YYYY-MM-DD-keyword-slug.md
```

- **File type prefix first** — enables `task_plan-*.md` glob in hooks
- **Date next** — natural chronological sort
- **Keyword slug last** — human-readable, matches request to filename
- **All in docs/** — not project root

Use the templates in `${CLAUDE_PLUGIN_ROOT}/templates/` as the base structure. Fill in the placeholders (TITLE, DATE, BRANCH) from context.

### task_plan rules

- **Keep it brief** — must be fully readable in the `head -50` hook output (~30 lines max)
- **Phase table format** — numbered rows with status emoji: pending, 🔄 in progress, ✅ complete
- **Link to blueprint** — if a detailed plan exists (from any planning tool), reference it: "Blueprint: docs/plans/plan-X.md"
- This is a TRACKER, not the plan itself. Detail belongs in the blueprint.

### findings rules

- **Write decisions immediately** — if a decision was made in conversation, it goes in findings NOW (not "we'll write it later")
- **2-Action Rule** — after every 2 search/view/browse operations, update findings with what you learned
- **Compounding readiness** — findings must have enough context to stand alone. When writing an entry, ask: "Would someone reading only this file understand what happened and why?" If not, add the missing context.
- **Detail for compounding** — provide enough detail that when findings are compounded into a solution doc, the doc can be written with full context and rationale with zero gaps. This is the source material for the final solution, so it must be comprehensive and clear.
- **This file graduates** — when /compound runs, findings become the source material for docs/solutions/

### progress.md (persistent, not ephemeral)

`docs/progress.md` is a project-level changelog that accumulates across work streams. Created on first `/sticky:start` (via the init script) using the template at `${CLAUDE_PLUGIN_ROOT}/templates/progress.md`. Appended to by `/sticky:done` and by staleness cleanup in `/sticky:start`. **Never deleted** by sticky commands.

Each entry is a short dated summary (~5-10 lines) of what was worked on, key outcomes, and what's next. Use this format:

```markdown
## YYYY-MM-DD — {Title}

**Branch:** `{branch}`
**Phases completed:** N/M

### What was done
- ...

### Key outcomes
- ...

### What's next
- ...
```

## Three-Layer Plan Model

| Layer | What | Lifetime | File |
|-------|------|----------|------|
| Blueprint | Full plan — phases, architecture, code | Permanent | `docs/plans/plan-*.md` |
| Tracker | Phase names + statuses | Ephemeral | `docs/task_plan-*.md` |
| Execution | Granular tasks with deps | In-memory | Claude's TaskCreate system |

Sticky owns the **Tracker** layer. The Blueprint comes from whatever planning tool the user prefers. Execution is Claude's built-in task system within a session.

## Planning is your choice

Sticky does NOT mandate which tools you use for brainstorming, planning, executing, or reviewing. It only manages the ephemeral tracking files and keeps them in Claude's attention.

Use whatever combination the user prefers, as long as the output is captured in the planning files. The /workflows examples below are drawn from compound-engineering, but the user is not limited to these. Work with whatever plugins and workflows the user prefers:
- **Brainstorm:** /workflows:brainstorm, just talking, nothing
- **Plan:** /workflows:plan, EnterPlanMode, any other planning skill the user has installed, manual
- **Execute:** /workflows:work, /lfg, manual
- **Review:** /workflows:review, manual

## Session Boundaries

Suggest starting a fresh session when:
- Planning files are loaded for work stream X and user pivots to unrelated Y
- Context usage exceeds ~70% and significant work remains
- A logical milestone is reached (PR created, feature complete) and next task is distinct

Before /clear: the user should run `/sticky:checkpoint` to sync planning files.
On fresh session: the user should re-invoke `/sticky:start` — step 1 catches up from files.

## Continuity across /clear

Ensured purely through the planning files:
- `task_plan-*.md` — phase statuses tell you exactly where work left off
- `findings-*.md` — decisions, blockers, context not captured in code
- Key rule: if a decision was made in conversation, it goes in findings IMMEDIATELY

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| Put planning files in project root | Always use docs/ |
| Make task_plan verbose (>30 lines) | Keep it scannable — detail goes in blueprint |
| Forget to update findings after decisions | Write decisions to findings IMMEDIATELY |
| Mandate a specific planning tool | Let the user choose — track the output |
| Delete blueprint plans on /sticky:done | Only delete ephemeral files (task_plan, findings) |
| Delete findings before compounding | /sticky:done compounds first, then deletes |
| Write long progress.md entries | Keep entries to ~5-10 lines — it's a changelog, not a journal |
| Write findings that lack context | Findings must stand alone — someone reading only this file should understand what and why |
