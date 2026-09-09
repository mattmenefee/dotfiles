# Document Review

Review the following document for quality, using the **documentation-expert** agent:

**Document:** `$ARGUMENTS`

## Reading the Document

For large documents — especially PDFs — choose a reading strategy before reviewing:

- **Text-heavy PDFs:** convert first with `pdftotext document.pdf document.txt` (add `-layout` to
  preserve columns), then `Grep` the text for navigation. No page limit, fast to search, but loses
  table/visual formatting.
- **Table- or form-heavy PDFs:** use the `Read` tool's `pages` parameter (max 20 pages per request;
  required for PDFs over 10 pages). It renders pages as images, so it captures tables and diagrams
  accurately.
- **Very large documents:** read disjoint page ranges in parallel subagents (e.g. `1-20`, `21-40`)
  to cut wall-clock time at the cost of more context.

The documentation-expert originates every finding and writes the review file itself, and it does not
read this command — it reads the prompt you compose from it. Silence about the status rule is
therefore not neutral: restate in the prompt that every actionable finding enters at **❓ Open**
whatever its recommendation, that ⏸️ and 🚫 may be written only after the user confirms that
specific finding, and that the summary table's Status column carries ❓ rather than a blank cell or
an em dash. On a re-review, also restate the preservation half: existing statuses carry over
unchanged, and a finding still marked ❓ Open stays ❓ Open unless the re-review shows it fixed. A
cross-reference to a section of this file reaches nobody. See Status Records a Decision, Not a
Recommendation.

Carry the same way the four implementation-group rules — Membership, Identifiers, Order and
Completion — together with the worked checklist example beneath them, since that example carries the
checkbox-plus-glyph shape the four rules do not state on their own. Carry the ⚖️ Decision's
**Options** line as well: it replaces the Recommendation, and a reviewer that never learns of it
either omits the alternatives or invents a recommendation the finding is not allowed to have.

Instruct the documentation-expert to perform a thorough review covering:

## Formatting

- **Markdown syntax** — Correct use of headings, lists, code blocks, tables, and links
- **Heading hierarchy** — Logical nesting (no skipped levels, consistent style)
- **Whitespace and spacing** — Consistent blank lines, no trailing whitespace, proper list
  indentation
- **Code blocks** — Correct language tags, properly formatted inline code
- **Tables** — Aligned columns, correct syntax, consistent formatting

## Consistency

- **Terminology** — Same concepts use the same terms throughout (no mixing synonyms inconsistently)
- **Capitalization** — Consistent casing for product names, features, and section titles
- **Formatting patterns** — Consistent use of bold, italics, and code formatting for similar
  elements
- **Tone and voice** — Consistent level of formality and perspective (first vs third person)
- **List style** — Consistent use of ordered vs unordered lists, punctuation at end of items
- **Cross-section consistency** — Information stated in one section does not contradict or conflict
  with information in another section (e.g., a summary that doesn't match the details, or repeated
  instructions that diverge)

## Accuracy

- **File paths and references** — Verify referenced files, directories, and commands exist in the
  codebase where possible
- **Code examples** — Check that code snippets match the actual codebase patterns and conventions
- **Cross-references** — Internal links and section references are valid
- **Technical claims** — Flag any statements that appear incorrect or outdated

## Clarity and Structure

- **Organization** — Logical flow of information, appropriate use of sections
- **Completeness** — No obvious gaps or missing context for the intended audience
- **Conciseness** — Flag verbose or redundant sections
- **Audience alignment** — Language and detail level appropriate for the target reader
- **Actionability** — For instructional or how-to content: are steps followable in order? Are
  prerequisites stated? Are expected outcomes described so the reader knows if they succeeded?
- **Examples** — Flag complex concepts or procedures that lack concrete examples to illustrate usage

## Sensitive Information

- **Secrets and credentials** — Flag any API keys, tokens, passwords, or connection strings that
  appear to be real (not placeholders)
- **Internal URLs and IPs** — Flag internal hostnames, IP addresses, or URLs that should not be in
  documentation
- **PII** — Flag personally identifiable information (names, emails, phone numbers) that may have
  been included accidentally

Findings in this category are reported to the user in conversation and **withheld from any published
comment** — see PR Comment Format. Flag them fully in the local artifact; the published record
carries only a count.

## Spelling and Grammar

- **Typos and misspellings** — Flag spelling errors in prose (not code/commands)
- **Grammar** — Flag grammatical errors and awkward phrasing
- **Punctuation** — Inconsistent or missing punctuation in sentences and lists

