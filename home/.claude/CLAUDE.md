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
  - Do not exceed 100 character line length
  - Use a maximum example group nesting of 4 levels
  - Use `Time.zone.today` instead of `Date.current`
  - Use single-line `let` and `before` blocks when they fit within 100 characters
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

# Serena MCP Server

- Serena must be activated at the start of each session before its tools can be used
- Activation steps:
  1. Load the tool: `ToolSearch` with query `select:mcp__serena__activate_project`
  2. Activate the project: `mcp__serena__activate_project` with the current project path
- Serena has project memories that can be read with `read_memory` when relevant
- Do NOT attempt to call any `mcp__serena__*` tool without first loading it via `ToolSearch`
