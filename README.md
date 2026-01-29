# Claude Code Statusline

Compact, colorful status line for [Claude Code](https://claude.ai/code) CLI **with real-time rate limits**.

![Preview](preview.png)

## Why?

Claude Code doesn't show your 5-hour and weekly rate limits in the UI. This statusline fetches them directly from Anthropic API so you always know how much capacity you have left.

## Features

- **Rate limits** — 5-hour and 7-day usage with colored progress bars + time until reset
- **Real context usage** — shows actual tokens used vs auto-compact threshold (not the full 200k window, but the real ~160k before compaction kicks in)
- **Model name** — short colored name (Opus4.5, Sonnet4, Haiku)
- **Directory & Git** — current folder, branch, uncommitted changes count

## Preview

```
Opus4.5 │ my-project (main) 3 │ ▓▓░░░░ 52k/160k │ 5h ▓▓░░░░░░░░ 25% (2:51) │ 7d ▓░░░░░░░░░ 18% (4d)
```

- `52k/160k` — you've used 52k tokens, auto-compact triggers at ~160k (80% of 200k)
- `5h 25% (2:51)` — 25% of 5-hour limit used, resets in 2 hours 51 minutes
- `7d 18% (4d)` — 18% of weekly limit used, resets in 4 days

## Installation

1. Copy scripts to Claude config directory:

```bash
mkdir -p ~/.claude/scripts
curl -o ~/.claude/scripts/context-bar.sh https://raw.githubusercontent.com/bartleby/claude-statusline/main/context-bar.sh
curl -o ~/.claude/scripts/update-usage-cache.sh https://raw.githubusercontent.com/bartleby/claude-statusline/main/update-usage-cache.sh
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

- macOS (uses `security` for Keychain access)
- `jq` — JSON processor (`brew install jq`)
- `git` — for repository info

> **Windows users**: See [windows/](windows/) folder for Python version that works on Windows.

## How it works

### Rate limits
Fetches usage data from Anthropic API (`/api/oauth/usage`) using OAuth token from macOS Keychain. Data is cached and refreshed in background every 60 seconds — no lag in your statusline.

### Context bar
Reads actual token usage from transcript file and shows progress relative to auto-compact threshold (80% of context window). This means when the bar is full, auto-compact is about to happen — no more guessing!

## License

MIT