## Staleness

- **Hardcoded dates** — Flag specific dates that may become outdated
- **Version numbers** — Flag pinned versions of tools, languages, or frameworks that may need
  updating
- **Deprecated references** — Flag mentions of tools, APIs, libraries, or practices that are known
  to be deprecated or superseded

## Output

### Review File

Write the review to a **Markdown file in the project root**. Derive the filename from the document
being reviewed: lowercase the name, convert spaces to dashes, drop the original extension, and
append `-DOC-REVIEW.md` (e.g., `San Rafael Loan Agreement.pdf` →
`san-rafael-loan-agreement-DOC-REVIEW.md`). This file is the working artifact for the review —
update it in place as findings are addressed during the conversation.

- **Create** the file if it doesn't exist
- **Merge** with existing findings if the file already exists (see below)

**IMPORTANT: Never delete findings.** Findings are a permanent record of what was reviewed. When a
finding is addressed, mark it with strikethrough and a status icon (✅ Fixed, 🚫 Ignored, ⏸️ Deferred)
— but preserve the original content. ✅ Fixed may be applied on your own reading; 🚫 Ignored and
⏸️ Deferred only after the user confirms that specific finding. This follows the same convention as
`/local-review` (a code review command available in project repositories).

### Document Header

Include a metadata header at the top of the review file with context about the review. Run
`git branch --show-current` and `git rev-parse --short HEAD` to populate the branch and commit
fields.

```markdown
# Document Review: [document name]

| | |
|---|---|
| **Document** | `path/to/document.md` |
| **Branch** | `feature-branch-name` |
| **Commit** | `abc1234` |
| **Reviewed** | YYYY-MM-DD |
| **Reviewed by** | Opus 5 (`claude-opus-5[1m]`) |

## Review History

### YYYY-MM-DD — Initial review
```

When re-reviewing, update the **Commit** and **Reviewed** fields to reflect the current state, and
append to the Review History. The commit field is what makes a stale finding diagnosable later: it
records the revision the reviewer actually read, so a reference that no longer resolves can be
traced to a change in the document rather than an error in the review.

### Recording the Reviewing Model

The review record captures **which Claude model produced it**, so a reader can later judge how much
weight it deserves. The `model:` alias in the documentation-expert's frontmatter is not sufficient
evidence: an alias such as `opus` resolves to a different model as new models ship, and can resolve
downward at runtime if the preferred model is unavailable. Only the resolved model identifies the
review's actual capability.

Instruct the documentation-expert to take the model from its own environment context, which states
both the display name and the exact model ID, and to record it verbatim in the header's
**Reviewed by** field — including any context-window or snapshot suffix. Do not infer it from
frontmatter and never guess: if it cannot determine its own model it must record `unknown`, because
a wrong entry in the record is worse than a missing one.

On a re-review, note the model in the Review History entry as well. A document reviewed by
different models at different times is exactly the case this field exists to expose.

### Merging with Existing Findings

When the review file already exists:

1. **Read the existing file first** to understand current findings and their status
1. **Preserve existing finding numbers** — don't renumber resolved findings
1. **Preserve status markers** — keep ✅ Fixed, 🚫 Ignored, ⏸️ Deferred markers and their associated
   content intact. A finding still marked ❓ Open stays ❓ Open unless the re-review shows it fixed;
   a re-review is not a decision
1. **Add new findings** with the next sequential number (e.g., if F1–F4 exist, new findings start at
   F5)
1. **Keep the implementation groups current** — a new finding recommended Implement joins the
   existing group whose edit it shares, or opens a new group with the next free identifier. Never
   renumber a group; re-sort the groups only when a dependency changed, and say so in the Review
   History entry. Check off a group whose members are all off the pre-merge path, in the
   `### G3 ✅ — …` form defined under Implementation groups, and un-check one that was checked and
   has since gained an open member — a completed group that a later round reopens reads as done to
   anyone scanning the headings for what is left
1. **Refresh citations** — every reference was written against an earlier revision of the document
   and may have moved. Re-locate each open finding's reference against the current document and
   correct it in place before judging whether the finding still holds; a citation that no longer
   resolves is evidence the document changed, not that the finding was addressed
1. **Update findings** if re-review shows they're now resolved or still present
1. **Strike through findings** that are no longer applicable (e.g., the section they referenced has
   been deleted or rewritten) — do **not** remove them; apply strikethrough and add a brief
   explanation of why. Because strikethrough marks a finding as decided, it must carry a status
   glyph so the finding stays countable: strike it as ✅ Fixed only when the condition it describes
   is verifiably gone. A rewrite that merely moved the text is not evidence of a fix — leave it
   ❓ Open and say so in the explanation
