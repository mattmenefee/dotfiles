# Session Handoff

Export everything a future agent needs to resume this session's work to a Markdown file.

**Topic (optional):** `$ARGUMENTS`

The reader is an agent with **zero memory of this conversation**. It will have the repository, the
`CLAUDE.md` files that load automatically (the user's global one and the project's, if any) and
this file — nothing else. Write accordingly: everything that only exists in this session's
conversation must survive into the file, and everything already recorded elsewhere should be pointed
at rather than copied.

## Arguments

- **No arguments** — derive the topic from the session's work and write a new handoff (or merge into
  the existing one, see **Merging with an Existing Handoff**).
- **A topic or slug** (e.g. `payment retry backoff`) — use it for the title and filename.
- **A path ending in `.md`** — write to that exact path instead of the derived one.

## Output File

**Look for an existing handoff before deriving a name** — the topic is re-derived each session and
will not spell itself the same way twice, so a derived name alone would strand the earlier file and
silently skip **Merging with an Existing Handoff**:

```bash
find "$(git rev-parse --show-toplevel)" -maxdepth 1 -name '*-HANDOFF.md'
```

`find` rather than `ls *-HANDOFF.md 2>/dev/null`: the redirect hides a real error on a name
beginning with `-`, and under zsh an unmatched glob is a shell error that prints regardless. Anchor
it to the repository root rather than `.`: handoffs live in the root, and from a subdirectory
`find .` prints nothing and exits 0, which is indistinguishable from there being no handoff.

- **One covers this work** — merge into it, whatever name the topic would have derived. Do not
  rename it.
- **More than one might** — ask the user which to update rather than guessing.
- **None covers this work** — derive a fresh name, even if handoffs for other work exist.

An explicit `.md` path in `$ARGUMENTS` wins over the lookup: write to that path, merging if the file
already exists, and tell the user about any other handoff the lookup found for this work. Warn them
when the path does not end in `-HANDOFF.md`, because a later pass's lookup will not find it.

Write to a **Markdown file in the project root**, unless `$ARGUMENTS` supplied an explicit `.md`
path (see **Arguments**), in which case use that path verbatim. Derive the filename from the topic:
lowercase it, convert spaces to dashes, drop any character other than letters, digits and dashes
and append `-HANDOFF.md` (e.g. `Payment retry backoff` → `payment-retry-backoff-HANDOFF.md`).

**Never `git add` or commit this file** unless the user explicitly asks. It is a working artifact,
not part of the change. Leave it untracked; do not add it to `.gitignore` on your own initiative
either.

`/ship-it` posts review and plan artifacts whole and then deletes them: `*local-review*.md` (an
identifier may sit on either side of the name, as in `payments-local-review.md` or
`local-review-2.md`), `*-DOC-REVIEW.md` and `*-PLAN.md` (or a legacy `PLAN.md`).

A handoff is treated differently. `/ship-it` posts only its durable sections — **Decisions &
Rationale**, **Insights & Learnings**, **Dead Ends**, still-open **Open Questions** and
**References** — as a collapsible pull request comment, then asks whether to delete the file. The
rest of a handoff describes a working tree that merging makes obsolete, and a handoff for work that
continues past the pull request outlives the pull request. Write the durable sections knowing they
are the part that will be read after merge, and that `/ship-it` publishes them to the pull request:
name no private repository, internal host or personal data in them.

## Gathering State

Collect the mechanical facts before writing, so the file records reality rather than recollection.
Use `--no-pager` on Git commands and `--json` on `gh` so output is machine-readable and nothing
waits for input. (`gh` has no `--no-pager` flag; set `GH_PAGER=cat` if a pager ever appears.)

Resolve the base branch first — the commit ranges below need it, and so does the **Branch** header
row. Never hardcode `main`: this command runs against any repository, including ones that ship from
`develop`. A stacked branch gets its real base only from its pull request; without one the fallback
is the repository default, so confirm the base with the user or record it as assumed.

```bash
gh auth status >/dev/null 2>&1 \
  || echo "gh unavailable — pull request, CI and issue state not checked"

if base=$(gh pr view --json baseRefName --jq .baseRefName 2>/dev/null); then
  base_source="pull request"
elif base=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name 2>/dev/null); then
  base_source="repository default"
else
  base=main base_source="assumed"
fi
echo "base: $base ($base_source)"

range_base=$(git rev-parse --verify --quiet "refs/remotes/origin/$base") \
  || range_base=$(git rev-parse --verify --quiet "$base") \
  || echo "base $base not found locally or on origin — commit range not checked"

git rev-parse --short HEAD
git --no-pager status --short --branch
git --no-pager diff --stat
git --no-pager diff --stat --cached
git --no-pager stash list
git --no-pager worktree list
git --no-pager branch --sort=-committerdate | head -10
gh pr view --json \
  number,url,state,isDraft,reviewDecision,statusCheckRollup,body,closingIssuesReferences 2>/dev/null
gh pr view --json comments,reviews,latestReviews 2>/dev/null

if [ -n "$range_base" ]; then
  git --no-pager log --oneline "$range_base"..HEAD
  git --no-pager log --format=%B "$range_base"..HEAD   # issue references in commit trailers
fi
```

