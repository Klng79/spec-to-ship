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

REQUIRED_SKILLS=(
    "spec-to-ship"
    "grill-with-docs"
    "to-prd"
    "to-issues"
    "tdd"
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

# Install a single skill, idempotently
install_skill() {
    local skill="$1"
    local required="$2"
    local target="$3"

    if [[ -d "$target/$skill" ]]; then
        echo "  ✓ $skill (already installed)"
        return 0
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
    local target
    target=$(detect_target)

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  spec-to-ship installer"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Target directory: $target"
    echo "Repository base:  $REPO_BASE"
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
