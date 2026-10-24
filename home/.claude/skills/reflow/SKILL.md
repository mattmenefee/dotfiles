---
name: reflow
description: >-
  Refill the paragraphs and comment blocks this branch adds or modifies so each line uses the full
  line length allowed for its file type, changing only line breaks. Use when a branch's prose or
  comments break short of the limit or run past it.
argument-hint: "[--base <ref>] [path...]"
---

# Reflow Changed Lines

Refill the lines this branch adds or modifies so each one takes as many words as fit within the
maximum line length for its file type. Only line breaks change: every file's words, and its rendered
Markdown, read the same before and after.

**Scope (optional):** `$ARGUMENTS`

An argument list of paths limits the reflow to those files. `--base <ref>` (or `--base=<ref>`),
anywhere in the list, sets the branch's base when the default resolution below would pick the wrong
one, as on a stacked branch with no pull request yet.

## 1. Find the Changed Lines

```bash
'${CLAUDE_SKILL_DIR}/scripts/changed-lines.sh' <arguments>
```

It prints `path<TAB>first-last` for each hunk of added or modified lines, measured from the merge
base with the pull request's base branch, then the repository default, then `origin/HEAD`. On stderr
it names the base and which of those chose it: when that is the repository default on a branch
stacked on another, run it again with `--base`. Committed, staged and unstaged changes all count. An
unknown option stops it with a usage line; pass the arguments on as the user gave them and report
any such error rather than guessing at a fix.

Untracked files do not count, and the script names each untracked or missing path it was given on
stderr. Reflow an untracked file only when the user names it, and then treat every line in it as
changed. A hunk that only deletes lines is reported as the two lines either side of the gap, since
the paragraph around a deletion can be left short.

Empty output, with no untracked file named and no path reported missing, means the branch changes
nothing in tracked files under the given paths; say so and stop rather than widening the scope.

## 2. Pick Each File's Limit

Take the limit from the project's own configuration. Where a linter that step 5 runs sets the width,
it wins; otherwise use the `.editorconfig` section that matches the file most narrowly:

| File type | Where the limit lives |
| --- | --- |
| Any | `.editorconfig` `max_line_length` for the file's section |
| Markdown | `.markdownlint*` or `.markdown-lint.yml` `MD013.line_length` (default 80) |
| Ruby | `.rubocop.yml` `Layout/LineLength` `Max` (default 120) |
| JavaScript, TypeScript, CSS | `.prettierrc*` or `package.json` `prettier.printWidth` (default 80); ESLint `@stylistic/max-len`, or the deprecated core `max-len`, in `eslint.config.*`, with `comments` for comments (default 80) |
| Python | `pyproject.toml`, `ruff.toml` or `.ruff.toml` `line-length` (Ruff and Black, default 88); `setup.cfg`, `tox.ini` or `.flake8` `max-line-length` (flake8, default 79); `max-doc-length` for comments |
| Rust | `rustfmt.toml` or `.rustfmt.toml` `max_width` (default 100); `comment_width` for comments only where `wrap_comments = true` is also set |
| YAML | `.yamllint*` or `.yaml-lint.yml` `rules.line-length.max` (default 80 under `extends: default`) |

Where the project runs one of these tools but leaves the width unset, the tool's default governs.
Where no tool or `.editorconfig` applies, use the user-wide default of 100. Check that a found
setting is live: an MD013 `line_length` with `code_blocks: false` still governs prose, but a rule
that is disabled sets no limit. Measure in characters, not bytes, and remember that markdownlint
counts UTF-16 code units, so an emoji counts as two.

## 3. Choose What to Refill

Refill a **block**: a Markdown paragraph, one list item's text, a block-quote paragraph, a YAML
folded scalar (`>` or `>-`) or a run of consecutive line comments sharing one indentation and
leader. Refill each block that contains a changed line, from its first line to its last, and stop at
its edges: a blank line, a heading, a list marker, a fence, a change of indentation other than a
list item's or folded scalar's continuation indent, a change of comment leader or a line of code.
Inside a comment block, a leader-only line (`#`, `//`), a list marker or doc tag (`@param`) after
the leader and a line indented further after the leader are edges too. Never pull a line from the
next block or from an untouched block.

