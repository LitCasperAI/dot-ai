#!/bin/bash
# install-symlinks.sh — Installs dot-ai symlinks into the consumer repository.
#
# Usage:
#   .ai/.scripts/install-symlinks.sh            # normal run (installs all tools)
#   .ai/.scripts/install-symlinks.sh --force     # overwrite existing non-symlinks
#   .ai/.scripts/install-symlinks.sh --dry-run   # preview only
#   .ai/.scripts/install-symlinks.sh --claude    # only install Claude symlinks
#   .ai/.scripts/install-symlinks.sh --gemini    # only install Gemini symlinks
#   .ai/.scripts/install-symlinks.sh --copilot   # only install Copilot symlinks
#
# --claude, --gemini and --copilot can be combined to select multiple tools.
# If none of them are passed, all tools are installed (default behaviour).
#
# Creates several symlinks:
#   File symlinks (entry points → .ai/AGENTS.md):
#     CLAUDE.md                       -> .ai/AGENTS.md
#     GEMINI.md                       -> .ai/AGENTS.md
#     .github/copilot-instructions.md -> ../.ai/AGENTS.md
#   Tool configuration symlinks (agent dirs → .ai/):
#     .claude/skills                  -> ../.ai/skills
#     .gemini/commands                -> ../.ai/.gemini/commands
#     .gemini/policies                -> ../.ai/.gemini/policies
#     .gemini/settings.json           -> ../.ai/.gemini/settings.json

set -eu

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
FORCE=false
DRY_RUN=false
INTERACTIVE=true
DO_CLAUDE=false
DO_GEMINI=false
DO_COPILOT=false

for arg in "$@"; do
    case "$arg" in
        --force)           FORCE=true ;;
        --dry-run)         DRY_RUN=true ;;
        --interactive)     INTERACTIVE=true ;;
        --non-interactive) INTERACTIVE=false ;;
        --claude)          DO_CLAUDE=true ;;
        --gemini)          DO_GEMINI=true ;;
        --copilot)         DO_COPILOT=true ;;
        -h|--help)
            sed -n '2,21s/^# \?//p' "$0"
            exit 0
            ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

# If none of --claude/--gemini/--copilot were passed, install all of them.
if [ "$DO_CLAUDE" = false ] && [ "$DO_GEMINI" = false ] && [ "$DO_COPILOT" = false ]; then
    DO_CLAUDE=true
    DO_GEMINI=true
    DO_COPILOT=true
fi

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
ALL_LINKS=""

if [ "$DO_CLAUDE" = true ]; then
    install_symlink "CLAUDE.md" ".ai/AGENTS.md"
    ALL_LINKS="$ALL_LINKS CLAUDE.md"
fi
if [ "$DO_GEMINI" = true ]; then
    install_symlink "GEMINI.md" ".ai/AGENTS.md"
    ALL_LINKS="$ALL_LINKS GEMINI.md"
fi
if [ "$DO_COPILOT" = true ]; then
    install_symlink ".github/copilot-instructions.md" "../.ai/AGENTS.md"
    ALL_LINKS="$ALL_LINKS .github/copilot-instructions.md"
fi

