<!-- User-wide Claude Code instructions, linked into ~/.claude and read in every project. Rules
     for the dotfiles repository alone go in its root CLAUDE.md. -->

# Workflow

- When creating pull requests or Linear issues, assign them to me by default
- Never add AI attribution to anything pushed to a repository: no `Co-Authored-By` trailers, no
  `Claude-Session` lines and no "Generated with" footers or session links in pull request or issue
  descriptions. Commits are authored by me alone.
- Route every change after a repository's initial commit through a branch and pull request, even in
  a new or solo repository
- Never merge a pull request unless I have asked you to merge that specific pull request in this
  conversation. Otherwise stop at "ready to merge" and report CI for the head commit. An approval
  never carries over to another pull request, a later push or a later session.
- After a push or merge mishap, recommend a server-side guardrail (a GitHub ruleset or branch
  protection) over client-side git configuration, and leave existing local configuration alone
- Never add review or working documents (`*local-review*.md`, `*-DOC-REVIEW*.md`, `*PLAN.md`,
  `*-HANDOFF.md`) to `.gitignore`. Commit one only where the project's `/ship-it` expects it;
  otherwise leave it untracked.
- Before changing an open-source project, read its `CONTRIBUTING.md` (or `.github/CONTRIBUTING.md`)
  and follow its conventions exactly. Add a changelog entry only for a change the library's users
  would notice, not for CI or tooling.
- Close an issue only when nothing actionable is left. If a concrete step remains, retitle the issue
  around that step and link its blocker in both directions.
- In chat replies, when naming a file I will open or run, give its full absolute path every time.
  Never shorten it to "in the scratchpad" or a `.../` prefix. Published text and working documents
  use repository-relative or `~` paths instead (see Public Repositories).
- In chat replies, write the first mention of a pull request or issue as a Markdown link with its
  identifier as the link text
- When walking me through findings or decisions one at a time, ask for each ruling with
  `AskUserQuestion` when its options fit the tool. Put the explanation and any recommendation in
  your reply before the question, put a recommended option first, labeled "(Recommended)", and end
  with an option that leaves the item undecided.
- Wrap text meant for me to paste into another session in a `text` fence whose first and last lines
  are the markers, with no commentary inside them:

  ````markdown
  ```text
  ===== PASTE TO <session> — BEGIN =====
  The text to paste
  ===== PASTE — END =====
  ```
  ````

- Run `/handoff` on your own initiative when it fits: after a substantial round of work, before a
  likely context break or when a review round closes. A command that changes or publishes shared
  state, such as a project's `/ship-it`, runs only when I start it.
- Put rules meant for an agent where agents read them: CLAUDE.md, a command or an agent file. Never
  put them in a `.gitignore`, a dotfile or a configuration comment. A comment warning any reader, as
  Code Style allows, is not such a rule; an instruction addressed to an agent is.
- Don't run linters on memory files under `~/.claude/projects/*/memory/`, and ignore hook lint
  errors reported on them.

## Verifying Claims

- Before relaying a fact learned from another session, a subagent or an earlier message, re-check it
  against the live source (git, gh, the file). If you cannot, attribute and date it rather than
  asserting it.
- Before saying a rule or section no longer exists, grep the whole tree for the concept, not just
  the text you removed
- For what a library does, run it or read the whole enclosing construct, not a `sed -n` window
- For "find every X", count with `wc -l` or list with `grep -l`; never truncate the search with
  `head`

## Linear Issues

When creating Linear issues, write descriptions for a non-technical audience:

- Focus on user benefits, not implementation details
- Use familiar references (e.g. "similar to Slack") to ground changes
- Include a "Why This Matters" section connecting the change to business value
- Avoid code-level details like file names, CSS values or internal refactors
- Describe accessibility improvements in plain language (e.g. "easier to tap" not "WCAG 2.5.8")

When filing or linking Linear issues:

- Before filing an issue, search Linear with two or three keyword queries. Comment on or attach to a
  match, and check its linked pull request, instead of filing a duplicate.
- A Linear issue identifier in a pull request body moves that issue through the team's pull request
  workflow statuses (by default In Progress when the pull request opens), even after `Refs`,
  `part of` or `toward`; those only skip the merge-to-Done step. For an issue the pull request does
  not implement, write `Related to <ID>`, which links it with no status change. This covers commit
  trailers wherever they reach the pull request body, as `gh pr create --fill` copies a single
  commit's. Attaching a pull request from inside Linear has been seen to move the issue too.
