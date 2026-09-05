# Document Review

Review the following document for quality, using the **documentation-expert** agent:

**Document:** `$ARGUMENTS`

The documentation-expert originates every finding and writes the review file itself, and it does not
read this command — it reads the prompt you compose from it. Silence about the status rule is
therefore not neutral: restate in the prompt that every actionable finding enters at **❓ Open**
whatever its recommendation, that ⏸️ and 🚫 may be written only after the user confirms that
specific finding, and that the summary table's Status column carries ❓ rather than a blank cell or
an em dash. On a re-review, also restate the preservation half: existing statuses carry over
unchanged, and a finding still marked ❓ Open stays ❓ Open unless the re-review shows it fixed. A
cross-reference to a section of this file reaches nobody. See Status Records a Decision, Not a
Recommendation.

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

### Merging with Existing Findings

When the review file already exists:

1. **Read the existing file first** to understand current findings and their status
1. **Preserve existing finding numbers** — don't renumber resolved findings
1. **Preserve status markers** — keep ✅ Fixed, 🚫 Ignored, ⏸️ Deferred markers and their associated
   content intact. A finding still marked ❓ Open stays ❓ Open unless the re-review shows it fixed;
   a re-review is not a decision
1. **Add new findings** with the next sequential number (e.g., if F1–F4 exist, new findings start at
   F5)
1. **Update findings** if re-review shows they're now resolved or still present
1. **Strike through findings** that are no longer applicable (e.g., the section they referenced has
   been deleted or rewritten) — do **not** remove them; apply strikethrough and add a brief
   explanation of why
1. **Update the review date** at the top of the document:

   ```markdown
   ## Review History
   - **Initial review:** YYYY-MM-DD
   - **Re-review:** YYYY-MM-DD (findings F1, F2 fixed; F5–F6 added)
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

**Observations** (not required to resolve the review — never appear in the checklist):

- ℹ️ **Observation** — Highlights a well-written section, good pattern, or structural choice worth
  noting
- 💡 **Observation (optional action)** — Something reads correctly but a small, optional improvement
  is available; state the action inline. Keep genuine praise (ℹ️) distinct from latent suggestions
  (💡) so neither drowns out the other.

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

State the recommendation with a one-line rationale. Every actionable finding (🔴🟠🟡🟢) must carry one.
ℹ️ observations carry no recommendation; 💡 observations state the optional action inline. When
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
- **Recommendation** — Implement / Defer / Skip, plus a one-line rationale (actionable findings
  only)

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
- [ ] ❓ F1 - Standardize terminology
- [ ] ❓ F2 - Add Oxford commas
- [ ] ❓ F3 - Rewrite the API section
```

Once a finding is decided, check the box and swap ❓ for the status glyph:

```markdown
- [x] ✅ F1 - Standardize terminology (fixed)
- [x] 🚫 F2 - Add Oxford commas (ignored — house style omits them)
- [x] ⏸️ F3 - Rewrite the API section (deferred to the next revision)
```

Never use a bare glyph bullet (`- 🚫 F2 …`) and never trail the glyph at the end of the line.
Markdown renders `- [ ]` flush left but an ordinary `-` bullet with extra indent, so a list mixing
the two forms gets two left margins, destroying the very column the glyphs exist to create.

### Consolidated Summary

At the end, provide:

1. **Summary table** of all findings:

| Finding | Priority | Category | Description | Location | Recommendation | Status |
| --------- | ---------- | ---------- | ------------- | ---------- | ---------------- | -------- |
| F1 | 🟡 Medium | Consistency | Example description | Section name | Implement | ❓ |
| F2 | 🟢 Low | Clarity | Example description | Section name | Skip | ❓ |
| F3 | ℹ️ Observation | Clarity | Example description | Section name | — | — |

1. **Overall assessment** - Brief summary of document quality

1. **Checklist** - Convert actionable findings (🔴🟠🟡🟢) into a checklist. Do not include ℹ️ or 💡
   Observation findings in the checklist — neither requires action. Items enter at `- [ ] ❓` — see
   Status Records a Decision, Not a Recommendation.

```markdown
- [ ] ❓ F1 - Fix description
- [ ] ❓ F2 - Fix description
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
grep -nE '/Users/|/home/|/private/tmp/|/var/folders/' /dev/null "$review_file" || true
```

The `/dev/null` argument keeps `grep` printing the filename. The trailing `|| true` keeps a clean
run from looking like a failure: `grep` exits 1 when it matches nothing, so without it the good
outcome — nothing to scrub — returns a failing status. No output means nothing to scrub.

When scrubbing a set of artifacts rather than one named file, match them with `find` rather than a
shell glob, and match `local-review*.md` rather than the exact name:

```bash
find . -maxdepth 1 \
  \( -name 'local-review*.md' -o -name '*-DOC-REVIEW.md' -o -name 'PLAN.md' \) \
  -exec grep -nE '/Users/|/home/|/private/tmp/|/var/folders/' /dev/null {} + || true
```

`find` does the matching so the shell never expands the glob. An unmatched `*-DOC-REVIEW.md` inside
a single `grep` command aborts that command outright under zsh, and `2>/dev/null` does not suppress
it, because the shell reports the failed expansion before the redirection applies — the scrub then
silently does not run at all. A branch-suffixed review document is a deliberate convention, so
matching the exact name would leave the artifact unopened, printing nothing and reading as clean.

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

Then build the comment:

```bash
{
  echo "## Document Review: [document name] — [status summary]"
  echo ""
  echo "**[N findings — X actionable, Y observations]**"
  echo ""
  echo "<details>"
  echo "<summary>Click to expand full review details</summary>"
  echo ""
  cat "$review_file"
  echo ""
  echo "</details>"
} > /tmp/pr-comment.md
gh pr comment --body-file /tmp/pr-comment.md
```

The `<summary>` line should include the total finding count and a breakdown (e.g., "24 findings — 14
fixed, 2 ignored, 8 observations"). Deferred and ignored findings are off the pre-merge path but
they are not resolved, so they never fold into the fixed count, and neither do findings still
❓ Open. Reserve "all clear" for a review in which every actionable finding is ✅ Fixed: "24 findings
— 16 fixed, 8 observations — all clear".

### Interactive Finding Selection

After displaying all review output, present the list of **actionable findings still marked ❓ Open**
(🔴🟠🟡🟢 — not ℹ️ or 💡 observations, and not findings already ✅ Fixed, ⏸️ Deferred or 🚫 Ignored).
A finding the user has already ruled on must not be re-offered: putting it back in the list reopens
a decision they made. Format the list as:

```text
F1 🔴 Critical - Description (location)
F3 🟡 Medium - Description (location)
F5 🟢 Low - Description (location)
```

Ask the user which findings to fix. Accept finding numbers (e.g., "F1, F3"), "all", or "skip". If
the user selects one or more findings, edit the document directly to resolve them in order.

Answering "skip" here means "not fixing any of these right now" — it is **not** a decision to mark
anything 🚫 Ignored. Unselected findings stay ❓ Open in both the summary table and the checklist.

**Do not offer a Defer or Ignore option here, and do not ask whether a finding should be deferred or
ignored.** That is deliberate, not an omission: this prompt exists to pick fixes, and a decision to
defer or ignore arrives from the user unprompted, about a specific finding. Record it when it comes;
until then the finding stays ❓ Open. If something they have said is ambiguous, ask what they meant —
never prompt for the decision itself.
