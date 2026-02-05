#!/bin/bash
# Claude Statusline Installer
# Installs custom statusline with themes for Claude Code

set -e

REPO_URL="https://raw.githubusercontent.com/bartleby/claude-statusline/main"
CLAUDE_DIR="${HOME}/.claude"
SCRIPTS_DIR="${CLAUDE_DIR}/scripts"
HOOKS_DIR="${CLAUDE_DIR}/hooks"

echo ""
echo "Installing Claude Statusline..."
echo ""

# Create directories
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$HOOKS_DIR"

# Download scripts
curl -fsSL "${REPO_URL}/context-bar.sh" -o "${SCRIPTS_DIR}/context-bar.sh"
curl -fsSL "${REPO_URL}/themes.sh" -o "${SCRIPTS_DIR}/themes.sh"
curl -fsSL "${REPO_URL}/claude-skin.sh" -o "${SCRIPTS_DIR}/claude-skin.sh"
curl -fsSL "${REPO_URL}/update-usage-cache.sh" -o "${SCRIPTS_DIR}/update-usage-cache.sh"

# Make executable
chmod +x "${SCRIPTS_DIR}/context-bar.sh"
chmod +x "${SCRIPTS_DIR}/claude-skin.sh"
chmod +x "${SCRIPTS_DIR}/update-usage-cache.sh"

echo "✓ Scripts installed to ${SCRIPTS_DIR}"

# Install hook for /skin command
cat > "${HOOKS_DIR}/skin-hook.sh" << 'EOF'
#!/bin/bash
# Hook for /skin command - runs directly without AI

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Check if command starts with /skin
if [[ "$PROMPT" =~ ^/skin ]]; then
    # Extract argument (skin name) if present
    ARG=$(echo "$PROMPT" | sed 's|^/skin[[:space:]]*||')

    # Run the skin script and redirect stdout to stderr (Claude Code shows stderr)
    ~/.claude/scripts/claude-skin.sh $ARG >&2

    # Exit code 2 = block the prompt from going to AI
    exit 2
fi

exit 0
EOF

chmod +x "${HOOKS_DIR}/skin-hook.sh"
echo "✓ Hook installed to ${HOOKS_DIR}"

# Install skill for /skin command visibility in menu
SKILLS_DIR="${CLAUDE_DIR}/skills/skin"
mkdir -p "$SKILLS_DIR"
cat > "${SKILLS_DIR}/SKILL.md" << 'EOF'
---
name: skin
description: Apply a skin/theme to Claude Code statusline
command: ~/.claude/scripts/claude-skin.sh
user-invocable: true
---

Apply a skin theme. Run without arguments to see gallery, or with skin name to apply.
EOF
echo "✓ Skill installed to ${SKILLS_DIR}"

# Update settings.json
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

if [[ -f "$SETTINGS_FILE" ]]; then
    # Use jq to merge settings if available
    if command -v jq &> /dev/null; then
        # Create temp file with new settings
        TMP_SETTINGS=$(mktemp)

        # Add statusLine if not present
        if ! grep -q "context-bar.sh" "$SETTINGS_FILE" 2>/dev/null; then
            jq '.statusLine = {"type": "command", "command": "~/.claude/scripts/context-bar.sh"}' "$SETTINGS_FILE" > "$TMP_SETTINGS" && mv "$TMP_SETTINGS" "$SETTINGS_FILE"
            echo "✓ StatusLine added to settings"
        else
            echo "✓ StatusLine already configured"
        fi

        # Add hook if not present
        if ! grep -q "skin-hook.sh" "$SETTINGS_FILE" 2>/dev/null; then
            jq '.hooks.UserPromptSubmit = (.hooks.UserPromptSubmit // []) + [{"matcher": "", "hooks": [{"type": "command", "command": "~/.claude/hooks/skin-hook.sh"}]}]' "$SETTINGS_FILE" > "$TMP_SETTINGS" && mv "$TMP_SETTINGS" "$SETTINGS_FILE"
            echo "✓ Hook added to settings"
        else
            echo "✓ Hook already configured"
        fi
    else
        echo ""
        echo "NOTE: jq not found. Please add hooks manually to ${SETTINGS_FILE}:"
        echo ""
        cat << 'SETTINGS'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/scripts/context-bar.sh"
  },
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/skin-hook.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS
        echo ""
    fi
else
    # Create settings
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/scripts/context-bar.sh"
  },
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/skin-hook.sh"
          }
        ]
      }
    ]
  }
}
EOF
    echo "✓ Settings created at ${SETTINGS_FILE}"
fi

# Set default skin
if [[ ! -f "${CLAUDE_DIR}/current_skin" ]]; then
    echo "kratos" > "${CLAUDE_DIR}/current_skin"
    echo "✓ Default skin set to 'kratos'"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Usage:"
echo "  /skin          - show available skins"
echo "  /skin <name>   - apply a skin"
echo ""
echo "Press Shift+Tab to refresh statusline after applying a skin."
echo ""
