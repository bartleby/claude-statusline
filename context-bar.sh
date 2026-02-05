#!/bin/bash
# Claude Code Status Line
# Format: Model │ Dir (branch) n │ Ctx ▓▓░░░░░░ 28% 49k/200k │ 5h ▓░░░░░░░ 2% (4:11) │ 7d ▓▓░░░░░░ 24% (3d)

export LC_ALL=C

# Base colors
RST='\033[0m'
BLD='\033[1m'
DIM='\033[2m'

# Load theme
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIN_CONFIG="${HOME}/.claude/current_skin"

if [[ -f "${SCRIPT_DIR}/themes.sh" ]]; then
    source "${SCRIPT_DIR}/themes.sh"
    if [[ -f "$SKIN_CONFIG" ]]; then
        load_theme "$(cat "$SKIN_CONFIG")"
    else
        load_theme "kratos"
    fi
else
    # Fallback: Kratos theme hardcoded
    C_MODEL='\033[38;5;196m'
    C_DIR='\033[38;5;223m'
    C_BRANCH='\033[38;5;180m'
    C_DIRTY='\033[38;5;160m'
    C_BAR='\033[38;5;180m'
    C_BAR_E='\033[38;5;52m'
    C_TXT='\033[38;5;252m'
    C_SEP='\033[38;5;137m'
    C_OK='\033[38;5;223m'
    C_WARN='\033[38;5;180m'
    C_HIGH='\033[38;5;196m'
    logo1=" \033[38;5;180m▐\033[38;5;196m▛\033[38;5;223m█\033[38;5;230m█\033[38;5;223m█\033[38;5;223m▜\033[38;5;180m▌${RST} "
    logo2="\033[38;5;180m▝\033[38;5;160m▜\033[38;5;223m█\033[38;5;230m█\033[38;5;223m█\033[38;5;230m█\033[38;5;223m█\033[38;5;223m▛\033[38;5;180m▘${RST}"
    logo3="  \033[38;5;223m▘▘ ▝▝${RST}  "
fi

# Parse input JSON once
input=$(cat)
read -r model_id cwd ctx_total ctx_used_pct cost_usd duration_ms lines_added lines_removed <<< "$(echo "$input" | jq -r '[.model.id // .model.display_name // "?", .cwd // "", .context_window.context_window_size // 0, .context_window.used_percentage // 0, .cost.total_cost_usd // 0, .cost.total_duration_ms // 0, .cost.total_lines_added // 0, .cost.total_lines_removed // 0] | @tsv')"

# Short model name
case "$model_id" in
    *opus*4*5*|*Opus*4.5*)     model="Opus4.5" ;;
    *opus*4*|*Opus*4*)         model="Opus4" ;;
    *sonnet*4*5*|*Sonnet*4.5*) model="Sonnet4.5" ;;
    *sonnet*4*|*Sonnet*4*)     model="Sonnet4" ;;
    *sonnet*|*Sonnet*)         model="Sonnet" ;;
    *haiku*|*Haiku*)           model="Haiku" ;;
    *)                         model="?" ;;
esac

# Context window from JSON
[[ -z "$ctx_total" || "$ctx_total" == "0" ]] && ctx_total=200000

# Directory and git
dir=$(basename "$cwd" 2>/dev/null)
[[ -z "$dir" ]] && dir="?"

branch="" git_st=""
if [[ -d "$cwd" ]]; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    if [[ -n "$branch" ]]; then
        changes=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        [[ "$changes" -gt 0 ]] && git_st="${C_DIRTY}${changes}${RST}" || git_st="${C_OK}✓${RST}"
    fi
fi

# Defaults for context data
[[ -z "$ctx_used_pct" || "$ctx_used_pct" == "null" ]] && ctx_used_pct=0

# Progress bar builder
bar() {
    local val=$1 max=$2 len=$3 color=$4
    [[ $max -le 0 ]] && max=1
    local filled=$((val * len / max))
    [[ $filled -gt $len ]] && filled=$len
    [[ $val -gt 0 && $filled -eq 0 ]] && filled=1
    local b=""
    for ((i=0; i<len; i++)); do
        [[ $i -lt $filled ]] && b+="${color}▓${RST}" || b+="${C_BAR_E}░${RST}"
    done
    echo "$b"
}

