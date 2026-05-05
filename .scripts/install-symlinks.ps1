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

# Dynamically discover skills and Gemini commands from the submodule
# Each becomes an individual file symlink (not directory — those break on Windows git clone)
$skillSymlinks = @()
$skillsDir = Join-Path $ScriptDir 'skills'
if (Test-Path $skillsDir) {
    Get-ChildItem $skillsDir -Directory | ForEach-Object {
        $name = $_.Name
        # Claude/Copilot: .claude/skills/<name>/SKILL.md → ../../../.ai/skills/<name>/SKILL.md
        $skillSymlinks += @{ Link = ".claude/skills/$name/SKILL.md"; Target = "../../../.ai/skills/$name/SKILL.md" }
    }
}

$geminiSymlinks = @()
$geminiCmdsDir = Join-Path $ScriptDir '.gemini/commands'
if (Test-Path $geminiCmdsDir) {
    Get-ChildItem $geminiCmdsDir -File -Filter '*.toml' | ForEach-Object {
        $name = $_.Name
        # Gemini: .gemini/commands/<name>.toml → ../../.ai/.gemini/commands/<name>.toml
        $geminiSymlinks += @{ Link = ".gemini/commands/$name"; Target = "../../.ai/.gemini/commands/$name" }
    }
}

$geminiPoliciesDir = Join-Path $ScriptDir '.gemini/policies'
if (Test-Path $geminiPoliciesDir) {
    Get-ChildItem $geminiPoliciesDir -File -Filter '*.toml' | ForEach-Object {
        $name = $_.Name
        # Gemini: .gemini/policies/<name>.toml → ../../.ai/.gemini/policies/<name>.toml
        $geminiSymlinks += @{ Link = ".gemini/policies/$name"; Target = "../../.ai/.gemini/policies/$name" }
    }
}

$geminiSettings = Join-Path $ScriptDir '.gemini/settings.json'
if (Test-Path $geminiSettings) {
    $geminiSymlinks += @{ Link = '.gemini/settings.json'; Target = '../../.ai/.gemini/settings.json' }
}

