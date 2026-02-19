#!/usr/bin/env python3
"""
Claude Code Status Line for Windows (with theme support)
3-line format with logo, matching bash version functionality
"""

import sys
import os

# Fix Windows console encoding
if os.name == 'nt':
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')

import json
import subprocess
from pathlib import Path
from datetime import datetime, timezone

# Windows-specific: CREATE_NO_WINDOW flag for subprocess
if os.name == 'nt':
    CREATE_NO_WINDOW = subprocess.CREATE_NO_WINDOW
else:
    CREATE_NO_WINDOW = 0

# Base ANSI codes
RST = '\033[0m'
BLD = '\033[1m'
DIM = '\033[2m'

# Wall characters for logo border
C_WALL = '\033[38;5;237m'


def load_theme() -> dict:
    """Load current theme from config file."""
    config_path = Path.home() / '.claude' / 'current_skin'
    theme_name = 'kratos'

    if config_path.exists():
        try:
            theme_name = config_path.read_text().strip().lower()
        except Exception:
            pass

    # Try to import themes module
    try:
        script_dir = Path(__file__).parent
        sys.path.insert(0, str(script_dir))
        from themes import get_theme
        return get_theme(theme_name)
    except ImportError:
        # Fallback: kratos theme hardcoded
        return {
            'C_MODEL': '\033[38;5;196m',
            'C_DIR': '\033[38;5;223m',
            'C_BRANCH': '\033[38;5;180m',
            'C_DIRTY': '\033[38;5;160m',
            'C_BAR': '\033[38;5;180m',
            'C_BAR_E': '\033[38;5;52m',
            'C_TXT': '\033[38;5;252m',
            'C_SEP': '\033[38;5;137m',
            'C_OK': '\033[38;5;223m',
            'C_WARN': '\033[38;5;180m',
            'C_HIGH': '\033[38;5;196m',
            'logo1': f" \033[38;5;180m▐\033[38;5;223m▛\033[38;5;230m█\033[38;5;230m█\033[38;5;223m█\033[38;5;196m▜\033[38;5;180m▌{RST} ",
            'logo2': f"\033[38;5;180m▝\033[38;5;223m▜\033[38;5;230m█\033[38;5;230m█\033[38;5;223m█\033[38;5;223m█\033[38;5;223m█\033[38;5;196m▛\033[38;5;180m▘{RST}",
            'logo3': f"  \033[38;5;223m▘▘ \033[38;5;223m▝▝{RST}  ",
        }


def get_short_model(model_id: str) -> str:
    """Return short model name."""
    model_id = model_id.lower()
    if 'opus' in model_id and ('4.6' in model_id or '4-6' in model_id):
        return 'Opus4.6'
    if 'opus' in model_id and ('4.5' in model_id or '4-5' in model_id):
        return 'Opus4.5'
    if 'opus' in model_id and '4' in model_id:
        return 'Opus4'
    if 'sonnet' in model_id and ('4.6' in model_id or '4-6' in model_id):
        return 'Sonnet4.6'
    if 'sonnet' in model_id and ('4.5' in model_id or '4-5' in model_id):
        return 'Sonnet4.5'
    if 'sonnet' in model_id and '4' in model_id:
        return 'Sonnet4'
    if 'sonnet' in model_id:
        return 'Sonnet'
    if 'haiku' in model_id:
        return 'Haiku'
    return '?'


def get_git_info(cwd: str, theme: dict) -> tuple[str, str]:
    """Return (branch, status_indicator)."""
    if not cwd or not os.path.isdir(cwd):
        return '', ''
    try:
        # Use creationflags on Windows to hide console window
        kwargs = {'capture_output': True, 'text': True, 'timeout': 2}
        if os.name == 'nt':
            kwargs['creationflags'] = CREATE_NO_WINDOW

        branch = subprocess.run(
            ['git', '-C', cwd, 'branch', '--show-current'],
            **kwargs
        ).stdout.strip()

        if not branch:
            return '', ''

        changes = subprocess.run(
            ['git', '-C', cwd, '--no-optional-locks', 'status', '--porcelain'],
            **kwargs
        ).stdout.strip()

        change_count = len(changes.splitlines()) if changes else 0
        if change_count > 0:
            return branch, f"{theme['C_DIRTY']}{change_count}{RST}"
        return branch, f"{theme['C_OK']}✓{RST}"
    except Exception:
        return '', ''


