#!/usr/bin/env python3
"""
Claude Code Status Line for Windows
Format: Model | Dir (branch) n | Ctx ▓▓░░░░░░ 28% 49k/200k | 5h ▓░░░░░░░ 2% (4:11) | 7d ▓▓░░░░░░ 24% (3d)
"""

import sys
import json
import os
import subprocess
from pathlib import Path
from datetime import datetime, timezone

# Windows-specific: CREATE_NO_WINDOW flag for subprocess
# This prevents console windows from flashing when running background scripts
if os.name == 'nt':
    CREATE_NO_WINDOW = subprocess.CREATE_NO_WINDOW
else:
    CREATE_NO_WINDOW = 0

# ANSI Colors
RST = '\033[0m'
BLD = '\033[1m'
DIM = '\033[2m'
C_MODEL = '\033[38;5;141m'
C_DIR = '\033[38;5;75m'
C_BRANCH = '\033[38;5;114m'
C_DIRTY = '\033[38;5;208m'
C_BAR = '\033[38;5;75m'
C_BAR_E = '\033[38;5;238m'
C_TXT = '\033[38;5;252m'
C_SEP = '\033[38;5;240m'
C_OK = '\033[38;5;114m'
C_WARN = '\033[38;5;220m'
C_HIGH = '\033[38;5;208m'


def get_short_model(model_id: str) -> str:
    """Return short model name."""
    model_id = model_id.lower()
    if 'opus' in model_id and ('4.5' in model_id or '4-5' in model_id):
        return 'Opus4.5'
    if 'opus' in model_id and '4' in model_id:
        return 'Opus4'
    if 'sonnet' in model_id and ('4.5' in model_id or '4-5' in model_id):
        return 'Sonnet4.5'
    if 'sonnet' in model_id and '4' in model_id:
        return 'Sonnet4'
    if 'sonnet' in model_id:
        return 'Sonnet'
    if 'haiku' in model_id:
        return 'Haiku'
    return '?'


def get_git_info(cwd: str) -> tuple[str, str]:
    """Return (branch, status_indicator)."""
    if not cwd or not os.path.isdir(cwd):
        return '', ''
    try:
        branch = subprocess.run(
            ['git', '-C', cwd, 'branch', '--show-current'],
            capture_output=True, text=True, timeout=2
        ).stdout.strip()
        if not branch:
            return '', ''

        changes = subprocess.run(
            ['git', '-C', cwd, '--no-optional-locks', 'status', '--porcelain'],
            capture_output=True, text=True, timeout=2
        ).stdout.strip()

        change_count = len(changes.splitlines()) if changes else 0
        if change_count > 0:
            return branch, f'{C_DIRTY}{change_count}{RST}'
        return branch, f'{C_OK}✓{RST}'
    except Exception:
        return '', ''


def get_context_info(data: dict) -> tuple[int, int, int]:
    """Extract context info from Claude Code JSON.
    Returns: (tokens_used, context_size, remaining_percentage)
    """
    context_window = data.get('context_window', {})

    total_input = context_window.get('total_input_tokens', 0)
    total_output = context_window.get('total_output_tokens', 0)
    tokens_used = total_input + total_output

    ctx_size = context_window.get('context_window_size', 200000)
    remaining_pct = context_window.get('remaining_percentage', 0)

    return tokens_used, ctx_size, remaining_pct


def bar(val: int, max_val: int, length: int, color: str) -> str:
    """Build a progress bar."""
    if max_val <= 0:
        return f'{C_BAR_E}{"░" * length}{RST}'
    filled = min(val * length // max_val, length)
    return ''.join(
        f'{color}▓{RST}' if i < filled else f'{C_BAR_E}░{RST}'
        for i in range(length)
    )


def time_until(iso_time: str) -> str:
    """Calculate time remaining until reset."""
    if not iso_time:
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


def lim_color(pct: str) -> str:
    """Get color based on percentage."""
    if pct == '?':
        return DIM
    try:
        val = int(pct)
        if val < 50:
            return C_OK
        if val < 80:
            return C_WARN
        return C_HIGH
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
                subprocess.Popen(
                    [sys.executable, str(script_path)],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    creationflags=CREATE_NO_WINDOW
                )
        except Exception:
            pass
    elif script_path.exists():
        # No cache, trigger update
        subprocess.Popen(
            [sys.executable, str(script_path)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=CREATE_NO_WINDOW
        )

    return h5, d7, h5_r, d7_r


def main():
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
    branch, git_st = get_git_info(cwd)

    # Context info from Claude Code API
    tokens, ctx_size, remaining_pct = get_context_info(data)
    used_pct = 100 - remaining_pct

    # Determine color based on usage
    ctx_color = C_BAR
    if used_pct >= 90:
        ctx_color = C_HIGH
    elif used_pct >= 70:
        ctx_color = C_WARN

    # Usage limits
    h5, d7, h5_r, d7_r = get_usage_cache()

    # Build output
    sep = f' {C_SEP}│{RST} '

    out = f'{C_MODEL}{BLD}{model}{RST}'
    out += f'{sep}{C_DIR}{dir_name}{RST}'

    if branch:
        out += f' {DIM}({RST}{C_BRANCH}{branch}{RST}{DIM}){RST} {git_st}'

    # Context bar with real percentage
    out += f'{sep}{DIM}Ctx{RST} {bar(used_pct, 100, 8, ctx_color)} {ctx_color}{used_pct}%{RST} {DIM}{tokens // 1000}k/{ctx_size // 1000}k{RST}'

    c5 = lim_color(h5)
    c7 = lim_color(d7)
    h5_val = int(h5) if h5 != '?' else 0
    d7_val = int(d7) if d7 != '?' else 0

    out += f'{sep}{DIM}5h{RST} {bar(h5_val, 100, 8, c5)} {c5}{h5}%{RST} {DIM}({time_until(h5_r)}){RST}'
    out += f'{sep}{DIM}7d{RST} {bar(d7_val, 100, 8, c7)} {c7}{d7}%{RST} {DIM}({time_until(d7_r)}){RST}'

    print(out)


if __name__ == '__main__':
    main()
