#!/bin/bash
# Claude Statusline Installer
# Installs custom statusline with themes for Claude Code

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
SCRIPTS_DIR="${CLAUDE_DIR}/scripts"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
SKILLS_DIR="${CLAUDE_DIR}/skills/skin"

echo ""
echo "Installing Claude Statusline..."
echo ""

# Create directories
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$HOOKS_DIR"
mkdir -p "$SKILLS_DIR"

# Copy scripts
cp "${SCRIPT_DIR}/context-bar.sh" "$SCRIPTS_DIR/"
cp "${SCRIPT_DIR}/themes.sh" "$SCRIPTS_DIR/"
cp "${SCRIPT_DIR}/claude-skin.sh" "$SCRIPTS_DIR/"

# Make executable
chmod +x "${SCRIPTS_DIR}/context-bar.sh"
chmod +x "${SCRIPTS_DIR}/claude-skin.sh"

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

# Install skill
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
    # Check if hooks already configured
    if grep -q "skin-hook.sh" "$SETTINGS_FILE" 2>/dev/null; then
        echo "✓ Settings already configured"
    else
        echo ""
        echo "NOTE: Add this to your ${SETTINGS_FILE} manually:"
        echo ""
        echo '  "hooks": {'
        echo '    "UserPromptSubmit": ['
        echo '      {'
        echo '        "matcher": "",'
        echo '        "hooks": ['
        echo '          {'
        echo '            "type": "command",'
        echo '            "command": "~/.claude/hooks/skin-hook.sh"'
        echo '          }'
        echo '        ]'
        echo '      }'
        echo '    ]'
        echo '  }'
        echo ""
    fi
else
    # Create settings with hooks
    cat > "$SETTINGS_FILE" << 'EOF'
{
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
