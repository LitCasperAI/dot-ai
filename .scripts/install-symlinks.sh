#!/bin/sh
# install-symlinks.sh — Installs dot-ai symlinks into the consumer repository.
#
# Usage:
#   .ai/.scripts/install-symlinks.sh            # normal run
#   .ai/.scripts/install-symlinks.sh --force     # overwrite existing non-symlinks
#   .ai/.scripts/install-symlinks.sh --dry-run   # preview only
#
# Creates 5 symlinks:
#   File symlinks (entry points → .ai/AGENTS.md):
#     CLAUDE.md                       -> .ai/AGENTS.md
#     GEMINI.md                       -> .ai/AGENTS.md
#     .github/copilot-instructions.md -> ../.ai/AGENTS.md
#   Directory symlinks (agent dirs → .ai/):
#     .claude/skills                  -> ../.ai/skills
#     .gemini/commands                -> ../.ai/.gemini/commands

set -eu

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
FORCE=false
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --force)   FORCE=true ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            sed -n '2,17s/^# \?//p' "$0"
            exit 0
            ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Resolve repo root
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"   # .ai/.scripts/
AI_DIR="$(dirname "$SCRIPT_DIR")"              # .ai/
REPO_ROOT="$(dirname "$AI_DIR")"               # repo root

if [ ! -f "$AI_DIR/AGENTS.md" ]; then
    echo "ERROR: Cannot find .ai/AGENTS.md — is this script inside .ai/.scripts/?" >&2
    exit 1
fi

cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# Helper: install a symlink (file or directory)
# ---------------------------------------------------------------------------
install_symlink() {
    link_rel="$1"    # relative to repo root
    target="$2"      # relative to link's parent directory

    link_path="$REPO_ROOT/$link_rel"
    link_dir="$(dirname "$link_path")"

    # Ensure parent directory exists
    if [ ! -d "$link_dir" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[dry-run] Would create directory: $link_dir"
        else
            mkdir -p "$link_dir"
        fi
    fi

    # Check if link already exists
    if [ -L "$link_path" ]; then
        echo "OK       $link_rel (symlink already exists)"
        return
    fi

    if [ -e "$link_path" ]; then
        if [ "$FORCE" != true ]; then
            echo "WARNING: SKIP     $link_rel exists (not a symlink). Use --force to overwrite." >&2
            return
        fi
        if [ "$DRY_RUN" = true ]; then
            echo "[dry-run] Would remove existing: $link_rel"
        else
            rm -rf "$link_path"
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "[dry-run] Would create symlink: $link_rel -> $target"
    else
        ln -s "$target" "$link_path"
        echo "CREATED  $link_rel -> $target"
    fi
}

# ---------------------------------------------------------------------------
# Create all symlinks
# ---------------------------------------------------------------------------
echo "=== File symlinks (entry points) ==="
install_symlink "CLAUDE.md"                       ".ai/AGENTS.md"
install_symlink "GEMINI.md"                       ".ai/AGENTS.md"
install_symlink ".github/copilot-instructions.md" "../.ai/AGENTS.md"

echo ""
echo "=== Directory symlinks (skills & commands) ==="
install_symlink ".claude/skills"    "../.ai/skills"
install_symlink ".gemini/commands"  "../.ai/.gemini/commands"

# ---------------------------------------------------------------------------
# Git add & validate all symlinks are stored correctly (mode 120000)
# ---------------------------------------------------------------------------
ALL_LINKS="CLAUDE.md GEMINI.md .github/copilot-instructions.md .claude/skills .gemini/commands"

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "[dry-run] Would run: git add $ALL_LINKS"
    echo "[dry-run] Would verify symlink mode (120000) in git index"
else
    echo ""
    # shellcheck disable=SC2086
    git add $ALL_LINKS
    echo "Staged all symlinks in git."

    failed=0
    for lp in $ALL_LINKS; do
        ls_entry="$(git ls-files -s "$lp" 2>/dev/null || true)"
        case "$ls_entry" in
            120000*)
                echo "VERIFIED $lp (git mode 120000 — symlink)"
                ;;
            *)
                echo "WARNING: PROBLEM  $lp is NOT stored as a symlink in git: $ls_entry" >&2
                failed=1
                ;;
        esac
    done

    if [ "$failed" -ne 0 ]; then
        echo "" >&2
        echo "WARNING: Some paths are not stored as symlinks in git." >&2
        echo "  Common causes:" >&2
        echo "    - core.symlinks was false when the paths were first added" >&2
        echo "    - The paths were added as regular files/dirs before this script ran" >&2
        echo "  Fix: ensure core.symlinks = true, remove the paths, run this script again." >&2
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# Scaffold docs/ directory tree
# ---------------------------------------------------------------------------
echo ""
echo "=== Docs directory structure ==="

for dir in \
    docs/briefs/active \
    docs/briefs/archive \
    docs/specs/active \
    docs/specs/archive \
    docs/plans/active \
    docs/plans/archive \
    docs/decisions
do
    if [ -d "$REPO_ROOT/$dir" ]; then
        echo "OK       $dir/"
    elif [ "$DRY_RUN" = true ]; then
        echo "[dry-run] Would create: $dir/"
    else
        mkdir -p "$REPO_ROOT/$dir"
        touch "$REPO_ROOT/$dir/.gitkeep"
        echo "CREATED  $dir/"
    fi
done

# Create docs/README.md stub if missing
docs_index="$REPO_ROOT/docs/README.md"
if [ -f "$docs_index" ]; then
    echo "OK       docs/README.md"
elif [ "$DRY_RUN" = true ]; then
    echo "[dry-run] Would create: docs/README.md"
else
    cat > "$docs_index" <<'EOF'
# Documentation Index

> Auto-generated by the `/refresh-docs` skill. Do not edit by hand.
EOF
    echo "CREATED  docs/README.md"
fi

if [ "$DRY_RUN" != true ]; then
    git add docs/
    echo "Staged docs/ in git."
fi

# ---------------------------------------------------------------------------
# Copy project.yaml.example → project.yaml if missing
# ---------------------------------------------------------------------------
echo ""
echo "=== Project manifest ==="

project_yaml="$REPO_ROOT/.ai/project.yaml"
project_yaml_example="$AI_DIR/project.yaml.example"

if [ -f "$project_yaml" ]; then
    echo "OK       .ai/project.yaml (already exists)"
elif [ ! -f "$project_yaml_example" ]; then
    echo "WARNING: SKIP     .ai/project.yaml.example not found" >&2
else
    if [ "$DRY_RUN" = true ]; then
        echo "[dry-run] Would copy .ai/project.yaml.example -> .ai/project.yaml"
    else
        cp "$project_yaml_example" "$project_yaml"
        echo "CREATED  .ai/project.yaml (copied from project.yaml.example)"
        echo "         Edit .ai/project.yaml to set your project name, type, and stacks."
    fi
fi

echo ""
echo "Done. All symlinks installed and verified."
