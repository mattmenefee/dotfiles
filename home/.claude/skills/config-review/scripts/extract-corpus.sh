#!/usr/bin/env bash
# Write the text the user typed into Claude Code over the last N days to one corpus file.
#
# Usage: extract-corpus.sh <output file> [days]
#
# Reads the top-level session transcripts under ~/.claude/projects (subagent transcripts sit under
# each session's own directory and hold no typed text). Each message is printed under a line
# `=== [<project directory>] <session> <timestamp>`, followed by `(accepted suggestion)` when the
# user accepted a suggested prompt rather than typing it. Messages are sorted by time, a record
# copied into a resumed session's transcript appears once and a text repeated within one session
# appears once. The output file is created with mode 600.
set -euo pipefail

out=${1:?usage: extract-corpus.sh <output file> [days]}
days=${2:-35}
[[ $days =~ ^[0-9]+$ ]] || { echo "days must be a whole number: $days" >&2; exit 2; }

filter="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/user-messages.jq"
projects="$HOME/.claude/projects"
[[ -d $projects ]] || { echo "no transcripts directory: $projects" >&2; exit 1; }
cutoff=$(date -u -v-"${days}"d +%Y-%m-%dT%H:%M:%SZ)

umask 077
records=$(mktemp)
trap 'rm -f "$records"' EXIT

files=0
while IFS= read -r -d '' transcript; do
  project=$(basename "$(dirname "$transcript")")
  session=$(basename "$transcript" .jsonl)
  jq -cR --arg project "$project" --arg session "$session" --arg cutoff "$cutoff" \
    -f "$filter" "$transcript" >>"$records"
  files=$((files + 1))
done < <(find "$projects" -mindepth 2 -maxdepth 2 -name '*.jsonl' -mtime "-$days" -print0 | sort -z)

jq -rs '
  unique_by(.key)
  | group_by(.session) | map(sort_by(.timestamp) | unique_by(.text)) | add // []
  | sort_by(.timestamp)
  | .[]
  | "=== [\(.project)] \(.session) \(.timestamp)\(if .accepted then " (accepted suggestion)" else "" end)\n\(.text)\n"
' "$records" >"$out"

messages=$(grep -c '^=== \[' "$out" || true)
span=$(jq -rs '[.[].timestamp] | if length == 0 then "none" else "\(min) to \(max)" end' "$records")
echo "corpus: $out" >&2
echo "transcripts read: $files; messages: $messages; requested since $cutoff; found $span" >&2