Leave these alone, whether or not they changed:

- Fenced and indented code blocks, tables, headings, front matter keys, HTML blocks, link reference
  definitions and Markdown hard breaks (a line ending in two spaces or a backslash)
- A line that holds a long URL, or any string, identifier or code span that cannot be split; let it
  run long rather than break it
- Code statements, commented-out code and diagrams drawn in comments. Line length in code is the
  formatter's call, and a formatter rewrites more than line breaks, so list each over-limit code
  line in the step 6 report and suggest the project's formatter or linter (e.g. `bin/rubocop -A`) as
  a separate step rather than running it here
- A trailing comment on a line of code, and tool directives such as `# rubocop:disable`,
  `# shellcheck disable=`, `# frozen_string_literal: true`, `// eslint-disable-next-line`,
  `# yamllint disable-line` or `<!-- markdownlint-disable -->`. Merging one into prose disables it
- Any line a project rule keeps whole, such as a long shell `alias`
- Files that must not be hard-wrapped at all: review, plan and handoff documents
  (`*local-review*.md`, `*DOC-REVIEW*.md`, `*PLAN.md`, `*HANDOFF.md`), pull request and issue text
  and Markdown meant to be pasted into Teams or Slack
- A file whose untouched paragraphs put one sentence per line: that is its style, so ask before
  filling it

## 4. Refill

Before the first edit to a file, copy it to the scratchpad under its full path mirrored, so the
check in step 5 has a before to compare against:

```bash
backup="<scratchpad>/reflow$(realpath <file>)" && mkdir -p "$(dirname "$backup")" \
  && cp <file> "$backup" && echo "$backup"
```

Fill each block greedily: put on every line as many words as fit within the limit, counting the
line's indentation and comment leader, and break only between words. A block that already fits on
fewer lines shrinks; a line over the limit wraps. Keep the block's first-line prefix (list marker,
`>` or comment leader) and give every continuation line the indentation the block already uses: a
list item's text column, the comment's own leader and the folded scalar's indent.

In Markdown, never start a continuation line with a word that would open a new block: `-`, `+` or
`*` followed by a space, a number followed by `.` or `)`, `#`, `>`, a run of `=` or `-` (a setext
underline), a run of `*` or `_` (a thematic break), a fence (three or more backticks or tildes), `<`
opening an HTML block or `|`. Move one more word down instead. Keep a code span or link text on one
line when it fits on the next line whole.

Make each edit with the Edit tool, one block at a time.

## 5. Check

For each file, confirm that only line breaks changed:

```bash
git diff --no-index --word-diff=porcelain --word-diff-regex='[^[:space:]]+' <backup> <file> \
  | sed '1,/^+++ /d' | grep '^[-+]'
```

The `sed` drops the diff's file header by position, so a changed word that itself starts with `-` or
`+`, such as `--base`, still shows. In prose the check prints only `>` block-quote markers that
moved between lines, and in a comment block only comment leaders (`#`, `//`) that moved. Anything
else is a changed word, so restore that block from the backup and refill it again.

Then check the width with the project's linter, not a character count. For Markdown, run
`npx --yes markdownlint-cli --config <config file> <file>`, naming the project's markdownlint config
by path, since markdownlint-cli looks for one only in the current directory; with no config file,
drop `--config`. Act only on its MD013 lines. For other files, use the linter or formatter step 2
took the limit from. Where there is none, `LC_ALL=en_US.UTF-8 grep -n '.\{<limit + 1>,\}' <file>`
lists every line over the limit; each one it prints must be a line step 3 leaves alone.

## 6. Report

List each file reflowed with its limit and where that limit came from, each changed block left alone
with the reason and each over-limit code line, with the formatter or linter that would fix it. Leave
the changes uncommitted and suggest `/commit`. When the branch already has commits, a reflow of
lines they introduced reads best folded into those commits, which `/commit amend <sha>` does.
