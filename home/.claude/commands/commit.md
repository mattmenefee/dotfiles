# Commit Changes

Create a git commit for the changes made during this session.

## Arguments

If `$ARGUMENTS` contains `reword <sha>` (or `reword` followed by a commit
identifier):

- Rewrite **only the commit message** of the specified commit, leaving its
  content unchanged
- Use `git history reword <sha>` (Git's experimental but linear-history-safe
  command), which automatically updates descendant commits to point at the
  rewritten commit
- To pass the new message non-interactively, point `GIT_EDITOR` at a script
  that overwrites the message file Git provides:

  ```bash
  printf '%s\n' "$NEW_MESSAGE" > /tmp/new-msg.txt
  GIT_EDITOR='cp /tmp/new-msg.txt' git history reword <sha>
  ```

- `git history` is marked **EXPERIMENTAL** and has three caveats: (1) it does
  **not** run git hooks, so it skips `commit-msg` validation — see "Rewording
  under a commit-msg hook" below if the project relies on one; (2) it fails on
  merge commits and on histories with conflicts, so the branch must be linear
  from the target commit forward; (3) it only edits a single commit's message —
  for collapsing or reordering commits, see "Reshaping History" below.
- After rewording, confirm with `git log --format=%B -1 <new-sha>` that the
  message is correct.

If `$ARGUMENTS` contains `amend` or `--amend`:

- Amend the changes to the most recent commit
- Update the commit message to describe ALL changes in the amended commit (both
  original and newly added changes)
- Use `git log -1 --format=%B` to get the original commit message for context

If `$ARGUMENTS` names a commit that is **not** HEAD (e.g. `amend <sha>`):

- `git commit --amend` only ever touches HEAD, so folding content into an
  earlier commit needs the squashing workflow under "Reshaping History" below
- Use that workflow for **content** changes (or content + message together);
  use `git history reword <sha>` for **message-only** edits, since it avoids a
  rebase entirely

Otherwise:

- Create a new commit with only the changes made during this session

## Reshaping History

This environment has no TTY, so any command that opens an editor or waits for
input will hang or fail. `git add -i` and `git add -p` have no way around this;
`git rebase -i` works only when its editors are neutralized, as in the fallback
below — use these instead:

- **Squashing content into an existing commit** — including amending a commit
  that isn't HEAD — is mechanical and safe to do unattended. Stage the change,
  then fold it into the target in one step:

  ```bash
  git add <file>
  git history fixup <sha>
  ```

  This keeps the target's message, leaves unstaged changes alone, works even
  when `<sha>` is the root commit, and refuses cleanly (`fixup would produce
  conflicts; aborting`) instead of dropping you into a half-finished rebase.
  It needs Git 2.55+, is EXPERIMENTAL, and — like `git history reword` — does
  **not** run hooks. Like any history rewrite it changes the SHA of the target
  and of every commit after it, so an already-pushed branch then needs
  `git push --force-with-lease`.

  Fall back to fixup+autosquash on older Git, or whenever a `pre-commit` or
  `commit-msg` hook must run, since `git commit --fixup` is an ordinary commit
  and fires hooks normally:

  ```bash
  git commit --fixup <sha>
  git rebase --autosquash <sha>~1
  ```

  A bare `--autosquash` requires Git 2.44+; older versions accept the flag and
  silently ignore it, leaving the `fixup!` commit unmerged, so on those
  neutralize the todo editor instead:
  `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <sha>~1`. When `<sha>`
  is the root commit, `<sha>~1` does not resolve — use `--root` in place of it.

  `--squash` is interactive by design: it opens an editor when creating the
  commit and again when the rebase combines the messages. When both messages
  matter, use a fixup and reword the result with `/commit reword <sha>`.

- **Reordering, dropping, or splitting commits** is a judgment call about what
  the history should say. **Stop and hand it back to the user** rather than
  reconstructing it — explain what reshaping is needed and let them drive the
  rebase themselves.

## Rewording Under a `commit-msg` Hook

`git history reword` bypasses hooks entirely, so a repo that enforces message
format needs a different route. Write an `amend!` commit — an ordinary commit,
so hooks fire — and let autosquash fold it in:

```bash
printf 'amend! %s\n\n%s\n' "$(git log --format=%s -1 <sha>)" "$NEW_MESSAGE" \
  > /tmp/new-msg.txt
GIT_EDITOR='cp /tmp/new-msg.txt' git commit --allow-empty --fixup=reword:<sha>
GIT_EDITOR=true git rebase --autosquash <sha>~1
```

