# Commit Changes

Create a git commit for the changes made during this session.

## Arguments

If `$ARGUMENTS` contains `amend` or `--amend`:

- Amend the changes to the most recent commit
- Update the commit message to describe ALL changes in the amended commit (both
  original and newly added changes)
- Use `git log -1 --format=%B` to get the original commit message for context

Otherwise:

- Create a new commit with only the changes made during this session

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

1. Run `git status` to see all changed files
1. Run `git diff` to review the actual changes
1. Identify which changes were made during this Claude session (not pre-existing
   uncommitted changes)
1. Stage only the files that were modified during this session using `git add -p`
1. Write a commit message following the guidelines above
1. If amending:
   - Review the original commit message and changes
   - Stage the new changes
   - Run `git commit --amend` with an updated message that covers all changes
1. If creating a new commit:
   - Run `git commit` with the message

## Important Notes

- **Never** stage files that were not modified during this session
- **Never** use `git add -A` or `git add .` — always add specific files
- **Never** commit sensitive files (`.env`, credentials, etc.)
- Use `git diff --cached` to verify staged changes before committing
- If uncertain which files were changed during this session, ask the user
