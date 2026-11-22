---
name: close-out
description: >-
  Before a session closes, report everything it would leave behind: uncommitted, unpushed or unfixed
  work, untracked working documents, scratch files holding production data, test-plan boxes and
  deployment notes it could tick, peer sessions owed a message, running background processes and
  follow-ups with no durable home. Acts on each item only with the user's go-ahead. Use when asked
  whether anything is outstanding before closing a session.
argument-hint: "[note]"
---

# Close Out a Session

Answer "is there anything outstanding before I close this session?" with a checked list, then act on
each item only when the user says so. Until then this skill only reads, re-runs checks and reports.

**Note (optional):** `$ARGUMENTS` — anything else the user wants checked or ruled out; when empty,
check the groups below only.

## 1. Gather

Check every group below, in the session's checkout and in every other checkout or worktree the
session worked in. Answer each from a command run now, never from memory of the conversation: a
commit, a push or another session may have changed it since. The conversation is the source only for
what no command can show, such as a promise made to the user or a peer.

1. **Uncommitted work:** `git status --short --branch`. Separate the session's own changes from ones
   that were there before it started, which are not this session's to commit.
1. **Unpushed work:** `git log --oneline '<branch>@{upstream}..<branch>'` for each branch the
   session committed to. When the branch has no upstream, or its upstream is gone, check
   `git ls-remote origin refs/heads/<branch>` before reporting it as never pushed.
1. **Unfixed work:** what the session agreed to fix and has not: an open box or ❓ row in a review
   file, a spec or lint run last seen failing, a change the user asked for that has not landed.
   Re-run a failing check before reporting it as still failing, but before re-running a spec, check
   for another session or a running test process as `/resume-handoff` does, and report the check as
   last seen failing if one is found.
1. **Untracked working documents:** the `??` lines from item 1's status, plus any file the session
   wrote outside the repository, except the files item 5 covers. For each, say where it should live:
   a plan, review or impact file stays untracked unless the project's `/ship-it` expects it
   committed, a handoff follows `/handoff` › After the Branch Merges, and anything else is
   committed, moved or deleted.
1. **Scratch files holding production data:** files the session wrote to the scratchpad, `/tmp` or
   the project root that hold production rows, exports, logs or customer data, including ignored
   files that `git status --short --ignored` lists in the project root. Name each by path and say
   what it holds without printing its contents, and recommend deleting it.
1. **Test-plan boxes and deployment notes:** each open `- [ ]` in the pull request body
   (`gh pr view --json body`) and, where the project keeps deployment notes on a draft release, each
   note on it (`gh release list --json tagName,isDraft`, then `gh release view <tag> --json body`),
   that evidence this session already has would let it tick. Name the evidence beside each.
1. **Peer sessions owed a message:** sessions that asked this one for a reply or a result, are
   waiting on work this session finished, or should hear about a decision it made. If `ListAgents`
   is available, find them in it; otherwise take the sessions the conversation shows this one
   exchanged messages with.
1. **Running processes:** background commands, servers, watchers and monitors this session started.
   Identify each by the PID or task captured when it started, never by `pgrep -f`, and confirm each
   is still running with `ps -p <PID>` or the task's status before reporting it.
1. **Follow-ups with no durable home:** anything this session said waits on a later date or event
   that is not yet in an issue, a deployment note, a handoff's Next Steps or a memory

## 2. Report

List what is outstanding under the group headings above, each item with the command or evidence
behind it and a proposed action. Name the groups with nothing outstanding in one line at the end, so
the user can see each was checked rather than skipped. When every group is empty, say the session
can close.

## 3. Act

Ask which proposed actions to take with `AskUserQuestion`: group the actions by section, one
question per group with `multiSelect` and at most four options, the recommended ones first and
labeled "(Recommended)". Leaving every box unchecked defers that group. Take only the actions the
user chose:

- Commit through `/commit`, and write or move a handoff through `/handoff`
- A push, a pull request, issue or release edit, a message to a peer, a deletion or stopping a
  process waits for that item's go-ahead, whoever else has asked for it
- Never delete a file the user did not choose, and never print a scratch file's contents to decide
  whether to delete it

After acting, run the checks for the groups the actions touched again and report what remains
outstanding.