1. **Append a Review History entry** — one entry per review run, newest last, each recording the
   date and what the run changed. Leave earlier entries untouched: they record the state that
   produced those findings, and rewriting one destroys the only evidence of what an earlier review
   actually saw. Update the header's **Commit**, **Reviewed** and **Reviewed by** fields to the
   current run:

   ```markdown
   ## Review History

   ### YYYY-MM-DD — Initial review

   ### YYYY-MM-DD — Re-review (findings F1, F2 fixed; F5–F6 added)
   ```

### Severity Indicators

Use the same severity conventions as `/local-review` (code review command) for quick visual
scanning:

**Actionable findings** (require attention):

- 🔴 **Critical** — Must fix (sensitive information exposure, factual errors that could cause harm,
  broken instructions that lead readers astray)
- 🟠 **High Priority** — Should fix (inaccurate technical claims, missing critical context,
  cross-section contradictions)
- 🟡 **Medium Priority** — Should address (inconsistent terminology, formatting issues, unclear
  instructions, staleness)
- 🟢 **Low Priority / Nice-to-Have** — Can address later (minor typos, style preferences, missing
  examples)

**Decisions** (need the user before anyone acts — appear in the checklist):

- ⚖️ **Decision** — The document is not wrong, but a choice between defensible alternatives is open
  and only the user can settle it (which of two conventions to standardize on, which audience a
  section is written for). The finding states the choices and what each costs in an **Options** line
  in place of a Recommendation, because the decision is the user's rather than the reviewer's. A
  re-review never resolves one on its own — re-reading a document cannot establish a decision that
  was never taken — so it stays ❓ Open until the user rules on it.

**Observations** (not required to resolve the review — never appear in the checklist):

- ℹ️ **Observation** — Highlights a well-written section, good pattern, or structural choice worth
  noting
- 💡 **Observation (optional action)** — Something reads correctly but a small, optional improvement
  is available; state the action inline. Keep genuine praise (ℹ️) distinct from latent suggestions
  (💡) so neither drowns out the other.

**Actionable** means 🔴🟠🟡🟢 *and* ⚖️ — everything that needs someone to act or to rule, as against
the ℹ️ and 💡 observations that need neither. Use the word rather than repeating the glyph list: the
list was written before ⚖️ existed, so every copy of it silently excludes decisions and drops them
out of the checklist. Where a rule genuinely applies to fixable findings but not to decisions, say
"actionable finding other than a ⚖️ Decision" rather than falling back to the four glyphs.

### Recommendations

Severity and recommendation are different axes: severity measures how much the issue matters; the
recommendation measures whether acting on it *now* is worth the cost. A finding can be valid yet not
worth implementing — rewriting a section that is about to be superseded, a terminology sweep through
a document nobody reads, a stylistic preference with no effect on the reader. Say so plainly rather
than implying every finding must be fixed. Use one of:

- **Implement** — worth doing in this revision; benefit clearly exceeds cost
- **Defer** — legitimate, but better as a follow-up (out of scope, needs a broader rewrite, or not
  urgent)
- **Skip** — not worth doing; the cost (churn, review time, risk of introducing new errors)
  outweighs the gain. Prefer this over a half-hearted "could fix" when the value is marginal

The Recommendation value **Skip** is unrelated to the `skip` keyword the interactive prompt accepts.
That keyword is a fix selection meaning "fix none of these right now": answering it never writes a
Recommendation onto a finding and never changes one already recorded. The two words coincide and
nothing more — see Interactive Finding Selection.

A ⚖️ Decision is the one actionable finding that takes no recommendation — the reviewer has no
advice to give until the user settles the choice. It carries an **Options** line in place of the
Recommendation, laying out the alternatives and what each costs, and its Recommendation cell in the
summary table reads `Options`.

State the recommendation with a one-line rationale. Every actionable finding other than a ⚖️
Decision must carry one. ℹ️ observations carry no recommendation; 💡 observations state the optional
action inline. When
severity and recommendation diverge — a 🟢 Low recommended **Implement**, or a 🟠 High recommended
**Defer** — that divergence is the useful signal; surface it rather than smoothing it over.

### Numbered Findings

Number all findings sequentially (F1, F2, F3, ...) across all categories. Present findings grouped
by category (Formatting, Consistency, Accuracy, Clarity, Sensitive Information, Spelling/Grammar,
Staleness). Omit categories with no findings.

