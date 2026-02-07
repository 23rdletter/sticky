# Idempotent session initialisation for sticky.
# Creates docs/ directory and planning files if they don't exist.
#
# Usage: init-session.ps1 <slug> [title] [branch]
#   slug   - keyword slug for filenames, e.g. "condition-enrichment"
#   title  - human-readable title (defaults to slug with dashes replaced)
#   branch - git branch name (defaults to current branch)
#
# Safe to run multiple times - only creates what's missing.

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Slug,

    [Parameter(Position=1)]
    [string]$Title,

    [Parameter(Position=2)]
    [string]$Branch
)

$ErrorActionPreference = "Stop"

# Defaults
if (-not $Title) {
    $Title = ($Slug -replace '-', ' ') -replace '\b(\w)', { $_.Groups[1].Value.ToUpper() }
}
if (-not $Branch) {
    $Branch = git branch --show-current 2>$null
    if (-not $Branch) { $Branch = "main" }
}
$Date = Get-Date -Format "yyyy-MM-dd"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplateDir = Join-Path (Split-Path -Parent $ScriptDir) "templates"

$Created = @()

# 1. Create docs/ if missing
if (-not (Test-Path "docs")) {
    New-Item -ItemType Directory -Path "docs" -Force | Out-Null
    $Created += "  created docs/"
}

# 2. Create task_plan if missing
$TaskPlan = "docs/task_plan-${Date}-${Slug}.md"
$existingPlan = Get-Item "docs/task_plan-*.md" -ErrorAction SilentlyContinue
if (-not $existingPlan) {
    $templatePath = Join-Path $TemplateDir "task_plan.md"
    if (Test-Path $templatePath) {
        $content = Get-Content $templatePath -Raw
        $content = $content -replace '\{TITLE\}', $Title
        $content = $content -replace '\{BRANCH\}', $Branch
        $content = $content -replace '\{DATE\}', $Date
        $content = $content -replace '\{PLAN_LINK\}', 'none yet'
        Set-Content -Path $TaskPlan -Value $content -NoNewline
    } else {
        @"
# Task Plan: $Title

**Branch:** ``$Branch``
**Blueprint:** _none yet_
**Started:** $Date

## Current Phase

Phase 1 next.

## Phase Tracker

| # | Phase | Status | Depends On |
|---|-------|--------|------------|
| 1 | TBD | pending | - |

## Decisions

| Decision | Rationale |
|----------|-----------|

## Errors

| Error | Phase | Resolution |
|-------|-------|------------|
"@ | Set-Content -Path $TaskPlan -NoNewline
    }
    $Created += "  created $TaskPlan"
} else {
    Write-Host "[sticky] task_plan already exists: $($existingPlan[0].Name)"
}

# 3. Create findings if missing
$Findings = "docs/findings-${Date}-${Slug}.md"
$existingFindings = Get-Item "docs/findings-*.md" -ErrorAction SilentlyContinue
if (-not $existingFindings) {
    $templatePath = Join-Path $TemplateDir "findings.md"
    if (Test-Path $templatePath) {
        $content = Get-Content $templatePath -Raw
        $content = $content -replace '\{TITLE\}', $Title
        Set-Content -Path $Findings -Value $content -NoNewline
    } else {
        @"
# Findings - $Title

## Requirements / Constraints

-

## Discoveries

-

## Decisions

| Decision | Rationale |
|----------|-----------|

## Blockers

-
"@ | Set-Content -Path $Findings -NoNewline
    }
    $Created += "  created $Findings"
} else {
    Write-Host "[sticky] findings already exists: $($existingFindings[0].Name)"
}

# 4. Create progress.md if missing
if (-not (Test-Path "docs/progress.md")) {
    $templatePath = Join-Path $TemplateDir "progress.md"
    if (Test-Path $templatePath) {
        Copy-Item $templatePath "docs/progress.md"
    } else {
        @"
# Progress Log

<!-- Persistent project-level changelog. Each entry is appended by /sticky:done
     (or staleness cleanup in /sticky:start). Never deleted by sticky commands. -->
"@ | Set-Content -Path "docs/progress.md" -NoNewline
    }
    $Created += "  created docs/progress.md"
}

# Report
if ($Created.Count -gt 0) {
    Write-Host ""
    Write-Host "[sticky] Initialised session files:"
    $Created | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "[sticky] All session files already exist - nothing to create."
}
