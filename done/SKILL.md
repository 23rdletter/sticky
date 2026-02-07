---
name: done
description: Wrap up a sticky work stream — compound findings, verify completion, update progress, clean up
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Skill
---

# /sticky:done — Wrap Up Work Stream

When the user invokes `/sticky:done`, follow this sequence. This is the full shutdown of a work stream: compound → verify → progress → delete.

## Step 1: Find active planning files

```bash
ls docs/task_plan-*.md docs/findings-*.md 2>/dev/null
```

If no files found, say "No active sticky files found." and stop.

## Step 2: Compound findings

Read all `docs/findings-*.md` files. Assess whether the content is worth compounding:

**Compound if ANY of these are true:**
- A bug took more than 1 attempt to fix
- A non-obvious decision was made (architectural choice, workaround, gotcha discovered)
- A reusable pattern or technique was established
- An external API/service quirk was discovered

**If worth compounding:**
1. First, enrich findings for compounding readiness (same as /sticky:checkpoint Step 3 — ensure every entry has enough standalone context)
2. Invoke the `/compound` skill using the Skill tool to graduate findings to `docs/solutions/`
3. Wait for /compound to complete before proceeding to the next step

**If not worth compounding:**
- Tell the user: "Nothing notable to compound — straightforward work. Proceeding to cleanup."
- If user disagrees, they can say "compound" to override, in which case run /compound

## Step 3: Verify completion

Read the task_plan and check phase statuses:

**All phases ✅:** Proceed to Step 4.

**Phases still in progress or pending:**
- List the incomplete phases
- Ask: "These phases aren't marked complete: [list]. Wrap up anyway, or continue working?"
- If user says continue → stop here, don't clean up
- If user says wrap up anyway → proceed

## Step 4: Update progress.md

**BEFORE deleting anything**, append a dated section to `docs/progress.md`:

- What was worked on (from task_plan title/phases)
- Key outcomes (phases completed, what was built/fixed)
- Notable decisions or discoveries (brief, from findings)
- What's next (any incomplete phases or follow-up work identified)

Keep the entry to ~5-10 lines. This is a changelog, not a journal.

If `docs/progress.md` doesn't exist, create it with a header and the first entry.

## Step 5: Clean up

Delete the ephemeral files:
- `docs/task_plan-*.md`
- `docs/findings-*.md`

Report what was deleted and confirm the work stream is closed.

**Never delete:**
- `docs/plans/plan-*.md` — permanent blueprints
- `docs/progress.md` — persistent project-level changelog