def get_context_info(data: dict) -> tuple[int, int, int]:
    """Extract context info from Claude Code JSON."""
    context_window = data.get('context_window', {})

    ctx_size = context_window.get('context_window_size', 200000)
    used_pct = context_window.get('used_percentage', 0)

    if used_pct is None or used_pct == 'null':
        used_pct = 0

    return int(used_pct), int(ctx_size)


def bar(val: int, max_val: int, length: int, color: str, empty_color: str) -> str:
    """Build a progress bar."""
    if max_val <= 0:
        return f'{empty_color}{"░" * length}{RST}'
    filled = min(val * length // max_val, length)
    if val > 0 and filled == 0:
        filled = 1
    return ''.join(
        f'{color}▓{RST}' if i < filled else f'{empty_color}░{RST}'
        for i in range(length)
    )


def time_until(iso_time: str) -> str:
    """Calculate time remaining until reset."""
    if not iso_time or iso_time == 'null':
        return '?'
    try:
        # Parse ISO format: 2024-01-15T10:30:00.000Z
        reset_time = datetime.fromisoformat(iso_time.replace('Z', '+00:00'))
        now = datetime.now(timezone.utc)
        diff = (reset_time - now).total_seconds()

        if diff <= 0:
            return '0:00'
        if diff < 86400:
            hours = int(diff // 3600)
            mins = int((diff % 3600) // 60)
            return f'{hours}:{mins:02d}'
        return f'{int(diff // 86400)}d'
    except Exception:
        return '?'


def lim_color(pct: str, theme: dict) -> str:
    """Get color based on percentage."""
    if pct == '?':
        return DIM
    try:
        val = int(pct)
        if val < 50:
            return theme['C_OK']
        if val < 80:
            return theme['C_WARN']
        return theme['C_HIGH']
    except ValueError:
        return DIM


def get_usage_cache() -> tuple[str, str, str, str]:
    """Read usage limits from cache file."""
    cache_path = Path.home() / '.claude' / 'usage_cache'
    script_path = Path.home() / '.claude' / 'scripts' / 'update-usage-cache.py'

    h5, d7, h5_r, d7_r = '?', '?', '', ''

    if cache_path.exists():
        try:
            age = datetime.now().timestamp() - cache_path.stat().st_mtime
            parts = cache_path.read_text().strip().split()
            if len(parts) >= 2:
                h5 = parts[0] or '?'
                d7 = parts[1] or '?'
            if len(parts) >= 4:
                h5_r = parts[2] or ''
                d7_r = parts[3] or ''

            # Refresh cache in background if older than 60 seconds
            if age > 60 and script_path.exists():
                kwargs = {
                    'stdout': subprocess.DEVNULL,
                    'stderr': subprocess.DEVNULL,
                }
                if os.name == 'nt':
                    kwargs['creationflags'] = CREATE_NO_WINDOW
                subprocess.Popen([sys.executable, str(script_path)], **kwargs)
        except Exception:
            pass
    elif script_path.exists():
        # No cache, trigger update
        kwargs = {
            'stdout': subprocess.DEVNULL,
            'stderr': subprocess.DEVNULL,
        }
        if os.name == 'nt':
            kwargs['creationflags'] = CREATE_NO_WINDOW
        subprocess.Popen([sys.executable, str(script_path)], **kwargs)

    return h5, d7, h5_r, d7_r


def main():
    # Load theme
    theme = load_theme()

    # Read input JSON from stdin
    try:
        data = json.loads(sys.stdin.read())
    except json.JSONDecodeError:
        print('?')
        return

    # Extract data
    model_info = data.get('model', {})
    model_id = model_info.get('id') or model_info.get('display_name') or '?'
    cwd = data.get('cwd', '')

    # Model name
    model = get_short_model(model_id)

    # Directory
    dir_name = os.path.basename(cwd) if cwd else '?'

    # Git info
    branch, git_st = get_git_info(cwd, theme)

    # Context info from Claude Code API
    ctx_used_pct, ctx_size = get_context_info(data)
    ctx_used_display = ctx_size * ctx_used_pct // 100

    # Cost and duration
    cost_data = data.get('cost', {})
    cost_usd = cost_data.get('total_cost_usd', 0) or 0
    duration_ms = cost_data.get('total_duration_ms', 0) or 0
    lines_added = cost_data.get('total_lines_added', 0) or 0
    lines_removed = cost_data.get('total_lines_removed', 0) or 0

    # Format cost
    cost_fmt = f'{float(cost_usd):.2f}'

    # Format duration (HH:MM)
    duration_s = int(duration_ms) // 1000
    duration_h = duration_s // 3600
    duration_m = (duration_s % 3600) // 60
    duration_fmt = f'{duration_h}:{duration_m:02d}'

    # Determine color based on usage
    ctx_color = theme['C_BAR']
    if ctx_used_pct >= 90:
        ctx_color = theme['C_HIGH']
    elif ctx_used_pct >= 70:
        ctx_color = theme['C_WARN']

    # Usage limits
    h5, d7, h5_r, d7_r = get_usage_cache()
    c5 = lim_color(h5, theme)
    c7 = lim_color(d7, theme)
    h5_val = int(h5) if h5 != '?' else 0
    d7_val = int(d7) if d7 != '?' else 0

    # Build output
    sep = f" {theme['C_SEP']}│{RST} "

    # Logo walls
    wl = f"{C_WALL}▏{RST}"
    wr = f"{C_WALL}▕{RST}"

    # Wrap logo with walls
    logo1_full = f"{wl}{theme['logo1']}{wr}"
    logo2_full = f"{wl}{theme['logo2']}{wr}"
    logo3_full = f"{wl}{theme['logo3']}{wr}"

    # Line 1: Model, Dir, Branch, Lines changed
    data1 = f"{theme['C_MODEL']}{BLD}{model}{RST}{sep}{theme['C_DIR']}{dir_name}{RST}"
    if branch:
        data1 += f" {DIM}({RST}{theme['C_BRANCH']}{branch}{RST}{DIM}){RST} {git_st}"
    if lines_added > 0 or lines_removed > 0:
        data1 += f"{sep}{theme['C_OK']}+{lines_added}{RST}{DIM}/{RST}{theme['C_WARN']}-{lines_removed}{RST}"

    # Line 2: Context, Cost, Duration
    ctx_bar = bar(ctx_used_pct, 100, 8, ctx_color, theme['C_BAR_E'])
    data2 = f"{DIM}ctx{RST} {ctx_bar} {ctx_color}{ctx_used_pct}%{RST} {DIM}{ctx_used_display//1000}k/{ctx_size//1000}k{RST}"
    data2 += f"{sep}{DIM}usd{RST} {theme['C_OK']}${cost_fmt}{RST}"
    data2 += f"{sep}{DIM}ttm{RST} {theme['C_OK']}{duration_fmt}{RST}"

    # Line 3: Rate limits (5hr and weekly)
    bar5 = bar(h5_val, 100, 8, c5, theme['C_BAR_E'])
    bar7 = bar(d7_val, 100, 8, c7, theme['C_BAR_E'])
    data3 = f"{DIM}5hr{RST} {bar5} {c5}{h5}%{RST} {DIM}({time_until(h5_r)}){RST}"
    data3 += f"{sep}{DIM}wkl{RST} {bar7} {c7}{d7}%{RST} {DIM}({time_until(d7_r)}){RST}"

    # Output 3 lines with logo
    print()
    print(f"{logo1_full} {data1}")
    print(f"{logo2_full} {data2}")
    print(f"{logo3_full} {data3}")
    print()


if __name__ == '__main__':
    main()