The `amend! <old subject>` first line is what `--autosquash` matches on, so it
must survive into the message file — replace the body, never that line. Drop it
and the stub is left behind as a stray empty commit while the target keeps its
original message.

Two limits are worth knowing before relying on this. The hook validates
`amend! <old subject>` as the subject rather than the new one, so a hook that
checks subject *format* judges the marker line, and one strict enough to reject
`amend!` outright blocks this path entirely — there, reword with
`git history reword` and run the hook's check by hand. And `<sha>~1` does not
resolve when `<sha>` is the root commit; use `--root` in its place.

## Commit Message Guidelines

Follow these commit message best practices:

### Subject Line (First Line)

- Limit to **72 characters** (not the traditional 50)
- Use the **imperative mood** ("Add feature" not "Added feature")
- **Capitalize** the first word
- **Do not** end with a period
- Summarize the "what" concisely

### Body (Optional, separated by blank line)

- Wrap at **72 characters**
- Explain the **"why"** behind the change, not just the "what"
- Use bullet points where appropriate (hyphen or asterisk)
- Include any relevant context or background
- Reference related issues if applicable

#### Recommended Structure for Non-Trivial Changes

For significant changes, follow the **problem → solution → user impact** structure:

1. **Problem**: What was the previous behavior and why was it insufficient?
1. **Solution**: What does this change do to address it?
1. **User Impact**: What will users experience differently? (bullet points work well)

This helps future developers understand the intent behind the code—invaluable when
debugging or considering refactors months later.

### Examples of Good Subject Lines

- `Add user authentication to API endpoints`
- `Fix null pointer exception in payment processing`
- `Refactor database queries for better performance`
- `Update dependencies to address security vulnerabilities`

### Examples of Bad Subject Lines

- `fixed bug` (not capitalized, not descriptive)
- `Updated the code to make it work better.` (ends with period, vague)
- `I added some new features and also fixed a few bugs` (too long, not imperative)

## Process

If rewording an existing commit (no content changes):

1. Confirm the target commit's current message with `git log --format=%B -1 <sha>`
1. Draft the new message following the guidelines above
1. Write the new message to a temp file (e.g. `/tmp/new-msg.txt`) and run
   `GIT_EDITOR='cp /tmp/new-msg.txt' git history reword <sha>`
1. Verify with `git log --format=%B -1 <new-sha>` that the message landed correctly

Otherwise, for a new commit or amend:

1. Run `git status` to see all changed files
1. Run `git diff` to review the actual changes
1. Identify which changes were made during this Claude session (not pre-existing
   uncommitted changes)
1. Stage only the files that were modified during this session, naming each one
   explicitly: `git add <file> <file>`
1. If a file contains **both** session changes and pre-existing changes, stage
   only the relevant hunks — do **not** use `git add -p`, which needs a TTY.
   Write the wanted hunks to a patch and apply them to the index alone:

   ```bash
   git diff -- <file> > /tmp/staged.patch   # trim to just the session's hunks
   git apply --cached --recount /tmp/staged.patch
   ```

   `--cached` leaves the working tree untouched, so a bad patch can only
   produce a wrong index (fix with `git reset`), never lost work. `--recount`
   lets Git recompute the `@@` line counts, so hand-trimmed hunks don't need
   exact headers. Verify with `git diff --cached` before committing.
1. Write a commit message following the guidelines above
1. If amending:
   - Review the original commit message and changes
   - Stage the new changes
   - Write the updated message to a temp file and run
     `git commit --amend -F /tmp/commit-msg.txt`
1. If creating a new commit:
   - Write the message to a temp file and run
     `git commit -F /tmp/commit-msg.txt`

Never run a bare `git commit` or `git commit --amend`: with no `-m`/`-F` it
opens `$EDITOR` and hangs. Prefer `-F` over `-m` — messages following the
guidelines above are multi-line and contain backticks, which makes shell
quoting fragile.

## Important Notes

- **Never** stage files that were not modified during this session
- **Never** use `git add -A` or `git add .` — always add specific files
- **Never** commit sensitive files (`.env`, credentials, etc.)
- Use `git diff --cached` to verify staged changes before committing
- If uncertain which files were changed during this session, ask the user
