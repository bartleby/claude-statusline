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

# Update settings.json
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

if [[ -f "$SETTINGS_FILE" ]]; then
    # Check if already configured
    if grep -q "context-bar.sh" "$SETTINGS_FILE" 2>/dev/null; then
        echo "✓ Settings already configured"
    else
        echo ""
        echo "NOTE: Add this to your ${SETTINGS_FILE}:"
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
echo "Restart Claude Code and press Shift+Tab to see statusline."
echo ""
