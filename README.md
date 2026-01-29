# Claude Code Statusline

Compact, colorful status line for [Claude Code](https://claude.ai/code) CLI.

![Preview](preview.png)

## Features

- **Model name** — short colored name (Opus4.5, Sonnet4, Haiku)
- **Directory & Git** — current folder, branch, uncommitted changes count
- **Context usage** — progress bar relative to auto-compact threshold (80%)
- **Rate limits** — 5-hour and 7-day usage with progress bars
- **Time to reset** — countdown until limits refresh

## Preview

```
Opus4.5 │ my-project (main) 3 │ ▓▓░░░░ 52k/160k │ 5h ▓▓░░░░░░░░ 25% (2:51) │ 7d ▓░░░░░░░░░ 18% (4d)
```

## Installation

1. Copy scripts to Claude config directory:

```bash
mkdir -p ~/.claude/scripts
cp context-bar.sh ~/.claude/scripts/
cp update-usage-cache.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/*.sh
```

2. Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/scripts/context-bar.sh"
  }
}
```

3. Restart Claude Code.

## Requirements

- macOS (uses `security` for Keychain access, `stat -f` for file age)
- `jq` — JSON processor
- `git` — for repository info

## How it works

### Context bar
Reads token usage from transcript file and shows progress relative to auto-compact threshold (80% of context window).

### Rate limits
Fetches usage data from Anthropic API using OAuth token stored in macOS Keychain. Data is cached and refreshed in background every 60 seconds.

## Configuration

Edit `context-bar.sh` to customize:
- Colors (256-color ANSI codes)
- Progress bar length
- Model name mappings

## License

MIT
