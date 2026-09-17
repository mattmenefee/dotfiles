# Document Review: handoff.md

| | |
|---|---|
| **Document** | `home/.claude/commands/handoff.md` |
| **Branch** | `verifiable-handoff-state` |
| **Commit** | `2c3fa72` |
| **Reviewed** | 2026-09-16 |
| **Reviewed by** | Opus 5 (`claude-opus-5[1m]`) |

## Review History

### 2026-09-16 — Initial review by Opus 5 (`claude-opus-5[1m]`)

## Overall Assessment

`/handoff` is a strong command file. It knows who its reader is (an agent with no memory of the
session), it explains the reason behind almost every rule and several of its hardest-won rules are
exactly right: record verified work separately from work that was only written, keep dead ends
that were ruled out apart from ones nobody tried, and scope commit ranges to the base branch rather
than `@{upstream}`. The shell claims it makes were checked and hold. Every prose line is within the
100-character limit, and there is no trailing whitespace.

The main weaknesses are mechanical gaps between what the file asks for and what its commands can
actually produce:

- The existing-handoff lookup scans the current directory rather than the project root (F10)
- The commit range is taken against a local base ref that may be stale (F11)
- Silenced `gh` failures become recorded facts (F12)
- The new provenance rule in **Current State** requires facts that **Gathering State** has no
  command to collect (F4)

A second cluster concerns what a later pass and a later reader can trust: the header records no
capture commit (F14), and a merge pass never refreshes **Start Here** or the **Resume Prompt**
(F15). The rest is house-style work: 19 serial commas, a few formatting inconsistencies and one
header format that needs your ruling (F2).

No sensitive information was found.

## Formatting

### F1 ~~🟢 Low Priority - Inline command broken across a line in Current State~~ ✅ Fixed

- **Location** — Current State, lines 207–208
- **Issue** — The code span `` `git --no-pager status --short --branch` `` is split across a line
  break after `--short`. It renders correctly, since a soft break inside a code span becomes a
  space, but a raw-text reader copying from line 207 gets a truncated command. The file's own
  Writing Guidelines (lines 408–411) say to let shell commands run past the wrap limit rather than
  break them.
- **Suggestion** — Reflow the paragraph so the whole code span sits on one line, letting that line
  run past 100 characters if necessary. The F4 and F17 rewrites of this paragraph are the natural
  place to do it.
- **Recommendation** — Implement: a one-line fix, and the file should follow its own wrapping rule.
- **Status** — ✅ Fixed: `git --no-pager status --short --branch` now sits whole on one line, as does
  the new `gh issue view <number> --json state`

### F2 ~~⚖️ Decision - Header fields render as one run-on line~~ ✅ Fixed

- **Location** — Document Structure › Header, lines 126–136
- **Issue** — The template puts `**Status:**`, `**Created:**`, `**Updated:**`, `**Branch:**`,
  `**Pull request:**`, `**Issues:**` and `**Captured by:**` on consecutive lines with no blank line,
  trailing backslash or two-space break between them. In a rendered Markdown file (an editor
  preview or a GitHub file view) consecutive lines join into one paragraph, so all seven fields run
  together on a single line. An agent reading the raw text is unaffected, and that is the file's
  primary reader, so both keeping and changing the format are defensible.
- **Options** — **(a)** Keep the lines as they are: nothing to change and raw text reads cleanly,
  but any rendered view of the handoff collapses the header. **(b)** Make each field a bullet
  (`- **Status:** …`): renders on separate lines and reads well raw, at the cost of a slightly
  noisier header. **(c)** Use a two-column table, as `/doc-review` does for its metadata: aligns the
  fields and matches the sibling artifact, but tables are harder to edit by hand on a merge pass
  and a URL in a cell makes the raw row very long.
- **Ruling** — **(c)** Two-column table, chosen by the user on 2026-09-16. The edit is not yet in
  the document, so the finding stays ❓ Open until it lands. The edit also has to change the prose
  that calls these fields "header lines" (**Branch**, **Issues** and **Captured by**) to match.
- **Status** — ✅ Fixed: the Header template is now a two-column table with one row per field, and
  the prose calling the fields header lines now says header rows

### F3 ~~🟢 Low Priority - Section cross-reference style differs in Arguments~~ ✅ Fixed

- **Location** — Arguments, lines 15–16
- **Issue** — The first bullet refers to a section in quotation marks ("Merging with an Existing
  Handoff"), while every other cross-reference in the file uses bold (**Merging with an Existing
  Handoff** at line 24, **Arguments** at line 39, **Output File** at line 428).
- **Suggestion** — Change it to `see **Merging with an Existing Handoff**`.
- **Recommendation** — Implement: trivial, and it makes section references look the same
  everywhere in the file.
- **Status** — ✅ Fixed: Arguments now reads "see **Merging with an Existing Handoff**"

## Consistency

