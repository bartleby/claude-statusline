# Claude Code Statusline (Windows)

Full-featured Python version of the statusline for Windows users with complete theme support.

![Preview](../preview.png)

## Features

All features from macOS/Linux version:

- **21 Themes** — Full gallery with `/skin` command support
- **Context usage** — Real-time token consumption with color-coded alerts
- **Rate limits** — 5-hour and 7-day usage with progress bars + time until reset
- **Model name** — Short colored name (Opus4.6, Opus4.5, Sonnet4.6, Sonnet4.5, Sonnet4, Haiku)
- **Directory & Git** — Current folder, branch, uncommitted changes count
- **Cost tracking** — Session cost in USD and total time
- **Lines changed** — Added/removed lines counter

## One-Line Installation

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/bartleby/claude-statusline/main/windows/install.ps1 | iex
```

This will:
1. Download all Python scripts to `~/.claude/scripts/`
2. Install the `/skin` command hook
3. Configure `settings.json` automatically
4. Install `keyring` package for rate limits (optional)
5. Set default theme to "kratos"

## Manual Installation

If you prefer manual installation:

### 1. Install Python

Make sure Python 3.8+ is installed and in PATH:
- Download from [python.org](https://python.org/downloads/)
- Or install via Microsoft Store: search for "Python 3.12"

Verify installation:
```powershell
python --version
```

### 2. Install keyring package (optional, for rate limits)

```powershell
pip install keyring
```

### 3. Create directories and download scripts

```powershell
mkdir -Force "$env:USERPROFILE\.claude\scripts"
mkdir -Force "$env:USERPROFILE\.claude\hooks"

$scripts = @("context-bar.py", "themes.py", "claude-skin.py", "update-usage-cache.py", "skin-hook.py")
foreach ($s in $scripts) {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bartleby/claude-statusline/main/windows/$s" -OutFile "$env:USERPROFILE\.claude\scripts\$s"
}
```

### 4. Configure settings.json

Add to `%USERPROFILE%\.claude\settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "python ~/.claude/scripts/context-bar.py"
  },
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python ~/.claude/scripts/skin-hook.py"
          }
        ]
      }
    ]
  }
}
```

### 5. Set default theme

```powershell
Set-Content -Path "$env:USERPROFILE\.claude\current_skin" -Value "kratos" -NoNewline
```

### 6. Restart Claude Code

## Usage

```
/skin          - Show theme gallery
/skin <name>   - Apply a theme (e.g., /skin ocean)
```

Press **Shift+Tab** to refresh the statusline after applying a theme.

## Available Themes

| Theme | Description |
|-------|-------------|
| kratos | Red & cream (default) |
| shadow | Monochrome gray |
| ocean | Deep blue to cyan |
| goose | Orange & white |
| matrix | Terminal green |
| sakura | Cherry blossom pink |
| aurora | Northern lights teal |
| ember | Glowing fire |
| frost | Ice crystal blue |
| odi | White cat |
| cyberpunk | Pink & electric blue |
| lavender | Soft purple |
| gold | Rich golden |
| inferno | Intense fire |
| copper | Bronze metallic |
| amethyst | Deep purple crystal |
| bubblegum | Bright pink |
| spiderman | Red & blue |
| captain | Shield colors |
| venom | Black & white |
| vaporwave | Retro pink/cyan |

## How Credentials Are Retrieved

The script retrieves OAuth tokens from multiple sources (in order):

1. **Windows Credential Manager** — Claude Code stores credentials under service name `"Claude Code-credentials"` using node-keytar. Requires `keyring` package.

2. **Credentials file** — `~/.claude/.credentials.json` (fallback for WSL or older versions)

3. **Environment variable** — `CLAUDE_CODE_OAUTH_TOKEN`

## Troubleshooting

### Statusline not appearing

1. Make sure Python is in your PATH:
   ```powershell
   python --version
   ```

2. Check that settings.json is correctly configured

3. Restart Claude Code

### Rate limits show "?"

This means credentials couldn't be retrieved:

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
   $env:CLAUDE_CODE_OAUTH_TOKEN = "your-token-here"
   ```

### Git info not showing

Make sure `git` is installed and in your PATH:
```powershell
git --version
```

### Progress bars look broken

Make sure your terminal supports ANSI colors:

- **Windows Terminal** — Supports colors by default
- **PowerShell 7+** — Supports colors by default
- **Older PowerShell** — Try setting:
  ```powershell
  $env:TERM = "xterm-256color"
  ```
- **CMD** — May have limited support, recommend using Windows Terminal

### /skin command not working

1. Check that the hook is configured in settings.json
2. Verify skin-hook.py exists in `~/.claude/scripts/`
3. Make sure Python is in PATH

## Files Installed

```
~/.claude/
├── scripts/
│   ├── context-bar.py      # Main statusline script
│   ├── themes.py           # Theme definitions (21 themes)
│   ├── claude-skin.py      # Theme selector/gallery
│   ├── update-usage-cache.py # Rate limits updater
│   └── skin-hook.py        # /skin command hook
├── skills/
│   └── skin/
│       └── SKILL.md        # Skill definition for menu
├── settings.json           # Claude Code configuration
├── current_skin            # Current theme name
└── usage_cache             # Cached rate limits
```

## Uninstallation

```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\scripts"
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\skills\skin"
Remove-Item -Force "$env:USERPROFILE\.claude\current_skin"
Remove-Item -Force "$env:USERPROFILE\.claude\usage_cache"
```

Then manually remove the `statusLine` and `/skin` hook entries from `settings.json`.

## WSL Users

If you're using Claude Code in WSL, the macOS/Linux bash version may work better. However, this Python version should also work in WSL — credentials will be read from `~/.claude/.credentials.json` file.

## Differences from Bash Version

The Python version is functionally equivalent to the bash version with these notes:

- Uses Python's `pathlib` for cross-platform path handling
- Uses Python's `datetime` instead of `date` command
- Uses `keyring` package instead of macOS Keychain
- All 21 themes are supported with identical colors and logos
- 3-line output format with logo matches bash version exactly
