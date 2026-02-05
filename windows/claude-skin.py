#!/usr/bin/env python3
"""
Claude Skin Selector for Windows
Usage: claude-skin.py          - show gallery
       claude-skin.py <name>   - apply theme
"""

import sys
import os

# Fix Windows console encoding
if os.name == 'nt':
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')

from pathlib import Path

# Add script directory to path for themes import
script_dir = Path(__file__).parent
sys.path.insert(0, str(script_dir))

from themes import THEMES, THEME_LIST, RST, get_theme

CONFIG_FILE = Path.home() / '.claude' / 'current_skin'
C_BORDER = '\033[38;5;240m'


def print_row(themes_row: list[str], names_row: list[str]):
    """Print a row of 3 themes with logos."""
    border = f"{C_BORDER}│{RST}"
    gap = "       "

    # Load themes
    t1 = get_theme(themes_row[0]) if len(themes_row) > 0 else None
    t2 = get_theme(themes_row[1]) if len(themes_row) > 1 else None
    t3 = get_theme(themes_row[2]) if len(themes_row) > 2 else None

    # Print logo lines
    for line in ['logo1', 'logo2', 'logo3']:
        parts = []
        if t1:
            parts.append(t1[line])
        if t2:
            parts.append(t2[line])
        if t3:
            parts.append(t3[line])
        print(f"{border} {gap.join(parts)}")

    # Print names centered under each logo
    # Approximate centering for 3 columns at positions 4, 20, 36
    col_positions = [4, 20, 36]
    out = ""
    pos = 0

    for i, name in enumerate(names_row):
        target = col_positions[i] - len(name) // 2
        while pos < target:
            out += " "
            pos += 1
        out += name.upper()
        pos += len(name)

    print(f"{border} {out}")
    print()


def show_gallery():
    """Display all available skins in a gallery."""
    print()
    print("Available Skins:")
    print()

    # Rows of 3 themes each
    rows = [
        ['kratos', 'spiderman', 'captain'],
        ['shadow', 'ocean', 'goose'],
        ['matrix', 'sakura', 'aurora'],
        ['ember', 'frost', 'odi'],
        ['cyberpunk', 'lavender', 'gold'],
        ['inferno', 'amethyst', 'bubblegum'],
        ['venom', 'vaporwave', 'copper'],
    ]

    for row in rows:
        print_row(row, row)

    # Show current skin
    if CONFIG_FILE.exists():
        try:
            current = CONFIG_FILE.read_text().strip()
            print(f"Current: {current}")
        except Exception:
            pass

    print("Usage: /skin <name>")
    print("Press Shift+Tab to refresh statusline after applying")
    print()


def apply_theme(name: str):
    """Apply a theme by saving it to config file."""
    name = name.lower().strip()

    # Validate theme exists
    if name not in THEMES:
        print(f"Unknown skin: {name}")
        print(f"Available: {' '.join(THEME_LIST)}")
        return False

    # Ensure config directory exists
    CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)

    # Save to config
    CONFIG_FILE.write_text(name)
    print(f"Skin applied: {name}")
    print("Press Shift+Tab to refresh statusline")
    return True


def main():
    if len(sys.argv) < 2:
        show_gallery()
    else:
        # Join all arguments in case theme name has spaces (shouldn't, but just in case)
        theme_name = ' '.join(sys.argv[1:])
        apply_theme(theme_name)


if __name__ == '__main__':
    main()