- Link every mention of a Linear issue identifier to the issue, in chat replies and in any document
  written for people (briefings, plans, handoffs, pull request bodies), not only the first. In a
  Markdown document, use a reference-style link (`[ENG-412][eng-412]`, with the definitions at the
  end) so lines stay within the column limit. In a public repository, write the identifier without
  its URL: the URL's workspace slug names the client (see Public Repositories).

## Pull Requests

- Use descriptive titles that summarize the overall change
- Make a pull request a meaningful, coherent changeset; split it further only when the diff is too
  large to review. Ship docs and changelog entries with the behavior they describe.
- When the branch name, its pull request description or the issue it implements says a class of
  issues will be handled on a later, dedicated branch, keep the change minimal. Fix what is in scope
  properly. For an adjacent issue the later branch will handle, add only the smallest stopgap (e.g.
  skipping a test whose failure belongs to the deferred work) and name the deferred work in the
  commit or pull request. Ask before any refactor the scope does not call for.
- Include a Summary section with bullet points
- Include a Test plan section with checkboxes. Tick `- [x]` each item you ran and saw pass, noting
  the evidence inline when the method matters, and leave open only what you did not run. A review
  file's checklist is different: tick a fix you made and verified, but leave a box that needs my
  ruling (Defer, Ignore or a decision) open until I make it.
- Reference related Linear issues if applicable
- GitHub autolinks a bare `#N` to this repository's issue or pull request. Write `owner/repo#N` for
  another repository, and a full URL for a Dependabot or code-scanning alert, never `#N`.
- In a clone with more than one remote, an `upstream` especially, pass `--repo OWNER/NAME` to every
  `gh` command. Otherwise `gh` may resolve to the parent repository and fail, or silently act on the
  wrong pull request.
- Confirm CI with `gh pr view --json headRefOid,statusCheckRollup` and name the commit it ran on. A
  CircleCI run canceled on purpose reports as a failed status, so `gh pr checks` shows it as
  "fail"; a run far shorter than usual is a cancellation. Before calling a branch green or merging
  it, check that `git ls-remote origin refs/heads/<branch>` equals local `HEAD` and the rollup's
  commit.
- `gh pr merge --delete-branch` deletes the local branch as well as the remote one, so when run from
  the pull request's own checkout it first switches that checkout to the default branch. Run it
  with `--repo` from another directory, and check `git reflog` before describing local state
  afterwards.
- Post a review file to a pull request, issue or release only once every actionable finding in it is
  ✅, ⏸️ or 🚫, with no ❓ row and no open box; a working list goes stale within hours and reads as
  the record. A handoff's still-open questions are the exception `/ship-it` posts by design.
