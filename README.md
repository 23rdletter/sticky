# Sticky Context

Persistent file-based planning for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that survives `/clear` and session boundaries.

Sticky keeps your planning context alive across sessions using two ephemeral markdown files and hooks that automatically inject state into every tool call.

> **Origins:** Sticky is a fork of [planning-with-files](https://github.com/OthmanAdi/planning-with-files) by [@OthmanAdi](https://github.com/OthmanAdi), restructured as a marketplace plugin with added checkpoint/compound workflows. The knowledge compounding pattern and plugin architecture are influenced by [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) by [Every](https://github.com/EveryInc).

## What It Does

- **Tracks work streams** with a lightweight phase tracker (`task_plan-*.md`) and a findings/decisions log (`findings-*.md`)
- **Hooks inject context automatically** — PreToolUse feeds the task plan into every tool call, so Claude never loses track of where you are
- **Session catchup** detects unsynced context from previous sessions
- **Compounds knowledge** — findings graduate to permanent docs via `/compound` when a work stream ends

## Why Does This Matter?
### Context Engineering
[Geoff Huntley](https://x.com/GeoffreyHuntley), the creator of Ralph, frames it like this:
> The name of the game is that you only have approximately 170k of context window to work with. So it's essential to use as little of it as possible. The more you use the context window, the worse the outcomes you'll get.

Like a human, an LLM can only hold so much in its working memory before it forgets stuff. As your context window grows, quality decreases.

Just as [humanlayer](https://www.humanlayer.dev/blog/advanced-context-engineering) descibes:
> Essentially, this means designing your ENTIRE WORKFLOW around context management, and keeping utilization in the 40%-60% range (depends on complexity of the problem).

RAG solutions and the like are impressive but add layers of complexity and are context-heavy. The 80/20 solution is simpler, more efficient, and elegant:
- **Recall** from recent sessions
- **Keep** track of tasks
- **Log** findings
- **Compound** learnings

### Compound Engineering
LLMs traditionally have no memory between sessions and aren't (yet) perfect at writing code. They will insert bugs and discover better ways of doing things as your code grows.

The [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) plugin manages this issue effectively.

Centered on a Plan → Work → Review → Compound → Repeat workflow, one of its most valuable features is compounding knowledge into /docs/solutions.

When Claude encounters a similar problem in future, it can check for documented learnings and build from them.

> Each unit of engineering work should make subsequent units easier—not harder.

### Sticky's Role

Sticky helps you manage context, create continuity between sessions, and store knowledge for later.

A task plan complements your actual plan by keeping track of exactly where you are in the execution phase. It stops drift by reminding Claude of what it should be doing.

A findings file keeps a log of every important decision. It stores what issues were encountered and how they were solved. Think of it like someone keeping the minutes for your work.

A progress file maintains a changelog once a set of tasks is done. It's the narrative for your project.

Rather than /compact and lose detail, use /clear to start a new session and /sticky:start to immediately get Claude caught up and ready to continue.

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

Clone into your Claude Code plugins directory:

```bash
git clone https://github.com/23rdletter/sticky-context.git ~/.claude/plugins/marketplaces/sticky-context
```

Restart Claude Code. The commands `/sticky:start`, `/sticky:checkpoint`, and `/sticky:done` will be available.

### Optional dependency

The `/sticky:done` command can auto-invoke `/compound` to graduate findings into categorized solution docs. This requires the [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) plugin by [Every](https://every.to). If `/compound` isn't available, `/sticky:done` writes solution docs directly using a compatible YAML frontmatter format.

## How Hooks Work

Sticky registers three hooks via the auto-loaded skill at `.claude/skills/sticky/SKILL.md`. These fire automatically whenever planning files exist:

- **PreToolUse** (`Write|Edit|Bash|Read|Glob|Grep`) — injects `task_plan-*.md` content (first 50 lines) before every tool call
- **PostToolUse** (`Write|Edit`) — reminds Claude to update phase status after file modifications
- **Stop** — checks if all phases are complete at end of turn, suggests `/sticky:done` if so

Hooks fire independently of any command invocation.

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
| Architecture | Single skill + subcommands | Marketplace plugin with commands + auto-loaded skill |
| Command syntax | `/planning-with-files start` | `/sticky:start` |
| Mid-session sync | Not built-in | `/sticky:checkpoint` |
| Knowledge compounding | Manual | Auto-invokes `/compound` or writes solution docs directly |
| Findings quality gate | Write and hope | Audits for standalone readability before /clear |
| Completion verification | Checks phases | Checks phases + asks before cleaning up incomplete work |

## Project Structure

```
sticky-context/
├── .claude-plugin/
│   ├── marketplace.json   # Marketplace registration
│   └── plugin.json        # Plugin metadata (points to commands + skills)
├── .claude/
│   ├── commands/          # User-invocable slash commands
│   │   ├── start.md       # /sticky:start
│   │   ├── checkpoint.md  # /sticky:checkpoint
│   │   └── done.md        # /sticky:done
│   └── skills/
│       └── sticky/
│           └── SKILL.md   # Hooks + shared reference (auto-loaded, not invocable)
├── scripts/
│   ├── init-session.sh    # Idempotent session setup (Unix)
│   ├── init-session.ps1   # Idempotent session setup (Windows)
│   ├── check-complete.sh  # Completion check (Stop hook, Unix)
│   ├── check-complete.ps1 # Completion check (Stop hook, Windows)
│   └── session-catchup.py # Detects unsynced context from previous sessions
├── templates/
│   ├── task_plan.md       # Phase tracker template
│   ├── findings.md        # Findings/decisions template
│   └── progress.md        # Progress log template
├── CHANGELOG.md           # Version history
├── README.md
└── LICENSE
```

## Acknowledgments

- **[planning-with-files](https://github.com/OthmanAdi/planning-with-files)** by [@OthmanAdi](https://github.com/OthmanAdi) — the original file-based planning skill that sticky evolves from. Core concepts (task_plan/findings/progress files, PreToolUse hook injection, session catchup) originate here.
- **[compound-engineering](https://github.com/EveryInc/compound-engineering-plugin)** by [Every](https://github.com/EveryInc) — the marketplace plugin architecture pattern (`.claude-plugin/marketplace.json`, namespaced commands) and the `/compound` knowledge graduation workflow that sticky integrates with.

## License

MIT — see [LICENSE](LICENSE).
