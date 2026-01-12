#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON (use system jq to avoid asdf shim issues)
current_dir=$(echo "$input" | /usr/bin/jq -r '.workspace.current_dir')
model=$(echo "$input" | /usr/bin/jq -r '.model.display_name')

# Extract context window information
input_tokens=$(echo "$input" | /usr/bin/jq -r '.context_window.total_input_tokens // 0')
output_tokens=$(echo "$input" | /usr/bin/jq -r '.context_window.total_output_tokens // 0')
context_size=$(echo "$input" | /usr/bin/jq -r '.context_window.context_window_size // 200000')

# Get current directory basename
dir_name=$(basename "$current_dir")

# Git information
if [ -d "$current_dir/.git" ] || git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$current_dir" branch --show-current 2>/dev/null || echo 'detached')

  # Fast dirty check - short-circuits on first difference found
  if ! git -C "$current_dir" diff --quiet HEAD 2>/dev/null; then
    dirty=" \033[0;33m✗\033[0m"
  else
    dirty=""
  fi

  # Ahead/behind tracking
  ahead_behind=$(git -C "$current_dir" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
  if [ -n "$ahead_behind" ]; then
    ahead=$(echo "$ahead_behind" | cut -f1)
    behind=$(echo "$ahead_behind" | cut -f2)
    sync_status=""
    [ "$ahead" -gt 0 ] && sync_status="${sync_status} \033[0;32m↑${ahead}\033[0m"
    [ "$behind" -gt 0 ] && sync_status="${sync_status} \033[0;31m↓${behind}\033[0m"
  else
    sync_status=""
  fi

  git_info=$(printf "%b%b \033[1;34mgit:(\033[0;31m%s\033[1;34m)\033[0m" "$dirty" "$sync_status" "$branch")
else
  git_info=""
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

# Green arrow (robbyrussell theme default)
arrow=$(printf "\033[1;32m➜\033[0m")

# Calculate context remaining as percentage
# NOTE: Known issue - tokens are cumulative session totals, not current context usage.
#       This means percentage may be inaccurate after auto-compaction.
#       See: https://github.com/anthropics/claude-code/issues/13783
context_info=""
if [ "$context_size" -gt 0 ] 2>/dev/null; then
  used_tokens=$((input_tokens + output_tokens))
  percent_used=$((used_tokens * 100 / context_size))

  # Cap at 100% (can exceed due to cumulative token bug)
  [ "$percent_used" -gt 100 ] && percent_used=100

  percent_remaining=$((100 - percent_used))

  # Color based on usage: green (<50%), yellow (50-80%), red (>80%)
  if [ "$percent_used" -lt 50 ]; then
    context_color="\033[0;32m"  # green
  elif [ "$percent_used" -lt 80 ]; then
    context_color="\033[0;33m"  # yellow
  else
    context_color="\033[0;31m"  # red
  fi

  context_info=$(printf " %b%d%% left\033[0m" "$context_color" "$percent_remaining")
fi

# Output: arrow + cyan directory + rails indicator + magenta model + context + git info
printf "%s \033[0;36m%s\033[0m%b \033[1;35m%s\033[0m%b%b" "$arrow" "$dir_name" "$rails_indicator" "$model" "$context_info" "$git_info"
