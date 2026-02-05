#!/usr/bin/env python3
"""
Hook for /skin command - runs directly without AI
Used by Claude Code hooks system on Windows
"""

import sys
import os
import json
from pathlib import Path

# Windows-specific: CREATE_NO_WINDOW flag for subprocess
if os.name == 'nt':
    import subprocess
    CREATE_NO_WINDOW = subprocess.CREATE_NO_WINDOW
else:
    import subprocess
    CREATE_NO_WINDOW = 0


def main():
    # Read input JSON from stdin
    try:
        input_data = sys.stdin.read()
        data = json.loads(input_data)
    except json.JSONDecodeError:
        # Not valid JSON, let it pass through
        sys.exit(0)

    # Get prompt from input
    prompt = data.get('prompt', '')

    # Check if command starts with /skin
    if not prompt.strip().startswith('/skin'):
        # Not a /skin command, let it pass through to AI
        sys.exit(0)

    # Extract argument (skin name) if present
    parts = prompt.strip().split(maxsplit=1)
    arg = parts[1] if len(parts) > 1 else ''

    # Path to claude-skin.py
    skin_script = Path.home() / '.claude' / 'scripts' / 'claude-skin.py'

    if not skin_script.exists():
        print(f"Error: Skin script not found at {skin_script}", file=sys.stderr)
        sys.exit(2)

    # Run the skin script - don't capture output, let it go directly to stderr
    try:
        cmd = [sys.executable, str(skin_script)]
        if arg:
            cmd.append(arg)

        env = os.environ.copy()
        env['PYTHONIOENCODING'] = 'utf-8'

        # Run without capturing - output goes directly to console/stderr
        subprocess.run(
            cmd,
            stdin=subprocess.DEVNULL,
            stdout=sys.stderr,  # Redirect stdout to stderr
            stderr=sys.stderr,
            timeout=5,
            env=env
        )

    except subprocess.TimeoutExpired:
        print("Error: Skin script timed out", file=sys.stderr)
    except Exception as e:
        print(f"Error running skin script: {e}", file=sys.stderr)

    # Exit code 2 = block the prompt from going to AI
    sys.exit(2)


if __name__ == '__main__':
    main()
