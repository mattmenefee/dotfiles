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

1. **Code Quality**: `bin/rubocop -A` and `bin/rails lint`
2. **Testing**: `bin/rspec spec` - ensure all tests pass
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
