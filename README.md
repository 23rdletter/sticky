# Sticky Context

Persistent file-based planning for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that survives `/clear` and session boundaries.

Sticky keeps your planning context alive across sessions using two ephemeral markdown files and hooks that automatically inject state into every tool call.

> **Origins:** Sticky is a fork of [planning-with-files](https://github.com/OthmanAdi/planning-with-files) by [@OthmanAdi](https://github.com/OthmanAdi), restructured as a namespaced plugin with added checkpoint/compound workflows. The knowledge compounding pattern and plugin architecture are influenced by [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) by [Every](https://github.com/EveryInc).

## What It Does

- **Tracks work streams** with a lightweight phase tracker (`task_plan-*.md`) and a findings/decisions log (`findings-*.md`)
- **Hooks inject context automatically** — PreToolUse feeds the task plan into every tool call, so Claude never loses track of where you are
- **Session catchup** detects unsynced context from previous sessions
- **Compounds knowledge** — findings graduate to permanent docs via `/compound` when a work stream ends

## Commands

| Command | What it does |
|---------|-------------|
| `/sticky:start` | Start or resume a work stream. Runs session catchup, creates/loads planning files, confirms approach before executing. |
| `/sticky:checkpoint` | Sync planning files before `/clear`. Updates phase statuses, enriches findings for standalone readability, confirms ready to clear. |
| `/sticky:done` | Wrap up a work stream. Compounds findings, verifies completion, updates progress log, deletes ephemeral files. |

## Three-Layer Plan Model

| Layer | What | Lifetime | File |
|-------|------|----------|------|
| Blueprint | Full plan — phases, architecture, code | Permanent | `docs/plans/plan-*.md` |
| Tracker | Phase names + statuses | Ephemeral | `docs/task_plan-*.md` |
| Execution | Granular tasks with deps | In-memory | Claude's TaskCreate system |

Sticky owns the **Tracker** layer. It's orchestration-agnostic — use whatever planning, brainstorming, or execution tools you prefer.

## Install

Clone into your Claude Code skills directory:

```bash
git clone https://github.com/23rdletter/sticky-context.git ~/.claude/skills/sticky
```

Restart Claude Code. The commands `/sticky:start`, `/sticky:checkpoint`, and `/sticky:done` will be available.

### Optional dependency

The `/sticky:done` command can auto-invoke `/compound` to graduate findings into categorized solution docs. This requires the [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) plugin by [Every](https://every.to). If `/compound` isn't available, `/sticky:done` skips the compounding step and proceeds with cleanup.

## How Hooks Work

Sticky registers three hooks that fire automatically whenever planning files exist:

- **PreToolUse** (`Write|Edit|Bash|Read|Glob|Grep`) — injects `task_plan-*.md` content (first 50 lines) before every tool call
- **PostToolUse** (`Write|Edit`) — reminds Claude to update phase status after file modifications
- **Stop** — checks if all phases are complete at end of turn, suggests `/sticky:done` if so

Hooks are defined in the root `SKILL.md` and fire independently of any command invocation.

## File Naming

Planning files follow a strict convention for glob-friendly hooks:

```
docs/task_plan-YYYY-MM-DD-keyword-slug.md
docs/findings-YYYY-MM-DD-keyword-slug.md
```

- File type prefix first (enables `task_plan-*.md` glob)
- Date next (chronological sort)
- Keyword slug last (human-readable)
- Always in `docs/` (never project root)

## Typical Workflow

```
/sticky:start          — create planning files, orient, confirm approach
  ... work ...         — hooks keep context alive automatically
/sticky:checkpoint     — sync files before /clear (mid-stream)
  /clear               — start fresh session
/sticky:start          — resume from where you left off
  ... finish work ...
/sticky:done           — compound findings, update progress, clean up
```

## What's Different from planning-with-files

| Feature | planning-with-files | sticky |
|---------|-------------------|--------|
| Architecture | Single skill + subcommands | Plugin with namespaced skills |
| Command syntax | `/planning-with-files start` | `/sticky:start` |
| Mid-session sync | Not built-in | `/sticky:checkpoint` |
| Knowledge compounding | Manual | Auto-invokes `/compound` in done flow |
| Findings quality gate | Write and hope | Audits for standalone readability before /clear |
| Completion verification | Checks phases | Checks phases + asks before cleaning up incomplete work |

## Project Structure

```
sticky/
├── .claude-plugin/
│   └── plugin.json         # Plugin registration (enables colon syntax)
├── SKILL.md                # Hooks + shared reference (not user-invocable)
├── start/
│   └── SKILL.md            # /sticky:start
├── checkpoint/
│   └── SKILL.md            # /sticky:checkpoint
├── done/
│   └── SKILL.md            # /sticky:done
├── scripts/
│   ├── check-complete.ps1  # Windows completion check (Stop hook)
│   ├── check-complete.sh   # Unix completion check (Stop hook)
│   └── session-catchup.py  # Detects unsynced context from previous sessions
└── templates/
    ├── task_plan.md         # Phase tracker template
    └── findings.md          # Findings/decisions template
```

## Acknowledgments

- **[planning-with-files](https://github.com/OthmanAdi/planning-with-files)** by [@OthmanAdi](https://github.com/OthmanAdi) — the original file-based planning skill that sticky evolves from. Core concepts (task_plan/findings/progress files, PreToolUse hook injection, session catchup) originate here.
- **[compound-engineering](https://github.com/EveryInc/compound-engineering-plugin)** by [Every](https://github.com/EveryInc) — the plugin architecture pattern (`.claude-plugin/plugin.json`, namespaced skills) and the `/compound` knowledge graduation workflow that sticky integrates with.

## License

MIT — see [LICENSE](LICENSE).