Scope the commit ranges to the **base branch**, not `@{upstream}`. `@{upstream}..HEAD` means
*commits not yet pushed*, which is empty the moment the branch is pushed — the normal state for any
work that has a pull request. It fails silently, succeeding with no output, so the harvest below
would report "none" precisely when there is most to find.

Take the range from the remote-tracking base when there is one. A local base branch is often behind
— a freshly created worktree's usually is — and a range from it attributes every commit merged
upstream since, with its issue references, to this branch. The block assumes the remote is
`origin`; substitute the repository's remote if it differs.

Every `gh` call above is silenced, so a pull request that does not exist and a `gh` that is missing,
unauthenticated or offline print the same nothing. The `gh auth status` check is what tells them
apart: when it prints its warning, record **Pull request** and **Issues** as "not checked", never
"none opened" or "none".

The pull request body, the `closingIssuesReferences` field and commit trailers are where issue
identifiers hide — harvest them for the **Issues** header row and **References** rather than
reporting "none" by default. Read each identifier's state from its tracker —
`gh issue view <number> --json state` for GitHub, the Linear MCP server's `get_issue` tool for
Linear — or record it as not checked.

`gh pr view` lists comments and reviews but not whether a review thread is resolved. When unresolved
comments matter, query `reviewThreads { isResolved }` through `gh api graphql`; otherwise record
them as "not checked".

Re-run any test or lint command whose result you intend to record, unless it was run since the last
relevant edit — a stale "tests pass" is worse than an honest "not run since the last change".

## Recording the Capturing Model

The handoff records **which Claude model wrote it**, so a reader can judge how much weight to give
its summaries and its reasoning about what remains. Take the display name and exact model ID from
your own environment context — do **not** infer them from an alias such as `opus`, which resolves to
a different model as new models ship and can resolve downward at runtime when the preferred model is
unavailable. Only the resolved model identifies the capability behind the file.

Record the ID verbatim, including any context-window or snapshot suffix (e.g. `claude-opus-5[1m]`).
If you cannot determine your own model, record `unknown` — a wrong entry is worse than a missing
one. This value populates the **Captured by** header row and the **Handoff History** entry for
*this* pass. **Never rewrite the model recorded on an earlier entry** — each entry is a permanent
record of the pass that produced it.

Write it as ``Display Name (`model-id`)`` — for example ``Opus 5 (`claude-opus-5[1m]`)``. Strip any
parenthetical the environment appends to the display name, such as a context-window note: the suffix
inside the ID already carries that, and keeping both nests parentheses inside parentheses.

## Document Structure

Include every section below that has content. Omit a section entirely rather than filling it with
"N/A" — except **Completed Work**, **Verification**, **Open Questions** and **Next Steps**, which
always appear (write "None" if genuinely empty, because their absence is itself information the
reader needs). **Verification** earns its place on that list the hard way: an omitted one is
indistinguishable from a section the author forgot, while a present one reading "None — nothing has
been run since the last edit" is the honest signal the rest of this file demands.

The sections appear as `###` headings here because they sit under this command file's own
`## Document Structure`. **In the generated file the title is an H1, the Header table sits directly
under it with no heading of its own and every other section below is an H2 in the order listed** —
`## Start Here`, `## Objective`, `## Next Steps` and so on.

### Header

```markdown
# Handoff: <one-line description of the work>

| | |
|---|---|
| **Status** | <In progress, Blocked, Ready for review or Paused> |
| **Created** | YYYY-MM-DD |
| **Updated** | YYYY-MM-DD |
| **Branch** | `<branch>` (base: `<base-branch>`) |
| **Commit** | `<short sha>` at capture |
| **Pull request** | <full URL, or "none opened"> |
| **Issues** | <full URLs for the Linear and GitHub issues this work tracks, or "none"> |
| **Captured by** | <display name> (`<exact-model-id>`) |
```

The header is a two-column table so each field renders on its own row; plain consecutive lines
collapse into a single run-on line in any rendered view.

