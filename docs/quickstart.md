# Quickstart

Get from install to productive in 5 minutes.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- Plugin cloned (see [README install section](../README.md#install))

## Step 1: Start a Work Stream

```
/sticky:start
```

What happens:

1. **Session catchup** runs automatically — detects unsynced context from previous sessions
2. **Checks for existing files** — if old planning files exist (>3 days stale), asks whether to resume or clean up
3. **Orients** — summarises where you left off, or discusses the new problem
4. **Confirms approach** — asks you to choose a path before doing anything:
   - *"Want to make a plan?"* — enter plan mode or use your preferred planning tool
   - *"Plan already exists"* — resume from an existing blueprint
   - *"This is simple — just go?"* — the tracker IS the plan
   - *"Resuming from last session"* — picks up where you left off

**Result:** `docs/task_plan-YYYY-MM-DD-slug.md` and `docs/findings-YYYY-MM-DD-slug.md` are created (or loaded if they already exist).

## Step 2: Work Normally — Hooks Are Automatic

You don't need to invoke anything. Hooks fire automatically when planning files exist:

- **Before every tool call:** your task_plan content appears in context (PreToolUse)
- **After every file write:** a reminder to update phase status (PostToolUse)
- **End of turn:** completion check tells you how many phases are done (Stop)

### Rules While Working

| Rule | Why |
|------|-----|
| **2-Action Rule:** after 2 search/view/browse operations, update findings | Prevents knowledge loss — if you forget, context fills up with unreferenced discoveries |
| **Decision made in conversation? Write it to findings IMMEDIATELY** | Decisions not in findings vanish on `/clear` |
| **Keep task_plan under ~30 lines** | It's injected every tool call — bloat costs tokens. Detail belongs in the blueprint. |

## Step 3: Checkpoint Before /clear

When context starts filling up (~60-70%) or you're switching tasks:

```
/sticky:checkpoint
```

What happens:

1. **Updates task_plan** — phase statuses, errors table, decisions
2. **Enriches findings** — audits each section for standalone readability. Asks: *"Would someone reading only this file understand what happened and why?"* Fills gaps from conversation context before it's lost.
3. **Reports** what changed, confirms ready to `/clear`

## Step 4: Resume After /clear

```
/clear
/sticky:start
```

Session catchup detects what happened since the last planning file update and shows a summary. Claude reads the task_plan and findings, picks up exactly where you left off.

This is the core loop: **work, checkpoint, clear, start, repeat.**

## Step 5: Finish Up

When all phases are done:

```
/sticky:done
```

What happens:

1. **Compounds findings** into `docs/solutions/` — tries `/compound` skill, falls back to writing solution docs directly with YAML frontmatter
2. **Verifies completion** — all phases `✅`? If not, asks whether to continue or wrap up incomplete
3. **Updates `docs/progress.md`** — dated entry with outcomes and what's next
4. **Deletes ephemeral files** (`task_plan-*.md`, `findings-*.md`) — keeps blueprints and progress

## Tips

- **Task plan is a TRACKER, not the plan itself.** Detail belongs in your blueprint (`docs/plans/`). The tracker links to it.
- **Use `/clear` aggressively.** Context filling up = quality decreasing. Checkpoint, clear, resume.
- **Findings must stand alone.** Ask: *"Would someone reading only this file understand?"*
- **`progress.md` is your project narrative.** It's never deleted — it accumulates across work streams.
- **Sticky is orchestration-agnostic.** Use whatever planning, brainstorming, or execution tools you prefer. Sticky just tracks the output.

## Next Steps

- [How It Works](how-it-works.md) — deep dive into hooks, context costs, architecture, and tradeoffs
- [Changelog](../CHANGELOG.md) — version history
