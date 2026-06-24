#!/usr/bin/env bash
# install.sh — Install spec-to-ship and its sub-skills for any AI agent
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Klng79/spec-to-ship/main/install.sh | bash
#   SKILLS_DIR=~/.my-agent/skills ./install.sh
#
# Environment variables:
#   SKILLS_DIR  Override the target skills directory (auto-detected if unset)
#   SKILLS_BASE Override the GitHub base URL (default: https://github.com/Klng79)

set -euo pipefail

REPO_BASE="${SKILLS_BASE:-https://github.com/Klng79}"
ORG_NAME="Klng79"
UPSTREAM_REPO="${UPSTREAM_BASE:-https://github.com/mattpocock/skills}"
UPSTREAM_PATH="skills/engineering"

# Skills sourced from mattpocock/skills (MIT licensed, official upstream).
# These are NOT forked into Klng79/ — install.sh pulls the canonical
# version directly from upstream via sparse-checkout.
UPSTREAM_SKILLS=(
    "grill-with-docs"
    "to-prd"
    "to-issues"
    "tdd"
)

REQUIRED_SKILLS=(
    "spec-to-ship"
    "${UPSTREAM_SKILLS[@]}"
)

OPTIONAL_SKILLS=(
    "agentic-coding-loop"
)

# Detect the target skills directory based on installed agent CLIs.
# Order matters: first existing parent directory wins.
detect_target() {
    if [[ -n "${SKILLS_DIR:-}" ]]; then
        echo "$SKILLS_DIR"
        return
    fi

    local -A candidates=(
        ["$HOME/.qwen"]="Qwen Code"
        ["$HOME/.claude"]="Claude Code"
        ["$HOME/.codex"]="OpenAI Codex"
        ["$HOME/.continue"]="Continue.dev"
        ["$HOME/.cursor"]="Cursor"
    )

    for dir in "${!candidates[@]}"; do
        if [[ -d "$dir" ]]; then
            echo "${dir}/skills"
            return
        fi
    done

    # Fallback: assume Qwen Code (the most common target)
    echo "$HOME/.qwen/skills"
}

# Verify a repo exists on GitHub before trying to clone it
verify_repo() {
    git ls-remote --heads "${REPO_BASE}/$1.git" >/dev/null 2>&1
}

# Check if a skill is sourced from mattpocock upstream
is_upstream_skill() {
    local skill="$1"
    for s in "${UPSTREAM_SKILLS[@]}"; do
        [[ "$s" == "$skill" ]] && return 0
    done
    return 1
}

# Install a skill sourced from mattpocock/skills via sparse-checkout.
# Also copies the upstream LICENSE into the installed sub-skill directory
# (renamed LICENSE-MATTPOCOCK) so MIT attribution is preserved per the
# license terms: "The above copyright notice and this permission notice
# shall be included in all copies or substantial portions of the Software."
install_upstream_skill() {
    local skill="$1"
    local target="$2"

    if [[ -d "$target/$skill" ]]; then
        echo "  ✓ $skill (already installed)"
        return 0
    fi

    local tmp
    tmp=$(mktemp -d)
    trap "rm -rf '$tmp'" RETURN

    echo "  → Installing $skill (from mattpocock/skills)..."

    if ! git clone --depth=1 --filter=blob:none --sparse "$UPSTREAM_REPO" "$tmp/repo" >/dev/null 2>&1; then
        echo "  ✗ $skill (could not clone $UPSTREAM_REPO)"
        return 1
    fi

    # Pull both the skill directory AND the upstream LICENSE so we can
    # preserve MIT attribution alongside the copied skill files.
    # --no-cone: LICENSE is a file at the repo root, not a directory under
    # the skills/ tree, so cone mode (the default) rejects it.
    if ! (cd "$tmp/repo" && git sparse-checkout set --no-cone "${UPSTREAM_PATH}/$skill" "LICENSE") >/dev/null 2>&1; then
        echo "  ✗ $skill (sparse-checkout for ${UPSTREAM_PATH}/$skill failed)"
        return 1
    fi

    if [[ ! -d "$tmp/repo/${UPSTREAM_PATH}/$skill" ]]; then
        echo "  ✗ $skill (not found at ${UPSTREAM_PATH}/$skill in upstream)"
        return 1
    fi

    mkdir -p "$target/$skill"
    cp -R "$tmp/repo/${UPSTREAM_PATH}/$skill/." "$target/$skill/"

    # Preserve MIT attribution: copy upstream LICENSE into the installed
    # sub-skill directory so redistribution stays license-compliant.
    if [[ -f "$tmp/repo/LICENSE" ]]; then
        cp "$tmp/repo/LICENSE" "$target/$skill/LICENSE-MATTPOCOCK"
    fi

    echo "  ✓ $skill (from mattpocock/skills)"
}

