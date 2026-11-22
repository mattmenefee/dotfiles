# Research Brief: Transcript Review

You are reviewing what one user typed to Claude Code over the window the dispatching session names
(35 days by default), to find the guidance their configuration is missing. The dispatching session
gives you the corpus path, the review month's state directory and your report path. Read only; the
only file you write is your report.

## Input

The corpus is one text file of the messages the user typed, sorted by time, each under a line
`=== [<project directory>] <session> <timestamp>`. Tool output and harness text have been filtered
out, a record copied into a resumed session appears once and a text repeated within one session
appears once. A header ending in `(accepted suggestion)` marks a prompt the user accepted rather
than typed: it shows what the user chose to do next, but its wording is the model's, so never count
it as the user's wording or quote it as theirs.

Read all of it, in order, rather than sampling or searching it: a correction often reads as an
ordinary request until it recurs. Read it in consecutive `offset` and `limit` ranges from start to
end, keeping a running tally of themes and their message counts between ranges.

Compare what you find against the guidance already in force:

- `~/.claude/CLAUDE.md`, the user-wide instructions
- each project's `CLAUDE.md` (and any nested `CLAUDE.md`) for the projects the corpus names. A
  project directory's name is its checkout path with every `/` and `.` written as `-`, so a name can
  decode more than one way: confirm the decoded path exists with `test -d` before reading it.
- `~/.claude/skills/*/SKILL.md`, `~/.claude/agents/*.md` and each project's `.claude/commands/*.md`,
  `.claude/skills/*/SKILL.md` and `.claude/agents/*.md`
- `~/.claude/settings.json` and the scripts in `~/.claude/hooks/`, for behavior a hook or permission
  rule already enforces
- each project's memory directory under `~/.claude/projects/*/memory/`, since a theme kept only in
  memory is not durable configuration

Match a theme against those files' headings and descriptions first, and before marking it `New`,
search their bodies for its key terms.

Where the state directory's parent holds earlier months' directories, read their
`transcript-review.md` and `rulings.md`. Mark a theme proposed before with that month and its
ruling, and propose it again only when its count or the configuration has changed since.

## What to Find

Group the themes into three tables:

- **A. Formatting and style corrections:** the user fixing how something was written, named, linked
  or laid out
- **B. Recurring prompts and requests:** the same request typed again and again, which a skill, a
  command or a standing rule could make unnecessary
- **C. Repeated frustration with agent behavior:** the user correcting what an agent did or failed
  to do

Count a theme in messages, from a full read. Where the wording allows, check the count by searching
the corpus for it and counting the messages the matches fall in, one per `=== [` header, not the
matching lines. Leave out a one-off unless it states a standing preference.

## Report

Write the report to the path you were given, starting with a short paragraph naming the corpus, its
date range (its first and last header timestamps), the message count and the files you compared
against. Then one table per group, with these columns:

| # | Theme | Count | Example quotes | Status | Proposed home | Proposed rule text |
| --- | --- | --- | --- | --- | --- | --- |

- **#:** `A1`, `B3` and so on, so the walkthrough can name each row
- **Example quotes:** up to three short quotes, each with its project directory and date
- **Status:** `Covered` (an existing rule handles it and the corrections stop after it landed;
  compare the message dates with `git log` for the rule), `Covered but weak` (a rule exists but is
  incomplete, in the wrong place or kept only in memory, or the corrections continue after it
  landed; name it) or `New`
- **Proposed home:** the one file and section where the rule would act soonest; one of user-wide
  `CLAUDE.md`, a project's `CLAUDE.md`, a skill, an agent, a command or a hook
- **Proposed rule text:** the rule as it would be written. The Example quotes column is evidence for
  the user only and is never copied into a rule.

End with a **Skipped** list: each theme you considered and left out, with its count and the reason.

Write every rule meant for a user-wide file (anything under `~/.claude` that the dotfiles repository
tracks) or for a public repository generically: such a rule is published, so it names no private
repository, client, person, host, issue identifier or file path from a project. Quote no secret,
credential, token, customer data, personal contact detail or production record anywhere in the
report; paraphrase around it or pick another example.