Use the format: `### F1 🟡 Medium Priority - Description`

For each finding, include:

- **Location** — Section heading or line reference
- **Issue** — Clear description of the problem
- **Suggestion** — Concrete fix or improvement
- **Recommendation** — Implement / Defer / Skip, plus a one-line rationale (every actionable
  finding other than a ⚖️ Decision)
- **Options** — For a ⚖️ Decision only, in place of the Recommendation: the alternatives and what
  each costs

When a suggestion quotes Markdown that itself contains a fenced code block, open and close the
outer fence with **four** backticks. A three-backtick outer fence is closed by the inner block's
closing fence, which silently swallows every following finding into a code block until the next
fence. The damage lands on the findings *after* the one that caused it, so it is easy to
misattribute — and a document review quotes Markdown far more often than a code review does.

Redact rather than quote when the evidence is itself sensitive — a credential, token, connection
string, internal hostname, IP address, email address, personal name, customer datum, or the name or
URL of a private repository. Name the section and line and describe the value's shape; do not
reproduce it. The list is deliberately wider than the scrub's patterns, which match paths only: an
authoring rule that stops at credentials leaves every other category to a backstop that was never
built to catch it.

This rule governs every artifact `/ship-it` publishes, not just the one this command writes — it
posts `local-review.md` and `PLAN.md` whole as well, and the scrub's own filename list in PR Comment
Format is the proof that an authoring rule scoped to a single file is scoped too narrowly.

The artifact **may** be published verbatim into a pull request comment — PR Comment Format says when
— and `/ship-it` deletes the local copy once it has posted it, so a quoted secret outlives both the
file and the fix. Neither step is unconditional, and neither is performed by this command; state the
rationale that way rather than asserting a publication this file cannot promise. The scrub in PR
Comment Format is the backstop at publishing time; this rule keeps the value out of the artifact in
the first place.

### Tracking Finding Status

Every actionable finding carries a status recording what was decided about it. Mark decided findings
visually while preserving the original content for reference. ℹ️ and 💡 Observation findings do not
require status tracking.

**Status indicators:**

- ❓ **Open** — Not yet decided, or decided to fix but not yet fixed. Every actionable finding starts
  here
- ✅ **Fixed** — The issue has been resolved
- 🚫 **Ignored** — Explicitly decided not to address (include reason)
- ⏸️ **Deferred** — Will address later

### Status Records a Decision, Not a Recommendation

A finding's **Recommendation** is the reviewer's advice about whether acting now is worth the cost.
Its **Status** records what the user decided. **Never derive the second from the first.**

- New actionable findings always enter at **❓ Open**, however minor the finding or however
  dismissive its recommendation
- **⏸️** and **🚫** may be written only after the user confirms that specific finding. Never infer
  the decision from a **Defer** or **Skip** recommendation, and never prompt for it — the reader
  raises it unprompted and you record it
- **✅** may be applied without asking — it asserts a verifiable fact about the document, not a
  decision
- Leave no Status cell blank or `—` for an actionable finding; either reads as "nothing to decide
  here" and quietly closes the finding. The em dash is reserved for ℹ️ and 💡 observations, where no
  status applies

The two columns are meant to be read together. **Skip** with ❓ says "the reviewer thinks this is not
worth doing, and nobody has agreed yet". **Skip** with 🚫 says "that call has been made". Collapsing
them loses the distinction between advice and consent. The vocabulary is deliberate and not an
inconsistency to resolve: **Skip** is a Recommendation value, **🚫 Ignored** is a Status value, and
there is no "Skipped" status. Prose that calls a finding "skipped" is naming a recommendation, never
a decision — rewrite it to say "ignored" rather than adding Skip to the status glossary.

A ⚖️ Decision follows the same rule with one difference: for it, the decision *is* the fix. It
enters at ❓ and stays there until the user rules. Once they do it is ✅, with the outcome in the
parenthetical — "kept as-is" or "changed to …" — and if the ruling requires an edit, ✅ waits until
that edit is in the document. ⏸️ records that the user pushed the decision to a follow-up. 🚫 is
never written for a ⚖️: a decision cannot be ignored, only made or deferred. Because ✅ on a ⚖️
records the user's ruling rather than a verifiable fact about the document, it is the one ✅ that may
not be applied without asking.

This binds the summary table and the checklist equally. Pre-populating either silently closes
findings the user never saw.

**How to mark findings:**

