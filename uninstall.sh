#!/bin/bash
# Claude Statusline Uninstaller
# Removes statusline scripts, hooks and settings

CLAUDE_DIR="${HOME}/.claude"
SCRIPTS_DIR="${CLAUDE_DIR}/scripts"
HOOKS_DIR="${CLAUDE_DIR}/hooks"

echo ""
echo "Uninstalling Claude Statusline..."
echo ""

# Remove scripts
rm -f "${SCRIPTS_DIR}/context-bar.sh"
rm -f "${SCRIPTS_DIR}/themes.sh"
rm -f "${SCRIPTS_DIR}/claude-skin.sh"
rm -f "${SCRIPTS_DIR}/update-usage-cache.sh"
echo "✓ Scripts removed"

# Remove hook
rm -f "${HOOKS_DIR}/skin-hook.sh"
echo "✓ Hook removed"

# Remove skin config
rm -f "${CLAUDE_DIR}/current_skin"
rm -f "${CLAUDE_DIR}/usage_cache"
echo "✓ Config removed"

echo ""
echo "NOTE: You may need to manually remove statusLine and hooks from:"
echo "  ${CLAUDE_DIR}/settings.json"
echo ""
echo "Uninstall complete!"
echo ""
