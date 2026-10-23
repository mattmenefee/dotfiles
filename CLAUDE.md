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
- Symlinks point into the castle checkout, `~/.homesick/repos/dotfiles/home`. A dotfile that
  exists only on a branch is linked only while the castle checkout has that branch checked out;
  from another worktree it is never linked, and the output doesn't mention it. Once the castle
  checkout leaves the branch, its link dangles silently
- `~/.gitconfig`, the shell profiles and `~/.claude/settings.json` are symlinks into this
  repository, so a tool that rewrites its own config (`git config --global`, Docker Desktop's PATH
  block, Claude Code's model picker) produces a diff in the castle checkout, not in a worktree.
  Before reverting a surprising diff, work out whether a tool wrote it; reverting one the tool will
  rewrite is wasted

# Homebrew

- I run Homebrew mutations myself (`brew install`, `upgrade`, `uninstall`, `untap`, `unlink`, a
  bare `brew bundle` and the `brewup` alias). Edit the `Brewfile`, propose the exact commands and
  wait. Read-only queries (`brew info`, `brew list`, `brew doctor`, `brew bundle check`) are fine
  to run

# Shell Files

- Leave a long shell `alias` on one line. Its command string is one unit, so the 100-character
  limit doesn't apply, and a pre-existing long alias isn't a violation to fix

# Subagents

- Run agents that only read, such as `/doc-review`'s reviewer, in this checkout under its
  Reviewing Without Editing rules, not in an isolated worktree: `worktree.baseRef` is `fresh`, so
  an isolated worktree branches from `origin/main` and its agent reads `main`, not the branch under
  review. Use a worktree only for an agent that must run something that writes, and exercise the
  destructive git aliases (`git cleanup`, `git bclean`, `git bdone`, `git pc`) only in disposable
  `git init` repositories under the scratchpad; `git bdone` and `git pc` pull first, so give them a
  second disposable repository as `origin`