Apply strikethrough to the finding heading (excluding the finding number) and add the status icon to
the right. Do **not** delete the finding content — preserve it for reference. Strikethrough marks a
finding as decided, so an ❓ Open finding keeps its plain heading.

```markdown
### F1 ~~🟡 Medium Priority - Inconsistent terminology~~ ✅ Fixed

**Location:** Section "Getting Started"
**Status:** Fixed — standardized on "deploy" throughout
...original finding content preserved...
```

In the checklist, keep every item a checkbox and put its status glyph **immediately after the box**,
so the leading column can be scanned for what is still open. Check the box for anything off the
pre-merge path — fixed, deferred and ignored all qualify — and let the glyph say which.

On entry every actionable finding is unchecked and ❓ Open, whatever the review recommended:

```markdown
- [ ] ❓ F2 - Add the missing prerequisite
- [ ] ❓ F3 - Rewrite the API table
- [ ] ❓ F4 - Add Oxford commas
```

Once a finding is decided, check the box and swap ❓ for the status glyph:

```markdown
- [x] ✅ F2 - Add the missing prerequisite (fixed)
- [x] ⏸️ F3 - Rewrite the API table (deferred to the next revision)
- [x] 🚫 F4 - Add Oxford commas (ignored — house style omits them)
```

Never use a bare glyph bullet (`- 🚫 F4 …`) and never trail the glyph at the end of the line.
Markdown renders `- [ ]` flush left but an ordinary `-` bullet with extra indent, so a list mixing
the two forms gets two left margins, destroying the very column the glyphs exist to create.

### Consolidated Summary

At the end, provide:

1. **Summary table** of all findings:

| Finding | Priority | Category | Description | Location | Recommendation | Group | Status |
| --------- | ---------- | ---------- | ------------- | ---------- | ---------------- | ------- | -------- |
| F1 | 🔴 Critical | Accuracy | Flag order in the install command | Installation | Implement | G2 | ❓ |
| F2 | 🟡 Medium | Accuracy | Missing prerequisite | Installation | Implement | G2 | ✅ |
| F5 | ⚖️ Decision | Clarity | Whether Quick Start covers the Docker path | Quick Start | Options | G1 | ❓ |
| F6 | 🟢 Low | Clarity | Troubleshooting section is thin | Troubleshooting | Skip | — | ❓ |
| F10 | ℹ️ Observation | Clarity | Quick Start's worked example is clear | Quick Start | — | — | — |

This is the same finding set the Pre-Merge Checklist below uses, so the two views can be read against
each other. The **Group** column carries the finding's implementation group, or `—` when it is
ungrouped — a finding recommended Defer or Skip, or an observation. An em dash there says nothing
about status: F6 is ungrouped and still ❓, because Skip is advice and nobody has agreed to it yet.

1. **Overall assessment** - Brief summary of document quality

1. **Checklist** - Convert every actionable finding into a checklist organized into implementation
   groups — see Pre-Merge Checklist below.

### Pre-Merge Checklist

Convert every **actionable** finding into a concrete checklist, organized into **implementation
groups**. Do not include ℹ️ or 💡 Observation findings in the checklist — neither requires action.
Items enter at `- [ ] ❓` — see Status Records a Decision, Not a Recommendation.

#### Implementation groups

A group is a set of findings that are revised together: the same edit, the same section, the same
root cause, or a dependency chain ("settle F5 first, then re-evaluate F9"). A flat list leaves the
batches to be reconstructed from status lines after the fact — "folded into the F7 edit", "same edit
fixes F1 and F2". The checklist states them up front instead.

- **Membership.** Every finding recommended **Implement** belongs to exactly one group, as does
  every ⚖️ Decision and every finding whose fix depends on one. Findings recommended **Defer** or
  **Skip** are listed after the groups under **Not recommended for this revision**, still at ❓,
  because the recommendation is advice and the user may take them anyway.
- **Identifiers.** Groups are numbered `G1`, `G2`, … and the number is permanent: a group is never
  renumbered, and a later round that adds a group takes the next free number even if it sorts
  earlier. Work the groups in the order they appear in the checklist, not in numeric order — after a
  re-review the two can differ, and a checklist that reads G1, G4, G2, G3 is correct. Refer to a
  group by its identifier in the summary table's Group column, in conversation ("do G2 next") and in
  commit messages.