### F4 ~~🟠 High Priority - Current State requires facts that Gathering State has no command for~~ ✅ Fixed

- **Location** — Current State, lines 199–210; Gathering State, lines 66–79
- **Issue** — The provenance paragraph (lines 206–210) requires every factual bullet about the
  branch, the pull request, CI or an issue to name the command it came from. It also forbids
  stating anything the session did not read from such a command in this pass. The bullet list just
  above asks for facts that no command in **Gathering State** produces:
  - **Unresolved comments** (line 203): the `gh pr view --json` field list at line 77 has no
    `comments`, `reviews` or `latestReviews`, and whether a review thread is resolved is not a
    `gh pr view` field at all
  - **Worktrees and branches created along the way** (line 202): there is no `git worktree list`
    or `git branch` in the block
  - **Issue state**: line 208 cites `mcp__linear-server__get_issue`, but **Gathering State** never
    tells the agent to call it

  An agent that obeys the provenance rule has to drop those bullets or run commands the file never
  named. One that obeys the bullet list breaks the provenance rule. That is a cross-section
  contradiction introduced by the commit under review.
- **Suggestion** — Add the missing collectors to the **Gathering State** block, for example:

  ```bash
  git --no-pager worktree list
  git --no-pager branch --list --sort=-committerdate | head -10
  gh pr view --json comments,reviews,latestReviews 2>/dev/null
  ```

  Then add a sentence saying that unresolved review threads need
  `gh api graphql` (`reviewThreads { isResolved }`) or should be reported as "not checked". Also
  add a line saying issue state comes from the issue tracker's tool (for Linear, its MCP
  `get_issue` tool) for each identifier harvested at line 86. Alternatively, drop "unresolved
  comments" from line 203.
- **Recommendation** — Implement: the rule was added to stop claims written from memory, and as it
  stands it forces either that kind of claim or a silent omission.
- **Status** — ✅ Fixed: Gathering State now collects `git worktree list`, recent branches and `gh pr
  view --json comments,reviews,latestReviews`, and says to read issue state from the tracker and
  review-thread resolution through `gh api graphql`, or record either as not checked

### F5 ~~🟡 Medium Priority - "Every section below is an H2" does not hold for Header~~ ✅ Fixed

- **Location** — Document Structure, lines 120–122; Header, lines 124–136
- **Issue** — Line 121 says that in the generated file "every section below is an H2", and the first
  section below is `### Header`. The Header template itself shows the H1 title followed by field
  lines, with no `## Header`. An agent taking line 121 literally writes a `## Header` heading, and
  one following the template does not. The paragraph also never says that the generated sections
  follow the order they are listed in, which the Handoff History example ("newest last", at the
  end) implies.
- **Suggestion** — Reword to: "In the generated file the title is an H1, the Header fields sit
  directly under it with no heading of their own and every other section below is an H2 in the
  order listed — `## Start Here`, `## Objective`, `## Next Steps` and so on."
- **Recommendation** — Implement: a single sentence settles what the generated file looks like.
- **Status** — ✅ Fixed: Document Structure now says the Header table sits under the H1 with no
  heading of its own and every other section is an H2 in the order listed

### F6 ~~🟡 Medium Priority - Plan-file patterns disagree across three sections~~ ✅ Fixed

- **Location** — Output File, lines 47–49; Key Files & Entry Points, lines 225–228; Merging with an
  Existing Handoff, lines 380–381
- **Issue** — **Output File** lists what `/ship-it` posts whole and deletes as `*local-review*.md`,
  `*-DOC-REVIEW.md` and `*-PLAN.md`. **Key Files** and the merge step add "or a legacy `PLAN.md`".
  The glob `*-PLAN.md` does not match a bare `PLAN.md`, since it needs a dash before `PLAN`, so the
  **Output File** list leaves out a file the other two sections say shipping removes. Line 227 then
  says `/ship-it` "deletes all three" right after naming four patterns.
- **Suggestion** — Name the same set in all three places: `*local-review*.md`, `*-DOC-REVIEW.md` and
  `*-PLAN.md` (or a legacy `PLAN.md`). Change "all three" to "all of them".
- **Recommendation** — Implement: the three lists are meant to describe one set of files, and a
  reader checking the first list would conclude a legacy `PLAN.md` survives shipping.
- **Status** — ✅ Fixed: Output File, Key Files and the merge step now all name `*local-review*.md`,
  `*-DOC-REVIEW.md` and `*-PLAN.md` (or a legacy `PLAN.md`), and "deletes all three" now reads
  "deletes all of them"

### F7 ~~🟢 Low Priority - Start Here's `git status` omits the required `--no-pager`~~ ✅ Fixed

- **Location** — Start Here, line 166; Gathering State, line 59
- **Issue** — **Gathering State** tells the agent to use `--no-pager` on Git commands, and every
  other Git command in the file does. The re-orientation block's `git status --short --branch` is
  the one exception, directly above a `git --no-pager log` in the same block. `git status` does not
  page by default, so nothing breaks, but the example contradicts the rule stated just before it.
