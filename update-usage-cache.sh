#!/bin/bash
# Фоновое обновление кэша usage limits через Anthropic API

export LC_ALL=C
cache_file="${HOME}/.claude/usage_cache"

# Получаем токен из Keychain
TOKEN=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty')

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
