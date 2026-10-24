<!-- Claude Code project instructions for this repository. The user-wide instructions live in
     home/.claude/CLAUDE.md, which Homesick links into ~/.claude; this file is never linked -->

# Homesick

- Link with `yes n | homesick link dotfiles`, which declines every overwrite. Without a TTY, a
  bare `homesick link` reads end-of-file at each prompt as yes and so deletes and relinks every
  path in the way, real files included; `--force` does the same with or without a TTY. Neither
  can be aimed at one file. To replace one, move that file aside yourself, then run the `yes n`
  form, which links a missing path without prompting
- Expect `conflict … exists` for every path already present, correct links included; only new
  links print `symlink`. A real file shadowing a link is declined the same way and kept, so check
  a suspected shadow with `test -L`, and a suspected miss with `test -e`
- Symlinks point into the castle checkout's `home` directory, `~/.homesick/repos/dotfiles/home`. A
  dotfile that exists only on a branch is linked only while the castle checkout has that branch
  checked out; from another worktree it is never linked, and the output doesn't mention it. Once the
  castle checkout leaves the branch, its link dangles silently
- `~/.gitconfig`, the shell profiles and `~/.claude/settings.json` are symlinks into this
  repository, so a tool that rewrites its own config (`git config --global`, the PATH block the
  Claude Code installer adds to `.zshrc`, Claude Code's model picker) produces a diff in the castle
  checkout, not in a worktree. Before reverting a surprising diff, work out whether a tool wrote it;
  reverting one the tool will rewrite is wasted

# Homebrew

- I run every `brew` command other than a read-only query myself (for example `brew install`,
  `upgrade`, `uninstall`, `tap`/`untap`, `link`/`unlink`, `update`, `cleanup`, `autoremove`,
  `services`, `pin`/`unpin`, a bare `brew bundle` and the `brewup` alias). Edit the `Brewfile`,
  propose the exact commands and wait. Read-only queries (`brew info`, `brew list`, `brew doctor`,
  `brew bundle check`) are fine to run

# Pull Requests

- Open a pull request as a draft and leave marking it ready to `/ship-it`, which asks first because
  that notifies watchers and cannot be undone. Report it as waiting on `/ship-it`, never as ready to
  merge, until it is out of draft and its head carries the `ship-it` commit status
  (`gh pr view --json isDraft,headRefOid,statusCheckRollup`). `main`'s ruleset requires that status,
  and `/ship-it` withholds it while a review finding is open, so a run that left one open, or any
  push after the run, blocks the merge until `/ship-it` runs again
- CI skips draft pull requests, so a draft's `lint` check reports `SKIPPED` and has not run, though
  it satisfies the required check and `gh pr checks` exits 0 on it. Never report a draft as green.

# Shell Files

- Leave a long shell `alias` on one line. Its command string is one unit, so the 100-character
  limit doesn't apply, and a pre-existing long alias isn't a violation to fix

# Subagents

- Dispatch agents into this checkout, not an isolated worktree. `worktree.baseRef` is `fresh`, so
  an isolated worktree branches from `origin/main`: its agent reads `main`, not the branch under
  review, and its edits land in the worktree rather than the project root. In this checkout:
  - Run read-only agents as needed
  - Run an agent whose only file changes are Edit and Write tool calls one at a time. Never
    dispatch two such agents at once: each would read the other's half-finished changes, and
    committing one agent's work would sweep up the other's
  - `/doc-review`'s collator and recording agents, which write only the review file, run here too,
    each under the rules `/doc-review` gives it
- Use an isolated worktree only for an agent that must run a command that writes, such as a test
  run, a build or a git operation. Its worktree starts at `origin/main`, so its prompt must first
  check out the commit under review (`git checkout --detach <sha>`, with the SHA resolved by the
  dispatching session), or it tests `main` instead of the change
- In any session, exercise the git aliases that delete branches (`git cleanup`, `git bclean`,
  `git bdone`, `git pc`) only in disposable repositories under the scratchpad. `git bdone` and
  `git pc` pull before pruning, so `git init` a second disposable repository, create the test
  branches in it and `git clone` the test repository from it: a branch checked out from `origin`
  tracks it, while one created in the clone has no upstream and its pull fails