- **Order.** Sort the groups by, in turn: any ⚖️ Decision, and whatever depends on it, first, since
  nobody can act until the user rules; then a group that other groups build on — a terminology
  choice, a section others cross-reference — ahead of its dependents; then by the highest severity in
  the group; then smallest first, so quick wins land before larger edits of equal weight. Write the
  reason for each group's position in one line under its heading. A reader should never have to guess
  why one group precedes another.
- **Completion.** A group whose members are all off the pre-merge path is checked off at its heading
  by placing a ✅ between the identifier and the em dash — `### G3 ✅ — Tidy the appendix`. The members
  keep their own boxes and glyphs. Do not reach for task-list syntax here: GFM renders `- [ ]` and
  `- [x]` only on list items, so `### [x] G3 — …` prints a literal `[x]`, and promoting the group to
  a list item is ruled out by the mixed-form rule under Tracking Finding Status.

Every item is a checkbox followed immediately by its status glyph, exactly as Tracking Finding
Status requires, so the leading columns read as one scannable strip:

```markdown
### G1 — Settle the Quick Start's scope

Decide first: F7 and F9 both change shape depending on the ruling.

- [ ] ❓ F5 - Whether Quick Start covers the Docker path (options: document both / native only)
- [ ] ❓ F7 - Add or drop the Docker prerequisites, per F5
- [ ] ❓ F9 - Rewrite the Quick Start intro to match F5's scope

### G2 — Correct the installation steps

Highest severity outside G1; one section, two adjacent paragraphs.

- [ ] ❓ F1 - Fix the flag order in the install command
- [x] ✅ F2 - Add the missing prerequisite (fixed)

### G3 ✅ — Tidy the appendix

Lowest severity of the three, and it touches nothing the others do. Both members were recommended
Implement and the user then ruled on each, which is why they sit in a group rather than under Not
recommended —
Membership routes by the recommendation, not by where the status later lands.

- [x] ⏸️ F3 - Rewrite the API table (deferred to the next revision)
- [x] 🚫 F4 - Add Oxford commas (ignored — house style omits them)

### Not recommended for this revision

- [ ] ❓ F6 - Expand the troubleshooting section (Skip — no reader has reported hitting it)
- [ ] ❓ F8 - Split the reference page (Defer — the sibling page is not in this branch)
```

### PR Comment Format

When posting review findings as a PR comment (e.g., during `/ship-it` or when explicitly asked),
build a temporary file with a collapsible `<details><summary>` wrapper and post it with
`--body-file` to avoid heredoc quoting issues.

Scrub the review document before building the comment. This artifact is written by an agent reading
a developer machine, and a finding that traces where a global command or a user-level agent resolves
from will cite an absolute path under the home directory. Check here rather than trusting the review
stage, because this is the step that publishes:

```bash
review_file="$(git rev-parse --show-toplevel)/<name>-DOC-REVIEW.md"
[ -r "$review_file" ] || { echo "scrub: cannot read $review_file" >&2; exit 1; }

grep -nE '/Users/|/home/|/private/tmp/|/var/folders/' /dev/null "$review_file"
rc=$?
[ "$rc" -le 1 ] || { echo "scrub FAILED (grep exit $rc) — do not post" >&2; exit 1; }
```

Define `$review_file` in the same block and make its absence fatal. Left undefined it is not an
error: `grep` warns on stderr, prints no match lines and — under a trailing `|| true` — exits 0, so
the scrub certifies a document it never opened. A block in a command file gets copied verbatim, so
it has to carry its own preconditions.

The `/dev/null` argument keeps `grep` printing the filename. Branch on the exit code rather than
swallowing it: `grep` exits 1 when it matches nothing, which is the benign case the scrub is written
around, but 2 when it cannot read the file. `|| true` collapses both to success, rewriting a read
failure into a clean bill of health — the exact fail-open this section exists to prevent, and a
warning on stderr is easy for an agent scanning for `file:line:` output to disregard.

**Empty output means nothing matched only if `grep` actually ran.** At least four paths produce no
output: nothing matched, which is the intended one; the file could not be read; `find` matched zero
files; and the wrong directory was scanned. Only the first is clean. Treat the others as a failed
scrub and do not post — which is what the readability check, the exit-code branch and the echoed
file list below are each there to make visible.

When scrubbing a set of artifacts rather than one named file, match them with `find` rather than a
shell glob, and match `local-review*.md` rather than the exact name:

