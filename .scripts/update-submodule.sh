#!/bin/sh
# update-submodule.sh — Updates the dot-ai submodule and refreshes all symlinks.
#
# Usage:
#   .ai/.scripts/update-submodule.sh            # normal run
#   .ai/.scripts/update-submodule.sh --dry-run   # preview only
#
# Steps:
#   1. Pulls latest .ai submodule from its tracking branch (--remote)
#   2. Removes dead symlinks (skills/commands removed upstream)
#   3. Re-invokes install-symlinks.sh to create any new symlinks
#   4. Stages everything in git

set -eu

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            sed -n '2,14s/^# \?//p' "$0"
            exit 0
            ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"   # .ai/.scripts/
AI_DIR="$(dirname "$SCRIPTS_DIR")"              # .ai/
REPO_ROOT="$(dirname "$AI_DIR")"                # repo root

if [ ! -f "$AI_DIR/AGENTS.md" ]; then
    echo "ERROR: Cannot find .ai/AGENTS.md — is this script inside .ai/.scripts/?" >&2
    exit 1
fi

cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# Step 1: Update submodule
# ---------------------------------------------------------------------------
echo "=== Updating .ai submodule ==="

before_sha="$(git -C .ai rev-parse HEAD 2>/dev/null || echo unknown)"

if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] Would run: git submodule update --remote .ai"
else
    git submodule update --remote .ai
fi

after_sha="$(git -C .ai rev-parse HEAD 2>/dev/null || echo unknown)"

if [ "$before_sha" = "$after_sha" ]; then
    echo "Already up to date (${before_sha%${before_sha#????????}})"
else
    echo "Updated: ${before_sha%${before_sha#????????}} -> ${after_sha%${after_sha#????????}}"
    if [ "$DRY_RUN" != true ]; then
        git -C .ai --no-pager log --oneline "$before_sha..$after_sha"
    fi
fi

# ---------------------------------------------------------------------------
# Step 2: Remove dead symlinks (targets removed upstream)
# ---------------------------------------------------------------------------
echo ""
echo "=== Pruning dead symlinks ==="

dead_count=0

# Check .claude/skills/*/SKILL.md
if [ -d ".claude/skills" ]; then
    for skill_dir in .claude/skills/*/; do
        [ -d "$skill_dir" ] || continue
        skill_md="${skill_dir}SKILL.md"
        [ -L "$skill_md" ] || continue

        name="$(basename "$skill_dir")"
        target_skill="$AI_DIR/skills/$name/SKILL.md"

        if [ ! -f "$target_skill" ]; then
            rel_path=".claude/skills/$name/SKILL.md"
            if [ "$DRY_RUN" = true ]; then
                echo "[dry-run] Would remove dead symlink: $rel_path"
            else
                git rm -f "$rel_path" 2>/dev/null || rm -f "$rel_path"
                # Remove empty parent dir
                rmdir "$skill_dir" 2>/dev/null || true
                echo "REMOVED  $rel_path (skill removed upstream)"
            fi
            dead_count=$((dead_count + 1))
        fi
    done
fi

# Check .gemini/commands/*.toml
if [ -d ".gemini/commands" ]; then
    for toml in .gemini/commands/*.toml; do
        [ -L "$toml" ] || continue

        name="$(basename "$toml")"
        target_toml="$AI_DIR/.gemini/commands/$name"

        if [ ! -f "$target_toml" ]; then
            rel_path=".gemini/commands/$name"
            if [ "$DRY_RUN" = true ]; then
                echo "[dry-run] Would remove dead symlink: $rel_path"
            else
                git rm -f "$rel_path" 2>/dev/null || rm -f "$rel_path"
                echo "REMOVED  $rel_path (command removed upstream)"
            fi
            dead_count=$((dead_count + 1))
        fi
    done
fi

if [ "$dead_count" -eq 0 ]; then
    echo "No dead symlinks found."
else
    echo "Pruned $dead_count dead symlink(s)."
fi

# ---------------------------------------------------------------------------
# Step 3: Re-invoke install to create new symlinks / verify existing
# ---------------------------------------------------------------------------
echo ""
echo "=== Running install-symlinks.sh ==="

install_script="$SCRIPTS_DIR/install-symlinks.sh"
install_args=""
if [ "$DRY_RUN" = true ]; then install_args="--dry-run"; fi

# shellcheck disable=SC2086
sh "$install_script" $install_args

# ---------------------------------------------------------------------------
# Step 4: Stage the submodule bump itself
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" != true ]; then
    git add .ai
    echo ""
    echo "Staged .ai submodule bump."
fi

echo ""
echo "Done. Review staged changes with: git diff --cached --stat"
