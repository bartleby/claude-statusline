# Claude Code Statusline (Windows)

Python version of the statusline for Windows users.

## Requirements

- Python 3.8+ (usually pre-installed or available via Microsoft Store)
- `git` in PATH (for repository info)
- `keyring` package (for reading credentials from Windows Credential Manager)

## Installation

1. Install the `keyring` package (required for rate limits):

```powershell
pip install keyring
```

2. Create scripts directory and download files:

```powershell
mkdir -Force "$env:USERPROFILE\.claude\scripts"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bartleby/claude-statusline/main/windows/context-bar.py" -OutFile "$env:USERPROFILE\.claude\scripts\context-bar.py"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bartleby/claude-statusline/main/windows/update-usage-cache.py" -OutFile "$env:USERPROFILE\.claude\scripts\update-usage-cache.py"
```

3. Add to `%USERPROFILE%\.claude\settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "python ~/.claude/scripts/context-bar.py"
  }
}
```

4. Restart Claude Code.

## Features

Same as macOS version:

- **Rate limits** — 5-hour and 7-day usage with colored progress bars + time until reset
- **Real context usage** — actual tokens vs auto-compact threshold
- **Model name** — short colored name (Opus4.5, Sonnet4, Haiku)
- **Directory & Git** — current folder, branch, uncommitted changes count

## Preview

```
Opus4.5 │ my-project (main) 3 │ ▓▓░░░░ 52k/160k │ 5h ▓▓░░░░░░░░ 25% (2:51) │ 7d ▓░░░░░░░░░ 18% (4d)
```

## How credentials are retrieved

The script tries to get OAuth token from multiple sources (in order):

1. **Windows Credential Manager** — Claude Code stores credentials under service name `"Claude Code-credentials"` using node-keytar. Requires `keyring` package.

2. **Credentials file** — `~/.claude/.credentials.json` (used on Linux/WSL or older versions)

3. **Environment variable** — `CLAUDE_CODE_OAUTH_TOKEN`

## Troubleshooting

### Python not found

Make sure Python is in your PATH. Install from:
- Microsoft Store: search for "Python 3.12"
- https://python.org/downloads/

Test with:
```powershell
python --version
```

### Rate limits show "?"

This means credentials couldn't be retrieved. Check:

1. Make sure you're logged into Claude Code (`claude` → `/login`)

2. Install the `keyring` package:
   ```powershell
   pip install keyring
   ```

3. Verify credentials exist in Windows Credential Manager:
   - Open "Credential Manager" from Control Panel
   - Look under "Generic Credentials"
   - Search for "Claude Code-credentials"

4. Alternative: set environment variable:
   ```powershell
   # Get your token from macOS keychain or another logged-in machine
   $env:CLAUDE_CODE_OAUTH_TOKEN = "sk-ant-oat01-..."
   ```

### Git info not showing

Make sure `git` is installed and in your PATH:
```powershell
git --version
```

### Progress bars look broken

Make sure your terminal supports ANSI colors. Windows Terminal and PowerShell 7+ support them by default. For older PowerShell:
```powershell
$env:TERM = "xterm-256color"
```

## How it works

1. **context-bar.py** — Main statusline script
   - Reads JSON input from Claude Code (model, cwd, transcript path)
   - Parses transcript for token usage
   - Gets git branch and status
   - Reads cached rate limits
   - Outputs formatted statusline with ANSI colors

2. **update-usage-cache.py** — Background cache updater
   - Fetches usage from `https://api.anthropic.com/api/oauth/usage`
   - Uses OAuth token from Credential Manager
   - Caches to `~/.claude/usage_cache`
   - Triggered by context-bar.py every 60 seconds

## WSL users

If you're using Claude Code in WSL, the macOS/Linux bash version may work better. However, this Python version should also work in WSL — credentials will be read from `~/.claude/.credentials.json` file.