```bash
root="$(git rev-parse --show-toplevel)"
scanned="$(find "$root" -maxdepth 1 \
  \( -name 'local-review*.md' -o -name '*-DOC-REVIEW.md' -o -name 'PLAN.md' \) -print)"
[ -n "$scanned" ] || { echo "scrub: no artifacts under $root — nothing was scanned" >&2; exit 1; }
printf 'scrub: scanned these files\n%s\n' "$scanned"

find "$root" -maxdepth 1 \
  \( -name 'local-review*.md' -o -name '*-DOC-REVIEW.md' -o -name 'PLAN.md' \) \
  -exec grep -nE '/Users/|/home/|/private/tmp/|/var/folders/' /dev/null {} +
rc=$?
[ "$rc" -le 1 ] || { echo "scrub FAILED (grep exit $rc) — do not post" >&2; exit 1; }
```

`find` does the matching so the shell never expands the glob. An unmatched `*-DOC-REVIEW.md` inside
a single `grep` command aborts that command outright under zsh, and `2>/dev/null` does not suppress
it, because the shell reports the failed expansion before the redirection applies — the scrub then
silently does not run at all. A branch-suffixed review document is a deliberate convention, so
matching the exact name would leave the artifact unopened, printing nothing and reading as clean.

Anchor the scan to `git rev-parse --show-toplevel`, not to `.`. The artifact is written to the
project root while `find .` scans wherever the agent happens to be, and `-maxdepth 1` makes that
miss total rather than partial — one `cd`, a subdirectory, or a review agent running in an isolated
worktree is enough to scan an empty set. Capture the file list and fail loudly when it is empty,
then echo what was scanned: `find … -exec … +` never invokes `grep` when it matches nothing, so it
prints nothing and exits 0, byte-identical to a genuinely clean scan. The `find` form was adopted to
stop the scrub silently not running, and without these two lines it reintroduces the same silence
through a different door. Listing the files scanned is what makes the verdict checkable rather than
merely quiet.

Rewrite each hit **in the review document** before building the comment — `~`-prefixed when the path
genuinely lies outside the repository, repo-relative when it does not. Fixing the comment afterwards
does not undo the disclosure: GitHub keeps the pre-edit revision in the comment's edit history,
readable by anyone with repo access, and the only complete remedy is to delete the comment and
repost it under a new URL.

A hit that is an illustrative placeholder carrying no real username — `/Users/<name>/…` quoted from
the rule itself — is already redacted; leave it and move on. Any review of these command files will
carry one, and rewriting it turns a quoted rule into something that no longer says what the rule
says.

While rewriting the hits, read what surrounds them. The patterns match paths, not secrets, so a
credential reaches this step only by sharing a line with one. If anything credential-shaped is
there, stop before posting anything and tell the user.

This section is the **normative definition** of the scrub, and every other command that publishes
these artifacts carries its own copy of it — notably a project's `/ship-it`, which posts
`local-review.md`, `*-DOC-REVIEW.md` and `PLAN.md` together and then deletes them, so it publishes
two artifacts this command never writes. Duplicate the check into each publisher; do not
cross-reference this section. A cross-reference between command files reaches nobody — the same
reason the status rule is restated in the prompt at the top of this file — and the agent running
`/ship-it` never reads this one. Duplication costs a few lines; a missing scrub costs a disclosure
that cannot be undone once posted.

**Withhold the body of every `## Sensitive Information` finding from the comment.** The redaction
rule keeps the *value* out of the artifact but it does not remove the *pointer*, and the pointer is
enough: a published finding reading "the connection string at line 42 of `deploy.md` is live" is a
targeting instruction for anyone with repository access, and it survives in the comment's edit
history even if the comment is deleted. Report those findings to the user in conversation, and
represent them in the comment as a neutral count only:

```text
1 Sensitive Information finding — withheld from this comment; see the local artifact
```

Excise the section before the body is assembled, not after — the block below pipes the artifact in
whole, so a rule applied to the finished comment has already published what it meant to withhold.
This is the one finding category where succeeding at the job is what creates the exposure: the
command is most dangerous exactly when it works.

Then build the comment:

```bash
comment_file="$(mktemp -t pr-comment)"
trap 'rm -f "$comment_file"' EXIT

body="$(cat "$review_file")" || { echo "cannot read $review_file" >&2; exit 1; }
[ -n "$body" ] || { echo "review body is empty — refusing to post" >&2; exit 1; }

{
  echo "## Document Review: [document name] — [status summary]"
  echo ""
  echo "**[N findings — X actionable, Y observations]**"
  echo ""
  echo "<details>"
  echo "<summary>Click to expand full review details</summary>"
  echo ""
  printf '%s\n' "$body"
  echo ""
  echo "</details>"
} > "$comment_file"
gh pr comment --body-file "$comment_file"
```

