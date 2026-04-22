#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Updates the dot-ai submodule and refreshes all symlinks.

.DESCRIPTION
    This script:
      1. Pulls the latest dot-ai submodule from its tracking branch (--remote)
      2. Removes dead symlinks (skills/commands that no longer exist upstream)
      3. Re-invokes install-symlinks.ps1 to create any new symlinks
      4. Stages everything in git

.PARAMETER DryRun
    Show what would be done without making changes.

.EXAMPLE
    .ai/.scripts/update-submodule.ps1
    .ai/.scripts/update-submodule.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
$ScriptsDir = $PSScriptRoot                               # .ai/.scripts/
$AiDir      = Split-Path -Parent $ScriptsDir              # .ai/
$RepoRoot   = Split-Path -Parent $AiDir                   # repo root

if (-not (Test-Path (Join-Path $AiDir 'AGENTS.md'))) {
    Write-Error "Cannot find .ai/AGENTS.md — is this script inside .ai/.scripts/?"
    exit 1
}

Push-Location $RepoRoot
try {

# ---------------------------------------------------------------------------
# Step 1: Update submodule
# ---------------------------------------------------------------------------
Write-Host "=== Updating .ai submodule ==="

$beforeSha = (git -C .ai rev-parse HEAD 2>$null) ?? 'unknown'

if ($DryRun) {
    Write-Host "[dry-run] Would run: git submodule update --remote .ai"
} else {
    git submodule update --remote .ai 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git submodule update --remote failed (exit $LASTEXITCODE)"
        exit 1
    }
}

$afterSha = (git -C .ai rev-parse HEAD 2>$null) ?? 'unknown'

if ($beforeSha -eq $afterSha) {
    Write-Host "Already up to date ($($beforeSha.Substring(0,8)))"
} else {
    Write-Host "Updated: $($beforeSha.Substring(0,8)) -> $($afterSha.Substring(0,8))"
    if (-not $DryRun) {
        # Show what changed
        git -C .ai --no-pager log --oneline "$beforeSha..$afterSha"
    }
}

# ---------------------------------------------------------------------------
# Step 2: Remove dead symlinks (targets removed upstream)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Pruning dead symlinks ==="

$deadCount = 0

# Check .claude/skills/*/SKILL.md
$claudeSkillsDir = Join-Path $RepoRoot '.claude/skills'
if (Test-Path $claudeSkillsDir) {
    Get-ChildItem $claudeSkillsDir -Directory | ForEach-Object {
        $skillMd = Join-Path $_.FullName 'SKILL.md'
        if (-not (Test-Path $skillMd)) { return }

        $item = Get-Item $skillMd -Force
        if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return }

        # Resolve target — does the submodule still have this skill?
        $targetSkill = Join-Path $AiDir "skills/$($_.Name)/SKILL.md"
        if (Test-Path $targetSkill) { return }

        # Dead symlink — target no longer exists
        $relPath = ".claude/skills/$($_.Name)/SKILL.md"
        if ($DryRun) {
            Write-Host "[dry-run] Would remove dead symlink: $relPath"
        } else {
            git rm -f $relPath 2>$null
            # Remove empty parent dir
            $parentDir = Split-Path -Parent $skillMd
            if ((Test-Path $parentDir) -and @(Get-ChildItem $parentDir -Force).Count -eq 0) {
                Remove-Item $parentDir -Force
            }
            Write-Host "REMOVED  $relPath (skill removed upstream)"
        }
        $deadCount++
    }
}

# Check .gemini/commands/*.toml
$geminiCmdsDir = Join-Path $RepoRoot '.gemini/commands'
if (Test-Path $geminiCmdsDir) {
    Get-ChildItem $geminiCmdsDir -File -Filter '*.toml' | ForEach-Object {
        $item = Get-Item $_.FullName -Force
        if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return }

        # Does the submodule still have this command?
        $targetToml = Join-Path $AiDir ".gemini/commands/$($_.Name)"
        if (Test-Path $targetToml) { return }

        $relPath = ".gemini/commands/$($_.Name)"
        if ($DryRun) {
            Write-Host "[dry-run] Would remove dead symlink: $relPath"
        } else {
            git rm -f $relPath 2>$null
            Write-Host "REMOVED  $relPath (command removed upstream)"
        }
        $deadCount++
    }
}

if ($deadCount -eq 0) {
    Write-Host "No dead symlinks found."
} else {
    Write-Host "Pruned $deadCount dead symlink(s)."
}

# ---------------------------------------------------------------------------
# Step 3: Re-invoke install to create new symlinks / verify existing
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Running install-symlinks.ps1 ==="

$installScript = Join-Path $ScriptsDir 'install-symlinks.ps1'
$installArgs = @{ DryRun = $DryRun }

& $installScript @installArgs

# ---------------------------------------------------------------------------
# Step 4: Stage the submodule bump itself
# ---------------------------------------------------------------------------
if (-not $DryRun) {
    git add .ai
    Write-Host ""
    Write-Host "Staged .ai submodule bump."
}

Write-Host ""
Write-Host "Done. Review staged changes with: git diff --cached --stat"

} finally {
    Pop-Location
}
