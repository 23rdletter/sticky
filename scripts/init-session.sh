#!/bin/bash
# Idempotent session initialisation for sticky.
# Creates docs/ directory and planning files if they don't exist.
#
# Usage: init-session.sh <slug> [title] [branch]
#   slug   — keyword slug for filenames, e.g. "condition-enrichment"
#   title  — human-readable title (defaults to slug with dashes replaced)
#   branch — git branch name (defaults to current branch)
#
# Safe to run multiple times — only creates what's missing.

set -e

SLUG="${1:?Usage: init-session.sh <slug> [title] [branch]}"
TITLE="${2:-$(echo "$SLUG" | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')}"
BRANCH="${3:-$(git branch --show-current 2>/dev/null || echo 'main')}"
DATE="$(date +%Y-%m-%d)"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/../templates" && pwd)"

CREATED=""

# 1. Create docs/ if missing
if [ ! -d "docs" ]; then
    mkdir -p docs
    CREATED="${CREATED}  created docs/\n"
fi

# 2. Create task_plan if missing
TASK_PLAN="docs/task_plan-${DATE}-${SLUG}.md"
if ! ls docs/task_plan-*.md >/dev/null 2>&1; then
    if [ -f "$TEMPLATE_DIR/task_plan.md" ]; then
        sed -e "s/{TITLE}/${TITLE}/g" \
            -e "s/{BRANCH}/${BRANCH}/g" \
            -e "s/{DATE}/${DATE}/g" \
            -e "s|{PLAN_LINK}|none yet|g" \
            "$TEMPLATE_DIR/task_plan.md" > "$TASK_PLAN"
    else
        # Inline fallback if template missing
        cat > "$TASK_PLAN" <<TMPL
# Task Plan: ${TITLE}

**Branch:** \`${BRANCH}\`
**Blueprint:** _none yet_
**Started:** ${DATE}

## Current Phase

Phase 1 next.

## Phase Tracker

| # | Phase | Status | Depends On |
|---|-------|--------|------------|
| 1 | TBD | pending | — |

## Decisions

| Decision | Rationale |
|----------|-----------|

## Errors

| Error | Phase | Resolution |
|-------|-------|------------|
TMPL
    fi
    CREATED="${CREATED}  created ${TASK_PLAN}\n"
else
    EXISTING=$(ls docs/task_plan-*.md 2>/dev/null | head -1)
    echo "[sticky] task_plan already exists: $(basename "$EXISTING")"
fi

# 3. Create findings if missing
FINDINGS="docs/findings-${DATE}-${SLUG}.md"
if ! ls docs/findings-*.md >/dev/null 2>&1; then
    if [ -f "$TEMPLATE_DIR/findings.md" ]; then
        sed -e "s/{TITLE}/${TITLE}/g" \
            "$TEMPLATE_DIR/findings.md" > "$FINDINGS"
    else
        cat > "$FINDINGS" <<TMPL
# Findings — ${TITLE}

## Requirements / Constraints

-

## Discoveries

-

## Decisions

| Decision | Rationale |
|----------|-----------|

## Blockers

-
TMPL
    fi
    CREATED="${CREATED}  created ${FINDINGS}\n"
else
    EXISTING=$(ls docs/findings-*.md 2>/dev/null | head -1)
    echo "[sticky] findings already exists: $(basename "$EXISTING")"
fi

# 4. Create progress.md if missing
if [ ! -f "docs/progress.md" ]; then
    if [ -f "$TEMPLATE_DIR/progress.md" ]; then
        cp "$TEMPLATE_DIR/progress.md" docs/progress.md
    else
        cat > "docs/progress.md" <<TMPL
# Progress Log

<!-- Persistent project-level changelog. Each entry is appended by /sticky:done
     (or staleness cleanup in /sticky:start). Never deleted by sticky commands. -->
TMPL
    fi
    CREATED="${CREATED}  created docs/progress.md\n"
fi

# Report
if [ -n "$CREATED" ]; then
    echo ""
    echo "[sticky] Initialised session files:"
    printf "$CREATED"
else
    echo "[sticky] All session files already exist — nothing to create."
fi