Read the body into a variable and assert it before wrapping it. Inside the group, a failing `cat`
sends its error to stderr and the group's exit status is the trailing `echo`'s, so an unreadable
`$review_file` still produces a well-formed comment with a complete `<details>` scaffold, an empty
body, and a heading confidently claiming N findings — posted with no failure signal in stdout or
exit status. Checking the finished file with `[ -s ]` does not help, because the scaffold is
non-empty; the body itself is what has to be non-empty.

Use `mktemp`, not a fixed path. `> /tmp/pr-comment.md` follows a pre-existing symlink and clobbers
its target, so a stale or hostile link redirects the write and `--body-file` posts whatever the
target holds. Under the usual umask the file is created world-readable, nothing removes it, and two
concurrent reviews race on one name — so if the scrub failed, the unredacted body persists under a
guessable name after the artifact it came from was deleted, which is the one copy the threat model
assumes is gone. `mktemp` creates the file 0600 and will not follow a symlink; the `trap` removes it
on exit.

The `<summary>` line should include the total finding count and a breakdown that names every bucket
separately (e.g., "24 findings — 14 fixed, 2 ignored, 2 open, 8 observations"). A ⚖️ Decision still
awaiting the user is named on its own — "2 open (1 decision)" — because it needs a person, not a
fix. Deferred and ignored findings are off the pre-merge path but they are not resolved, so they
never fold into the fixed count, and neither do findings still ❓ Open. Reserve "all clear" for a
review in which every actionable finding is ✅ Fixed: "24 findings — 16 fixed, 8 observations — all
clear". Never write it while a 🔴 Critical, a 🟠 High or a ⚖️ Decision sits at any status other
than ✅ Fixed.

### Interactive Finding Selection

After displaying all review output, present the list of **actionable findings still marked ❓ Open**
(actionable, so including any open ⚖️ Decision — but not ℹ️ or 💡 observations, and not findings
already ✅ Fixed, ⏸️ Deferred or 🚫 Ignored), grouped as the checklist groups them, with any open
⚖️ Decision listed first under its own heading. A finding the user has already ruled on must not be
re-offered: putting it back in the list reopens a decision they made. Format the list as:

```text
Decisions needed:
F5 ⚖️ Decision - Whether Quick Start covers the Docker path (document both / native only)

G1 — Settle the Quick Start's scope
F7 🟡 Medium - Add or drop the Docker prerequisites (Quick Start)
F9 🟡 Medium - Rewrite the Quick Start intro (Quick Start)

G2 — Correct the installation steps
F1 🔴 Critical - Fix the flag order in the install command (Installation)

Not recommended for this revision
F6 🟢 Low - Expand the troubleshooting section (Troubleshooting)
F8 🟢 Low - Split the reference page (Reference)
```

This is the same finding set the Pre-Merge Checklist example uses, and the differences between the
two views are the rule at work rather than drift. F5 moves out of G1 to the Decisions heading while
G1 keeps its other members; F2 is gone because it is ✅ Fixed; and G3 has no heading at all because
both of its members are decided, one ⏸️ and one 🚫. Re-offering either would reopen a ruling the
user already made.

Ask the user which findings to fix. Accept finding numbers (e.g., "F1, F3"), group identifiers
(e.g., "G2"), "all", or "skip". A group identifier selects every open finding in that group; a ⚖️
Decision is never selected by "all" or by its group — it is answered, in the user's words, and the
answer is recorded.

While an unanswered ⚖️ sits in a group, that group's identifier selects nothing. Put the decision
first, ask it, record the ruling, and only then begin the member edits. Membership deliberately
co-locates a decision with the findings whose fix depends on it, and Order puts such a group first
because nobody can act until the user rules — so editing the members against an unmade ruling is
exactly the sequence the grouping exists to prevent, and it earns a rework of every member once the
ruling lands.

If the user selects one or more findings, edit the document directly to resolve them in group
order.

Answering "skip" here means "not fixing any of these right now" — it is **not** a decision to mark
anything 🚫 Ignored. Unselected findings stay ❓ Open in both the summary table and the checklist.

**Do not offer a Defer or Ignore option here, and do not ask whether a finding should be deferred or
ignored.** That is deliberate, not an omission: this prompt exists to pick fixes, and a decision to
defer or ignore arrives from the user unprompted, about a specific finding. Record it when it comes;
until then the finding stays ❓ Open. If something they have said is ambiguous, ask what they meant —
never prompt for the decision itself.
