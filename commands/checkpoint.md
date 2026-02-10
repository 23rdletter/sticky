---
name: checkpoint
description: Sync planning files before /clear — update tracker, enrich findings, confirm ready
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# /sticky:checkpoint — Sync Before Clear

When the user invokes `/sticky:checkpoint`, follow this sequence. This command prepares planning files for a session boundary (/clear or session end) so nothing is lost.

## Step 1: Find active planning files

```bash
ls docs/task_plan-*.md docs/findings-*.md 2>/dev/null
```

If no files found, say "No active sticky files to checkpoint." and stop.

## Step 2: Update task_plan

Read the task_plan and update it to reflect current reality:

- Update phase statuses (pending → 🔄 → ✅) based on work done this session
- Update the "Current Phase" section to point at the correct next phase
- Add any new phases discovered during the session
- Record any errors encountered in the Errors table
- If decisions were made, ensure the Decisions table is current

## Step 3: Enrich findings

Read the findings file and audit it for compounding readiness.

**Check each section:**
- **Requirements/Constraints**: Are all constraints discovered this session captured?
- **Discoveries**: Are technical insights written with enough context to stand alone?
- **Decisions**: Are all decisions from this session recorded with rationale?
- **Blockers**: Are current blockers listed?

**Compounding readiness test:** For each entry, ask: "Would someone reading only this file understand what happened and why?" If an entry is thin or relies on conversation context that won't survive /clear, add the missing context now.

**Fill gaps from conversation:** Review what was discussed and built this session. Any decision, discovery, or constraint mentioned in conversation but not yet in findings — add it now. This is the last chance before context is lost.

## Step 3.5: Size gate — compound and prune bloated findings

Count the lines in the findings file. If **over 300 lines**, the file has accumulated too much and will degrade future sessions.

**Action when over 300 lines:**

1. Say: "Findings file is [N] lines — over the 300-line threshold. Compounding and pruning."
2. For each section in findings, classify it:
   - **Compound and delete:** Self-contained discoveries, resolved bugs, completed research, tooling gotchas — anything that is a complete learning with no forward dependency on remaining work. These become `docs/solutions/` entries.
   - **Compound but keep a summary:** Findings that are complete BUT inform later phases (e.g. architectural decisions, API contracts, constraint lists). Compound the full detail to `docs/solutions/`, replace the section in findings with a 1-2 line summary + link to the solution doc.
   - **Keep as-is:** In-progress findings, unresolved blockers, active constraints still being worked against — anything the next session needs in full to continue.
3. For sections marked "compound and delete" or "compound but keep summary":
   - Create solution docs in `docs/solutions/` (group related findings into one doc where natural)
   - Delete or replace the findings sections accordingly
4. Report what was compounded, what was summarised, and what remains.

**Action when under 300 lines:** Skip this step silently.

**Key principle:** Findings are a working scratchpad. `docs/solutions/` is the archive. But the scratchpad must retain anything that actively informs remaining work — don't delete context you'll need tomorrow just because the phase is "done".

## Step 4: Report

Summarise what was updated:

```
Checkpoint complete:
- task_plan: [what changed — e.g. "Phase 2 → ✅, Phase 3 → 🔄"]
- findings: [what was added/enriched — e.g. "added 2 discoveries, enriched decision rationale"]
- [any warnings — e.g. "Phase 3 still in progress — will resume next session"]

Ready to /clear.
```

If everything was already up to date, just say: "Files already current. Ready to /clear."
