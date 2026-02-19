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

## Task Completion Checklist

After completing any coding task, run these commands in order:

1. **Code Quality**: Run only the relevant linters for your changes (e.g. `bin/rubocop -A` for Ruby files, `bin/rails lint:haml` for Haml, etc.) — never run `bin/rails lint`
2. **Testing**: Run only the specs relevant to your changes (never the entire suite)
3. **Frontend Build**: `yarn build` (if frontend changes were made)
4. **Search Indexing**: `bin/rails chewy:update` (if model changes affect search)

# Code Style

- Try to follow Sandi Metz's rules in her "Practical Object-Oriented Design in
  Ruby" book
- Try to follow the rules in the [Ruby Style Guide](https://rubystyle.guide/)
  and the [Rails Style Guide](https://rails.rubystyle.guide/)
- Always leave a blank line at the end of a file

# Testing

- When writing tests:
  - Do not stub the subject
  - Use verified doubles
  - Do not exceed 100 character line length
  - Use a maximum example group nesting of 4 levels
  - Use `Time.zone.today` instead of `Date.current`
  - Use single-line `let` and `before` blocks when they fit within 100 characters
  - Generally prefer fewer lines — avoid multi-line blocks for simple expressions

# Browser Automation

- Prefer `@playwright/cli` for browser automation tasks over the Playwright MCP
  server

# Serena MCP Server

- Serena must be activated at the start of each session before its tools can be used
- Activation steps:
  1. Load the tool: `ToolSearch` with query `select:mcp__serena__activate_project`
  2. Activate the project: `mcp__serena__activate_project` with the current project path
- Serena has project memories that can be read with `read_memory` when relevant
- Do NOT attempt to call any `mcp__serena__*` tool without first loading it via `ToolSearch`

# System Workarounds

## jq and asdf

The `jq` command may be managed by asdf without a version specified. Use the
full path `/usr/bin/jq` instead of just `jq` to bypass the asdf shim:

```bash
# Use this
/usr/bin/jq -r '.key'

# Not this
jq -r '.key'
```
