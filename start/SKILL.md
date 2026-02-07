---
name: start
description: Start or resume a sticky work stream — session catchup, file creation, confirm approach
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# /sticky:start — Start or Resume Work Stream

When the user invokes `/sticky:start`, follow this sequence:

## Step 1: Session catchup (optional)

Run the catchup script to check for unsynced context from a previous session:

```bash
python "${CLAUDE_PLUGIN_ROOT}/scripts/session-catchup.py" "$(pwd)"
```

If catchup shows unsynced context, cross-reference with the user's current request before proceeding.

## Step 2: Check for existing files

```bash
ls docs/task_plan-*.md docs/findings-*.md 2>/dev/null
```

**If files exist:**
- **Staleness check:** If any file was last modified >3 days ago:
  1. Read the task_plan and findings to understand what was worked on
  2. Ask: "Found old planning files for {slug} — delete or resume?"
  3. If user says **delete**: append a short summary to `docs/progress.md` FIRST (what was worked on, phases completed, key findings). If `docs/progress.md` doesn't exist, create it from the template at `${CLAUDE_PLUGIN_ROOT}/templates/progress.md` then append. After logging, delete the stale files.
- **Relevance check:** Match filename slug against user's current request. If clearly relevant → load and resume. If clearly unrelated → ask user. If ambiguous → ask user.
- Read the task_plan file to identify current phase and status.

**If no files exist → initialise:**

Determine a clear and identifiable keyword slug from the user's request (e.g. "condition-enrichment", "hero-ui-update"). Then run the init script:

```bash
# Unix/macOS/Git Bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/init-session.sh" "<slug>" "<title>" "<branch>"
```

```powershell
# Windows PowerShell
& "${CLAUDE_PLUGIN_ROOT}/scripts/init-session.ps1" "<slug>" "<title>" "<branch>"
```

The init script is idempotent — it creates `docs/`, `task_plan`, `findings`, and `progress.md` only if they don't already exist. It uses templates from `${CLAUDE_PLUGIN_ROOT}/templates/`.

After running, read the created task_plan file so you can populate it with phases in Step 3.

## Step 3: Orient

- If resuming: summarise where work left off based on task_plan phases and findings content.
- If fresh: discuss the problem space with the user. Populate findings with requirements and constraints as they emerge.
- task_plan can start populating loosely during discussion — that's fine.

## Step 4: Confirm before acting

**CRITICAL: Do NOT start executing work without confirming the approach with the user.**

After Orient, present the user with the appropriate path:

**a) "Want to make a plan?"** — The task is non-trivial. task_plan has rough phases but no detailed blueprint. Ask: "Want me to enter plan mode, or do you have a planning skill you'd prefer to use?" After planning, link the blueprint in task_plan and confirm before executing.

**b) "Plan already exists"** — A blueprint was created beforehand (check `docs/plans/` or ~/.claude/plans/), or the user is resuming a previous session where planning was already done. Summarise: "Blueprint at {path}, task_plan shows Phase N in progress — pick up here?" Confirm before executing.

**c) "This is simple — just go?"** — The task is small enough that the task_plan tracker IS the plan. No blueprint needed. Still confirm: "This is straightforward — I'll do X then Y. Good to go?"

**d) "Resuming from last session"** — task_plan has phases already in progress/complete. Summarise where things left off and ask: "Continue from Phase N, or re-plan?"

Never silently jump into execution. The user chooses the path.
