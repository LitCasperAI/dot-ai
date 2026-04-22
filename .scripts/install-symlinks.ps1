#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates git-compatible symlinks from AI agent entry-point files to .ai/AGENTS.md.

.DESCRIPTION
    This script is part of the dot-ai submodule (.ai/).
    It creates symlinks so that various AI coding tools (Claude Code, Gemini CLI,
    GitHub Copilot, etc.) all resolve to the single .ai/AGENTS.md file.

    Symlinks created (relative to repo root):
      CLAUDE.md                         -> .ai/AGENTS.md
      GEMINI.md                         -> .ai/AGENTS.md
      .github/copilot-instructions.md   -> ../.ai/AGENTS.md

    On Windows, the script:
      - Enables git symlink support (core.symlinks = true)
      - Requires either Developer Mode or an elevated (admin) shell to create symlinks

.PARAMETER Force
    Overwrite existing files (non-symlink) with symlinks.

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
# Symlink definitions: LinkPath (relative to repo root) -> Target (relative to link location)
# ---------------------------------------------------------------------------
$symlinks = @(
    @{ Link = 'CLAUDE.md';                          Target = '.ai/AGENTS.md' }
    @{ Link = 'GEMINI.md';                          Target = '.ai/AGENTS.md' }
    @{ Link = '.github/copilot-instructions.md';    Target = '../.ai/AGENTS.md' }
)

# ---------------------------------------------------------------------------
# Create symlinks
# ---------------------------------------------------------------------------
foreach ($entry in $symlinks) {
    $linkPath   = Join-Path $RepoRoot $entry.Link
    $linkDir    = Split-Path -Parent $linkPath
    $target     = $entry.Target

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
            Write-Host "OK  $($entry.Link) (symlink already exists)"
            continue
        }

        # It's a regular file
        if (-not $Force) {
            Write-Warning "SKIP  $($entry.Link) exists as a regular file. Use -Force to overwrite."
            continue
        }

        if ($DryRun) {
            Write-Host "[dry-run] Would remove existing file: $($entry.Link)"
        } else {
            Remove-Item $linkPath -Force
        }
    }

    if ($DryRun) {
        Write-Host "[dry-run] Would create symlink: $($entry.Link) -> $target"
    } else {
        New-Item -ItemType SymbolicLink -Path $linkPath -Value $target | Out-Null
        Write-Host "CREATED  $($entry.Link) -> $target"
    }
}

# ---------------------------------------------------------------------------
# Git add & validate symlinks are stored correctly (mode 120000)
# ---------------------------------------------------------------------------
$linkPaths = $symlinks | ForEach-Object { $_.Link }

if ($DryRun) {
    Write-Host "[dry-run] Would run: git add $($linkPaths -join ' ')"
    Write-Host "[dry-run] Would verify symlink mode (120000) in git index"
} else {
    Write-Host ""
    git add @linkPaths
    Write-Host "Staged symlinks in git."

    # Validate that git recorded them as symlinks (mode 120000), not regular files
    $failed = @()
    foreach ($lp in $linkPaths) {
        $lsEntry = git ls-files -s $lp 2>$null
        if ($lsEntry -match '^120000') {
            Write-Host "VERIFIED  $lp (git mode 120000 — symlink)"
        } else {
            Write-Warning "PROBLEM   $lp is NOT stored as a symlink in git: $lsEntry"
            $failed += $lp
        }
    }

    if ($failed.Count -gt 0) {
        Write-Host ""
        Write-Warning @"
Some files are not stored as symlinks in git. Common causes:
  - core.symlinks was false when the files were first added
  - The files were added as regular files before this script ran
Fix: ensure core.symlinks = true, delete the files, run this script again.
"@
        exit 1
    }
}

Write-Host ""
Write-Host "Done."

} finally {
    Pop-Location
}
