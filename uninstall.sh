#!/usr/bin/env bash
# uninstall.sh — Remove spec-to-ship and its sub-skills
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Klng79/spec-to-ship/main/uninstall.sh | bash
#   SKILLS_DIR=~/.my-agent/skills ./uninstall.sh

set -euo pipefail

SKILLS=(
    "spec-to-ship"
    "grill-with-docs"
    "to-prd"
    "to-issues"
    "tdd"
    "agentic-coding-loop"
)

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

    echo "$HOME/.qwen/skills"
}

main() {
    local target
    target=$(detect_target)

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  spec-to-ship uninstaller"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Target directory: $target"
    echo ""

    for skill in "${SKILLS[@]}"; do
        if [[ -d "$target/$skill" ]]; then
            rm -rf "$target/$skill"
            echo "  ✓ Removed $skill"
        else
            echo "  ⊘ $skill (not installed)"
        fi
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ Uninstallation complete"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

main "$@"