# ---------------------------------------------------------------------------
# Helper: create a single symlink (file or directory)
# ---------------------------------------------------------------------------
function Install-Symlink {
    param(
        [string]$LinkRelative,
        [string]$Target
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
            Write-Host "OK       $LinkRelative"
            return
        }

        # It's a regular file
        if (-not $Force) {
            Write-Warning "SKIP     $LinkRelative exists as a regular file. Use -Force to overwrite."
            return
        }

        if ($DryRun) {
            Write-Host "[dry-run] Would remove existing: $LinkRelative"
        } else {
            Remove-Item $linkPath -Force
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
Write-Host "=== Claude/Copilot skill symlinks ($($skillSymlinks.Count) skills) ==="
foreach ($entry in $skillSymlinks) {
    Install-Symlink -LinkRelative $entry.Link -Target $entry.Target
}

Write-Host ""
Write-Host "=== Gemini configuration symlinks ($($geminiSymlinks.Count) files) ==="
foreach ($entry in $geminiSymlinks) {
    Install-Symlink -LinkRelative $entry.Link -Target $entry.Target
}

# ---------------------------------------------------------------------------
# Git add & validate all symlinks are stored correctly (mode 120000)
# ---------------------------------------------------------------------------
$allLinks = @($fileSymlinks + $skillSymlinks + $geminiSymlinks) | ForEach-Object { $_.Link }

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

# ---------------------------------------------------------------------------
# Scaffold docs/ directory tree (if it doesn't exist yet)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Docs directory structure ==="

$docsDirs = @(
    'docs/briefs/active'
    'docs/briefs/archive'
    'docs/specs/active'
    'docs/specs/archive'
    'docs/plans/active'
    'docs/plans/archive'
    'docs/decisions'
)

foreach ($dir in $docsDirs) {
    $dirPath = Join-Path $RepoRoot $dir
    if (Test-Path $dirPath) {
        Write-Host "OK       $dir/"
    } elseif ($DryRun) {
        Write-Host "[dry-run] Would create: $dir/"
    } else {
        New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
        # Add .gitkeep so empty dirs are tracked
        $gitkeep = Join-Path $dirPath '.gitkeep'
        if (-not (Test-Path $gitkeep)) {
            New-Item -ItemType File -Path $gitkeep -Force | Out-Null
        }
        Write-Host "CREATED  $dir/"
    }
}

# Create docs/README.md stub if missing (refresh-docs skill regenerates it)
$docsIndex = Join-Path $RepoRoot 'docs/README.md'
if (Test-Path $docsIndex) {
    Write-Host "OK       docs/README.md"
} elseif ($DryRun) {
    Write-Host "[dry-run] Would create: docs/README.md"
} else {
    Set-Content -Path $docsIndex -Value @"
# Documentation Index

> Auto-generated by the `/refresh-docs` skill. Do not edit by hand.
"@
    Write-Host "CREATED  docs/README.md"
}

if (-not $DryRun) {
    git add docs/
    Write-Host "Staged docs/ in git."
}

# ---------------------------------------------------------------------------
# Scaffold .ai-local/ directory (project-specific config, outside submodule)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Project-local config (.ai-local/) ==="

$aiLocalDirs = @(
    '.ai-local/rules'
    '.ai-local/overrides'
)

foreach ($dir in $aiLocalDirs) {
    $dirPath = Join-Path $RepoRoot $dir
    if (Test-Path $dirPath) {
        Write-Host "OK       $dir/"
    } elseif ($DryRun) {
        Write-Host "[dry-run] Would create: $dir/"
    } else {
        New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
        $gitkeep = Join-Path $dirPath '.gitkeep'
        if (-not (Test-Path $gitkeep)) {
            New-Item -ItemType File -Path $gitkeep -Force | Out-Null
        }
        Write-Host "CREATED  $dir/"
    }
}

# Copy project.yaml.example → .ai-local/project.yaml if missing
$projectYaml = Join-Path $RepoRoot '.ai-local/project.yaml'
$projectYamlExample = Join-Path $ScriptDir 'project.yaml.example'

if (Test-Path $projectYaml) {
    Write-Host "OK       .ai-local/project.yaml (already exists)"
} elseif (-not (Test-Path $projectYamlExample)) {
    Write-Warning "SKIP     .ai-local/project.yaml.example not found — cannot scaffold project.yaml"
} elseif ($DryRun) {
    Write-Host "[dry-run] Would create .ai-local/project.yaml from template"
} else {
    $projName = "example-mobile-app"
    $stack = "react-native"

    # Interactive Project Configuration
    if (-not $DryRun) {
        Write-Host ""
        Write-Host "--- Project Configuration ---"
        $inputName = Read-Host "Enter project name [$projName]"
        if ($inputName) { $projName = $inputName }

        $stacksDir = Join-Path $ScriptDir "rules/stacks"
        if (Test-Path $stacksDir) {
            $availableStacks = Get-ChildItem $stacksDir -Directory
            Write-Host "Available stacks:"
            for ($i = 0; $i -lt $availableStacks.Count; $i++) {
                Write-Host ("  {0}) {1}" -f ($i + 1), $availableStacks[$i].Name)
            }
            Write-Host ("  {0}) Custom..." -f ($availableStacks.Count + 1))

            $stack = $null
            while ($null -eq $stack) {
                $choice = Read-Host "Select a stack (1-$($availableStacks.Count + 1))"
                if ($choice) {
                    if ($choice -eq ($availableStacks.Count + 1)) {
                        while ($null -eq $stack) {
                            $customStack = Read-Host "Enter custom stack name"
                            if ($customStack) { $stack = $customStack }
                        }
                    } elseif ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $availableStacks.Count) {
                        $stack = $availableStacks[$choice - 1].Name
                    } else {
                        Write-Host "Invalid selection."
                    }
                }
            }
        }
        Write-Host "-----------------------------"
    }

    $content = Get-Content $projectYamlExample -Raw
    $content = $content -replace 'name: "example-mobile-app"', ('name: "{0}"' -f $projName)
    $content = $content -replace 'type: react-native', ('type: {0}' -f $stack)
    $content = $content -replace 'stacks: \[react-native\]', ('stacks: [{0}]' -f $stack)
    $content = $content -replace 'rules/stacks/react-native/', ('rules/stacks/{0}/' -f $stack)
    
    Set-Content -Path $projectYaml -Value $content
    Write-Host "CREATED  .ai-local/project.yaml (customized: name=$projName, stack=$stack)"
}

if (-not $DryRun) {
    git add .ai-local/
    Write-Host "Staged .ai-local/ in git."
}

Write-Host ""
Write-Host "Done. All symlinks installed and verified."

} finally {
    Pop-Location
}
