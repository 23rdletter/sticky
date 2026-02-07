# Changelog

All notable changes to sticky-context are documented here.

## [3.0.0] — 2026-02-07

### Changed
- **BREAKING:** Restructured from `~/.claude/skills/` to `~/.claude/plugins/marketplaces/` (proper marketplace plugin)
- Commands moved from `start/SKILL.md`, `checkpoint/SKILL.md`, `done/SKILL.md` to `.claude/commands/start.md`, `.claude/commands/checkpoint.md`, `.claude/commands/done.md`
- Root `SKILL.md` moved to `.claude/skills/sticky/SKILL.md` (auto-loaded hooks + shared reference)
- Install path changed from `~/.claude/skills/sticky` to `~/.claude/plugins/marketplaces/sticky-context`

### Added
- `.claude-plugin/marketplace.json` — marketplace registration (enables proper colon-namespaced commands)
- `.claude/commands/` directory — commands are now `.md` files following the marketplace plugin spec
- `.claude/skills/sticky/` directory — auto-loaded skill for hooks

### Fixed
- `/sticky:start`, `/sticky:checkpoint`, `/sticky:done` now appear correctly in the slash command palette (previously only showed as flat `sticky` skill)

### Removed
- `start/`, `checkpoint/`, `done/` subdirectories (replaced by `.claude/commands/`)
- Root `SKILL.md` (moved to `.claude/skills/sticky/SKILL.md`)

## [2.1.0] — 2026-02-07

### Added
- `templates/progress.md` — consistent format for progress log from first use
- `scripts/init-session.sh` — idempotent Unix init script (creates docs/, task_plan, findings, progress.md)
- `scripts/init-session.ps1` — Windows PowerShell equivalent
- `CHANGELOG.md` — version history

### Changed
- `start/SKILL.md` — uses init script for file creation; handles missing progress.md in staleness cleanup
- `done/SKILL.md` — references progress template; structured entry format; `/compound` fallback for users without compound-engineering
- Root `SKILL.md` — progress.md section references template and includes entry format

### Fixed
- First-time user experience: docs/ directory, progress.md, and planning files are now created reliably via init scripts instead of relying on implicit Write tool behaviour

## [2.0.0] — 2026-02-07

### Changed
- Restructured from skill with subcommands to **plugin** with namespaced skills
- Commands now use colon syntax: `/sticky:start`, `/sticky:checkpoint`, `/sticky:done`
- Root SKILL.md is non-invocable (hooks + shared reference only)

### Added
- `.claude-plugin/plugin.json` — plugin registration enabling colon namespace
- `checkpoint/SKILL.md` — new command for syncing files before `/clear`
- `done/SKILL.md` — revised flow: compound → verify → progress → delete
- `README.md` — public documentation with attribution
- `LICENSE` — MIT with dual copyright (OthmanAdi + Simon)

### Removed
- `commands/` directory (replaced by plugin subdirectories)

## [1.0.0] — 2026-02-06

Initial fork from [planning-with-files](https://github.com/OthmanAdi/planning-with-files).

- Ephemeral task_plan + findings files in docs/
- PreToolUse/PostToolUse/Stop hooks
- Session catchup script
- `/start` and `/done` commands
