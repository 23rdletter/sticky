---
name: done
description: Wrap up a sticky work stream — compound findings, verify completion, update progress, clean up
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
- Anything else that would save time/effort, improve your output, or avoid pitfalls for future you or a teammate working on something similar

**If worth compounding:**
1. First, enrich findings for compounding readiness (same as /sticky:checkpoint Step 3 — ensure every entry has enough standalone context)
2. Always try to first invoke the `/compound` skill using the Skill tool to graduate findings to `docs/solutions/`; if the skill or tool is not available, fall back to writing solution docs directly as described below.
3. **If `/compound` is not available** (plugin not installed or skill not found): write the solution doc directly. For each compoundable finding, create a file in `docs/solutions/` using this format:
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
   Organise files into subdirectories by category (e.g. `docs/solutions/bug-fix/`, `docs/solutions/architecture/`). Tell the user: "Wrote solution doc directly — install compound-engineering for richer categorisation."

4. Wait for compounding to complete before proceeding to the next step

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

**BEFORE deleting anything**, append a dated section to `docs/progress.md`.

If `docs/progress.md` doesn't exist, create it from `${CLAUDE_PLUGIN_ROOT}/templates/progress.md` first.

Use the entry format from the root SKILL.md reference:

```markdown
## YYYY-MM-DD — {Title from task_plan}

**Branch:** `{branch}`
**Phases completed:** N/M

### What was done
- (from task_plan phases)

### Key outcomes
- (what was built/fixed, key decisions)

### What's next
- (incomplete phases, follow-up work identified)
```

Keep entries brief; line count will depend on work completed, but it should be between ~5 and 20 lines. This is a changelog, not a journal.

## Step 5: Clean up

Delete the ephemeral files:
- `docs/task_plan-*.md`
- `docs/findings-*.md`

Report what was deleted and confirm the work stream is closed.

**Never delete:**
- `docs/plans/plan-*.md` — permanent blueprints
- `docs/progress.md` — persistent project-level changelog
