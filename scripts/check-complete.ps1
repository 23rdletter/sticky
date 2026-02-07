# Check if all phases in sticky-knowledge task_plan files are complete.
# Glob-aware: finds docs/task_plan-*.md files.
# Exit 0 if complete (or no plan exists), exit 1 if incomplete.

$planFiles = @()
$planFiles += Get-Item "docs/task_plan-*.md" -ErrorAction SilentlyContinue
if ($planFiles.Count -eq 0) {
    $planFiles += Get-Item "task_plan*.md" -ErrorAction SilentlyContinue
}

if ($planFiles.Count -eq 0) {
    exit 0
}

Write-Host "=== Sticky-Knowledge Completion Check ==="
Write-Host ""

$totalAll = 0
$completeAll = 0

foreach ($planFile in $planFiles) {
    $content = Get-Content $planFile -Raw
    # Match phase rows: lines starting with "| <digit>" (anchored to avoid false positives)
    $total = ([regex]::Matches($content, "(?m)^\| *\d+ *\|")).Count
    $complete = ([regex]::Matches($content, "✅")).Count

    $totalAll += $total
    $completeAll += $complete

    Write-Host "$($planFile.Name): $complete/$total phases complete"
}

Write-Host ""

if ($completeAll -eq $totalAll -and $totalAll -gt 0) {
    Write-Host "ALL PHASES COMPLETE — consider running /sticky:done to clean up."
} else {
    Write-Host "IN PROGRESS — $completeAll/$totalAll phases done."
}

# Stop hooks must always exit 0 — non-zero is treated as an error by Claude Code
exit 0
