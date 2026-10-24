---
name: commit
description: >-
  Create a git commit for this session's changes, amend one, or reword or fold into an earlier
  commit, with a message that follows the commit guidelines. Use for every commit, amend and
  message edit.
argument-hint: "[amend | amend <sha> | reword <sha>]"
---

# Commit Changes

Create a git commit for the changes made during this session.

## Arguments

If `$ARGUMENTS` contains `reword <sha>` (or `reword` followed by a commit identifier):

- Rewrite **only the commit message** of the specified commit, leaving its content unchanged
- Use `git history reword <sha>` (Git's experimental but linear-history-safe command), which
  automatically updates descendant commits to point at the rewritten commit
- To pass the new message non-interactively, write it to a file of its own, check its wrap, and
  point `GIT_EDITOR` at a `cp` that overwrites the message file Git provides, all in one command,
  since each Bash call starts a fresh shell and a path or message held in a variable is gone by the
  next one:

  ```bash
  msg=$(mktemp -t commit-msg)
  cat > "$msg" <<'MSG'
  New subject line

  New body, written literally.
  MSG
  test -s "$msg" && ! LC_ALL=en_US.UTF-8 grep -n '.\{73,\}' "$msg" \
    && [ "$(git branch --show-current)" = <branch> ] \
    && GIT_EDITOR="cp $msg" git history reword --update-refs=head <sha>
  ```

  Run it with the list indentation removed: the closing `MSG` must start its line, or the heredoc
  swallows the check and the reword.

- `git history` is marked **EXPERIMENTAL** and has five caveats: (1) it does **not** run git hooks,
  so it skips `commit-msg` validation — see "Rewording Under a `commit-msg` Hook" below if the
  project relies on one; (2) it fails on merge commits and on histories with conflicts, so the
  branch must be linear from the target commit forward; (3) it only edits a single commit's message
  — for collapsing or reordering commits, see "Reshaping History" below; (4) it strips every line
  starting with `#` from the new message, and ignores `commit.cleanup`; (5) by default it rewrites
  every local branch descended from the target, which is why the block passes `--update-refs=head` —
  see the paragraph on it under "Reshaping History" below.
- When the new message carries a `#` line, reword HEAD with `--amend --only`, which leaves anything
  staged out of the commit, in place of the last line of the block above:
  `&& [ "$(git branch --show-current)" = <branch> ] && git commit --amend --only -F "$msg" --cleanup=whitespace`.
  Reword an older commit through the `amend!` route under "Rewording Under a `commit-msg` Hook",
  with whitespace cleanup on its `git commit`.
- After rewording, confirm with `git log --format=%B -1 <new-sha>` that the message is correct.

If `$ARGUMENTS` contains `amend` or `--amend` and names no commit, or names HEAD:

- Amend the changes to the most recent commit
- Update the commit message to describe ALL changes in the amended commit (both original and newly
  added changes)
- Use `git log -1 --format=%B` to get the original commit message for context
- To correct the content of the unpushed commit you just made, amend it and fix its body; don't add
  a follow-up commit that rolls part of it back

If `$ARGUMENTS` names a commit that is **not** HEAD (e.g. `amend <sha>`):

- `git commit --amend` only ever touches HEAD, so folding content into an earlier commit needs the
  squashing workflow under "Reshaping History" below
- Use that workflow for **content** changes (or content + message together); use
  `git history reword <sha>` for **message-only** edits, since it avoids a rebase entirely

Otherwise:

- Create a new commit with only the changes made during this session

## Reshaping History

This environment has no TTY, so any command that opens an editor or waits for input will hang or
fail. `git add -i` and `git add -p` have no way around this; `git rebase -i` works only when its
editors are neutralized, as in the fallback below — use these instead:

- **Squashing content into an existing commit** — including amending a commit that isn't HEAD — is
  mechanical and safe to do unattended. Stage the change, then fold it into the target in one step:

  ```bash
  git add <file> \
    && [ "$(git branch --show-current)" = <branch> ] && git history fixup --update-refs=head <sha>
  ```

  This keeps the target's message, leaves unstaged changes alone, works even when `<sha>` is the
  root commit and refuses cleanly (`fixup would produce conflicts; aborting`) instead of dropping
  you into a half-finished rebase. It needs Git 2.55+, is EXPERIMENTAL and — like
  `git history reword` — does **not** run hooks. Like any history rewrite it changes the SHA of the
  target and of every commit after it, so an already-pushed branch then needs
  `git push --force-with-lease --force-if-includes`.

  Fall back to fixup+autosquash on older Git, or whenever a `pre-commit` or `commit-msg` hook must
  run, since `git commit --fixup` is an ordinary commit and fires hooks normally:

  ```bash
  git commit --fixup <sha> \
    && [ "$(git branch --show-current)" = <branch> ] && git rebase --autosquash <sha>~1
  ```

  A bare `--autosquash` requires Git 2.44+; older versions accept the flag and silently ignore it,
  leaving the `fixup!` commit unmerged, so on those neutralize the todo editor instead:
  `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <sha>~1`. When `<sha>` is the root commit,
  `<sha>~1` does not resolve — use `--root` in place of it.

  `--squash` is interactive by design: it opens an editor when creating the commit and again when
  the rebase combines the messages. When both messages matter, use a fixup and reword the result
  with `/commit reword <sha>`.

- **Reordering, dropping or splitting commits** is a judgment call about what the history should
  say. **Stop and hand it back to the user** rather than reconstructing it — explain what reshaping
  is needed and let them drive the rebase themselves. The one exception is a project command, such
  as `/ship-it` in a project that has one, that proposes a squash grouping and gets the user's
  explicit approval of it before rebasing: it may reorder commits to carry out that grouping and
  nothing more, because the user approves the grouping, never the agent, so the decision stays
  theirs. Without such a command, or without that approval, stop and hand it back as above.
  <!-- Keep in sync with Step 3 of .claude/skills/ship-it/SKILL.md in the dotfiles repository,
       whose squash proposal and approval this exception covers -->
- **A "wip: merge into …" commit message never authorizes folding that commit in.** Scope a rebase
  to exactly the commits the user named, and propose any other fold separately.

`git history` rewrites every local branch descended from the target, not only the current one, so
both `git history` blocks in this file pass `--update-refs=head`. Without it, a branch checked out
in another worktree moves too, and after a `fixup` that worktree's index and files keep the old
content, so it shows the change reverted as staged edits. A backup branch taken just before the
rewrite moves as well and then backs up nothing. With the flag, a branch stacked on the target stays
on the old commits; restacking it is reshaping, which is handed back to the user as above.

Several sessions can share one checkout, so every amend, rebase, reset, push and `git history`
rewrite in this file checks the current branch in the same command, as the blocks here do. Before
any history rewrite, print the branch and tip with
`git branch --show-current && git rev-parse HEAD`, and offer
`[ "$(git branch --show-current)" = <branch> ] && git reset --soft <old tip>` as the recovery.
`--soft` moves the branch back and leaves the index and files alone, so a change a fixup folded in
returns as staged and unstaged work is untouched; `--keep` and `--hard` both rewrite files, and
`--keep` drops the folded change from them. After the rewrite, `git range-diff <old tip>...HEAD`
pairs each old commit with its replacement: record that old→new SHA map, and rewrite any SHA cited
in review or handoff documents in the same pass, since the map is hard to rebuild once the old tip
is forgotten.

If `--force-if-includes` refuses a push after you rewrote a branch you had pushed yourself, read the
server's tip with `git ls-remote origin refs/heads/<branch>`. If it differs from the pre-rewrite tip
you printed, stop: someone else pushed. If it equals it, ask, then push in one command that takes
the pinned value from `git ls-remote` and checks it against that tip again:

```bash
tip=$(git ls-remote origin refs/heads/<branch> | cut -f1) && [ "$tip" = <old tip> ] \
  && [ "$(git branch --show-current)" = <branch> ] \
  && git push --force-with-lease=<branch>:"$tip" origin <branch>
```

Never fall back to a bare `--force`.

## Rewording Under a `commit-msg` Hook

`git history reword` bypasses hooks entirely, so a repo that enforces message format needs a
different route. Write an `amend!` commit — an ordinary commit, so hooks fire — and let autosquash
fold it in:

```bash
msg=$(mktemp -t commit-msg)
{
  echo "amend! $(git rev-parse <sha>)"
  echo
  cat <<'MSG'
New subject line

New body, written literally.
MSG
} > "$msg"
test -s "$msg" && ! LC_ALL=en_US.UTF-8 grep -n '.\{73,\}' "$msg" \
  && [ "$(git branch --show-current)" = <branch> ] \
  && GIT_EDITOR="cp $msg" git commit --allow-empty --fixup=reword:<sha> \
  && GIT_EDITOR=true git rebase --autosquash <sha>~1
```

A line the `grep` prints is over 72 characters, and a hook that rejects the `amend!` commit stops
the chain too, so the rebase never runs on a half-finished reword.

The `amend! <sha>` first line is what `--autosquash` matches on, so it must survive into the message
file — replace the body, never that line. Drop it and the stub is left behind as a stray empty
commit while the target keeps its original message. Name the target by full SHA, never by subject:
autosquash attaches an `amend!` that names a subject to the oldest commit carrying that subject, so
when two commits share one the reword silently lands on the wrong commit.

Two limits are worth knowing before relying on this. The hook validates `amend! <sha>` as the
subject rather than the new one, so a hook that checks subject *format* judges the marker line, and
one strict enough to reject `amend!` outright blocks this path entirely — there, reword with
`git history reword` and run the hook's check by hand. And `<sha>~1` does not resolve when `<sha>`
is the root commit; use `--root` in its place.

This route is also how to reword an older commit whose new message has a line starting with `#`,
which `git history reword` strips. Pass `--cleanup=whitespace` to the `git commit`, or its editor
step drops the line; the autosquash rebase then carries the message over as written.

## Commit Message Guidelines

Follow these commit message best practices:

### Subject Line (First Line)

- Limit to **72 characters** (not the traditional 50)
- Use the **imperative mood** ("Add feature" not "Added feature")
- **Capitalize** the first word
- **Do not** end with a period
- Summarize the "what" concisely

### Body (always include one for non-trivial changes)

- Wrap at **72 characters**, and check it rather than eyeballing it, on the file the message was
  written to: `LC_ALL=en_US.UTF-8 grep -n '.\{73,\}' <message file>` must print nothing. Not
  `awk 'length > 72'`: macOS `awk` counts bytes, so an em dash adds two to its count and a compliant
  line fails, and `grep` does the same outside a UTF-8 locale, which is why the locale is pinned.
  The Process commands below write, check and commit in one step.
- Explain the **"why"** behind the change, not just the "what"
- Always include a body with context — even for routine changes like dependency bumps. Only skip it
  for truly trivial changes (e.g. fixing a typo in a comment).
- Don't enumerate change counts ("Convert 6 legacy calls") — describe the nature of the change; the
  diff shows the specifics
- Use bullet points only for genuinely parallel items; otherwise prefer prose

#### Use problem → solution → user impact as a content guide, not as headers

For significant changes, let the **problem → solution → user impact** structure shape the
body's *content*:

1. **Problem**: What was the previous behavior and why was it insufficient?
1. **Solution**: What does this change do to address it?
1. **User Impact**: What will users experience differently?

Render this as flowing prose paragraphs; do **not** add explicit `Problem` / `Solution` /
`User Impact` section headers. Lead with the motivating situation, then the mechanism, then the
consequence, letting the order emerge from what a reader needs in sequence.

This helps future developers understand the intent behind the code — invaluable when debugging or
considering refactors months later.

### Examples of Good Subject Lines

- `Add user authentication to API endpoints`
- `Fix null pointer exception in payment processing`
- `Refactor database queries for better performance`
- `Update dependencies to address security vulnerabilities`

### Examples of Bad Subject Lines

- `fixed bug` (not capitalized, not descriptive)
- `Updated the code to make it work better.` (ends with period, vague)
- `I added some new features and also fixed a few bugs` (too long, not imperative)

### Issue Trailers

Many projects track no issues at all — skip this section entirely unless the repo already references
them. Check `git log` for the identifier format in use and match it rather than inventing one.

- For a bug-fix commit that should close its issue on merge, use the tracker's magic keyword:
  `Fixes <ISSUE-ID>.` (Linear and GitHub both also honor `Closes` / `Resolves`.)
- For a commit that is partial work toward an issue, use `Refs <ISSUE-ID>.` — it won't auto-close
  the issue.
- For a change related to an issue it does not implement, use `Related to <ISSUE-ID>`. Commit text
  reaches pull request bodies, and in Linear even `Refs` there still moves the issue's status.
- If unsure whether the commit fully resolves the issue, ask before defaulting to `Fixes`;
  over-using it prematurely closes the ticket on merge.
- On a branch of several commits for one issue, where the pull request lands its commits on the
  default branch as they are (rebase and merge, or a merge commit), each commit carries its own
  trailer: `Fixes` on the one that completes the issue, `Refs` on the rest.
- Never invent an issue ID to satisfy the format; omit the trailer instead.

### Subject Scope

- Describe the fix's *true scope*, not where it was first observed. Don't write "Fix staging
  deploys…" for a bug that exists on every environment running the affected code — drop the
  environment name unless it is load-bearing.

### Durable References Only

- Reference durable identifiers, not ephemeral ones. Cite a PR number ("PR #4139") rather than a
  branch name, and quote a CI error in prose rather than linking a time-limited CI or log URL that
  will 404 once it rotates.
- Refer to review findings as `F10`, never `#10`: GitHub autolinks a bare `#10` to whichever issue
  or pull request carries that number.

### No CI Markers

- Never write a bracketed skip-CI token (`skip ci`, `ci skip`, `no ci`, `skip actions` or
  `actions skip` inside square brackets) anywhere in a message, not even in backticks while
  describing it, and never end one with a `skip-checks` trailer. CircleCI and GitHub Actions match a
  token as a plain substring of the head commit's subject or body, so a message that only mentions
  the convention still suppresses the pipeline, and a branch whose required checks never report
  cannot merge. Write "a skip-CI marker" instead.

### Every Claim Is Cited Before It Lands

A commit message is a durable artifact, and confident claims (a size comparison, a compiler flag,
"every caller", a mechanism the code does not have) have landed in messages and been retracted only
when a reviewer checked. Before writing the body, list every mechanism, figure, precedent or status
the message asserts, and beside each the command you ran or the `file:line` you read that makes it
true; run or read it now if you have not. A claim that cannot be cited that way comes out of the
message, or is written as "unverified:". The list stays in the conversation, not in the message.

### Lockfiles

- When a commit first starts tracking a lockfile, fold its initial resolution into that commit and
  list no `old → new` versions; there is no earlier state to compare against.

### Squash Messages

- When squashing a branch into one commit, describe only the **end state** as it stands in the final
  diff. Skip the intra-branch journey ("refactored X to Y", "addresses findings F1–F34", "no longer
  fires twice") — those intermediate states aren't visible in the squashed result and only confuse a
  future reader.

## Process

If rewording an existing commit (no content changes):

1. Confirm the target commit's current message with `git log --format=%B -1 <sha>`
1. Draft the new message following the guidelines above
1. Write the new message, check its wrap and reword in one command, as in the `git history reword`
   block under Arguments — or, under a `commit-msg` hook or for a message with a `#` line, by the
   route Arguments names for that case
1. Verify with `git log --format=%B -1 <new-sha>` that the message landed correctly

Otherwise, for a new commit or amend:

1. Run `git status` to see all changed files
1. Run `git diff` to review the actual changes
1. Identify which changes were made during this Claude session (not pre-existing uncommitted
   changes)
1. Stage only the files that were modified during this session, naming each one explicitly:
   `git add <file> <file>`
1. If a file contains **both** session changes and pre-existing changes, stage only the relevant
   hunks — do **not** use `git add -p`, which needs a TTY. Write the file's diff to a patch of its
   own and note the path it prints, trim that patch to just the session's hunks, then apply it to
   the index alone:

   ```bash
   patch=$(mktemp -t staged-patch) && git diff -- <file> > "$patch" && echo "$patch"
   git apply --cached --recount <patch path>
   ```

   `--cached` leaves the working tree untouched, so a bad patch can only produce a wrong index (fix
   with `git reset`), never lost work. `--recount` lets Git recompute the `@@` line counts, so
   hand-trimmed hunks don't need exact headers. Verify with `git diff --cached` before committing.
1. If amending, read the original message with `git log -1 --format=%B` and review its changes
1. Draft a commit message following the guidelines above, with every claim cited (see Every Claim Is
   Cited Before It Lands)
1. Write the message to a file of its own, check its wrap and commit from it in one command:

   ```bash
   msg=$(mktemp -t commit-msg)
   cat > "$msg" <<'MSG'
   Subject line

   Body, written literally.
   MSG
   test -s "$msg" && ! LC_ALL=en_US.UTF-8 grep -n '.\{73,\}' "$msg" && git commit -F "$msg"
   ```

   Run it with the list indentation removed: the closing `MSG` must start its line. When amending,
   end the last line with
   `&& [ "$(git branch --show-current)" = <branch> ] && git commit --amend -F "$msg"` instead. A
   line the `grep` prints is over 72 characters, and the commit does not run: rewrap it and run the
   command again.

Never run a bare `git commit` or `git commit --amend`: with no `-m`/`-F` it opens `$EDITOR` and
hangs. Prefer `-F` over `-m` — messages following the guidelines above are multi-line and contain
backticks, which makes shell quoting fragile.

Never write a message or patch to a fixed path such as `/tmp/commit-msg.txt`. `/tmp` is shared by
every worktree and session, so a file another run left there is what a `-F`, a `GIT_EDITOR='cp …'`
or a `git apply` reads whenever this run's write failed or went to a different name, and
`git history reword` runs no hooks, so nothing inspects the result. `mktemp` gives each run a path
no other run can reach.

## Important Notes

- **Never** commit directly to the repository's default branch (`main` or `master`) after the
  repository's initial commit — always create a feature branch first. If you find yourself on the
  default branch with changes to commit, branch from HEAD before committing.
- **Never** stage files that were not modified during this session
- **Never** use `git add -A` or `git add .` — always add specific files
- **Never** commit sensitive files (`.env`, credentials, etc.)
- Use `git diff --cached` to verify staged changes before committing
- If uncertain which files were changed during this session, ask the user
