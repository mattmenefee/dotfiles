#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
current_dir=$(echo "$input" | /usr/bin/jq -r '.workspace.current_dir')
model=$(echo "$input" | /usr/bin/jq -r '.model.display_name')

# Calculate context percentage including output tokens to match auto-compact threshold.
# The pre-calculated used_percentage excludes output tokens, so it underreports usage.
pct=$(echo "$input" | /usr/bin/jq -r '
  .context_window |
  if .current_usage != null and .context_window_size > 0 then
    ((.current_usage.input_tokens // 0)
     + (.current_usage.cache_creation_input_tokens // 0)
     + (.current_usage.cache_read_input_tokens // 0)
     + (.current_usage.output_tokens // 0))
    * 100 / .context_window_size | floor
  else
    .used_percentage // 0 | floor
  end
')
[ -z "$pct" ] && pct=0

# Get current directory basename
dir_name=$(basename "$current_dir")

# Git information (cached per-directory for performance)
dir_hash=$(echo "$current_dir" | md5 -q 2>/dev/null || echo "$current_dir" | md5sum | cut -d' ' -f1)
CACHE_FILE="/tmp/statusline-git-cache-${dir_hash}"
CACHE_MAX_AGE=5

cache_is_stale() {
  [ ! -f "$CACHE_FILE" ] || \
  [ $(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0))) -gt $CACHE_MAX_AGE ]
}

if cache_is_stale; then
  if [ -d "$current_dir/.git" ] || git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$current_dir" branch --show-current 2>/dev/null || echo 'detached')

    dirty=""
    if ! git -C "$current_dir" diff --quiet HEAD 2>/dev/null; then
      dirty="dirty"
    fi

    ahead=0
    behind=0
    ahead_behind=$(git -C "$current_dir" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
    if [ -n "$ahead_behind" ]; then
      ahead=$(echo "$ahead_behind" | cut -f1)
      behind=$(echo "$ahead_behind" | cut -f2)
    fi

    echo "$branch|$dirty|$ahead|$behind" > "$CACHE_FILE"
  else
    echo "|||" > "$CACHE_FILE"
  fi
fi

IFS='|' read -r branch dirty ahead behind < "$CACHE_FILE"

git_info=""
if [ -n "$branch" ]; then
  dirty_indicator=""
  [ "$dirty" = "dirty" ] && dirty_indicator=" \033[0;33m✗\033[0m"

  sync_status=""
  [ "$ahead" -gt 0 ] 2>/dev/null && sync_status="${sync_status} \033[0;32m↑${ahead}\033[0m"
  [ "$behind" -gt 0 ] 2>/dev/null && sync_status="${sync_status} \033[0;31m↓${behind}\033[0m"

  git_info=$(printf "%b%b \033[1;34mgit:(\033[0;31m%s\033[1;34m)\033[0m" "$dirty_indicator" "$sync_status" "$branch")
fi

# Rails server indicator (check PID file and verify process is running)
rails_indicator=""
pid_file="$current_dir/tmp/pids/server.pid"
if [ -f "$pid_file" ]; then
  pid=$(cat "$pid_file" 2>/dev/null)
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    rails_indicator=$(printf " \033[0;32m🚀\033[0m")
  fi
fi

# Green arrow
arrow=$(printf "\033[1;32m➜\033[0m")

# --- Line 1: arrow + directory + rails + model + git ---
printf "%s \033[0;36m%s\033[0m%b \033[1;35m%s\033[0m %b\n" "$arrow" "$dir_name" "$rails_indicator" "$model" "$git_info"

# --- Line 2: context progress bar + cost + duration ---
# Color thresholds: green (<70%), yellow (70-89%), red (>=90%)
if [ "$pct" -ge 90 ]; then
  bar_color="\033[0;31m"  # red
elif [ "$pct" -ge 70 ]; then
  bar_color="\033[0;33m"  # yellow
else
  bar_color="\033[0;32m"  # green
fi

# Build 20-char progress bar for finer granularity
BAR_WIDTH=20
FILLED=$((pct * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
bar=""
[ "$FILLED" -gt 0 ] && bar=$(printf "%${FILLED}s" | tr ' ' '█')
[ "$EMPTY" -gt 0 ] && bar="${bar}$(printf "%${EMPTY}s" | tr ' ' '░')"

printf "%b%s\033[0m %d%%" "$bar_color" "$bar" "$pct"

