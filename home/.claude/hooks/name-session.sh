#!/usr/bin/env bash
# UserPromptSubmit hook: name an unnamed session `<checkout directory>-<branch>`, so other sessions
# can tell from `ListAgents` which checkout and branch it is working in.
#
# Naming is one-shot: the hook's own title comes back as `session_title` on later prompts, so a
# session keeps the branch it was first named on. It skips `main` and the `temp`, `temp<N>` and
# `temp-<x>` branches so that the name lands on the branch the work happens on.
#
# It stays silent and exits 0 on any failure, outside a git repository, on a detached HEAD, on a
# skipped branch and whenever the session already has a title. Its only output is the JSON object jq
# builds; the title holds nothing but [A-Za-z0-9._-] and at most 80 characters.

name_session() {
  local input title_set cwd branch top title
  input=$(cat) || return
  command -v jq >/dev/null || return

  title_set=$(jq -r 'if (.session_title // "") == "" then "no" else "yes" end' <<<"$input") \
    || return
  [[ $title_set == no ]] || return

  cwd=$(jq -r '.cwd // empty' <<<"$input") || return
  [[ -n $cwd && -d $cwd ]] || return

  branch=$(git -C "$cwd" branch --show-current) || return
  [[ -n $branch ]] || return
  case $branch in
    main | temp | temp[0-9]* | temp-*) return ;;
  esac

  top=$(git -C "$cwd" rev-parse --show-toplevel) || return
  title=$(printf '%s-%s' "${top##*/}" "$branch" | LC_ALL=C tr -c 'A-Za-z0-9._-' '-' | cut -c1-80) \
    || return
  [[ -n $title ]] || return

  jq -cn --arg t "$title" \
    '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: $t}}'
}

name_session 2>/dev/null
exit 0
