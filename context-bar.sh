#!/bin/bash
# Claude Code Status Line
# Format: Model │ Dir (branch) n │ Ctx ▓▓░░░░░░ 28% 49k/200k │ 5h ▓░░░░░░░ 2% (4:11) │ 7d ▓▓░░░░░░ 24% (3d)

export LC_ALL=C

# Colors
RST='\033[0m'
BLD='\033[1m'
DIM='\033[2m'
C_MODEL='\033[38;5;141m'
C_DIR='\033[38;5;75m'
C_BRANCH='\033[38;5;114m'
C_DIRTY='\033[38;5;208m'
C_BAR='\033[38;5;75m'
C_BAR_E='\033[38;5;238m'
C_TXT='\033[38;5;252m'
C_SEP='\033[38;5;240m'
C_OK='\033[38;5;114m'
C_WARN='\033[38;5;220m'
C_HIGH='\033[38;5;208m'

# Parse input JSON once
input=$(cat)
read -r model_id cwd ctx_used ctx_total ctx_remaining_pct <<< "$(echo "$input" | jq -r '[.model.id // .model.display_name // "?", .cwd // "", (.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0), .context_window.context_window_size // 0, .context_window.remaining_percentage // 0] | @tsv')"

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
[[ -z "$ctx_used" || "$ctx_used" == "null" ]] && ctx_used=0
[[ -z "$ctx_remaining_pct" || "$ctx_remaining_pct" == "null" ]] && ctx_remaining_pct=0
# If no tokens used, context is empty (0% used), not full (100% used)
[[ "$ctx_used" -eq 0 ]] && ctx_remaining_pct=100

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
out="${C_MODEL}${BLD}${model}${RST}"
out+="${sep}${C_DIR}${dir}${RST}"
[[ -n "$branch" ]] && out+=" ${DIM}(${RST}${C_BRANCH}${branch}${RST}${DIM})${RST} ${git_st}"

# Context bar (from Claude Code's actual data)
ctx_used_pct=$((100 - ctx_remaining_pct))

# Choose color based on usage
ctx_color="$C_BAR"
[[ $ctx_used_pct -ge 90 ]] && ctx_color="$C_HIGH" || { [[ $ctx_used_pct -ge 70 ]] && ctx_color="$C_WARN"; }

# Context usage bar
out+="${sep}${DIM}Ctx${RST} $(bar $ctx_used_pct 100 8 $ctx_color) ${ctx_color}${ctx_used_pct}%${RST} ${DIM}$((ctx_used/1000))k/$((ctx_total/1000))k${RST}"

c5=$(lim_color "$h5"); c7=$(lim_color "$d7")
out+="${sep}${DIM}5h${RST} $(bar ${h5:-0} 100 8 $c5) ${c5}${h5}%${RST} ${DIM}($(time_until "$h5_r"))${RST}"
out+="${sep}${DIM}7d${RST} $(bar ${d7:-0} 100 8 $c7) ${c7}${d7}%${RST} ${DIM}($(time_until "$d7_r"))${RST}"

printf '%b\n' "$out"