- When posting review findings (local review, doc review, etc.) as a pull request comment, wrap the
  full content in a `<details><summary>` block so only a summary line is visible by default. Name
  the review file in the heading so a later post can find and update the comment:

  ```markdown
  ## [Review Type] (`[review file's base name]`) — [status summary]

  **[brief stats line]**

  <details>
  <summary>Click to expand full review details</summary>

  [full review content here]

  </details>
  ```

## Committing Changes

- Always use the `/commit` slash command when writing or editing a commit message — this includes
  creating new commits, amending commits and editing commit messages
- Consider using the `/doc-review` slash command after writing or updating a significant amount of
  documentation

## Task Completion Checklist

After completing any coding task, run these commands in order:

1. **Code Quality**: Run only the relevant linters for your changes (e.g. `bin/rubocop -A` for Ruby
   files, `bin/rails lint:haml` for Haml, etc.) — never run `bin/rails lint`
2. **Testing**: Run only the specs relevant to your changes — never the entire suite

# Public Repositories

Some of my repositories are public, including dotfiles. In anything published to one (tracked files,
commit messages, pull request and issue text, comments), name no private repository, client project,
production host or home directory path, and link to none of them; write "another project" instead.
Check `gh repo view <slug> --json visibility` before writing a cross-repository reference. Commit
messages are the strictest case: once merged they cannot be edited.

- The dotfiles repository publishes every file under its `home` directory through symlinks, among
  them `~/.zshrc`, `~/.gitconfig`, `~/.config/gh/config.yml`, everything in `~/.zsh/` and
  `~/.claude/` files such as `CLAUDE.md`, `settings.json` and the commands. Treat a file whose
  `realpath` lies under `~/.homesick/repos/dotfiles/home` as published. Keep secrets in the macOS
  Keychain, `~/.claude.json` or an untracked file, never in a tracked dotfile.
- Name no private individual (a colleague, a client, me) in checked-in guidance such as CLAUDE.md,
  commands or agent files; state conventions generically

# Code Style

- Follow Sandi Metz's rules from "Practical Object-Oriented Design in Ruby"
- Follow the [Ruby Style Guide](https://rubystyle.guide/) and the
  [Rails Style Guide](https://rails.rubystyle.guide/)
- End every file with a single trailing newline (not a literal blank line)
- Wrap at 100 characters where it makes sense — source code and comments, Markdown prose
  (including slash command and agent files) and configuration. Defer to a project's own linter or
  `.editorconfig` when it sets a different limit.
- When an edit changes a line of wrapped prose or comment, refill the paragraph or comment block it
  belongs to so every line again takes as many words as fit within the limit. Change only line
  breaks, and leave blocks the edit did not touch as they are. `/reflow` does this for every block a
  branch changed.
- Do not wrap where the line break would be wrong rather than merely long: pull request and issue
  descriptions and comments (GitHub renders each line break in them, so a hard wrap shows as ragged
  lines); Markdown written to be pasted into Teams or Slack; review, plan, handoff and other working
  documents; long URLs; Markdown tables; and any string or identifier that cannot be split
- A comment that is a single phrase or sentence takes no final period; comments of several sentences
  punctuate normally. A docstring whose linter requires the period is exempt.
- A comment states why the code is as it is now. Leave out issue and pull request numbers, notes
  about what was removed or what to clean up later, before/after history and figures that drift
  (sizes, counts); cite the command that re-measures a drifting fact instead. Add an unrequested
  comment only when a reader could otherwise make a real mistake; decision history belongs in the
  commit message or pull request.
- Keep a framework, gem or configuration default unless a current bug, constraint or measured need
  justifies changing it. Speculative future-proofing does not count; pinning a default against
  upgrade drift is fine.

# Writing & Copy Conventions

- Use American English spelling everywhere — code, comments, commit messages, pull request
  descriptions, issue descriptions and user-facing copy. Write "behavior" not "behaviour", "favor"
  not "favour", "color" not "colour", "organize" not "organise".
- Generally prefer spelling terms out over abbreviating, though it can depend on the context — for
  example, write "DigitalOcean" rather than "DO"
- Write lists without the serial comma: "a, b and c". When editing a file that mixes styles, remove
  the serial comma; if dropping one makes a sentence ambiguous, restructure the sentence instead.
- A list item that is a single phrase or sentence takes no final period. An item of several
  sentences ends each of them with a period, the last one included: the single-sentence rule does
  not reach it, here or for comments under Code Style.
- Write `e.g.` and `i.e.` with no following comma
- In prose, write "changelog" in lowercase. Write `CHANGELOG.md` only when naming the file, and keep
  a proper name such as "Keep a Changelog" capitalized.
- Write dates month-first ("October 4 to October 21"), never day-first ("4 to 21 October"), in
  prose, team messages, issues and release notes. ISO dates (2026-10-24) stay as they are where a
  document uses them.
- Write a Teams message as a finished artifact: summary first, then decisions, then reference. Save
  it to a file and deliver it with `teams-copy <file>`, which copies it as rich text, rather than as
  terminal text. Don't hard-wrap it, and use only the Markdown `teams-copy` supports (see
  `teams-copy --help`).

# Testing (RSpec)

- When writing tests:
  - Do not stub the subject
  - Use verified doubles
  - Use a maximum example group nesting of 4 levels
  - Use `Time.zone.today` instead of `Date.current`
  - Use single-line `let` and `before` blocks when they fit within the Code Style line length
  - Generally prefer fewer lines — avoid multi-line blocks for simple expressions
  - Keep each `expect` on one line: bind the subject to a local on the line above. When the length
    is in the matcher chain, split it into two expectations under `:aggregate_failures`.
  - Write Capybara scoping as `within '.selector' do … end`, never with braces or a parenthesized
    selector, even when it would fit on one line
- When a change breaks an existing test, check what its assertion actually verifies before adding
  stubs; the example's name may be a misnomer. Trim the assertion to the code's real contract and
  rename the example.
- When a VCR cassette or fixture is out of date, re-record or fix it rather than adding a fallback
  code path to keep it passing

# Shell Commands

- No TTY is available, so any command that opens an editor or waits for input will hang — supply
  input via flags instead (`git commit -F <file>`, `gh pr create --title --body`). Common offenders:
  bare `git commit`, `git commit --squash`, `git add -i`/`-p`, `docker run -it`/`kubectl exec -it`,
  REPLs (`psql`, `rails console`) and `yarn upgrade-interactive`.
- `-i` is not itself the hazard: `git rebase -i` runs fine when its editors are neutralized
  (`GIT_SEQUENCE_EDITOR=true`), which some commands prescribe
- When writing slash commands, agent files or docs that prescribe shell commands, prescribe the
  non-interactive form. Claude follows a command file literally, so an editor-opening command in one
  will hang.
- Never put `$` followed by a digit (`$0`, `$1`, `$2`) in a slash command or skill file. Claude Code
  replaces each one with a word of the invocation's arguments, even inside fenced blocks and quoted
  `awk`. Write awk fields as `$(0)` and `$(2)`, pass shell function arguments through `"$@"` or a
  variable set before the call, or move the logic into a script run by path.
- In Claude Code's Bash tool, `find` is bfs, which rejects a relative `-newermt` time ("-1 hour")
  with an error and exit 1, unlike `/usr/bin/find`. Pass an absolute timestamp, and never conclude a
  negative from empty output when stderr is hidden or the command sits in a pipeline.
- Never wait on `pgrep -f '<pattern>'` in a loop: any other process with the pattern in its command
  line, a second wait loop included, keeps the loop spinning. Wait on a PID captured at spawn, or
  use `pgrep -x` or a full path, and kill by PID, never `pkill -f`.
- When temporarily changing a file, back it up under its full path mirrored in the scratchpad, never
  by basename alone, so two files with the same name cannot collide

## zsh

The shell is zsh, not bash, and each of these has broken commands before:

- Brace a variable before a colon (`"${sha}:path"`). Unbraced, any letter after the colon is a
  modifier that silently changes the value: `:h`, `:t`, `:r` and `:e` cut the path, and `:a` makes
  it absolute, so `$t:app/x` becomes a path under the current directory.
- An unmatched glob aborts its command with `no matches found` before it runs, and `2>/dev/null`
  does not hide it. Quote a literal pattern, or match files with `find`.
- A word starting with `=` is replaced by the path of the command it names, so `echo ====` fails
  with `=== not found` and abandons the rest of the line. Quote separators: `echo '===='`.
- An unquoted `$var` is not split into words, so `cmd $files` passes every name as one argument. Use
  an array (`files=(a b); cmd "${files[@]}"`) or name each argument; a tool given one bogus argument
  may print its usage and still exit 0.
- `PIPESTATUS` does not exist; zsh's array is `pipestatus`, indexed from 1 (`${pipestatus[1]}`)
- An unquoted `~word` is a user or named-directory lookup that abandons the line when nothing
  matches; quote it
- Don't name a shell function after an alias: `g` and `r` are aliases in my shell, so `g() { … }`
  fails to parse. Pick another name.
- `status` is a read-only variable; use another name, such as `rc`

## Git

- Assume the latest Git. Prefer readable modern porcelain (`git branch --show-current`) over
  plumbing kept only for old-version portability (`git symbolic-ref --short HEAD`). Use plumbing
  where it earns its place, such as a stable output contract in a checked-in script.
- Use hyphens, not slashes, in branch names: `fix-login-redirect`, not `fix/login-redirect`
- When a local branch has diverged from its remote, inspect it with
  `git log --left-right <branch>...origin/<branch>` and ask before any `reset --hard`. The
  divergence may be a deliberate rebase.
- Several sessions can share one checkout, so re-check the current branch in the same command as an
  amend, reset, rebase or force-push
- `rebase.autosquash` is on in my git config, so an interactive rebase, including one run with
  `GIT_SEQUENCE_EDITOR=true`, silently folds `fixup!`, `amend!` and `squash!` commits. Pass
  `--no-autosquash` when the branch carries fixups meant to stay separate. The setting does not
  reach a rebase without `-i`.
- A bare `git push` is safe, even on a new branch: `push.default = current` and
  `push.autoSetupRemote = true` in my git config push to a same-named branch on origin and set it as
  upstream. Don't warn that it will push to `main`.
- Take any SHA passed to a pinning flag (`--match-head-commit`, `--force-with-lease=<ref>:<sha>`)
  from `git rev-parse`, `git ls-remote` or `gh … headRefOid` in the same command; never complete one
  from memory
- Find a git state path with `git rev-parse --git-path rebase-merge` (or `MERGE_HEAD`); a literal
  `.git/…` path is wrong in a linked worktree

# Serena MCP Server

- Serena must be activated at the start of each session before its tools can be used
- Activation steps:
  1. Load the tool: `ToolSearch` with query `select:mcp__serena__activate_project`
  2. Activate the project: `mcp__serena__activate_project` with the current project path
- Serena has project memories that can be read with `mcp__serena__read_memory` when relevant
- Do NOT attempt to call any `mcp__serena__*` tool without first loading it via `ToolSearch`
