# How Sticky Works

## The Problem: LLMs Forget

Claude Code's context window is working memory. Like RAM, it's fast but finite — and as it fills up, quality degrades.

> "The name of the game is that you only have approximately 170k of context window to work with. So it's essential to use as little of it as possible. The more you use the context window, the worse the outcomes you'll get."
> — [Geoff Huntley](https://x.com/GeoffreyHuntley), creator of Ralph

The practical implication, as [humanlayer](https://www.humanlayer.dev/blog/advanced-context-engineering) describes:

> "Essentially, this means designing your ENTIRE WORKFLOW around context management, and keeping utilization in the 40%-60% range."

The 80/20 solution is simpler than RAG or retrieval systems:

- **Recall** from recent sessions (session catchup)
- **Keep** track of tasks (task_plan)
- **Log** findings (findings file)
- **Compound** learnings (graduation to docs/solutions/)

```
Context Window = RAM  (volatile, limited)
Filesystem     = Disk (persistent, unlimited)

Anything important gets written to disk.
```

## Compound Engineering

LLMs have no memory between sessions. They insert bugs and discover better approaches as code grows — but those learnings vanish at session end.

The [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) plugin manages this: Plan, Work, Review, Compound, Repeat. Its most valuable feature is compounding knowledge into `docs/solutions/` — categorised solution docs with YAML frontmatter that Claude can reference in future sessions.

> Each unit of engineering work should make subsequent units easier — not harder.

Sticky integrates with this: `/sticky:done` tries `/compound` first to graduate findings into solution docs. If the compound-engineering plugin isn't installed, sticky writes solution docs directly using a compatible format:

```markdown
---
title: <short title>
date: YYYY-MM-DD
category: <bug-fix|architecture|integration|performance|tooling>
tags: [relevant, keywords]
---

## Problem
<what went wrong or what was unclear>

## Solution
<what was done and why>

## Lesson
<what to do differently next time>
```

**What's worth compounding:**
- Bugs that took more than 1 attempt to fix
- Non-obvious decisions (architectural choices, workarounds, gotchas)
- Reusable patterns or techniques
- External API/service quirks
- Anything that would save time or avoid pitfalls for future work

## Sticky and Claude's Auto Memory

Claude Code already has a built-in memory system: `MEMORY.md` files in `~/.claude/projects/` that persist across sessions and load into the system prompt automatically. A reasonable question: if Claude already remembers things, why do you need sticky?

They solve different problems. Think of it as the difference between a reference card pinned to your monitor and the notebook open on your desk.

### What each layer does

| | Auto Memory (`MEMORY.md`) | Sticky (planning files) |
|-|---------------------------|------------------------|
| **Scope** | The whole project | One work stream |
| **Lifetime** | Permanent — accumulates forever | Ephemeral — deleted when work stream ends |
| **Injection** | Once, into the system prompt at session start | Every tool call, via PreToolUse hook |
| **Size** | ~200 lines (truncated after that) | ~30 lines task_plan + unbounded findings |
| **Content** | Project truths: column names, gotchas, API quirks, behavioral patterns | Current state: phase statuses, active decisions, blockers, discoveries |
| **Updates** | Occasionally, when something important is learned | Continuously, as work progresses |

### How they complement each other

**Memory is broad and shallow.** It stores the things you always need to know about a project — the kind of context that prevents Claude from guessing column names. It's a 200-line cheat sheet.

**Sticky is narrow and deep.** It stores everything about what you're doing right now — which phase you're in, what you discovered this session, what decisions were made and why. It's a working scratchpad that gets injected into every tool call so Claude can't drift.

Memory provides the baseline ("here's what I know about this project"). Sticky provides the focus ("here's what I'm doing right now and where I am in doing it").

### The knowledge lifecycle

The two systems feed each other:

```
Work stream starts
  → Memory provides project context (auto-loaded)
  → Sticky tracks current work (task_plan + findings)

Work stream ends (/sticky:done)
  → Findings compound into docs/solutions/ (permanent learnings)
  → Key insights may warrant a MEMORY.md update
  → Ephemeral files are deleted
```

A discovery during sticky's work stream — say, that a particular API returns dates in an unexpected format — starts in the findings file. When the work stream ends, it graduates to `docs/solutions/`. If it's important enough to always have in context, it gets a line in `MEMORY.md`.

Neither makes the other redundant. Without memory, Claude would forget project-level truths between sessions. Without sticky, Claude would lose track of what it's doing mid-session as the context window fills up. They operate at different timescales and different scopes.

## The Hook System

Sticky registers three hooks via the auto-loaded skill at `.claude/skills/sticky/SKILL.md`. These fire automatically whenever planning files exist in `docs/` — and silently no-op when they don't (zero overhead when sticky isn't active).

### PreToolUse — Injecting the Plan

```yaml
matcher: "Write|Edit|Bash|Read|Glob|Grep"
command: "cat docs/task_plan-*.md 2>/dev/null | head -50 || true"
```

Before every tool call matching those 6 tools, the task plan content (first 50 lines) is injected into the conversation. This is sticky's core mechanism — it prevents Claude from drifting mid-task, especially after auto-compaction strips earlier context.

The `head -50` cap is the critical design constraint. It keeps injection bounded and is why the "keep task_plan to ~30 lines" rule exists.

### PostToolUse — Nudging Updates

```yaml
matcher: "Write|Edit"
command: "ls docs/task_plan-*.md ... && echo '[sticky] File updated. If this completes a phase, update the task_plan status.' || true"
```

Narrower than PreToolUse — only fires on file modifications. Outputs a one-liner reminder to update phase status. Prevents stale plans where work is done but status never updated.

### Stop — Completion Detection

Fires at the end of every turn (no matcher — always runs when planning files exist). Runs `check-complete.{sh,ps1}` with platform-aware dispatch (Windows detection via `$OS` / `uname`).

The logic: count total phases (regex: `| <digit> |`) vs complete phases (regex: `✅`). If all complete, suggests `/sticky:done`.

**Critical:** always exits 0. A failing Stop hook would break Claude Code.

### Guard Clause

All hooks silently no-op when no planning files exist:

```bash
ls docs/task_plan-*.md >/dev/null 2>&1 ... || true
```

If you're not using sticky on a project, the hooks add zero overhead.

## Context Window Cost

The math:

| Metric | Value |
|--------|-------|
| Typical task_plan | ~30 lines, ~400 tokens |
| Working session | 80-150 tool calls |
| Total injected | 32,000-60,000 tokens over a session |
| On 200k window | 15-30% consumed by the hook alone |

**Why do it anyway:** Without injection, Claude drifts mid-task — especially after auto-compaction. The alternative (manual re-reading) is unreliable. The `head -50` cap + "keep task_plan to ~30 lines" rule are the key mitigations.

**The escape valve:** `/clear` + `/sticky:start` is better than `/compact`. It wipes context entirely, re-injects ~50 lines once from files, and carries on. Sweet spot: `/clear` when context hits 60-70%, not when it's too late.

## Session Catchup

Source: `scripts/session-catchup.py` (227 lines, Python 3, cross-platform).

Invoked automatically by `/sticky:start` as the first step. It:

1. **Sanitises Windows paths** — `C:\Users\simon\Desktop` becomes `c--users-simon-desktop` (Claude's storage convention)
2. **Parses session JSONL** files from `~/.claude/projects/{sanitised-path}/`
3. **Finds last planning file update** — scans for Write/Edit tool calls to planning files
4. **Extracts unsynced messages** after that point (capped at last 15)
5. **Outputs a catchup summary** + recommended next steps (git diff, read files, continue)

This means even if you ran out of context before updating planning files, the catchup script recovers what happened.

## File System

### Naming Convention

```
docs/task_plan-YYYY-MM-DD-keyword-slug.md
docs/findings-YYYY-MM-DD-keyword-slug.md
```

- **File type prefix first** — enables `task_plan-*.md` glob in hooks
- **Date next** — natural chronological sort
- **Keyword slug last** — human-readable, matches request to filename
- **Always in `docs/`** — never project root

### Templates

Files are created from templates in the `templates/` directory via init scripts (`init-session.sh` / `init-session.ps1`). Placeholders (`{TITLE}`, `{BRANCH}`, `{DATE}`, `{PLAN_LINK}`) are substituted via sed/regex.

| Template | Sections |
|----------|----------|
| `task_plan.md` (27 lines) | Current Phase, Phase Tracker table, Decisions, Errors |
| `findings.md` (19 lines) | Requirements/Constraints, Discoveries, Decisions, Blockers |
| `progress.md` (5 lines) | Persistent changelog header |

### Ephemeral vs Persistent

| File | Lifetime | Deleted by `/sticky:done`? |
|------|----------|---------------------------|
| `docs/task_plan-*.md` | Ephemeral | Yes |
| `docs/findings-*.md` | Ephemeral | Yes (after compounding) |
| `docs/progress.md` | Persistent | Never |
| `docs/plans/*.md` | Persistent | Never |

The `.gitignore` confirms this: ephemeral planning files are ignored, templates are preserved.

## Three-Layer Plan Model

| Layer | What | Lifetime | File |
|-------|------|----------|------|
| Blueprint | Full plan — phases, architecture, code | Permanent | `docs/plans/plan-*.md` |
| Tracker | Phase names + statuses only | Ephemeral | `docs/task_plan-*.md` |
| Execution | Granular tasks with dependencies | In-memory | Claude's TaskCreate system |

Sticky owns **only** the Tracker layer. This is deliberate:

- **Orchestration-agnostic** — works with any planning tool (EnterPlanMode, `/workflows:plan`, manual planning, anything)
- **The tracker is NOT the plan.** It's a status board that fits in 30 lines. Detail belongs in the blueprint.
- **The tracker links to the blueprint** via the `Blueprint:` field in the template

## Command Deep Dive

### /sticky:start

1. **Session catchup** — runs `session-catchup.py` to detect unsynced context from previous sessions
2. **Check existing files** — staleness check (>3 days triggers review), relevance check (is this file for the current task?)
3. **Orient** — summarise where work left off (resume) or discuss the new problem (fresh)
4. **Confirm** — ask user to choose: plan mode, use existing blueprint, simple tracker-only, or resume. Never silently jumps into execution.

### /sticky:checkpoint

1. **Find active files** — glob for `docs/task_plan-*.md` and `docs/findings-*.md`
2. **Update task_plan** — phase statuses, errors table, decisions
3. **Enrich findings** — audit each section for standalone readability. The "compounding readiness test": would someone reading only this file understand what happened and why?
4. **Report** — summarise what changed, confirm ready to `/clear`

### /sticky:done

1. **Find active files**
2. **Compound findings** — try `/compound` skill, fall back to writing solution docs directly (YAML frontmatter + Problem/Solution/Lesson sections)
3. **Verify completion** — all phases `✅`? If not, ask: continue working or wrap up incomplete?
4. **Update progress.md** — dated entry with outcomes and what's next. **Before** deleting anything.
5. **Delete ephemeral files** — `task_plan-*.md` and `findings-*.md`. Keeps blueprints and progress.

## Platform Support

| Script | Unix | Windows |
|--------|------|---------|
| Session init | `init-session.sh` (132 lines) | `init-session.ps1` (151 lines) |
| Completion check | `check-complete.sh` (46 lines) | `check-complete.ps1` (43 lines) |
| Session catchup | `session-catchup.py` (227 lines, cross-platform) | Same |

The Stop hook detects Windows via `$OS` / `uname` and dispatches to the correct script.

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| Put planning files in project root | Always use `docs/` |
| Make task_plan verbose (>30 lines) | Keep it scannable — detail goes in blueprint |
| Forget to update findings after decisions | Write decisions to findings IMMEDIATELY |
| Mandate a specific planning tool | Let the user choose — track the output |
| Delete blueprint plans on `/sticky:done` | Only delete ephemeral files (task_plan, findings) |
| Delete findings before compounding | `/sticky:done` compounds first, then deletes |
| Write long progress.md entries | Keep entries to ~5-10 lines — it's a changelog |
| Write findings that lack context | Findings must stand alone |

## Project Structure

```
sticky-context/
├── .claude-plugin/
│   ├── marketplace.json    # Marketplace registration
│   └── plugin.json         # Plugin metadata (commands + skills dirs)
├── .claude/
│   ├── commands/           # User-invocable slash commands
│   │   ├── start.md        # /sticky:start
│   │   ├── checkpoint.md   # /sticky:checkpoint
│   │   └── done.md         # /sticky:done
│   └── skills/
│       └── sticky/
│           └── SKILL.md    # Hooks + shared reference (auto-loaded)
├── scripts/
│   ├── init-session.sh     # Idempotent session setup (Unix)
│   ├── init-session.ps1    # Idempotent session setup (Windows)
│   ├── check-complete.sh   # Completion check (Unix)
│   ├── check-complete.ps1  # Completion check (Windows)
│   └── session-catchup.py  # Detects unsynced context (Python 3)
├── templates/
│   ├── task_plan.md        # Phase tracker template
│   ├── findings.md         # Findings/decisions template
│   └── progress.md         # Progress log template
├── docs/
│   ├── quickstart.md       # 5-minute walkthrough
│   └── how-it-works.md     # This file
├── CHANGELOG.md
├── README.md
└── LICENSE                 # MIT
```
