#!/bin/bash
# Фоновое обновление кэша usage limits через Anthropic API

export LC_ALL=C
config_dir="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
cache_file="${config_dir}/usage_cache"

# Профиль с CLAUDE_CONFIG_DIR хранит токен под отдельным именем в Keychain
keychain_service="Claude Code-credentials"
if [[ -n "$CLAUDE_CONFIG_DIR" ]]; then
    keychain_service="${keychain_service}-$(printf '%s' "$CLAUDE_CONFIG_DIR" | shasum -a 256 | cut -c1-8)"
fi

# Получаем токен: macOS Keychain или Linux credentials file
if [[ "$(uname)" == "Darwin" ]]; then
    TOKEN=$(security find-generic-password -s "$keychain_service" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty')
else
    TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "${config_dir}/.credentials.json" 2>/dev/null)
fi

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    exit 1
fi

# Запрос к API
response=$(curl -s --max-time 5 "https://api.anthropic.com/api/oauth/usage" \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-beta: oauth-2025-04-20" 2>/dev/null)

if [[ -n "$response" ]]; then
    five_hour=$(echo "$response" | jq -r '.five_hour.utilization // 0' 2>/dev/null)
    seven_day=$(echo "$response" | jq -r '.seven_day.utilization // 0' 2>/dev/null)
    five_hour_reset=$(echo "$response" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
    seven_day_reset=$(echo "$response" | jq -r '.seven_day.resets_at // empty' 2>/dev/null)

    # Округляем до целых
    five_hour=$(printf "%.0f" "$five_hour" 2>/dev/null || echo "0")
    seven_day=$(printf "%.0f" "$seven_day" 2>/dev/null || echo "0")

    echo "${five_hour} ${seven_day} ${five_hour_reset} ${seven_day_reset}" > "$cache_file"
fi
