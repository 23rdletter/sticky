#!/bin/bash
# Check if all phases in sticky-knowledge task_plan files are complete.
# Glob-aware: finds docs/task_plan-*.md files.
# Exit 0 if complete (or no plan exists), exit 1 if incomplete.
# Requires UTF-8 locale for emoji matching.

# Find task_plan files — check docs/ with glob, fall back to root
PLAN_FILES=$(ls docs/task_plan-*.md 2>/dev/null || ls task_plan*.md 2>/dev/null || true)

if [ -z "$PLAN_FILES" ]; then
    # No planning session active — exit cleanly
    exit 0
fi

echo "=== Sticky-Knowledge Completion Check ==="
echo ""

TOTAL_ALL=0
COMPLETE_ALL=0

for PLAN_FILE in $PLAN_FILES; do
    # Match phase rows: lines starting with "| <digit>" (anchored to avoid false positives)
    TOTAL=$(grep -cE "^\| *[0-9]+ *\|" "$PLAN_FILE" 2>/dev/null || true)
    COMPLETE=$(grep -c "✅" "$PLAN_FILE" 2>/dev/null || true)

    : "${TOTAL:=0}"
    : "${COMPLETE:=0}"

    TOTAL_ALL=$((TOTAL_ALL + TOTAL))
    COMPLETE_ALL=$((COMPLETE_ALL + COMPLETE))

    BASENAME=$(basename "$PLAN_FILE")
    echo "$BASENAME: $COMPLETE/$TOTAL phases complete"
done

echo ""

if [ "$COMPLETE_ALL" -eq "$TOTAL_ALL" ] && [ "$TOTAL_ALL" -gt 0 ]; then
    echo "ALL PHASES COMPLETE — consider running /sticky:done to clean up."
else
    echo "IN PROGRESS — $COMPLETE_ALL/$TOTAL_ALL phases done."
fi

# Stop hooks must always exit 0 — non-zero is treated as an error by Claude Code
exit 0