Give **full URLs**, not bare identifiers: `ENG-412` and `#88` are not clickable and are ambiguous
across projects and repositories. Put the identifier and the URL together —
`ENG-412 (https://linear.app/…)`. Find them rather than assuming there are none: check the pull
request body and the branch's commit messages for issue references, and read
`closingIssuesReferences` from the `gh pr view` output gathered above — a bare `gh issue list`
returns the repository's recent open issues, which have no relationship to this branch. If the work
tracks no issue at all, say "none" explicitly so the reader knows it was checked rather than
skipped.

On the first pass **Updated** matches **Created**; every later pass advances **Updated** and leaves
**Created** alone, so the gap between the two shows at a glance how long the work has been running
and how fresh the state is.

Use absolute dates — never "today", "yesterday" or "last week", which mislead whenever the file is
read.

Record the branch even though the reader can run `git branch --show-current`: by the time the file
is read the checkout may be somewhere else entirely, and the branch named here is the one the state
below describes. The base branch is the `$base` resolved in **Gathering State**. When
`base_source` is not the pull request, say where it came from — `(base: main, repository default)`
or `(base: main, assumed)` — so a fallback is never presented as checked.

Record **Commit** from `git rev-parse --short HEAD` in **Gathering State**. It is the one field that
tells a later reader whether the branch has moved since capture.

### Start Here

Three or four sentences orienting the reader: what this work is, how far it got and what the very
first action should be. Then the re-orientation commands, since the repository may have moved on
since capture:

```bash
git --no-pager status --short --branch
git --no-pager log --oneline -5
```

Call out explicitly that the state below was accurate at capture time and should be re-verified
before it is trusted, starting with the header's **Commit**: if the first line of `git log` names a
different commit, the branch has moved since capture.

### Objective

What the work is meant to accomplish and why. Quote the user's original request where it is short
enough to quote — a paraphrase silently drops requirements. Include the acceptance criteria: how the
reader will know the work is finished.

### Scope

What is deliberately **in** scope and what was explicitly ruled **out**. An out-of-scope list
prevents the next agent from "helpfully" widening the change, and prevents it from reading an
omission as an oversight.

### Completed Work

What is done, in the order it was done. For each item state what changed and where
(`path/to/file.rb:42`), and — critically — whether it is **verified** (a test ran, the app was
exercised, output was inspected) or merely **written**. Conflating the two is the single most
expensive error a handoff can make.

Mark anything that is done but deliberately provisional (a stub, a hardcoded value, a simplification
agreed with the user) so it isn't mistaken for finished.

### Current State

The state of the working tree and the world around it:

- Files modified, staged and untracked — and which of those belong to this work versus pre-existing
  local changes that must not be swept into a commit
- Commits made on this branch, with subjects
- Stashes, worktrees or branches created along the way
- Pull request state: number, review decision, CI status, unresolved comments
- Anything left in a knowingly broken or half-migrated state, stated plainly

Every bullet that states a fact about the branch, the pull request, CI or an issue names the command
whose output it summarizes — in the bullet itself, or once under the section heading when a single
command backs every bullet. Use the commands from **Gathering State**, such as
`git --no-pager status --short --branch`, `gh pr view --json …` or `mcp__linear-server__get_issue`,
and state nothing the session did not read from such a command in this pass. Claims written from
memory at the end of a session are the ones most often wrong, and the next agent cannot tell them
apart from checked ones.

### Environment & Setup

Only what the reader could not infer: services that must be running, migrations pending, seed data
required, feature flags toggled, environment variables needed (**names only — never values**),
non-obvious tool versions and any local setup performed during the session.

### Key Files & Entry Points

A short reading list in the order the reader should work through it, each with a `path:line`
reference and one line on why it matters. Reference code; do not paste it. The exception is code
that exists nowhere on disk — a snippet the user supplied, or a command output being reasoned about
— which must be included verbatim or it is lost.

**Do not lean on another working artifact without saying it may be gone.** `*local-review*.md` and
`*-DOC-REVIEW.md` are untracked, `*-PLAN.md` (or a legacy `PLAN.md`) is tracked but stripped from
the branch history at ship time, and `/ship-it` deletes all of them once it has posted them to the
pull request — so a handoff that names one as its authoritative record is describing a file that
shipping will remove. Mark any such reference as branch-local and deletable, and carry the
load-bearing parts into this file: the conclusions, the open items and the reasoning the next agent
would otherwise lose. Point at the artifact for the detail; never depend on it for the substance.

### Decisions & Rationale

