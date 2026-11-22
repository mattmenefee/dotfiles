---
name: config-review
description: >-
  Monthly review of the user's recent Claude Code transcripts and every project's memories, to
  promote recurring corrections, repeated prompts and durable memories into checked-in
  configuration. Builds a corpus of the text the user typed, scans it for secrets, dispatches two
  research agents and walks the user through each candidate. Use when the monthly reminder fires or
  the user asks for a config review.
argument-hint: "[days]"
---

# Config Review

Find the guidance the user keeps giving by hand and the memories that have outgrown memory, then
carry the ones the user approves into checked-in configuration.

**Days (optional):** `$ARGUMENTS` — how far back the transcript corpus reaches; 35 when empty, which
covers a month with a few days of overlap. Transcripts are kept for 90 days, so a longer window is
possible: worth it for the first run, which has no earlier months' rulings, or for an occasional
long view, but a monthly run over 90 days re-reads two months already reviewed.

Every working file this review writes (the corpus, the scan report, the research reports and the
rulings) stays under `~/.local/state/claude-config-review/<YYYY-MM>/`, never in a repository or
under `~/.claude`: they quote the user's own messages, and a file in either place can be committed,
published or loaded into another session's context.

## 1. Prepare the State Directory

```bash
dir="$HOME/.local/state/claude-config-review/$(date +%Y-%m)" \
  && mkdir -p -m 700 "$dir/corpus" && chmod 700 "$dir" && ls -laR "$dir"
```

If the directory already holds a corpus, reports or a `rulings.md` from an earlier run this month,
ask whether to reuse them or start over before writing anything. Reusing a `rulings.md` resumes the
walkthrough after its last recorded ruling.

## 2. Build the Corpus

```bash
'${CLAUDE_SKILL_DIR}/scripts/extract-corpus.sh' "<dir>/corpus/user-messages.txt" <days>
```

It reads the top-level transcripts under `~/.claude/projects` changed in the window and keeps only
what the user typed, prompts queued while a turn ran included: tool results, which the transcripts
also store as user records, and the text the harness or a program wrote are filtered out by
`scripts/user-messages.jq`, and a prompt suggestion the user accepted is kept under a marked header.
It prints on stderr the transcript and message counts, the requested cutoff and the span the
messages actually cover. Never print the corpus into this session; the transcript review agent reads
it.

## 3. Scan for Secrets

```bash
gitleaks dir "<dir>/corpus" --redact --no-banner --report-format json \
  --report-path "<dir>/gitleaks.json"
```

`--redact` keeps any secret out of the report. Exit 0 means no finding. On any other exit, stop
before any agent reads the corpus. When the report lists findings, print only each one's rule and
line with `jq -r '.[] | "\(.RuleID) line \(.StartLine)"' "<dir>/gitleaks.json"`, report them and ask
the user how to proceed; when it lists none or was never written, the exit was a scan error, so
report the error instead. When `gitleaks` is not installed, stop and say so; the user's `Brewfile`
lists it.

## 4. Dispatch the Research Agents

Dispatch two fresh `general-purpose` agents in parallel, never forks of this session. Each prompt
names the brief to follow by path, the state directory and the report path, and says the agent
writes nothing but that report:

| Agent | Brief | Report |
| --- | --- | --- |
| Transcript review | `${CLAUDE_SKILL_DIR}/transcript-review-brief.md`, with the corpus path | `<dir>/transcript-review.md` |
| Memory audit | `${CLAUDE_SKILL_DIR}/memory-audit-brief.md` | `<dir>/memory-audit.md` |

Both briefs tell the agent never to quote a secret or customer data, and to read earlier months'
reports and rulings beside the state directory. When both finish, confirm each report exists and is
not empty before going on.

## 5. Walk Through the Candidates

Read both reports. Take the candidates in this order:

1. The memory audit's cross-cutting findings
2. Its promotions, grouped by target file
3. Its **Already codified** and **Stale or wrong** rows, one bucket at a time, with the `MEMORY.md`
   index edits each implies
4. The transcript review's rows whose status is `New` or `Covered but weak`

For each, give the evidence and a recommendation in the reply, then ask for the ruling with
`AskUserQuestion`, putting the recommended answer first and labeled "(Recommended)" and ending with
an option that leaves it undecided. For a promotion or a transcript row, the answers are adopt as
proposed (or with the wording you recommend), adopt with changes and keep as it is. For a codified
or stale memory, they are delete (or merge the named fact, then delete) and keep. Put up to four
independent candidates for one target file in one call.

Record each ruling in `<dir>/rulings.md` as it is made, keyed by its report row (`X1`, `P3`, `B2`)
and its report, with the answer and any changed wording, so a long walkthrough can resume and next
month's agents can see what was decided.

## 6. Carry Out the Rulings

- **User-wide items** (`~/.claude/CLAUDE.md`, skills, agents, settings and hooks) go to the dotfiles
  repository on a branch and draft pull request, following that repository's `CLAUDE.md`
- **Project items** go to a branch in that project, following its own workflow
- Carry **rule text only**. The reports' example quotes, session and project names, people, hosts,
  issue identifiers and file paths stay in the state directory. Before each commit to a public
  repository, grep its diff for the private names the reports mention.
- **Memory rulings** happen only for the memories the user ruled on. Delete a codified or stale
  memory, and edit its `MEMORY.md` line, once it is ruled on. Hold a memory whose rule is being
  promoted until that rule's pull request merges, since until then the memory is the only copy that
  is loaded.

A change to configuration still goes through the user's usual review: the walkthrough approves
content, not a push.

## 7. Report

Give the corpus span and message count, the scan result, the number of candidates ruled on in each
direction, the branches and pull requests opened, the memory edits waiting on a merge with their
pull requests and what was left undecided. Leave the state directory in place for next month's
comparison; the user may delete older months.