# Time until reset
time_until() {
    local t=$1
    [[ -z "$t" || "$t" == "null" ]] && { echo "?"; return; }
    local ts=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "${t%%.*}" "+%s" 2>/dev/null)
    [[ -z "$ts" ]] && { echo "?"; return; }
    local d=$((ts - $(date -u +%s)))
    if [[ $d -le 0 ]]; then echo "0:00"
    elif [[ $d -lt 86400 ]]; then printf "%d:%02d" $((d/3600)) $(((d%3600)/60))
    else echo "$((d/86400))d"
    fi
}

# Limit color
lim_color() {
    [[ "$1" == "?" ]] && { echo "$DIM"; return; }
    [[ $1 -lt 50 ]] && echo "$C_OK" || { [[ $1 -lt 80 ]] && echo "$C_WARN" || echo "$C_HIGH"; }
}

# Usage limits from cache
cache="${HOME}/.claude/usage_cache"
h5="?" d7="?" h5_r="" d7_r=""
if [[ -f "$cache" ]]; then
    age=$(( $(date +%s) - $(stat -f %m "$cache" 2>/dev/null || echo 0) ))
    read -r h5 d7 h5_r d7_r < "$cache" 2>/dev/null
    [[ -z "$h5" ]] && h5="?"
    [[ -z "$d7" ]] && d7="?"
    [[ $age -gt 60 ]] && nohup "${HOME}/.claude/scripts/update-usage-cache.sh" >/dev/null 2>&1 &
else
    nohup "${HOME}/.claude/scripts/update-usage-cache.sh" >/dev/null 2>&1 &
fi

# Build output
sep=" ${C_SEP}│${RST} "

# Logo walls
C_WALL='\033[38;5;237m'
wl="${C_WALL}▏${RST}"
wr="${C_WALL}▕${RST}"

# Wrap logo with walls
logo1_full="${wl}${logo1}${wr}"
logo2_full="${wl}${logo2}${wr}"
logo3_full="${wl}${logo3}${wr}"

# Context bar (from Claude Code's used_percentage directly)
ctx_used_display=$((ctx_total * ctx_used_pct / 100))

# Format cost
[[ -z "$cost_usd" || "$cost_usd" == "null" ]] && cost_usd=0
cost_fmt=$(printf '%.2f' "$cost_usd" 2>/dev/null || echo "0.00")

# Format duration (HH:MM format)
[[ -z "$duration_ms" || "$duration_ms" == "null" ]] && duration_ms=0
duration_s=$((duration_ms / 1000))
duration_h=$((duration_s / 3600))
duration_m=$((duration_s % 3600 / 60))
duration_fmt=$(printf "%d:%02d" $duration_h $duration_m)

# Format lines added/removed
[[ -z "$lines_added" || "$lines_added" == "null" ]] && lines_added=0
[[ -z "$lines_removed" || "$lines_removed" == "null" ]] && lines_removed=0
lines_fmt="+${lines_added}/-${lines_removed}"


# Choose color based on usage
ctx_color="$C_BAR"
[[ $ctx_used_pct -ge 90 ]] && ctx_color="$C_HIGH" || { [[ $ctx_used_pct -ge 70 ]] && ctx_color="$C_WARN"; }

c5=$(lim_color "$h5"); c7=$(lim_color "$d7")

# Build lines
data1="${C_MODEL}${BLD}${model}${RST}${sep}${C_DIR}${dir}${RST}"
[[ -n "$branch" ]] && data1+=" ${DIM}(${RST}${C_BRANCH}${branch}${RST}${DIM})${RST} ${git_st}"
[[ $lines_added -gt 0 || $lines_removed -gt 0 ]] && data1+="${sep}${C_OK}+${lines_added}${RST}${DIM}/${RST}${C_WARN}-${lines_removed}${RST}"
data2="${DIM}5hr${RST} $(bar ${h5:-0} 100 8 $c5) ${c5}${h5}%${RST} ${DIM}($(time_until "$h5_r"))${RST}${sep}${DIM}wkl${RST} $(bar ${d7:-0} 100 8 $c7) ${c7}${d7}%${RST} ${DIM}($(time_until "$d7_r"))${RST}"
data3="${DIM}ctx${RST} $(bar $ctx_used_pct 100 8 $ctx_color) ${ctx_color}${ctx_used_pct}%${RST} ${DIM}$((ctx_used_display/1000))k/$((ctx_total/1000))k${RST}${sep}${DIM}usd${RST} ${C_OK}\$${cost_fmt}${RST}${sep}${DIM}ttm${RST} ${C_OK}${duration_fmt}${RST}"

printf '\n'
printf '%b\n' "${logo1_full} ${data1}"
printf '%b\n' "${logo2_full} ${data3}"
printf '%b\n' "${logo3_full} ${data2}"
printf '\n'
