#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Installs dot-ai symlinks into the consumer repository.

.DESCRIPTION
    This script is part of the dot-ai submodule (.ai/).
    It creates symlinks so that various AI coding tools (Claude Code, Gemini CLI,
    GitHub Copilot CLI, etc.) all resolve to content inside .ai/.

    File symlinks (entry points → .ai/AGENTS.md):
      CLAUDE.md                         -> .ai/AGENTS.md
      GEMINI.md                         -> .ai/AGENTS.md
      .github/copilot-instructions.md   -> ../.ai/AGENTS.md

    Directory symlinks (agent skill/command dirs → .ai/):
      .claude/skills                    -> ../.ai/skills
      .gemini/commands                  -> ../.ai/.gemini/commands

    On Windows, the script:
      - Enables git symlink support (core.symlinks = true)
      - Requires either Developer Mode or an elevated (admin) shell

.PARAMETER Force
    Overwrite existing files/directories (non-symlink) with symlinks.

.PARAMETER DryRun
    Show what would be done without making changes.

.EXAMPLE
    .ai/.scripts/install-symlinks.ps1
    .ai/.scripts/install-symlinks.ps1 -Force
    .ai/.scripts/install-symlinks.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Resolve repo root (parent of .ai/)
# ---------------------------------------------------------------------------
$ScriptDir = Split-Path -Parent $PSScriptRoot          # .ai/
$RepoRoot  = Split-Path -Parent $ScriptDir              # repo root

# Sanity check: we expect to be inside .ai/.scripts/
if (-not (Test-Path (Join-Path $ScriptDir 'AGENTS.md'))) {
    Write-Error "Cannot find .ai/AGENTS.md — is this script inside .ai/.scripts/?"
    exit 1
}

Push-Location $RepoRoot
try {

# ---------------------------------------------------------------------------
# Windows: ensure git symlink support is enabled
# ---------------------------------------------------------------------------
$IsWindows_ = ($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows

if ($IsWindows_) {
    $currentValue = git config --local --get core.symlinks 2>$null
    if ($currentValue -ne 'true') {
        if ($DryRun) {
            Write-Host "[dry-run] Would set git config core.symlinks = true"
        } else {
            Write-Host "Enabling git symlinks (core.symlinks = true) ..."
            git config --local core.symlinks true
        }
    }

    # Quick check: can we create symlinks at all?
    if (-not $DryRun) {
        $testLink = Join-Path $RepoRoot '.ai/.scripts/.symlink-test'
        $testTarget = Join-Path $RepoRoot '.ai/AGENTS.md'
        try {
            New-Item -ItemType SymbolicLink -Path $testLink -Value $testTarget -Force | Out-Null
            Remove-Item $testLink -Force
        }
        catch {
            Write-Warning @"
Cannot create symlinks. On Windows you need one of:
  1. Developer Mode enabled  (Settings > Update & Security > For developers)
  2. Run this script in an elevated (Administrator) PowerShell
Aborting.
"@
            exit 1
        }
    }
}

# ---------------------------------------------------------------------------
# Symlink definitions
# ---------------------------------------------------------------------------

# File symlinks: entry-point files → .ai/AGENTS.md
$fileSymlinks = @(
    @{ Link = 'CLAUDE.md';                          Target = '.ai/AGENTS.md' }
    @{ Link = 'GEMINI.md';                          Target = '.ai/AGENTS.md' }
    @{ Link = '.github/copilot-instructions.md';    Target = '../.ai/AGENTS.md' }
)

# Directory symlinks: agent-specific dirs → content in .ai/
$dirSymlinks = @(
    @{ Link = '.claude/skills';     Target = '../.ai/skills' }
    @{ Link = '.gemini/commands';   Target = '../.ai/.gemini/commands' }
)

# ---------------------------------------------------------------------------
# Helper: create a single symlink (file or directory)
# ---------------------------------------------------------------------------
function Install-Symlink {
    param(
        [string]$LinkRelative,
        [string]$Target,
        [switch]$IsDirectory
    )

    $linkPath = Join-Path $RepoRoot $LinkRelative
    $linkDir  = Split-Path -Parent $linkPath

    # Ensure parent directory exists
    if (-not (Test-Path $linkDir)) {
        if ($DryRun) {
            Write-Host "[dry-run] Would create directory: $linkDir"
        } else {
            New-Item -ItemType Directory -Path $linkDir -Force | Out-Null
        }
    }

    # Check if link already exists
    if (Test-Path $linkPath) {
        $item = Get-Item $linkPath -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            Write-Host "OK       $LinkRelative (symlink already exists)"
            return
        }

        # It's a regular file or directory
        if (-not $Force) {
            $kind = if ($IsDirectory) { 'directory' } else { 'file' }
            Write-Warning "SKIP     $LinkRelative exists as a regular $kind. Use -Force to overwrite."
            return
        }

        if ($DryRun) {
            Write-Host "[dry-run] Would remove existing: $LinkRelative"
        } else {
            Remove-Item $linkPath -Force -Recurse
        }
    }

    if ($DryRun) {
        Write-Host "[dry-run] Would create symlink: $LinkRelative -> $Target"
    } else {
        New-Item -ItemType SymbolicLink -Path $linkPath -Value $Target | Out-Null
        Write-Host "CREATED  $LinkRelative -> $Target"
    }
}

# ---------------------------------------------------------------------------
# Create all symlinks
# ---------------------------------------------------------------------------
Write-Host "=== File symlinks (entry points) ==="
foreach ($entry in $fileSymlinks) {
    Install-Symlink -LinkRelative $entry.Link -Target $entry.Target
}

Write-Host ""
Write-Host "=== Directory symlinks (skills & commands) ==="
foreach ($entry in $dirSymlinks) {
    Install-Symlink -LinkRelative $entry.Link -Target $entry.Target -IsDirectory
}

# ---------------------------------------------------------------------------
# Git add & validate all symlinks are stored correctly (mode 120000)
# ---------------------------------------------------------------------------
$allLinks = @($fileSymlinks + $dirSymlinks) | ForEach-Object { $_.Link }

if ($DryRun) {
    Write-Host ""
    Write-Host "[dry-run] Would run: git add $($allLinks -join ' ')"
    Write-Host "[dry-run] Would verify symlink mode (120000) in git index"
} else {
    Write-Host ""
    git add @allLinks
    Write-Host "Staged all symlinks in git."

    # Validate that git recorded them as symlinks (mode 120000)
    $failed = @()
    foreach ($lp in $allLinks) {
        $lsEntry = git ls-files -s $lp 2>$null
        if ($lsEntry -match '^120000') {
            Write-Host "VERIFIED $lp (git mode 120000 — symlink)"
        } else {
            Write-Warning "PROBLEM  $lp is NOT stored as a symlink in git: $lsEntry"
            $failed += $lp
        }
    }

    if ($failed.Count -gt 0) {
        Write-Host ""
        Write-Warning @"
Some paths are not stored as symlinks in git. Common causes:
  - core.symlinks was false when the paths were first added
  - The paths were added as regular files/dirs before this script ran
Fix: ensure core.symlinks = true, remove the paths, run this script again.
"@
        exit 1
    }
}

Write-Host ""
Write-Host "Done. All symlinks installed and verified."

} finally {
    Pop-Location
}
