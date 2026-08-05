<!-- Claude Code project instructions for dotfiles and related projects -->

# Workflow

- When creating Pull Requests or Linear issues, assign them to me by default

## Linear Issues

When creating Linear issues, write descriptions for a non-technical audience:
- Focus on user benefits, not implementation details
- Use familiar references (e.g., "similar to Slack") to ground changes
- Include a "Why This Matters" section connecting the change to business value
- Avoid code-level details like file names, CSS values, or internal refactors
- Describe accessibility improvements in plain language (e.g., "easier to tap" not "WCAG 2.5.8")

## Pull Requests

- Use descriptive titles that summarize the overall change
- Include a Summary section with bullet points
- Include a Test plan section with checkboxes
- Reference related Linear issues if applicable
- When posting review findings (local review, doc review, etc.) as a PR comment, wrap the full
  content in a `<details><summary>` block so only a summary line is visible by default:
  ```markdown
  ## [Review Type] — [status summary]

  **[brief stats line]**

  <details>
  <summary>Click to expand full review details</summary>

  [full review content here]

  </details>
  ```

## Committing Changes

- Always use the `/commit` slash command when writing or editing a commit message — this includes
  creating new commits, amending commits, and editing commit messages
- Consider using the `/doc-review` slash command after writing or updating a significant amount of
  documentation

## Task Completion Checklist

After completing any coding task, run these commands in order:

1. **Code Quality**: Run only the relevant linters for your changes (e.g. `bin/rubocop -A` for Ruby
   files, `bin/rails lint:haml` for Haml, etc.) — never run `bin/rails lint`
2. **Testing**: Run only the specs relevant to your changes — never the entire suite

# Code Style

- Follow Sandi Metz's rules from "Practical Object-Oriented Design in Ruby"
- Follow the [Ruby Style Guide](https://rubystyle.guide/) and the
  [Rails Style Guide](https://rails.rubystyle.guide/)
- Always leave a blank line at the end of a file
- Wrap at 100 characters where it makes sense — source code, comments, Markdown prose, slash command
  and agent files, and configuration. Defer to a project's own linter or `.editorconfig` when it
  sets a different limit
- Do not wrap where the line break would be wrong rather than merely long: PR and issue descriptions
  (GitHub and Linear both reflow them), long URLs, Markdown tables, and strings or identifiers that
  cannot be split

# Writing & Copy Conventions

- Use American English spelling everywhere — code, comments, commit messages, PR descriptions, issue
  descriptions and user-facing copy. Write "behavior" not "behaviour", "favor" not "favour", "color"
  not "colour", "organize" not "organise".
- Generally prefer spelling terms out over abbreviating, though it can depend on the context — for
  example, write "DigitalOcean" rather than "DO"

# Testing

- When writing tests:
  - Do not stub the subject
  - Use verified doubles
  - Use a maximum example group nesting of 4 levels
  - Use `Time.zone.today` instead of `Date.current`
  - Use single-line `let` and `before` blocks when they fit within the Code Style line length
  - Generally prefer fewer lines — avoid multi-line blocks for simple expressions

# Shell Commands

- No TTY is available, so any command that opens an editor or waits for input will hang — supply
  input via flags instead (`git commit -F <file>`, `gh pr create --title --body`). Common offenders:
  bare `git commit`, `git commit --squash`, `git add -i`/`-p`, `docker`/`kubectl -it`, REPLs
  (`psql`, `rails console`), and `yarn upgrade-interactive`.
- `-i` is not itself the hazard: `git rebase -i` runs fine when its editors are neutralized
  (`GIT_SEQUENCE_EDITOR=true`), which some commands prescribe
- When writing slash commands, agent files, or docs that prescribe shell commands, prescribe the
  non-interactive form — a command file that says to run an editor-opening command will be followed

# Git Worktrees

Subagents have Edit and Write access, and several of them often run against the same checkout at
once — every reviewer in `/local-review`, for instance. An agent that edits files to test an
assertion corrupts what its siblings are reading, and leaves changes in the working tree that
nobody asked for. Worktrees are how that work gets isolated.

## Isolating Subagents

- Spawn any subagent that reviews, tests, or otherwise exercises code with `isolation: "worktree"`.
  The harness gives it a throwaway checkout under `.claude/worktrees/agent-<id>/`, locks it while
  the agent runs, and removes it afterward when nothing changed. Prose constraints in a prompt are
  advisory; a worktree is structural
- An agent that discovers mid-task that it needs to modify code uses the `EnterWorktree` tool
  rather than `git worktree add`, so the harness tracks and cleans up the result. `ExitWorktree`
  with `action: "remove"` tears it down
- Do not put `isolation: worktree` in an agent's frontmatter. These agents are also invoked
  directly to do real work, and frontmatter isolation would silently divert that work into a
  worktree that later gets swept
- `worktree.baseRef` is `head` in `~/.claude/settings.json` so an isolated agent branches from the
  current `HEAD`. The default, `fresh`, branches from `origin/<default branch>` — a reviewer would
  analyze the wrong code and never notice
- Uncommitted changes do **not** follow an agent into its worktree, because `head` resolves to the
  last commit. When the work under review is uncommitted, either commit it first or capture
  `git diff HEAD` and pass it in the delegation prompt

## Bootstrapping a Worktree

A worktree is a fresh checkout: no `node_modules`, no `tmp/`, and none of the gitignored
configuration an application needs to boot. A `.worktreeinclude` file at the project root lists the
gitignored files to copy in — `.gitignore` syntax, and only files that both match a pattern and are
gitignored are copied. Anything else (`bundle install`, `yarn install`, `bin/rails db:test:prepare`)
the agent runs itself, inside the worktree.

If a worktree still cannot be made to run, report the finding as unverified. Never fall back to
running in the shared checkout — that failure path is exactly how an isolated agent ends up
modifying the real working tree.

## What a Worktree Does Not Isolate

A worktree has its own files and index. Everything else is shared with the real repository:

- **Refs and objects** — `git branch -D`, `git stash`, `git tag`, and `git reflog expire` all write
  to the one shared `.git` directory. The `git cleanup` / `bclean` / `bdone` aliases in
  `~/.gitconfig` delete real branches when run from inside a worktree. Exercise destructive git
  tooling against disposable `git init` repositories under the scratchpad, never a worktree
- **Databases and services** — the same PostgreSQL server, Redis instance, and Elasticsearch
  cluster. Two agents running the suite will truncate each other's test database unless each points
  at its own; see the project's own instructions for how
- **Ports** — only one agent can bind a given port, so only one can run a server or a system spec

## Cleaning Up

Leave the shared checkout exactly as you found it: `git status --porcelain` in the main working
tree must return what it returned before you started. Remove a worktree you created manually with
`git worktree remove <path>`, adding `--force` when it holds uncommitted files, and follow up with
`git worktree prune`. Scratch files belong in the session scratchpad, not in the repository.

# Serena MCP Server

- Serena must be activated at the start of each session before its tools can be used
- Activation steps:
  1. Load the tool: `ToolSearch` with query `select:mcp__serena__activate_project`
  2. Activate the project: `mcp__serena__activate_project` with the current project path
- Serena has project memories that can be read with `read_memory` when relevant
- Do NOT attempt to call any `mcp__serena__*` tool without first loading it via `ToolSearch`