Every non-obvious choice, the alternatives considered and why they were rejected. This is the
section that most justifies the file's existence: the diff shows what was decided, and nothing but
this shows *why*, so without it the next agent relitigates settled questions and may quietly undo
deliberate choices.

Attribute each decision — the user's call, or the agent's judgment. A user's decision should not be
reopened without asking; an agent's may be revisited on new evidence.

### Insights & Learnings

The understanding earned during the session that outlives it: how a subsystem actually behaves, a
surprising interaction between components, a convention the codebase follows that isn't written
down, the reason a plausible-looking approach cannot work here. Include explanations offered during
the session that would take real effort to reconstruct.

Keep each to a couple of sentences, anchored to a file or symbol where possible. Skip general
programming knowledge — record only what is specific to this codebase or this problem.

### Constraints & Preferences

Guidance the user gave during this session that isn't already in `CLAUDE.md`: corrections, style
calls, tools or approaches ruled out, patterns to follow. Note where these were confirmed with the
user rather than inferred. Do **not** restate what `CLAUDE.md` already says — the reader loads it
automatically, and duplication creates two copies to drift apart.

### Dead Ends

Approaches that were tried and abandoned, with the reason each failed. Without this the next agent
spends its first hour rediscovering them. Include failing error messages verbatim where they were
the deciding evidence.

Distinguish "this cannot work" from "this was not pursued" — the second is a fork in the road, not a
closed door, and the reader should be told which it is.

### Open Questions

Everything unresolved, each one labeled:

- **Blocking** — work cannot proceed correctly until it is answered. State who can answer it and
  what the plausible answers imply for the work.
- **Non-blocking** — an assumption was made to keep moving. State the assumption explicitly and what
  to revisit if it turns out to be wrong.

Questions already put to the user and still unanswered belong here, phrased as they were asked.

### Next Steps

A concrete, ordered checklist. Each item must be actionable without further context — name the file,
the function and the intended change:

```markdown
- [ ] 1. Cap `PaymentRetry#backoff` (`app/models/payment_retry.rb:31`) at 5 attempts, matching
      `max_attempts` in `config/payments.yml`
- [ ] 2. Add a spec for the ceiling in `spec/models/payment_retry_spec.rb`
- [ ] 3. Run `bin/rspec spec/models/payment_retry_spec.rb`, then
      `bin/rubocop -A app/models/payment_retry.rb`
```

"Finish the refactor" is not a next step. If an item is genuinely unspecified, that is an open
question, not a task — move it.

Note dependencies between items, and flag any step that needs the user (a decision, a credential, an
interactive command the agent cannot run).

### Verification

The exact commands that prove the work is correct, with the last known result and when it was run:

```markdown
- `bin/rspec spec/models/payment_retry_spec.rb` — 12 examples, 0 failures (2026-07-31)
- `bin/rubocop -A app/models/payment_retry.rb` — clean (2026-07-31)
- Manual: retried a failed charge in the admin UI, confirmed backoff in the job log — not re-run
  since the last edit
```

Follow the task-completion checklist in `CLAUDE.md`: only the linters and specs relevant to the
change, never the full suite.

If nothing has been run, say so — "None — nothing has been run since the last edit" — rather than
dropping the section. Silence here reads as "verified" to a reader in a hurry, which is the
conflation **Completed Work** calls the most expensive error a handoff can make.

### References

Everything the reader might need to open, as a full URL with one line on its relevance. Commit SHAs
are the one exception — a short SHA resolves with `git show` and needs no URL:

```markdown
- Linear ENG-412 — https://linear.app/acme/issue/ENG-412 — the originating issue; acceptance
  criteria live in its description
- PR #412 — https://github.com/acme/app/pull/412 — this branch; one unresolved review comment on
  `app/models/payment_retry.rb`
- GitHub issue #88 — https://github.com/acme/app/issues/88 — the bug report that prompted the work
- Upstream stripe/stripe-ruby#2311 — https://github.com/stripe/stripe-ruby/issues/2311 — why the
  retry header is unreliable
- `a1b2c3d` — the commit that introduced the original backoff, useful context for the change
```

Repeat the pull request and issue links from the header here rather than pointing back at it — the
header is scanned, this section is worked from, and a reader following one should never have to
scroll to the other. Include anything consulted during the session that shaped the work: upstream
issues, vendor documentation, Stack Overflow answers and prior commits or pull requests that set
the pattern being followed.

### Resume Prompt

A fenced `text` block the user can paste into a fresh session to start the next agent, naming this
file and the first task:

````markdown
```text
Read payment-retry-backoff-HANDOFF.md in the project root, then continue the work from
"Next Steps". Start with item 1 and confirm the plan before editing.
```
````

### Handoff History

A dated log so re-runs accumulate rather than overwrite, one entry per pass, **newest last**, each
naming the model that wrote it:

```markdown
- **2026-07-31** — Initial handoff: retry backoff implemented, ceiling outstanding.
  Captured by Opus 5 (`claude-opus-5[1m]`)