- **Suggestion** — Change line 166 to `git --no-pager status --short --branch`.
- **Recommendation** — Implement: a one-word change that removes a counterexample from a block
  agents copy.
- **Status** — ✅ Fixed: Start Here's block now runs `git --no-pager status --short --branch`

### F8 🟢 Low Priority - Wording for stale verification varies across four places

- **Location** — Gathering State, line 91; Document Structure, line 118; Verification, lines 306–307
  and 313; Merging, lines 377–378
- **Issue** — The same state is phrased four ways: "not run since the last change", "None —
  nothing has been run since the last edit", "not re-run since the last edit" and "not re-run since
  `<date>`". Only the last is anchored to something a later reader can check.
- **Suggestion** — Standardize on "not re-run since `<date>`" for stale results and "None — nothing
  has been run" for the empty section.
- **Recommendation** — Skip: every variant is understandable in context, and a wording sweep adds
  churn to a file that just changed.

### F9 🟢 Low Priority - Verification paraphrases CLAUDE.md, contrary to the file's own rule

- **Location** — Verification, lines 310–311; Constraints & Preferences, lines 257–258
- **Issue** — **Constraints & Preferences** says not to restate `CLAUDE.md`, because duplication
  "creates two copies to drift apart". **Verification** then paraphrases the task-completion
  checklist from `home/.claude/CLAUDE.md` ("only the linters and specs relevant to the change, never
  the full suite").
- **Suggestion** — Reduce it to a pointer: "Follow the task-completion checklist in `CLAUDE.md`."
- **Recommendation** — Skip: the paraphrase is short and accurate today, and it keeps the rule
  visible to an agent that skimmed `CLAUDE.md`.

## Accuracy

### F10 ~~🟠 High Priority - `find .` misses an existing handoff when run from a subdirectory~~ ✅ Fixed

- **Location** — Output File, line 27; Process, line 416
- **Issue** — The lookup exists so a re-derived topic name does not "strand the earlier file and
  silently skip **Merging with an Existing Handoff**" (lines 22–24). Handoffs live in the project
  root (line 38), but `find . -maxdepth 1` scans the current working directory. From any
  subdirectory, and an agent often `cd`s into one during a session, it prints nothing and exits 0.
  That is the same result as "none exists", so the agent derives a fresh name and creates the
  second file the rule was meant to prevent. This was reproduced: with `a-HANDOFF.md` in a parent
  directory, `find . -maxdepth 1 -name '*-HANDOFF.md'` run from a child directory printed nothing
  with exit status 0. `/doc-review` anchors its own artifact scan to `git rev-parse --show-toplevel`
  for exactly this reason.
- **Suggestion** — Anchor both occurrences to the repository root:

  ```bash
  find "$(git rev-parse --show-toplevel)" -maxdepth 1 -name '*-HANDOFF.md'
  ```

- **Recommendation** — Implement: a small edit that closes a silent failure in the step whose whole
  purpose is avoiding one.
- **Status** — ✅ Fixed: the lookup is now `find "$(git rev-parse --show-toplevel)" -maxdepth 1 -name
  '*-HANDOFF.md'`, with the reason stated beside it, and Process points at it; from a subdirectory
  of a scratch repository the anchored form found the handoff while `find .` printed nothing with
  exit 0

### F11 ~~🟠 High Priority - Commit range is taken against a local base ref that may be stale~~ ✅ Fixed

- **Location** — Gathering State, lines 62–72 and 78; Header, lines 156–157
- **Issue** — `$base` is a branch *name* (`baseRefName`, `defaultBranchRef.name` or `main`),
  and the ranges use it as a local ref: `"$base"..HEAD`. Two cases give a wrong range with no error:
  - **Stale or missing local base.** In a worktree or a clone where the local `main` was never
    pulled, `main..HEAD` includes every commit merged upstream after the local ref's position. The
    commit list and the issue harvest at line 78 then attribute other people's work and issues to
    this branch. If the local branch does not exist at all, `git log` fails with "unknown revision".
  - **Stacked branch with no pull request.** Lines 63–64 say the resolution handles "branches
    stacked on other feature branches", but without a pull request it falls through to the default
    branch. The range then includes the parent branch's commits, and **Branch** records the wrong
    base.
- **Suggestion** — Resolve the range against the remote-tracking ref when one exists, and let the
  file say which remote it assumes:

  ```bash
  range_base=$(git rev-parse --verify --quiet "refs/remotes/origin/$base") \
    || range_base=$(git rev-parse --verify "$base")
  git --no-pager log --oneline "$range_base"..HEAD
  ```

  Qualify the stacked-branch claim: without a pull request the base is a guess, to be confirmed with
  the user or recorded as assumed.
- **Recommendation** — Implement: the range feeds **Completed Work**, **Current State** and
  **Issues**, and the stale-ref case is the default state of a freshly created worktree.
- **Status** — ✅ Fixed: the range now comes from `refs/remotes/origin/$base` with the local base as
  fallback, and is skipped with a message when neither exists; the stacked-branch claim now says the
  base is only real from a pull request and must otherwise be confirmed or recorded as assumed. Run
  in bash and zsh, the block ranged from `origin/main` and reported a missing base instead of
  printing an empty range

### F12 ~~🟡 Medium Priority - Silenced `gh` failures are recorded as facts~~ ✅ Fixed

- **Location** — Gathering State, lines 67–69 and 77; Header, lines 133–134 and 143–145
- **Issue** — Every `gh` call ends in `2>/dev/null`, and base resolution falls back to `main` with
  no notice. When `gh` is missing, unauthenticated or offline, `gh pr view` prints nothing and the
  base silently becomes `main`. The agent then writes **Pull request:** none opened and
  `(base: main)`, which look exactly like values that were checked. Line 144 asks for "none" to
  signal that the check happened, and lines 156–157 say to "record what was resolved rather than
  assuming `main`". The fallback does assume `main`, with nothing to show it.
- **Suggestion** — Record which source resolved the base, and check that `gh` works before trusting
  an empty result:

  ```bash
  gh auth status >/dev/null 2>&1 || echo "gh unavailable — pull request and issue state not checked"
  ```

  Then say in the Header guidance that a fallback base is written as `(base: main, assumed)` and an
  unchecked pull request as "not checked", never as "none opened".
- **Recommendation** — Implement: the provenance commit exists to stop unverified claims, and this
  is the one route by which one gets in automatically.
- **Status** — ✅ Fixed: the block runs `gh auth status` first and prints a warning when `gh` is
  unusable, records `base_source`, and the prose says to write "not checked" rather than "none
  opened"; the Branch guidance labels a fallback base. With `gh` removed from `PATH` the block
  printed the warning and `base: main (assumed)` in both shells

## Clarity and Structure

### F13 ~~🟡 Medium Priority - Output File's decision rules leave several cases unresolved~~ ✅ Fixed

- **Location** — Arguments, line 18; Output File, lines 33–41
- **Issue** — The three bullets do not cover every case, and they conflict with **Arguments**:
  - **One handoff exists but covers other work**: "Exactly one exists and it covers this work" does
    not apply, and "None matches" does not literally apply either
  - **"None matches"** never says what "matches" means. Presumably "none covers this work", but
    "Several exist" then applies even when only one of the several is relevant
  - **An explicit `.md` path while an existing handoff covers this work**: **Arguments** says to
    write to the given path, and **Output File** says to merge into the existing file "whatever name
    the topic would have derived". Neither says which wins
  - **An explicit path whose name does not end in `-HANDOFF.md`** can never be found by the next
    pass's `find`, which strands it exactly as lines 22–24 warn
- **Suggestion** — Recast the bullets around coverage: "**One covers this work** — merge into it.
  **More than one might** — ask the user. **None covers this work** — derive a fresh name, even if
  unrelated handoffs exist." Add: "An explicit `.md` path wins over the lookup. Warn the user if the
  name does not end in `-HANDOFF.md`, since a later pass will not find it."
- **Recommendation** — Implement: these are the branches an agent actually hits, and each one
  currently leaves it to guess.
- **Status** — ✅ Fixed: the bullets now read one covers this work / more than one might / none
  covers this work, and a new paragraph says an explicit path wins over the lookup and warns when
  its name will not end in `-HANDOFF.md`

### F14 ~~🟡 Medium Priority - Header records no capture commit~~ ✅ Fixed

- **Location** — Header, lines 126–136 and 154–157; Start Here, lines 161–171
- **Issue** — **Start Here** tells the reader to re-verify the state "before it is trusted" and
  supplies `git log --oneline -5`. But the header records only the branch name, so the reader has no
  commit to compare against and cannot tell whether the branch moved after capture. `/doc-review`
  records a **Commit** field for the same reason: "a reference that no longer resolves can be traced
  to a change in the document".
- **Suggestion** — Add a header line, ``**Commit:** `<short sha>` at capture``, taken from
  `git rev-parse --short HEAD` in **Gathering State**. Tell **Start Here** to compare it with the
  first line of `git log`, and list **Commit** among the fields the merge step updates (line 375).
- **Recommendation** — Implement: one line gives the reader a concrete test of whether "the state
  below" is still the state.
- **Status** — ✅ Fixed: added a **Commit** row from `git rev-parse --short HEAD` (now in the
  Gathering State block), told Start Here to compare it with `git log` and added it to the merge
  step's update list

### F15 ~~🟡 Medium Priority - A merge pass never refreshes Start Here, Next Steps or the Resume Prompt~~ ✅ Fixed

- **Location** — Merging with an Existing Handoff, lines 372–390
- **Issue** — The merge steps move finished **Next Steps** into **Completed Work** but never say to
  renumber what remains, rewrite **Start Here** ("what the very first action should be") or update
  the **Resume Prompt**, whose example says "Start with item 1". After a merge, all three can point
  at work that is already done, and they are the first three things the next agent reads.
- **Suggestion** — Add a step: "Rewrite **Start Here** and the **Resume Prompt** for the current
  first action, and renumber **Next Steps** so item 1 is the next undone task."
- **Recommendation** — Implement: stale orientation sends the next agent to redo finished work, and
  the fix is one list item.
- **Status** — ✅ Fixed: Merging with an Existing Handoff has a new step to renumber the remaining
  Next Steps and rewrite Start Here and the Resume Prompt to point at item 1

### F16 ~~🟡 Medium Priority - Authors are not told the durable sections become a pull request comment~~ ✅ Fixed

- **Location** — Output File, lines 47–54; Writing Guidelines, lines 403–405
- **Issue** — Lines 49–51 say `/ship-it` posts **Decisions & Rationale**, **Insights & Learnings**,
  **Dead Ends**, **Open Questions** and **References** as a pull request comment. The only guidance
  for those sections is "Write the durable sections knowing they are the part that will be read
  after merge", which is about staleness, not audience. Nothing tells the author that the sections
  are *published*, so a private repository's name, an internal hostname or an issue from another
  organization cited in **References** goes out verbatim. Separately, "repository-relative paths
  only" (line 405) gives no form for a file that genuinely lives outside the repository, such as a
  global command under `~/.claude/`. An agent that cannot make such a path relative is likely to
  write it absolute, which names the home directory. The `/doc-review` redaction rule says an
  authoring rule has to stand on its own rather than lean on the publishing scrub.
- **Suggestion** — Extend line 54: "…the part that will be read after merge, and that `/ship-it`
  publishes to the pull request. Name no private repository, internal host or personal data in
  them." Change line 405 to "repository-relative paths, or `~`-prefixed for a file outside the
  repository — never an absolute home path".
- **Recommendation** — Implement: once a comment is posted the disclosure cannot be undone, and the
  handoff's author is the only party positioned to avoid it cheaply.
- **Status** — ✅ Fixed: the handoff paragraph now says `/ship-it` publishes the durable sections and
  to name no private repository, internal host or personal data in them; Writing Guidelines allow a
  `~`-prefixed path for a file outside the repository and rule out absolute home paths

### F17 ~~🟡 Medium Priority - "The usage record" is an undefined reference~~ ✅ Fixed

- **Location** — Current State, lines 206–210
- **Issue** — "A claim written from recollection is the kind the usage record shows being retracted
  a session later" refers to a record the reader has never seen and cannot find, which breaks the
  file's own "Write for a stranger" guideline (lines 394–395). "In the bullet or beside the section"
  is also vague: it does not say whether a single command note under the heading covers every
  bullet.
- **Suggestion** — Replace the last sentence with the reason itself: "Claims written from memory at
  the end of a session are the ones most often wrong, and the next agent cannot tell them from
  checked ones." Replace "beside the section" with "or once under the section heading when a single
  command backs every bullet".
- **Recommendation** — Implement: the reason is one of the file's key rationales, and as written it
  points at nothing.
- **Note** — The first half is addressed in `bef98be`, which replaced the sentence with "a claim
  written from recollection is the kind that gets retracted a session later" while removing
  indirect references to private work. "In the bullet or beside the section" is unchanged, so the
  finding stays open.
- **Status** — ✅ Fixed: the last sentence now gives the reason itself, and "beside the section" is
  replaced by "once under the section heading when a single command backs every bullet"

### F18 ~~🟢 Low Priority - The `/ship-it` paragraph is hard to parse~~ ✅ Fixed

- **Location** — Output File, lines 47–54
- **Issue** — The first sentence places a long parenthetical about identifiers in the middle of a
  three-item list. That leaves "which it posts whole and deletes" loosely attached to the end, so it
  reads as if it describes only `*-PLAN.md`. In "a handoff for work that continues past the pull
  request outlives it", the "it" could mean the pull request or the working tree.
- **Suggestion** — Split the paragraph: "`/ship-it` posts review and plan artifacts whole and then
  deletes them: `*local-review*.md` (an identifier may sit on either side of the name, as in
  `payments-local-review.md` or `local-review-2.md`), `*-DOC-REVIEW.md` and `*-PLAN.md`. A handoff
  is treated differently." Replace the ambiguous "it" with "the pull request".
- **Recommendation** — Implement: the paragraph is rewritten by F6 and F16 anyway, so clarifying it
  adds almost no extra cost.
- **Status** — ✅ Fixed: the artifact list is its own paragraph ending in the list it describes, the
  handoff paragraph starts "A handoff is treated differently", and the ambiguous "it" now reads "the
  pull request"

### F19 ~~🟢 Low Priority - The topic-to-filename rule ignores punctuation~~ ✅ Fixed

- **Location** — Output File, lines 39–41
- **Issue** — "Lowercase it, convert spaces to dashes" says nothing about other characters.
  A topic such as `PR #412: retry /backoff` would produce a filename containing `#`, `:` and `/`,
  and `/` makes the "filename" a path.
- **Suggestion** — Add "and drop any character other than letters, digits and dashes".
- **Recommendation** — Implement: a clause that prevents a malformed path, and it fits in the same
  edit as F13.
- **Status** — ✅ Fixed: deriving the filename now drops any character other than letters, digits and
  dashes

### F20 🟢 Low Priority - Issue-harvest instructions are repeated in two sections

- **Location** — Gathering State, lines 86–88; Header, lines 139–145
- **Issue** — Both passages say to look for issue references in the pull request body, commit
  messages and `closingIssuesReferences` rather than reporting "none". The Header version adds only
  the warning about `gh issue list`.
- **Suggestion** — Keep the full instruction in **Gathering State** and reduce the Header passage to
  the URL format, the `gh issue list` warning and a pointer back.
- **Recommendation** — Skip: the repetition sits where each instruction is used, and it costs a
  reader seconds.

## Spelling and Grammar

### F21 ~~🟢 Low Priority - Serial commas throughout the prose~~ ✅ Fixed

- **Location** — Lines 40, 86, 114, 122, 151, 161, 199, 202, 216, 230, 235, 283, 336, 375, 389, 394,
  403, 418 and 427
- **Issue** — House style omits the serial (Oxford) comma, and the file uses one in 19 places, for
  example "the `closingIssuesReferences` field, and commit trailers" (line 86) and
  "**Open Questions**, and **Next Steps**" (line 114). Other lists in the same file already follow
  the house style, such as "**Dead Ends**, still-open **Open Questions** and **References**" (lines
  50–51), so the file is inconsistent with itself as well.
- **Suggestion** — Remove the comma before the final "and"/"or" at each listed line, including
  "`## Next Steps`, and so on" (line 122). Line 227's series of three clauses ("…at ship time, and
  `/ship-it` deletes…") can keep its comma, since it joins independent clauses.
- **Recommendation** — Implement: a mechanical sweep that brings the file in line with the house
  convention.
- **Status** — ✅ Fixed: removed the serial comma from every list the review named that survived the
  earlier groups' rewrites, plus one it missed in the opening paragraph; the lines at 40 and 86 were
  already rewritten without one in G2 and G3. A scan of the joined text found no remaining
  list-ending serial comma, and commas joining independent clauses were left as the finding allowed

### F22 ~~🟢 Low Priority - "url" and "urls" lowercase in the Header template~~ ✅ Fixed

- **Location** — Header, lines 133–134
- **Issue** — The placeholders read `<full url, …>` and `<full urls for …>`, while the prose
  directly below (line 138) and everywhere else in the file writes "URLs".
- **Suggestion** — Change them to `<full URL, …>` and `<full URLs for …>`.
- **Recommendation** — Implement: two characters, and the template is what agents copy.
- **Status** — ✅ Fixed: the placeholders now read "full URL" and "full URLs"

### F23 ~~🟢 Low Priority - Stray comma in Writing Guidelines~~ ✅ Fixed

- **Location** — Writing Guidelines, line 405
- **Issue** — "**Absolute dates only**, and repository-relative paths only." puts a comma before
  "and" in a two-item phrase, which the house style does not use.
- **Suggestion** — "**Absolute dates only** and repository-relative paths only." F16 rewrites this
  bullet, so fold it into that edit if both are taken.
- **Recommendation** — Implement: trivial.
- **Status** — ✅ Fixed: the bullet was rewritten as "**Absolute dates, portable paths.**" with no
  comma before a two-item "and"

## Staleness

### F24 🟢 Low Priority - Example model IDs and a configuration-specific tool name will age

- **Location** — Recording the Capturing Model, lines 101 and 107; Current State, line 208; Handoff
  History, lines 358–360
- **Issue** — The examples name specific models (`claude-opus-5[1m]`, `claude-sonnet-5`), which
  will look dated as models ship. `mcp__linear-server__get_issue` is the tool name under one
  particular MCP server configuration and does not exist where Linear is registered under another
  name, or not at all.
- **Suggestion** — Leave the model examples alone. Describe the Linear tool generically ("the issue
  tracker's MCP tool, e.g. Linear's `get_issue`").
- **Recommendation** — Skip: they are illustrative examples, and a wrong-looking example misleads no
  one about the rule it illustrates.

## Observations

### F25 ℹ️ Observation - The shell claims were checked and hold

The `find`-versus-`ls` rationale (lines 30–31) is correct. Under zsh, `ls *-HANDOFF.md 2>/dev/null`
with no match printed `no matches found` despite the redirect. With a file named `-l-HANDOFF.md`
present, the same command printed nothing and exited 1, the redirect having hidden `ls` rejecting
the name as an option. The `@{upstream}..HEAD` warning (lines 81–84) describes range semantics
correctly. Every field requested at line 77, including `closingIssuesReferences`, is valid for
`gh pr view --json` in gh 2.101.0. `gh` has no `--no-pager` flag, and `GH_PAGER` is the documented
override.

### F26 ℹ️ Observation - Distinctions that prevent the most expensive handoff errors

Three distinctions give the file much of its value: **verified** versus merely **written** in
**Completed Work** (lines 187–190), "this cannot work" versus "this was not pursued" in
**Dead Ends** (lines 266–267) and decisions the user made versus decisions the agent made in
**Decisions & Rationale** (lines 240–241). Each names a specific way a handoff misleads its next
reader, and explains why.

### F27 ℹ️ Observation - Nested fence and code spans are built correctly

The **Resume Prompt** example opens a four-backtick `markdown` fence around a three-backtick `text`
block (lines 344–349), which is the correct construction. The double-backtick code spans at line
107, which contain single backticks, render as intended. The file has no heading-level skips and
tags every fenced block with a language.

### F28 💡 Observation (optional action) - `/doc-review` scrub lags the names `/ship-it` publishes

This file now says `/ship-it` posts `*local-review*.md` (with an identifier on either side) and
`*-PLAN.md`. The artifact scrub in `home/.claude/commands/doc-review.md` (lines 725–726) still
matches `local-review*.md` and a bare `PLAN.md`. A `payments-local-review.md` or `payments-PLAN.md`
would therefore go unscanned by that copy of the scrub. This is outside the document under review,
and `/ship-it` carries its own copy, which cannot be checked from this repository. Optional action:
widen the `find` patterns in `doc-review.md` to `*local-review*.md`, `*-PLAN.md` and `PLAN.md` in a
follow-up.

### F29 💡 Observation (optional action) - The References example cites a real public repository

Line 328 uses `stripe/stripe-ruby#2311` with a live `github.com` URL. The `acme` examples are
clearly placeholders, but this one is a real repository with a real issue number that may point at
an unrelated issue. Optional action: use an obviously fictional repository, such as
`example/http-client#123`.

## Consolidated Summary

| Finding | Type | Category | Description | Location | Recommendation | Group | Status |
| --------- | ---------- | ---------- | ------------- | ---------- | ---------------- | ------- | -------- |
| F1 | 🟢 Low | Formatting | Inline command broken across a line | Current State | Implement | G3 | ✅ |
| F2 | ⚖️ Decision | Formatting | Header fields render as one run-on line | Header | Options | G1 | ✅ |
| F3 | 🟢 Low | Formatting | Section cross-reference in quotes, not bold | Arguments | Implement | G6 | ✅ |
| F4 | 🟠 High | Consistency | Current State requires facts no gathering command produces | Current State / Gathering State | Implement | G3 | ✅ |
| F5 | 🟡 Medium | Consistency | "Every section below is an H2" does not hold for Header | Document Structure | Implement | G1 | ✅ |
| F6 | 🟡 Medium | Consistency | Plan-file patterns disagree across three sections | Output File / Key Files / Merging | Implement | G5 | ✅ |
| F7 | 🟢 Low | Consistency | `git status` omits the required `--no-pager` | Start Here | Implement | G6 | ✅ |
| F8 | 🟢 Low | Consistency | Stale-verification wording varies | Verification and three others | Skip | — | ❓ |
| F9 | 🟢 Low | Consistency | Verification paraphrases CLAUDE.md | Verification | Skip | — | ❓ |
| F10 | 🟠 High | Accuracy | `find .` misses a handoff from a subdirectory | Output File / Process | Implement | G2 | ✅ |
| F11 | 🟠 High | Accuracy | Commit range uses a possibly stale local base ref | Gathering State | Implement | G3 | ✅ |
| F12 | 🟡 Medium | Accuracy | Silenced `gh` failures recorded as facts | Gathering State / Header | Implement | G3 | ✅ |
| F13 | 🟡 Medium | Clarity and Structure | Output File decision rules leave cases unresolved | Arguments / Output File | Implement | G2 | ✅ |
| F14 | 🟡 Medium | Clarity and Structure | Header records no capture commit | Header / Start Here | Implement | G1 | ✅ |
| F15 | 🟡 Medium | Clarity and Structure | Merge pass never refreshes Start Here, Next Steps or Resume Prompt | Merging | Implement | G4 | ✅ |
| F16 | 🟡 Medium | Clarity and Structure | Durable sections not flagged as published; no form for outside paths | Output File / Writing Guidelines | Implement | G5 | ✅ |
| F17 | 🟡 Medium | Clarity and Structure | "The usage record" is undefined | Current State | Implement | G3 | ✅ |
| F18 | 🟢 Low | Clarity and Structure | `/ship-it` paragraph is hard to parse | Output File | Implement | G5 | ✅ |
| F19 | 🟢 Low | Clarity and Structure | Topic-to-filename rule ignores punctuation | Output File | Implement | G2 | ✅ |
| F20 | 🟢 Low | Clarity and Structure | Issue-harvest instructions repeated | Gathering State / Header | Skip | — | ❓ |
| F21 | 🟢 Low | Spelling and Grammar | 19 serial commas | Throughout | Implement | G6 | ✅ |
| F22 | 🟢 Low | Spelling and Grammar | "url"/"urls" lowercase in the template | Header | Implement | G1 | ✅ |
| F23 | 🟢 Low | Spelling and Grammar | Stray comma before "and" | Writing Guidelines | Implement | G5 | ✅ |
| F24 | 🟢 Low | Staleness | Example model IDs and a configuration-specific tool name | Several | Skip | — | ❓ |
| F25 | ℹ️ Observation | Accuracy | Shell and `gh` claims verified | Output File / Gathering State | — | — | — |
| F26 | ℹ️ Observation | Clarity and Structure | Distinctions that prevent the costliest errors | Completed Work / Dead Ends / Decisions | — | — | — |
| F27 | ℹ️ Observation | Formatting | Nested fence and code spans built correctly | Resume Prompt / Recording the Capturing Model | — | — | — |
| F28 | 💡 Observation | Accuracy | `/doc-review` scrub patterns lag this file | Output File (vs `doc-review.md`) | — | — | — |
| F29 | 💡 Observation | Accuracy | References example cites a real repository | References | — | — | — |

## Pre-Merge Checklist

### G1 ✅ — Settle the header format

Decide first: F2's ruling sets how the F14 commit line and the F22 placeholders are written, and F5
describes the header's shape. F2 is now ruled (table), so the group's members are unblocked.

- [x] ✅ F2 - Header field format (changed to a two-column table)
- [x] ✅ F5 - Say Header fields sit under the H1 with no heading and sections follow listed order
- [x] ✅ F14 - Add a capture **Commit** header line and compare against it in Start Here
- [x] ✅ F22 - Capitalize "URL"/"URLs" in the Header placeholders

### G2 ✅ — Make the existing-handoff lookup find the right file

Highest severity outside G1, and the smallest High-severity group: one command and the three bullets
beside it.

- [x] ✅ F10 - Anchor the `find` lookup to `git rev-parse --show-toplevel`
- [x] ✅ F13 - Recast lookup bullets around coverage; settle explicit path versus existing file
- [x] ✅ F19 - Drop characters other than letters, digits and dashes when deriving the filename

### G3 ✅ — Make Gathering State produce every fact Current State records

Same severity as G2 but a larger edit spanning the gathering block and the provenance paragraph.

- [x] ✅ F11 - Range against the remote-tracking base ref; qualify the stacked-branch claim
- [x] ✅ F12 - Surface `gh` failures and mark an assumed base or unchecked pull request as such
- [x] ✅ F4 - Add collectors for comments, worktrees, branches and issue state, or drop those bullets
- [x] ✅ F17 - Replace "the usage record" with the reason itself; define "beside the section"
- [x] ✅ F1 - Keep the `git --no-pager status --short --branch` code span on one line

### G4 ✅ — Refresh orientation on a merge pass

Builds on G1: the new merge step should also update the **Commit** line F14 adds.

- [x] ✅ F15 - Add a merge step to rewrite Start Here and Resume Prompt and renumber Next Steps

### G5 ✅ — Align the `/ship-it` and artifact guidance

Medium severity; three edits to the same `/ship-it` paragraph and its echoes in Key Files, Merging
and Writing Guidelines.

- [x] ✅ F6 - Name the same plan-file set in Output File, Key Files and Merging; fix "all three"
- [x] ✅ F16 - Say durable sections are published; give a `~`-prefixed form for outside paths
- [x] ✅ F18 - Split the `/ship-it` paragraph and resolve the ambiguous "it"
- [x] ✅ F23 - Remove the comma in "Absolute dates only, and"

### G6 ✅ — Tidy house-style details

Lowest severity and touches nothing the other groups depend on; do it last so the serial-comma sweep
also covers text the earlier groups rewrite.

- [x] ✅ F3 - Use bold for the section cross-reference in Arguments
- [x] ✅ F7 - Add `--no-pager` to Start Here's `git status`
- [x] ✅ F21 - Remove the 19 serial commas

### Not recommended for this revision

- [ ] ❓ F8 - Standardize stale-verification wording (Skip — each variant reads clearly in context)
- [ ] ❓ F9 - Reduce the CLAUDE.md paraphrase to a pointer (Skip — short and currently accurate)
- [ ] ❓ F20 - Deduplicate the issue-harvest instructions (Skip — each copy sits where it is used)
- [ ] ❓ F24 - Genericize example model IDs and the Linear tool name (Skip — illustrative only)