# Install a single skill, idempotently
install_skill() {
    local skill="$1"
    local required="$2"
    local target="$3"

    if [[ -d "$target/$skill" ]]; then
        # In update mode, refresh upstream skills (overwrite with latest from
        # mattpocock). Always skip spec-to-ship and agentic-coding-loop — those
        # are local repos the user might be actively developing.
        if [[ "$UPDATE_MODE" == "1" ]] && is_upstream_skill "$skill"; then
            rm -rf "$target/$skill"
            echo "  ↻ $skill (refreshing from upstream)"
        else
            echo "  ✓ $skill (already installed)"
            return 0
        fi
    fi

    # Upstream skills come from mattpocock, not from REPO_BASE
    if is_upstream_skill "$skill"; then
        install_upstream_skill "$skill" "$target"
        return $?
    fi

    if ! verify_repo "$skill"; then
        if [[ "$required" == "required" ]]; then
            echo "  ✗ $skill (REPO NOT FOUND at ${REPO_BASE}/$skill.git)"
            echo "      This is a required sub-skill. Create the repo and re-run,"
            echo "      or install manually: git clone ${REPO_BASE}/$skill.git $target/$skill"
            return 1
        else
            echo "  ⊘ $skill (optional, repo not found — skipping)"
            return 0
        fi
    fi

    echo "  → Installing $skill..."
    if git clone --depth=1 "${REPO_BASE}/$skill.git" "$target/$skill" >/dev/null 2>&1; then
        echo "  ✓ $skill"
        return 0
    else
        echo "  ✗ $skill (clone failed)"
        return 1
    fi
}

main() {
    # Parse command-line flags
    UPDATE_MODE=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --update|-u)
                UPDATE_MODE=1
                shift
                ;;
            --help|-h)
                cat <<EOF
spec-to-ship installer

Usage: install.sh [--update]

Environment variables:
  SKILLS_DIR    Override target skills directory (auto-detected if unset)
  UPSTREAM_BASE Override upstream repo URL (default: mattpocock/skills)

Modes:
  (default)  Idempotent install: skip any skill already present.
             Safe to re-run; never overwrites anything.

  --update   Refresh the 4 upstream skills (grill-with-docs, to-prd,
             to-issues, tdd) from latest mattpocock. Always skips
             spec-to-ship and agentic-coding-loop — those are your
             own repos and won't be touched.

Examples:
  curl -fsSL https://raw.githubusercontent.com/Klng79/spec-to-ship/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/Klng79/spec-to-ship/main/install.sh | bash -s -- --update
  SKILLS_DIR=~/.my-agent/skills ./install.sh --update
EOF
                exit 0
                ;;
            *)
                echo "Unknown option: $1 (use --help for usage)" >&2
                exit 1
                ;;
        esac
    done

    local target
    target=$(detect_target)

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  spec-to-ship installer"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Target directory: $target"
    echo "Repository base:  $REPO_BASE"
    echo "Upstream skills:  $UPSTREAM_REPO (skills/engineering)"
    if [[ "$UPDATE_MODE" == "1" ]]; then
        echo "Mode:             --update (refresh upstream skills)"
    else
        echo "Mode:             default (skip existing)"
    fi
    echo ""

    if ! command -v git >/dev/null 2>&1; then
        echo "Error: git is not installed or not in PATH."
        echo "Install git first, then re-run this script."
        exit 1
    fi

    mkdir -p "$target"

    echo "Required sub-skills:"
    local failed=0
    for skill in "${REQUIRED_SKILLS[@]}"; do
        install_skill "$skill" "required" "$target" || failed=1
    done

    echo ""
    echo "Optional sub-skills:"
    for skill in "${OPTIONAL_SKILLS[@]}"; do
        install_skill "$skill" "optional" "$target" || true
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ $failed -eq 0 ]]; then
        echo "  ✓ Installation complete"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Restart your AI agent, then run:"
        echo "  /spec-to-ship"
    else
        echo "  ⚠ Installation completed with errors"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Some required skills could not be installed."
        echo "See messages above for details."
        exit 1
    fi
}

main "$@"
