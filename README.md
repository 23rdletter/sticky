# Sticky Context

Persistent file-based planning for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that survives `/clear` and session boundaries.

> **Origins:** Fork of [planning-with-files](https://github.com/OthmanAdi/planning-with-files) by [@OthmanAdi](https://github.com/OthmanAdi), restructured as a marketplace plugin with checkpoint/compound workflows. Knowledge compounding influenced by [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) by [Every](https://every.to).

## What It Does

- **Tracks work streams** with a lightweight phase tracker (`task_plan-*.md`) and a findings/decisions log (`findings-*.md`)
- **Hooks inject context automatically** — PreToolUse feeds the task plan into every tool call, so Claude never loses track of where you are
- **Session catchup** detects unsynced context from previous sessions
- **Compounds knowledge** — findings graduate to permanent `docs/solutions/` when a work stream ends

## Install

Clone into your Claude Code plugins directory:

```bash
git clone https://github.com/23rdletter/sticky-context.git ~/.claude/plugins/marketplaces/sticky-context
```

Restart Claude Code. The commands will be available immediately.

### Optional dependency

`/sticky:done` can auto-invoke `/compound` to graduate findings into categorised solution docs. This requires the [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) plugin. If it's not installed, sticky writes solution docs directly using a compatible YAML frontmatter format.

## Commands

| Command | What it does |
|---------|-------------|
| `/sticky:start` | Start or resume a work stream — session catchup, create/load files, confirm approach |
| `/sticky:checkpoint` | Sync planning files before `/clear` — update statuses, enrich findings, confirm ready |
| `/sticky:done` | Wrap up — compound findings, verify completion, update progress, clean up |

## Workflow

```
/sticky:start          — create planning files, orient, confirm approach
  ... work ...         — hooks keep context alive automatically
/sticky:checkpoint     — sync files before /clear (mid-stream)
  /clear               — start fresh session
/sticky:start          — resume from where you left off
  ... finish work ...
/sticky:done           — compound findings, update progress, clean up
```

## Why?

As your context window fills, Claude's output quality degrades. The fix: write important state to files, inject it back via hooks, and use `/clear` aggressively instead of letting context rot.

Sticky automates this. Hooks keep the plan in attention. Session catchup recovers where you left off. Findings compound into permanent knowledge so the same mistakes don't repeat.

[Learn more about context engineering and how the hooks work.](docs/how-it-works.md)

## Three-Layer Plan Model

| Layer | What | Lifetime | File |
|-------|------|----------|------|
| Blueprint | Full plan — phases, architecture, code | Permanent | `docs/plans/plan-*.md` |
| Tracker | Phase names + statuses | Ephemeral | `docs/task_plan-*.md` |
| Execution | Granular tasks with deps | In-memory | Claude's TaskCreate system |

Sticky owns the **Tracker** layer. It's orchestration-agnostic — use whatever planning, brainstorming, or execution tools you prefer.

## What's Different from planning-with-files

| Feature | planning-with-files | sticky |
|---------|-------------------|--------|
| Architecture | Single skill + subcommands | Marketplace plugin with commands + auto-loaded skill |
| Command syntax | `/planning-with-files start` | `/sticky:start` |
| Mid-session sync | Not built-in | `/sticky:checkpoint` |
| Knowledge compounding | Manual | Auto-invokes `/compound` or writes solution docs directly |
| Findings quality gate | Write and hope | Audits for standalone readability before `/clear` |
| Completion verification | Checks phases | Checks phases + asks before cleaning up incomplete work |

## Quick Links

- [Quickstart](docs/quickstart.md) — first productive session in 5 minutes
- [How It Works](docs/how-it-works.md) — hooks, context costs, architecture, tradeoffs
- [Changelog](CHANGELOG.md) — version history

## Acknowledgments

- **[planning-with-files](https://github.com/OthmanAdi/planning-with-files)** by [@OthmanAdi](https://github.com/OthmanAdi) — the original file-based planning skill that sticky evolves from
- **[compound-engineering](https://github.com/EveryInc/compound-engineering-plugin)** by [Every](https://every.to) — the marketplace plugin architecture and `/compound` knowledge graduation workflow

## License

MIT — see [LICENSE](LICENSE).