# Dynamically discover skills and Gemini commands from the submodule
if [ "$DO_CLAUDE" = true ]; then
    echo ""
    echo "=== Claude skill symlinks ==="

    if [ -d "$AI_DIR/skills" ]; then
        for skill_dir in "$AI_DIR/skills"/*/; do
            [ -d "$skill_dir" ] || continue
            name="$(basename "$skill_dir")"
            link=".claude/skills/$name/SKILL.md"
            target="../../../.ai/skills/$name/SKILL.md"
            install_symlink "$link" "$target"
            ALL_LINKS="$ALL_LINKS $link"
        done
    fi
fi

if [ "$DO_GEMINI" = true ]; then
    echo ""
    echo "=== Gemini configuration symlinks ==="

    if [ -d "$AI_DIR/.gemini/commands" ]; then
        for toml in "$AI_DIR/.gemini/commands"/*.toml; do
            [ -f "$toml" ] || continue
            name="$(basename "$toml")"
            link=".gemini/commands/$name"
            target="../../.ai/.gemini/commands/$name"
            install_symlink "$link" "$target"
            ALL_LINKS="$ALL_LINKS $link"
        done
    fi

    if [ -d "$AI_DIR/.gemini/policies" ]; then
        for toml in "$AI_DIR/.gemini/policies"/*.toml; do
            [ -f "$toml" ] || continue
            name="$(basename "$toml")"
            link=".gemini/policies/$name"
            target="../../.ai/.gemini/policies/$name"
            install_symlink "$link" "$target"
            ALL_LINKS="$ALL_LINKS $link"
        done
    fi

    if [ -f "$AI_DIR/.gemini/settings.json" ]; then
        link=".gemini/settings.json"
        target="../../.ai/.gemini/settings.json"
        install_symlink "$link" "$target"
        ALL_LINKS="$ALL_LINKS $link"
    fi
fi

# ---------------------------------------------------------------------------
# Git add & validate all symlinks are stored correctly (mode 120000)
# ---------------------------------------------------------------------------

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
# Scaffold .ai-local/ directory (project-specific config, outside submodule)
# ---------------------------------------------------------------------------
echo ""
echo "=== Project-local config (.ai-local/) ==="

for dir in \
    .ai-local/rules \
    .ai-local/overrides
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

# Copy project.yaml.example → .ai-local/project.yaml if missing (or forced)
project_yaml="$REPO_ROOT/.ai-local/project.yaml"
project_yaml_example="$AI_DIR/project.yaml.example"

if [ -f "$project_yaml" ] && [ "$FORCE" = false ]; then
    echo "OK       .ai-local/project.yaml (already exists)"
elif [ ! -f "$project_yaml_example" ]; then
    echo "WARNING: SKIP     .ai-local/project.yaml.example not found" >&2
else
    if [ "$DRY_RUN" = true ]; then
        echo "[dry-run] Would create .ai-local/project.yaml from template"
    else
        # Interactive prompts if enabled
        PROJ_NAME="example-mobile-app"
        STACK="react-native"

        if [ "$INTERACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
            echo ""
            echo "--- Project Configuration ---"
            printf "Enter project name [%s]: " "$PROJ_NAME"
            read -r input_name
            [ -n "$input_name" ] && PROJ_NAME="$input_name"

            echo "Available stacks:"
            stacks=()
            i=1
            for d in "$AI_DIR/rules/stacks"/*/; do
                [ -d "$d" ] || continue
                sname=$(basename "$d")
                stacks+=("$sname")
                printf "  %d) %s\n" "$i" "$sname"
                i=$((i+1))
            done
            printf "  %d) Custom...\n" "$i"
            
            STACK=""
            while [ -z "$STACK" ]; do
                printf "Select a stack (1-%d): " "$i"
                read -r choice
                if [ -n "$choice" ]; then
                    if [ "$choice" -eq "$i" ]; then
                        while [ -z "$STACK" ]; do
                            printf "Enter custom stack name: "
                            read -r custom_stack
                            [ -n "$custom_stack" ] && STACK="$custom_stack"
                        done
                    elif [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
                        STACK="${stacks[$((choice-1))]}"
                    else
                        echo "Invalid selection."
                    fi
                fi
            done
            echo "-----------------------------"
        fi

        # Create the file by replacing placeholders
        sed -e "s/name: \"example-mobile-app\"/name: \"$PROJ_NAME\"/" \
            -e "s/type: react-native/type: $STACK/" \
            -e "s/stacks: \[react-native\]/stacks: [$STACK]/" \
            -e "s|rules/stacks/react-native/|rules/stacks/$STACK/|" \
            "$project_yaml_example" > "$project_yaml"

        echo "CREATED  .ai-local/project.yaml (customized: name=$PROJ_NAME, stack=$STACK)"
    fi
fi

if [ "$DRY_RUN" != true ]; then
    git add .ai-local/
    echo "Staged .ai-local/ in git."
fi

# ---------------------------------------------------------------------------
# Install Git Hooks
# ---------------------------------------------------------------------------
echo ""
echo "=== Git Hooks ==="

if [ -d "$REPO_ROOT/.git" ]; then
    HOOKS_DIR="$REPO_ROOT/.git/hooks"
    mkdir -p "$HOOKS_DIR"
    
    if [ -d "$SCRIPT_DIR/git-hooks" ]; then
        for hook_file in "$SCRIPT_DIR/git-hooks"/*; do
            hook_name=$(basename "$hook_file")
            # Symlink target for new hooks (relative to .git/hooks/)
            target="../../.ai/.scripts/git-hooks/$hook_name"
            # Injection line for existing hooks (relative to repo root)
            source_line="[ -f \".ai/.scripts/git-hooks/$hook_name\" ] && . \".ai/.scripts/git-hooks/$hook_name\""
            
            hook_path="$HOOKS_DIR/$hook_name"
            
            if [ -L "$hook_path" ]; then
                echo "OK       git hook: $hook_name (symlink already exists)"
            elif [ -e "$hook_path" ]; then
                if grep -Fq ".ai/.scripts/git-hooks/$hook_name" "$hook_path"; then
                    echo "OK       git hook: $hook_name (already integrated)"
                elif [ "$FORCE" = true ]; then
                    if [ "$DRY_RUN" = true ]; then
                        echo "[dry-run] Would overwrite existing git hook: $hook_name"
                    else
                        ln -sf "$target" "$hook_path"
                        chmod +x "$hook_path"
                        echo "OVERWROTE git hook: $hook_name"
                    fi
                else
                    if [ "$DRY_RUN" = true ]; then
                        echo "[dry-run] Would inject safety trigger into: $hook_name"
                    else
                        # Prepend the trigger after the shebang (if any), otherwise at the top
                        tmp_hook=$(mktemp)
                        if head -n 1 "$hook_path" | grep -q "^#!"; then
                            head -n 1 "$hook_path" > "$tmp_hook"
                            echo "$source_line" >> "$tmp_hook"
                            tail -n +2 "$hook_path" >> "$tmp_hook"
                        else
                            echo "$source_line" > "$tmp_hook"
                            cat "$hook_path" >> "$tmp_hook"
                        fi
                        cat "$tmp_hook" > "$hook_path"
                        rm "$tmp_hook"
                        chmod +x "$hook_path"
                        echo "INJECTED safety trigger into: $hook_name"
                    fi
                fi
            else
                if [ "$DRY_RUN" = true ]; then
                    echo "[dry-run] Would install git hook symlink: $hook_name -> $target"
                else
                    ln -s "$target" "$hook_path"
                    chmod +x "$hook_path"
                    echo "INSTALLED git hook: $hook_name"
                fi
            fi
        done
    fi
else
    echo "SKIP     .git directory not found (skipping hooks)"
fi

echo ""
echo "Done. All symlinks installed and verified."