- **2026-08-04** — Resumed: ceiling added and specs pass; PR #412 opened, awaiting review.
  Captured by Sonnet 5 (`claude-sonnet-5`)
```

Per-entry models matter more than a single header value: passes run on whatever model was current at
the time, so a reader tracing a claim back to the pass that made it needs to know what wrote *that*
pass, not what wrote the most recent one.

## Merging with an Existing Handoff

When a handoff for this work already exists, **read it first** and update it in place — never
clobber it:

1. Append a new **Handoff History** entry rather than replacing the old one, naming your own model
   and leaving every earlier entry's model untouched
1. Move finished **Next Steps** into **Completed Work**, preserving their order
1. Renumber the remaining **Next Steps** so item 1 is the next undone task, then rewrite
   **Start Here** and the **Resume Prompt** to point at it — they are the first things the next
   agent reads, and left alone they send it back to work that is already done
1. Update **Status**, **Updated**, **Branch**, **Commit**, **Pull request**, **Issues**,
   **Captured by** and **Current State** to current reality — leaving **Created** untouched
1. Refresh **Verification** — re-run the recorded commands, or mark each result "not re-run since
   `<date>`". This is the section most certain to be stale on a re-run and the one whose staleness
   misleads most
1. Re-check every working artifact this handoff points at — `*local-review*.md`, `*-DOC-REVIEW.md`,
   `*-PLAN.md` (or a legacy `PLAN.md`; tracked, but stripped by `/ship-it`) and anything else
   untracked. If one is gone, say so where it is referenced and promote what it was carrying. If one
   is still there but the handoff leans on it for substance, promote the load-bearing parts now and
   mark the reference deletable. An earlier pass may have been written before this rule existed, and
   shipping deletes these files — so the check is on the reference, not on whether a previous pass
   thought it was fine
1. Resolve **Open Questions** that have since been answered — record the answer in **Decisions &
   Rationale** rather than deleting the question
1. Preserve **Dead Ends**, **Decisions & Rationale** and **Insights & Learnings** in full; these
   only ever accumulate, because a dead end that is deleted is a dead end that gets retried

## Writing Guidelines

- **Write for a stranger.** No "the fix we discussed", "as mentioned above" or "the file I edited"
  — name the thing every time. The reader cannot resolve a reference to a conversation it never saw.
- **Separate fact from hypothesis.** Mark unverified reasoning as such ("likely", "not yet
  confirmed"). A confident-sounding guess recorded as fact is how a handoff actively causes harm
  rather than merely omitting help.
- **Be specific over complete.** One exact command beats a paragraph describing the general idea of
  running tests.
- **Point, don't paste.** The repository travels with the file; long code blocks only go stale. Cite
  `path:line` instead.
- **Never include secrets.** No API keys, tokens, passwords, connection strings or personal data —
  name the variable and where its value comes from.
- **Absolute dates, portable paths.** Write absolute dates, never relative ones. Write paths
  repository-relative, or `~`-prefixed for a file outside the repository — never an absolute path
  that names a home directory.
- **Keep it scannable.** A reader skims this file before doing anything; prefer short sections and
  bullets over prose walls.
- **Wrap prose at 100 characters.** Let URLs and shell commands run past it rather than breaking
  them — a wrapped URL stops being clickable and a wrapped command stops being pasteable. Put any
  command long enough to need wrapping in a fenced block instead of a bullet, so it survives a copy
  intact.

## Process

1. Determine the topic and target path from `$ARGUMENTS` (or from the session's work), checking for
   an existing handoff with the root-anchored `find` in **Output File** first; if one covers this
   work, read it and follow **Merging with an Existing Handoff**
1. Gather repository, pull request, issue and check state using the commands above, recording your
   own model from your environment context
1. Re-run verification commands whose recorded results would otherwise be stale
1. Draft the document, working backwards from **Next Steps** — deciding what the next agent must do
   first reveals which context it actually needs
1. Write the file, ending it with a blank line
1. Re-read what was written and ask, for each section, whether it survives without the conversation;
   rewrite anything that does not
1. Report to the user: the file path, the status, a one-line summary of what is done and what is
   next and the resume prompt as a copy-pasteable block
1. Do **not** stage or commit the file unless the user explicitly asks (see **Output File**)
