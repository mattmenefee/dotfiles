# Document Review: 28 files on convert-commands-to-skills

| | |
| --- | --- |
| **Scope** | The changes on this branch (base d22496a): 18 Markdown documents, each with its own reviewer, plus the 10 shell scripts in the change, reviewed by security, code-quality and test reviewers |
| **Branch** | `convert-commands-to-skills` |
| **Reviewed** | 2026-10-24 |
| **Reviewed by** | Opus 5.5 (`claude-opus-5-5`) |
| **Collated by** | Opus 5.5 (`claude-opus-5-5`) |

## Documents

| Document | Commit |
| --- | --- |
| `home/.claude/CLAUDE.md` | `1d26aa3` |
| `.claude/skills/ship-it/SKILL.md` | `1d26aa3` |
| `home/.claude/agents/documentation-expert.md` | `5af2aa1` |
| `home/.claude/skills/commit/SKILL.md` | `1d26aa3` |
| `home/.claude/skills/doc-review/SKILL.md` | `5af2aa1` |
| `home/.claude/skills/doc-review/reviewer-rules.md` | `5af2aa1` |
| `home/.claude/skills/doc-review/review-file.md` | `5af2aa1` |
| `home/.claude/skills/doc-review/posting.md` | `d1d0f27` |
| `home/.claude/skills/doc-review/walkthrough-example.md` | `5af2aa1` |
| `home/.claude/skills/handoff/SKILL.md` | `e2ce58b` |
| `home/.claude/skills/resume-handoff/SKILL.md` | `e2ce58b` |
| `home/.claude/skills/update-deps/SKILL.md` | `17e65df` |
| `home/.claude/skills/update-deps/javascript.md` | `17e65df` |
| `home/.claude/skills/update-deps/terraform.md` | `17e65df` |
| `home/.claude/skills/update-deps/pins.md` | `17e65df` |
| `home/.claude/skills/update-deps/linters.md` | `17e65df` |
| `home/.claude/skills/update-deps/version-locked.md` | `17e65df` |
| `home/.claude/skills/update-deps/changelogs.md` | `17e65df` |
| `home/.claude/skills/doc-review/scripts/scrub-lib.sh` | `d1d0f27` |
| `home/.claude/skills/doc-review/scripts/scrub.sh` | `5af2aa1` |
| `home/.claude/skills/doc-review/scripts/post.sh` | `5af2aa1` |
| `home/.claude/skills/doc-review/scripts/header.sh` | `5af2aa1` |
| `home/.claude/skills/doc-review/scripts/test-post.sh` | `d1d0f27` |
| `home/.claude/skills/handoff/scripts/gather-state.sh` | `e2ce58b` |
| `home/.claude/skills/resume-handoff/scripts/gather-state.sh` | `e2ce58b` |
| `home/.claude/skills/resume-handoff/scripts/check-loss.sh` | `e2ce58b` |
| `.claude/skills/ship-it/scripts/scrub.sh` | `d1d0f27` |
| `.claude/skills/ship-it/scripts/test-scrub.sh` | `d1d0f27` |

## Review History

### 2026-10-24 — Initial review by Opus 5.5 (`claude-opus-5-5`)

Twenty-one reports collated: one documentation reviewer per Markdown document and a security, a code-quality and a test reviewer for the shell scripts. Nine findings raised by two reports each were merged, leaving 165 findings (139 actionable, 26 observations).

## Overall Assessment

The moves themselves lost no text, but the branch is not ready to merge: it carries one critical regression and a long tail of wiring the conversion left unfinished. The 🔴 is the refill commit's damage to two fenced examples (G5). The 🟠 cluster is a non-executable `header.sh` (G7), a late read trigger and conflicting posting rule in doc-review's router (G8), a zsh colon-modifier trap in resume-handoff (G9), a `local-review` preload the branch's own rule forbids (G6) and a `test-post.sh` suite that still passes with most of its gates mutated away (G11), which follows the `post.sh` hardening in G10. Most remaining findings are cross-file references, command-to-skill terminology and prose that still describes the removed inline blocks (G12–G17).

The groups run G3, G4, G5, G6, G7, G8, G9, G10, G11, G1, G2, G12 through G19. Two ⚖️ Decisions are still unruled and lead the checklist: whether the two `gather-state.sh` scripts share code (F43, G3) and the handoff's issue-link style (F25, G4). The 🔴 group (G5) and the 🟠 groups (G6 through G11) follow. The other five ⚖️ were ruled on 2026-10-24 and wait only on their edits, so their groups follow G11: the three update-deps router stubs (F115, F116 and F119, G1) and the `.local` and key-cell scrub terms (F54 and F130, G2), which go after G11 so their new test-post.sh cases land in the restructured suite. The 🟡 groups G12 to G17 and the 🟢 groups G18 and G19 close the list.

## Formatting

### F1 🔴 Critical - Refill joined the paste-marker example onto one line

- **Document** — `home/.claude/CLAUDE.md`
- **Location** — Workflow, the "Wrap text meant for me to paste into another session" bullet, lines 34–41; also `home/.claude/skills/handoff/SKILL.md`, Document Structure › Resume Prompt, where a line break inside its `text` fence moved
- **Issue** — The rule says the paste text goes in a `text` fence "whose first and last lines are the markers". Commit 1d26aa3 ("Refill … to 100 columns") joined the example's three lines into one line inside the fenced block: `===== PASTE TO <session> — BEGIN ===== The text to paste ===== PASTE — END =====`. A code block shows its line breaks exactly, so the rendered example changed too. It now shows the begin marker, the text and the end marker on a single line. That is the opposite of what the rule asks for. This file is loaded in every session in every project, so an agent copying the example will produce paste blocks the user's convention rejects. The commit message also says "Only line breaks change: each file's words and its rendered Markdown are identical before and after." That is false for this hunk, and since this repository uses rebase and merge, the claim would land on `main` as written. The likely cause is that the refill tool treated text inside the outer ````` ````markdown ````` fence as prose. The two other files in 1d26aa3 (`.claude/skills/ship-it/SKILL.md` and `home/.claude/skills/commit/SKILL.md`) touch no fenced blocks in that commit. I checked their hunks.
- **Suggestion** — Put the example back to its form at d22496a, as a fixup to 1d26aa3:

  `````markdown
    ````markdown
    ```text
    ===== PASTE TO <session> — BEGIN =====
    The text to paste
    ===== PASTE — END =====
    ```
    ````
  `````

  After the fix, 1d26aa3's message is true again, so it can stay as written.
- **Recommendation** — Implement. The example now teaches the wrong format in every session, and a fixup before `/ship-it` keeps the refill commit's claim true.
- **Verification** — Confirmed by the orchestrator: every file the refill reflowed was rendered before and after the refill with `marked`, and each `<pre>` block compared exactly. Two code blocks were damaged and no others: this paste-marker example (three lines joined into one) and the Resume Prompt example in `home/.claude/skills/handoff/SKILL.md` (Document Structure › Resume Prompt; a line break inside its `text` fence moved). Both sit inside a four-backtick fence holding a three-backtick fence, which the refill tool closed early.

### F2 🟢 Low Priority - The "refill" made the ship-it intro paragraph narrower

- **Document** — `.claude/skills/ship-it/SKILL.md`
- **Location** — Intro paragraph under `# Ship It` (lines 13–17)
- **Issue** — This paragraph is the only change commit 1d26aa3 ("Refill … to 100 columns") makes to this file. Its message says it fills paragraphs that "broke well short of the 100-column limit … to the full width". But the base paragraph was already filled to the limit: its lines were 94, 98, 99, 97 and 73 wide, and adding the next word to any of them would pass 100. After the change the lines are 89, 94, 94, 98 and 86 wide, so the paragraph is narrower than before. The hunk adds churn and makes the commit's claim untrue for this file. The same commit also joined three lines inside a fenced `text` block in `home/.claude/CLAUDE.md` (line 39, the paste-marker example; see F1), which means this commit's refill output deserves checking wherever it ran.
- **Suggestion** — Restore the base line breaks for lines 13–17, which takes this file out of 1d26aa3's diff.
- **Recommendation** — Implement: a five-line revert, and the commit's stated purpose doesn't apply to this paragraph.

### F3 🟢 Low Priority - The refill broke a commit-skill line that already fit

- **Document** — `home/.claude/skills/commit/SKILL.md`
- **Location** — Body, "Use problem → solution → user impact as a content guide, not as headers" (lines 228–229)
- **Issue** — The old first line, "…structure shape the body's", is 96 characters (`wc -m`), but 100 bytes because of the two arrows. The refill moved "body's" to the next line anyway, leaving a 93-character line. The other refills in this diff fill to the 100-character limit; one example is the `Refs` bullet, now 99 characters. So the tool that broke this line seems to have counted bytes or display width here, not characters. It has no effect on a reader.
- **Suggestion** — Restore "body's" to line 228, or leave it.
- **Recommendation** — Skip. It changes nothing a reader sees. The useful signal is that the refill tool's measure is inconsistent, which may matter in other files on this branch that contain arrows or em dashes.

### F4 🟢 Low Priority - Base name in the handoff Header prose examples is not backticked, unlike the template

- **Document** — `home/.claude/skills/handoff/SKILL.md`
- **Location** — Document Structure › Header, line 193
- **Issue** — The template writes ``(base: `<base-branch>`)``, but the prose examples write `(base: main, repository default)` and `(base: main, assumed)` with `main` bare. An agent copying the example produces a different Branch row from one copying the template.
- **Suggestion** — Use ``(base: `main`, repository default)`` and ``(base: `main`, assumed)``.
- **Recommendation** — Implement: a two-character fix that makes the template and examples agree.

## Consistency

### F5 🟡 Medium Priority - Skill sweep missed "where agents read them"

- **Document** — `home/.claude/CLAUDE.md`
- **Location** — Workflow, line 46: "Put rules meant for an agent where agents read them: CLAUDE.md, a command or an agent file."
- **Issue** — Commit b606e19 says it updated the user-wide CLAUDE.md to "name skills alongside commands". It did that at lines 162, 166, 175 and 239–241 but not here. This bullet lists the places agents read rules, and skills, now the user-wide format, are left out. A reader could conclude that a rule placed in a SKILL.md or one of its on-demand files is in the wrong place.
- **Suggestion** — Change it to "CLAUDE.md, a command, a skill or an agent file", or "CLAUDE.md, a command or skill, or an agent file" to match the wording at line 240.
- **Recommendation** — Implement. It is a one-word fix that completes the branch's own sweep.

### F6 🟢 Low Priority - `/commit` and `/doc-review` are still called "slash commands"

- **Document** — `home/.claude/CLAUDE.md`
- **Location** — Committing Changes, lines 139 and 141
- **Issue** — Both lines say "the `/commit` slash command" and "the `/doc-review` slash command". On this branch both are skills (`home/.claude/skills/commit/SKILL.md`, `home/.claude/skills/doc-review/SKILL.md`). The same file now treats the two kinds as different things: "slash commands, skills, agent files" (line 239) and "slash command, skill and agent files" (line 175). Skills can still be run with a slash, so the instruction works. Only the terminology is inconsistent.
- **Suggestion** — Write "the `/commit` skill" and "the `/doc-review` skill".
- **Recommendation** — Implement. It is two words, and it matches the distinction the branch draws elsewhere in the file.

### F7 🟢 Low Priority - The heredoc ground rule doesn't cover the squash todo heredoc

- **Document** — `.claude/skills/ship-it/SKILL.md`
- **Location** — Ground Rules, "Write derived text with the `Write` tool" (line 46), against Step 3 › Perform the approved squash (lines 236–245)
- **Issue** — The ground rule says "A heredoc is used below only for fixed text the skill itself supplies." The squash todo list is built from the branch's SHAs and message-file paths, so it is not text the skill supplies. Step 3 justifies the heredoc on its own terms ("The list holds only SHAs and paths, so a heredoc is safe here"), so the two sections state different criteria. This predates the branch.
- **Suggestion** — Extend the ground rule: "A heredoc is used below only for fixed text the skill itself supplies and for the squash todo list, which holds only SHAs and paths."
- **Recommendation** — Defer: it predates the branch, and Step 3's own sentence keeps a reader from going wrong.

### F8 🟡 Medium Priority - The rule that every rebase checks the branch has an exception in the same file

- **Document** — `home/.claude/skills/commit/SKILL.md`
- **Location** — Reshaping History, the fallback paragraph (line 107) compared with the paragraph at lines 133–134
- **Issue** — Lines 133–134 say "every amend, rebase, reset, push and `git history` rewrite in this file checks the current branch in the same command, as the blocks here do". But the older-Git fallback on line 107, `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <sha>~1`, is a rebase with no `[ "$(git branch --show-current)" = <branch> ] &&` guard. The fenced block just above it (lines 101–102) has the guard. This paragraph predates the branch.
- **Suggestion** — Write line 107 as `[ "$(git branch --show-current)" = <branch> ] && GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <sha>~1`.
- **Recommendation** — Defer. The body changed only by line breaks on this branch, and the fix is a one-line follow-up. It is cheap enough to take now if the user prefers.

### F9 🟢 Low Priority - "Project command" now names something that is a skill

- **Document** — `home/.claude/skills/commit/SKILL.md`
- **Location** — Reshaping History, the "Reordering, dropping or splitting commits" bullet (lines 116–120)
- **Issue** — The bullet calls the exception "a project command, such as `/ship-it` in a project that has one" and closes with "Without such a command". This branch made `/ship-it` a skill: the HTML comment on lines 121–122 of the same bullet points at `.claude/skills/ship-it/SKILL.md`. So the prose and the comment beside it now name the same thing differently.
- **Suggestion** — Write "a project skill or command, such as `/ship-it` in a project that has one" and "Without such a skill or command". Other projects may still have an old-style `/ship-it` command, so naming both stays correct. The sibling `home/.claude/CLAUDE.md` (Workflow, the `/handoff` bullet) has the same wording, "A command that changes or publishes shared state, such as a project's `/ship-it`". Change both together so they still match.
- **Recommendation** — Implement. Converting commands to skills is this branch's purpose, and the fix is two words.

### F10 🟠 High Priority - "Never post a review file by another route" contradicts this repository's `/ship-it`

- **Document** — `home/.claude/skills/doc-review/SKILL.md`
- **Location** — Posting the Review (lines 499–503)
- **Issue** — The section tells the orchestrator to read `posting.md` before posting "on the user's request or from a project's `/ship-it`". It then says posting goes only through `scrub.sh` and `post.sh`, and adds a new absolute rule: "Never post a review file by another route." But `.claude/skills/ship-it/SKILL.md` posts `*-DOC-REVIEW*.md` files by its own route. It uses its own `.claude/skills/ship-it/scripts/scrub.sh` (lines 55, 609 and 749), its own withholding steps ("Ask before withholding", line 474) and its own `gh pr comment` (lines 667 and 768). It never reads `posting.md` or calls `post.sh`. `posting.md`'s own sync comment says each `/ship-it` carries its own copies of the pattern set and the withholding. A session that has run `/doc-review` and then runs `/ship-it` has two rules about the same post that contradict each other. `posting.md` line 18 ("e.g. during `/ship-it` … post them with `scripts/post.sh`") has the same conflict; that is its own reviewer's to file.
- **Suggestion** — Limit the rule to this skill's own posting. For example: "When this skill posts the review at the user's request, read `${CLAUDE_SKILL_DIR}/posting.md` in full … and never post a review file by another route. A project's `/ship-it` posts with its own copy of these rules (see the sync comment at the top of `posting.md`)."
- **Recommendation** — Implement. The sentence was added in this change, and the fix is one sentence.

### F11 🟡 Medium Priority - The router names the recording agents as readers of `review-file.md`, but they are given its rules inline and their tool limit forbids reading it

- **Document** — `home/.claude/skills/doc-review/SKILL.md`
- **Location** — Opening file list (lines 19–25), compared with Composing the Prompts (line 141) and Recording the rulings, item 2 (lines 432–436)
- **Issue** — Line 20 says each file in the list is "read in full by whoever it names". Lines 24–25 name `review-file.md` as being "for the orchestrator and the recording agents whenever they edit that file". Read together, the recording agents read `review-file.md` in full. But line 141 says "The recording agents' rules travel inline instead". The recording agent's tool limit also allows "Read and Edit on the review file" only, which rules out reading `review-file.md`. The old file gave a reason for inline quoting: the extract directory was deleted once the collator returned. That reason no longer applies, and SKILL.md never states the new one (the tool limit). So "instead" now reads as arbitrary, and a maintainer may "fix" it by adding the path to the prompt.
- **Suggestion** — Change lines 24–25 to "the rules for the review file, read by the collator and by the orchestrator, which quotes the parts a recording agent needs into its prompt". At line 141, say why: "(see Recording the rulings: a recording agent's only tools are Read and Edit on the review file itself)".
- **Recommendation** — Implement. The two passages contradict each other on the very procedure this split rerouted.

### F12 🟢 Low Priority - "this command" and a singular "the file" sit beside "this skill's files" in Who Does What

- **Document** — `home/.claude/skills/doc-review/SKILL.md`
- **Location** — Who Does What, opening paragraph (lines 92–94)
- **Issue** — "Four parties run this command … every instruction in this skill's files belongs to one of them … and the file never addresses an unnamed 'you'". The sentence moves from "command" to "skill's files" and then to a singular "the file" within three lines. Since the split, the rule about no unnamed "you" has to cover all five files. Elsewhere on the branch, "this command" is in wide use across the converted skills (`update-deps`, `handoff`, `resume-handoff`), so only this sentence's internal mix is flagged here.
- **Suggestion** — Write "and none of the files addresses an unnamed 'you'". Optionally, write "Four parties run this skill".
- **Recommendation** — Implement. The fix is a two-word edit that makes the rule's scope match the split.

### F13 🟡 Medium Priority - "This command" has no antecedent in a rules file read by path

- **Document** — `home/.claude/skills/doc-review/reviewer-rules.md`
- **Location** — Reviewing Without Editing (HTML comment, line 85); Reading Strategy, "Very large text documents" (line 144); Redacting Sensitive Evidence, second and third paragraphs (lines 388 and 395)
- **Issue** — Four passages moved verbatim from the command file still call the thing they describe "this command":
  - "this command's reviewers each review one document"
  - "This command is used on Markdown far more often than on PDFs"
  - "not just the one this command writes"
  - "neither is performed by this command"

  In the old command file the antecedent was `/doc-review` itself. In this file the reader is a reviewer or the collator, who has been handed a rules file by path, not a command. "This command" now points at nothing the reader holds. In line 395 it also sits next to "this file", which here means `reviewer-rules.md`, so one sentence uses two self-references that name different things.
- **Suggestion** — Replace each occurrence with "`/doc-review`" (for example "`/doc-review`'s reviewers each review one document", "`/doc-review` is used on Markdown far more often…", "not just the one `/doc-review` writes", "neither is performed by `/doc-review`").
- **Recommendation** — Implement: four word swaps that finish the move this branch makes, and the brief asks for exactly this check.

### F14 🟡 Medium Priority - Sensitive Information says its findings are always withheld, but `posting.md` lets the user clear some

- **Document** — `home/.claude/skills/doc-review/reviewer-rules.md`
- **Location** — Sensitive Information, closing paragraph (lines 55–58)
- **Issue** — The paragraph says findings in this category are "**withheld from any published comment**" and that "the published record carries only a count".
  - It conflicts with Ask before withholding in `home/.claude/skills/doc-review/posting.md` (PR Comment Format). Under that section, the user may clear a Sensitive Information finding that names no value ("**Post it in full**"), and "A cleared finding is posted like any other". When every finding is cleared, no count line is written at all.
  - This contradiction is older than the branch (the old command file had both texts), but this branch edited this exact sentence to add the `posting.md` hint.
- **Suggestion** — Qualify the claim, for example: "…and **withheld from any published comment** unless the user clears one that names no value — see PR Comment Format in `posting.md`. … the published record carries only a count for each finding withheld."
- **Recommendation** — Implement: a single clause on a line this branch already touched. Deferring leaves a reviewer rules file that contradicts the posting rules it cites.

### F15 🟡 Medium Priority - File Name holds orchestrator steps that run before SKILL.md tells the orchestrator to read this file

- **Document** — `home/.claude/skills/doc-review/review-file.md`
- **Location** — File Name, lines 17–37
- **Issue** — File Name says the orchestrator resolves the review file's name, and that "Before dispatching" it names any other `*-DOC-REVIEW*.md` to the user. Both happen while the scope is confirmed (SKILL.md, Scope: "Confirm a described scope before dispatching"). But `home/.claude/skills/doc-review/SKILL.md`, at its opening "Skill directory" paragraph (lines 32–34), says the orchestrator reads `review-file.md` "before its first edit to the review file", which comes later. SKILL.md's pointer at line 79 ("see File Name in `review-file.md`") covers only the other-review-files rule. The naming rules themselves exist only here: lowercasing, branch `/` to dash, asking on a detached HEAD.
- **Suggestion** — Open File Name with "The orchestrator reads this section while confirming the scope (see Scope in SKILL.md), before dispatching anything." Pair it with the matching change to SKILL.md lines 32–34 (F98).
- **Recommendation** — Implement. A misnamed file breaks the merge into the same file on a later run.

### F16 🟢 Low Priority - File hints added to some cross-file references in review-file.md but not others

- **Document** — `home/.claude/skills/doc-review/review-file.md`
- **Location** — Overall Assessment line 153; Collating the Reports line 188; Tracking Finding Status lines 294–295; Implementation groups, Membership, lines 443–444 and 451
- **Issue** — The move added file hints where a reference left this file (line 6 "in SKILL.md", line 92 "in `posting.md`"), but these references were left without one:
  - "What Is Not Written" and "Recording the Reviewing Model" are in `reviewer-rules.md`.
  - "F8 from the walkthrough example" is in `walkthrough-example.md`.
  - "(see Walkthrough and Finding Selection)" and "phase 2" are in SKILL.md.

  The last three matter most: the collator is given neither SKILL.md nor `walkthrough-example.md`, so nothing tells it that these sections are not in the files it has.
- **Suggestion** — Add the hints in the style the file already uses: "What Is Not Written (`reviewer-rules.md`)", "Recording the Reviewing Model in `reviewer-rules.md`", "F8 from the walkthrough example in `walkthrough-example.md`", "(see Walkthrough and Finding Selection in SKILL.md)" and "phase 2 of the walkthrough".
- **Recommendation** — Implement. Five small edits that complete a convention the move started.

### F17 🟡 Medium Priority - Several posting.md paragraphs still describe the inline blocks that were removed

- **Document** — `home/.claude/skills/doc-review/posting.md`
- **Location** — PR Comment Format, lines 53–57, 70–74 and 85–93
- **Issue** — Some text was carried over from the old blocks and now points at code the reader cannot see, or describes it wrongly:
  - Line 53 says "The `/dev/null` argument keeps `grep` printing the filename. Branch on the exit code rather than swallowing it". No command in the document has a `/dev/null` argument any more, so the sentence has nothing to refer to, and its instruction is addressed to nobody.
  - Line 73 says "the two scrub forms would silently run different tools". That referred to the old single-file block and the artifact-set block. The single-file form is gone.
  - Line 74 says "`find -exec grep` already runs the binary directly". In `scrub-lib.sh`, `grep_artifacts` now runs `find … -exec sh -c 'LC_ALL=C grep …'`. That calls `sh`, and `sh` then looks up `grep`.
  - Line 91 says "without these two lines it reintroduces the same silence". The two lines (`scanned=` and its emptiness check) are no longer in the document; they are lines 20–21 of `scrub.sh`.
- **Suggestion** — Recast each passage as the reason the scripts work as they do, and name where:
  - "`grep_artifacts` and post.sh's Gate 2 pass `/dev/null` so `grep` always prints the filename, and branch on `grep`'s exit status rather than swallowing it"
  - "the scripts and any copy synced from them would silently run different tools"
  - "`find -exec sh -c` runs a non-interactive shell, which loads no user functions or aliases"
  - "without lines 20–22 of `scrub.sh` it reintroduces…"
- **Recommendation** — Implement. The task asks for this cleanup, and readers who sync other projects from this section will look for code that is not there.

### F18 🟡 Medium Priority - reviewer-rules.md cites a filename list that posting.md no longer has

- **Document** — `home/.claude/skills/doc-review/posting.md`
- **Location** — PR Comment Format, lines 65–68
- **Issue** — `home/.claude/skills/doc-review/reviewer-rules.md` (Redacting Sensitive Evidence) says "the scrub's own filename list in PR Comment Format is the proof that an authoring rule scoped to a single file is scoped too narrowly". That list was in the old artifact-set block. It now lives only in `artifacts()` in `scripts/scrub-lib.sh`, and posting.md never names the four patterns (`*local-review*.md`, `*-DOC-REVIEW*.md`, `*-HANDOFF.md`, `*PLAN.md`). As a result, nothing in the document tells the orchestrator that handoffs and plans are scanned too. A hit in an unrelated `*-HANDOFF.md` in the root will block a doc-review post, and the orchestrator has no warning of it.
- **Suggestion** — At line 65, after "The scan covers the set of artifacts rather than one named file", add: "every top-level file matching `*local-review*.md`, `*-DOC-REVIEW*.md`, `*-HANDOFF.md` or `*PLAN.md`, so a hit in another artifact blocks this post too".
- **Recommendation** — Implement. One sentence restores the list the sibling cites and explains a block the user would otherwise find puzzling.

### F19 🟢 Low Priority - Stale "command file" and "this command" wording in posting.md

- **Document** — `home/.claude/skills/doc-review/posting.md`
- **Location** — PR Comment Format, line 152 ("Any review of these command files"), lines 192–197 ("every other command that publishes", "two artifacts this command never writes", "A cross-reference between command files reaches nobody") and line 266 ("the command is most dangerous exactly when it works")
- **Issue** — `/doc-review` is now a skill, and both posting.md and the document it posts are skill files. In its rewritten paragraph at line 271 the document itself says "the normal way a skill file gets used". The siblings are mixed: SKILL.md says "this skill" at lines 93 and 144 but "this command" at lines 73 and 92. "Command files" is now wrong, and it is not merely a style difference. "Publishers" in line 192 still covers `/ship-it`, which is a command in some projects.
- **Suggestion** — Write "skill files" at line 152, "this skill" at lines 195 and 266, "every other skill or command that publishes" at line 192 and "between skill or command files" at line 196.
- **Recommendation** — Implement. These are cheap word swaps in a section this branch already rewrote.

### F20 🟢 Low Priority - The reason given for moving an observation contradicts review-file.md's summary table

- **Document** — `home/.claude/skills/doc-review/posting.md`
- **Location** — Ask before withholding, lines 209–211
- **Issue** — The document says an observation under `## Observations` must be moved because its summary row "names no category". In `home/.claude/skills/doc-review/review-file.md` (Consolidated Summary), the table has a Category column for every row, and the example ℹ️ row F10 names `Clarity`. If an observation's row reads `Sensitive Information`, post.sh's `ids` awk would find it through `c[4]` without any move. The premise is false; the rule just costs an unneeded edit. The same sentence was in the base, so this is pre-existing.
  - From the concurring report: `.claude/skills/ship-it/SKILL.md` (Step 6 › Copy, redact and scrub, lines 491–493) says to stop "when the summary table names Sensitive Information for a finding filed elsewhere, such as under `## Observations`", which assumes an observation's row carries a Category, as review-file.md does. So two publishers of the same withholding rule describe the review file differently, though both end with the same action (move the finding under the heading) and no reader takes a wrong step. The base `home/.claude/commands/doc-review.md` has the same wording at lines 1697–1698.
- **Suggestion** — Give the real reason: "`post.sh`'s number check finds one under `## Sensitive Information` or by a summary row whose Category cell reads `Sensitive Information`, so check that the row of an observation filed under `## Observations` says so, and move it under `## Sensitive Information` with the user's agreement when it does not." Leave `.claude/skills/ship-it/SKILL.md` alone.
- **Recommendation** — Defer. This is pre-existing, and the false premise only causes an extra move, never a leak.
- **Concurred by** — `.claude/skills/ship-it/SKILL.md`, which filed it at 🟡 Medium Priority, also recommending Defer (fix it with the next posting.md edit)

### F21 🟢 Low Priority - SKILL.md calls the walkthrough example "the whole walkthrough", but the file stops at the order proposal

- **Document** — `home/.claude/skills/doc-review/walkthrough-example.md`
- **Location** — Introduction, line 3; set against `home/.claude/skills/doc-review/SKILL.md`, 3. Proposing an order, lines 494–495
- **Issue** — `SKILL.md` points here as "a worked example of the whole walkthrough". This file says it runs "from phase 1 to the proposed order", and the transcript ends at "Which group first?". Nothing after that is shown: not the choice of a group, not the check for a choice a Suggestion leaves open, not the group work. This file's wording is the accurate one, so `SKILL.md` promises more than the file contains.
- **Suggestion** — In `SKILL.md` line 494, change "a worked example of the whole walkthrough" to "a worked example of the walkthrough up to the order proposal".
- **Recommendation** — Implement: a few words, and it keeps a reader from looking here for group work that isn't shown.

### F22 🟢 Low Priority - F5's recommendation comes after its options in the walkthrough example, but F8's comes before

- **Document** — `home/.claude/skills/doc-review/walkthrough-example.md`
- **Location** — Transcript, F5 question (lines 10–18) and F8 question (lines 20–25)
- **Issue** — In the F8 item the recommendations come before the options: "Reviewer: Defer … Mine: Defer". In the F5 item the line "Recommended: (b), because …" comes after the option list. `home/.claude/CLAUDE.md` (Workflow) says to "Put the explanation and any recommendation in your reply before the question", and the option list is where the AskUserQuestion widget would go. Read literally, the F5 item shows the recommendation after the question. The F5 wording is carried over unchanged from the base.
- **Suggestion** — Move the line `Recommended: (b), because the Quick Start exists to be short and Installation covers Docker.` up so it comes right after "The choice is how much of that the Quick Start carries." and before the `(b) …` option line.
- **Recommendation** — Implement: moving one line in a file that is new on this branch costs little. This is not the usual Defer for a problem that already existed.

### F23 🟡 Medium Priority - "This command file" names a file that is now `SKILL.md`

- **Document** — `home/.claude/skills/handoff/SKILL.md`
- **Location** — Document Structure intro, line 149; Gathering State, line 81
- **Issue** — Line 149 says the sections are `###` "because they sit under this command file's own `## Document Structure`". The file is no longer a command file. Line 81, "this command runs against any repository", is looser and matches how sibling skills still describe themselves (`home/.claude/skills/resume-handoff/SKILL.md` lines 19 and 323, and `home/.claude/skills/update-deps/SKILL.md` line 16). "Command file", though, is simply wrong.
- **Suggestion** — Line 149: "because they sit under this file's own `## Document Structure`". Line 81, optionally: "this skill runs against any repository".
- **Recommendation** — Implement: a one-word fix to a claim the rename made false.

### F24 🟢 Low Priority - The two `gather-state.sh` scripts take the remote in different ways

- **Document** — `home/.claude/skills/handoff/SKILL.md`
- **Location** — Gathering State, lines 100–101; `home/.claude/skills/handoff/scripts/gather-state.sh` line 12 (`remote=${1:-origin}`); `home/.claude/skills/resume-handoff/scripts/gather-state.sh` line 15 (`remote=${REMOTE:-origin}`)
- **Issue** — This document says "pass the repository's remote as its argument", which is correct for its script (`remote=${1:-origin}`). The sibling `home/.claude/skills/resume-handoff/SKILL.md` (Resolve the Branch and Its Base) says "set `REMOTE`", and its script of the same name reads `remote=${REMOTE:-origin}` and uses its positional arguments for the branch, date and files. An agent that has used one will misuse the other:
  - Setting `REMOTE` for this script is silently ignored.
  - Passing a remote as the first argument to the other script makes that argument the branch: `gather-state.sh upstream` in resume-handoff sets the branch to `upstream`.
- **Suggestion** — Make this script read `REMOTE` like its sibling (`remote=${REMOTE:-origin}`, with no positional argument), which already uses its positional arguments for other values. Change the sentence to "set `REMOTE` to the repository's remote if it differs", and update the script's `Usage` comment to match.
- **Recommendation** — Implement: both scripts are new on this branch, so aligning them now costs nothing to existing users, and it removes a trap between near-identical tools.
- **Concurred by** — `home/.claude/skills/handoff/scripts/gather-state.sh`, also 🟢 Low Priority and Implement, with the same fix

### F25 ⚖️ Decision - Issue links in a handoff: inline full URL, or `CLAUDE.md`'s reference-style link

- **Document** — `home/.claude/skills/handoff/SKILL.md`
- **Location** — Document Structure › Header, lines 176–181; References, lines 360–372
- **Issue** — The handoff says "Give **full URLs**… Put the identifier and the URL together — `ENG-412 (https://linear.app/…)`", and its References example uses bare URLs. `home/.claude/CLAUDE.md` › Linear Issues says to link every Linear identifier mention in documents, naming handoffs, "In a Markdown document, use a reference-style link (`[ENG-412][eng-412]`, with the definitions at the end) so lines stay within the column limit". The stated reason (column limit) does not apply to a handoff, which is never hard-wrapped, but the rule names handoffs explicitly. This predates the branch; the `CLAUDE.md` rule landed in `d22496a`.
- **Options**
  - **(a) Adopt reference-style links in the handoff.** Matches `CLAUDE.md` as written and links every mention, not only the header and References. Costs a rewrite of the Header guidance and the References example, and moves URLs out of the lines `/ship-it` copies, so the posted References section has to carry the definitions.
  - **(b) Keep inline full URLs and narrow `CLAUDE.md`.** Make the reference-style rule apply only to hard-wrapped documents, since its stated reason is the column limit, and say in the handoff that each later mention of an identifier links too. Smaller change and keeps References self-contained when posted, but it edits the user-wide guidance.
- **Recommended** — (b): the reference-style rule exists for the column limit, which handoffs deliberately ignore, and inline URLs keep each posted References line usable on its own.

### F26 🟢 Low Priority - Public-repository rule for Linear URLs is missing from the handoff's durable-sections warning

- **Document** — `home/.claude/skills/handoff/SKILL.md`
- **Location** — Output File, lines 70–72; Header, line 176
- **Issue** — The document warns that `/ship-it` publishes the durable sections, References included, to the pull request, and to "name no private repository, internal host or personal data in them". It also tells the reader to give full Linear URLs. `home/.claude/CLAUDE.md` says that in a public repository you write the identifier without its URL, because "the URL's workspace slug names the client". `.claude/skills/ship-it/SKILL.md` (around line 549) asks about any `linear.app/` link before posting, so a backstop exists, but the authoring rule here does not say it. This predates the branch.
- **Suggestion** — Extend line 72: "…name no private repository, internal host or personal data in them, and in a public repository write Linear identifiers without their URLs."
- **Recommendation** — Defer: pre-existing, with a working backstop at `/ship-it`. It fits naturally with whichever option F25 settles on.

### F27 🟡 Medium Priority - Plans described as always "tracked but stripped" contradicts this repository's `/ship-it`

- **Document** — `home/.claude/skills/handoff/SKILL.md`
- **Location** — Key Files & Entry Points, lines 261–263; Merging with an Existing Handoff, step 6 (line 427); Output File, line 62
- **Issue** — The document states as universal that "`*-PLAN.md` (or a legacy `PLAN.md`) is tracked but stripped from the branch history at ship time", and that `/ship-it` "posts review and plan artifacts whole and then deletes them". This skill is user-wide. `.claude/skills/ship-it/SKILL.md` Step 6 posts "an untracked plan" and says a plan `git ls-files` lists "is tracked, which this repository's workflow never does: stop and ask the user about it rather than posting or deleting it". It also deletes only sources whose comment verified, and a `*-DOC-REVIEW*.md` with a withheld finding only on the user's word. `home/.claude/CLAUDE.md` says to commit a working document "only where the project's `/ship-it` expects it". This predates the branch.
  - From the concurring report: line 262 says `*-PLAN.md` "is tracked but stripped from the branch history at ship time, and `/ship-it` deletes all of them", and line 427 says "tracked, but stripped by `/ship-it`". This repository's `/ship-it` posts only an untracked plan (Copy, redact and scrub, line 456), never strips one from history and stops on a tracked plan (Step 6, lines 414–416). Handoff is a user-wide skill describing other projects' `/ship-it` as well, and resume-handoff's Keep It Portable rule asks for such references to be conditional. The wording predates the branch (base `handoff.md` lines 279 and 444).
- **Suggestion** — Write "`*-PLAN.md` (or a legacy `PLAN.md`), tracked or untracked depending on the project's `/ship-it`", and "posts… and then deletes the ones it verified". The concurring report proposes the same conditional form, e.g. "tracked in a project whose `/ship-it` strips it at ship time"; no change is needed in `.claude/skills/ship-it/SKILL.md`.
- **Recommendation** — Defer: pre-existing and outside the conversion's scope. The practical advice (carry the substance into the handoff) holds either way.
- **Concurred by** — `.claude/skills/ship-it/SKILL.md`, which filed it at 🟢 Low Priority, also recommending Defer (the fix belongs in the sibling file)

### F28 🟢 Low Priority - The doc-review artifact pattern in resume-handoff is narrower than the siblings'

- **Document** — `home/.claude/skills/resume-handoff/SKILL.md`
- **Location** — Step 3, Also Check, "Working artifacts" (line 211)
- **Issue** — This document uses `*-DOC-REVIEW.md`. `home/.claude/skills/handoff/SKILL.md` (Output File, Key Files & Entry Points, Merging with an Existing Handoff), `home/.claude/skills/doc-review/review-file.md` and the user-wide `home/.claude/CLAUDE.md` all use `*-DOC-REVIEW*.md`. The scope did not introduce this.
- **Suggestion** — Write `*-DOC-REVIEW*.md`.
- **Recommendation** — Implement: a one-character fix that brings it in line with the other skills.

### F29 🟢 Low Priority - Resume-handoff examples cite commands the agent no longer runs

- **Document** — `home/.claude/skills/resume-handoff/SKILL.md`
- **Location** — Step 5, drift table example, row 1 (line 305); Step 4, item 1 under Current State (lines 251–253)
- **Issue** — Row 1 gives `git rev-parse --verify --quiet refs/heads/<branch>` as its "Checked with" value. Since this revision, the agent gets the tip from `gather-state.sh`'s `tip:` line, which may come from `origin` or the pull request, not from the local ref. Current State's "each bullet naming the command it came from" has the same gap: most state now comes from one script call.
- **Suggestion** — Change row 1's "Checked with" to `gather-state.sh` (`tip:` line). In Current State, write "naming the command or `gather-state.sh` part it came from".
- **Recommendation** — Implement: this keeps the examples in step with the new workflow.

### F30 🟢 Low Priority - `REMOTE` is half-documented in resume-handoff

- **Document** — `home/.claude/skills/resume-handoff/SKILL.md`
- **Location** — Step 3, Resolve the Branch and Its Base, lines 112–124
- **Issue** — The text says to "set `REMOTE`", but there is no example of passing it (`REMOTE=upstream '…/gather-state.sh' …`). The surrounding prose still says `origin` for what is now `$REMOTE` ("then from `origin`", "When local and `origin` differ"). The script's `gh` calls also ignore `REMOTE`. In a clone with an `upstream` remote, the user-wide CLAUDE.md says `gh` needs `--repo`, so setting `REMOTE` alone can still read the wrong repository's pull request.
- **Suggestion** — Show the env-prefixed invocation. Say "the remote" or "`origin` (or `REMOTE`)" in the prose. Note that `gh` follows its own repository resolution.
- **Recommendation** — Defer: `gh` resolution is a script design question for the scripts' reviewers (see F82). The prose fix is small but only matters in multi-remote clones.

### F31 🟢 Low Priority - Update-deps opening paragraph omits the tool and image pins that the description and Overview name

- **Document** — `home/.claude/skills/update-deps/SKILL.md`
- **Location** — Frontmatter `description` (lines 3–5) compared with the opening paragraph (lines 11–12)
- **Issue** — The new frontmatter description says "Ruby, JavaScript and Terraform dependencies and its tool and image pins". The opening paragraph below it still says only "Ruby, JavaScript and Terraform dependencies". Overview item 7 and Step 7 cover the pins.
- **Suggestion** — Change line 11 to "Update the app's Ruby, JavaScript and Terraform dependencies and its tool and image pins, build a detailed commit message from changelogs and open a pull request."
- **Recommendation** — Implement. This is one phrase, and it aligns the opening paragraph with the description the skill listing shows.

### F32 🟢 Low Priority - "this command" for what is now a skill, in javascript.md

- **Document** — `home/.claude/skills/update-deps/javascript.md`
- **Location** — Run Yarn with a Release-Age Gate and No Install Scripts, line 42 ("Nothing later in this command builds the app")
- **Issue** — The branch turns `/update-deps` into a skill. The user-wide CLAUDE.md now lists "slash command, skill and agent files" as separate kinds of file, yet this topic file still calls the run "this command". The same wording is in version-locked.md line 55, terraform.md line 208 and update-deps/SKILL.md line 16 ("This command automates"), so the files agree with each other and the issue is only the term.
- **Suggestion** — Change it to "Nothing later in this run builds the app". "Run" is the word the step already uses, and it stays correct whatever the mechanism is called.
- **Recommendation** — Defer. Fix it in one terminology pass over the update-deps files rather than in one of four places.

### F33 🟢 Low Priority - The platform-coverage restore hardcodes a platform list the step says to adapt

- **Document** — `home/.claude/skills/update-deps/terraform.md`
- **Location** — Step 6: Re-resolve and Verify Terraform Lock Files, the `providers lock -platform=darwin_arm64 -platform=linux_amd64` block (lines 419–424)
- **Issue** — Earlier in the same step (lines 290–293), the reader is told: "Adapt that platform list rather than copying it: it must name every other platform that runs Terraform against this repository". Lines 282–284 add that naming a platform with no build "makes the whole command fail and write nothing". The coverage-restore block then gives a fixed two-platform list with no such qualifier. Copied as written, it fails to restore coverage for a lock file that also served `darwin_amd64` or `linux_arm64`. If the provider has no `darwin_arm64` build, it fails outright. This was in the base text before the move.
- **Suggestion** — Add one sentence after the block: "Name the same platforms as above — every platform that runs Terraform against this repository, and none the provider publishes no build for."
- **Recommendation** — Defer. The problem predates the move, and this branch is a verbatim move. Fixing it belongs in a content pass on the Terraform steps.

### F34 🟢 Low Priority - "this command" for what is now a skill, in terraform.md

- **Document** — `home/.claude/skills/update-deps/terraform.md`
- **Location** — Bump the Pins, line 208 ("it is not a dependency this command updates")
- **Issue** — The file now lives under `skills/`, and the user-wide guidance on this branch treats slash commands and skills as different kinds of file (`home/.claude/CLAUDE.md`, Code Style and Shell Commands: "slash command, skill and agent files"). The same wording appears in sibling files: `home/.claude/skills/update-deps/SKILL.md` line 16 ("This command automates…"), `javascript.md` line 42 and `version-locked.md` line 55. Fixing only this file would leave the skill inconsistent with itself. The skill is still started as `/update-deps`, so the word is not misleading in practice.
- **Suggestion** — In one sweep across the update-deps files, replace "this command" with "this skill" (or "this run", where the sentence means the run).
- **Recommendation** — Defer. This is a terminology sweep across five files rather than a fix to this document. It fits a follow-up on command-to-skill wording.

### F35 🟢 Low Priority - "See Step 10" in linters.md now points at a step that is not in this file

- **Document** — `home/.claude/skills/update-deps/linters.md`
- **Location** — Step 8, item 4 (line 26); Step 9, item 3 (line 66)
- **Issue** — Both items say "(see Step 10)" as bare text. In the original file Step 10 was further down the same page. Now it lives in `home/.claude/skills/update-deps/SKILL.md`, and this file has no Step 10. The sibling topic files point to the same step with a cross-file link: `javascript.md` line 156 and `terraform.md` lines 376 and 483 use `[Step 10](SKILL.md#step-10-build-the-final-commit-message)`. This file is the only one that leaves it unlinked.
- **Suggestion** — In both places, replace `(see Step 10)` with `(see [Step 10](SKILL.md#step-10-build-the-final-commit-message))`, rewrapping to 100 columns.
- **Recommendation** — Implement. It is a two-line edit that brings this file in line with its siblings and finishes the link rewriting the move set out to do.

### F36 🟢 Low Priority - "Never skip linter checks" contradicts the conditional steps it links to

- **Document** — `home/.claude/skills/update-deps/linters.md`
- **Location** — Step 8 (opening check) and Step 9 ("If haml-lint was updated:"), as cited from `home/.claude/skills/update-deps/SKILL.md`, Important Notes
- **Issue** — The Important Notes bullet "**Never skip linter checks** — see Step 8 and Step 9" links into this file. Both steps here run only when their gem changed, and the `SKILL.md` stubs (Steps 8 and 9) say the same. An agent could read the note as "always run `bin/rubocop -A` and `bin/rails lint:haml`", which goes further than the steps it cites. The wording was already in the original command file (line 1473), so this branch did not introduce it.
- **Suggestion** — Change the `SKILL.md` bullet to say what is actually mandatory. For example: "**Always check for linter gem bumps** — and when one changed, finish its step before committing; see Step 8 and Step 9."
- **Recommendation** — Defer. It predates this branch and the fix belongs in `SKILL.md`, but take it up the next time that section is edited.

### F37 🟡 Medium Priority - The Rails check runs "after Step 4's restore", but the intro and Step 4 put the check before that single call

- **Document** — `home/.claude/skills/update-deps/version-locked.md`
- **Location** — Rails JavaScript Packages, line 95 ("After Step 4's restore, check each against the gem"), against the section intro, lines 9–10
- **Issue** — The intro says to make these changes "inside Step 4's single restore call when the prefix is the restore prefix". `javascript.md` (Update the Direct Dependencies and Restore Holds, lines 74–75) agrees: it says "Then check the Version-Locked Packages … and put every hold back in one call with the restore prefix", so the check comes first. The Rails subsection instead runs its check after the restore. Any `@rails/*` fix it finds then needs a second restore-prefix call, which contradicts "single". The text is unchanged from the base, so this branch did not introduce it.
- **Suggestion** — Change "After Step 4's restore, check each against the gem:" to "Before Step 4's restore call, check each against the gem:". The `grep -n '"@rails/' package.json` check already works on the manifest that `yarn up '*'` leaves behind.
- **Recommendation** — Defer. This is a verbatim move, and a wording fix belongs with the next change to Step 4's restore flow.

### F38 🟢 Low Priority - The version-locked.md H1 repeats SKILL.md's title instead of naming the topic

- **Document** — `home/.claude/skills/update-deps/version-locked.md`
- **Location** — Line 1 (`# Update Dependencies`)
- **Issue** — Four topic files carry an `Update Dependencies: <Topic>` H1: `javascript.md` ("Update Dependencies: JavaScript"), `terraform.md`, `pins.md` and `linters.md`. This file uses the bare `# Update Dependencies`, which is also the H1 of `SKILL.md`, so it does not identify itself when opened alone. `changelogs.md` has the same bare H1 (F40).
- **Suggestion** — Use `# Update Dependencies: Version-Locked Packages`. Keep the `## Version-Locked Packages` H2 even though it then repeats part of the title, because five inbound links target its `#version-locked-packages` slug.
- **Recommendation** — Implement. This branch introduced the H1, and the fix is one line.

### F39 🟢 Low Priority - "during this command" survives the conversion to a skill

- **Document** — `home/.claude/skills/update-deps/version-locked.md`
- **Location** — Playwright, item 4, line 55 ("install scripts are off during this command")
- **Issue** — The branch converts the command into a skill, and the files now mix "this command" and "this skill". Examples: `doc-review/SKILL.md` lines 92–93 use both, and `javascript.md:42` and `terraform.md:208` say "this command". The user-wide `CLAUDE.md` now speaks of "command or skill" files. In this sentence, "command" can also be misread as the `yarn up` or system-spec command just mentioned.
- **Suggestion** — Write "install scripts are off during this run". `SKILL.md` already says "this run" (Step 2: "whether this run should ship with it"), and the wording works whichever word the branch settles on for the artifact. Make the same change in `javascript.md:42` and `terraform.md:208`.
- **Recommendation** — Implement. It is a one-word change on the branch whose purpose is this conversion.

### F40 🟡 Medium Priority - The changelogs.md H1 repeats `SKILL.md`'s title instead of naming the topic

- **Document** — `home/.claude/skills/update-deps/changelogs.md`
- **Location** — Line 1, `# Update Dependencies`
- **Issue** — The scope says the section moved "under a new H1 title", but the H1 is word for word the skill's own title in `home/.claude/skills/update-deps/SKILL.md` line 9. The sibling topic files name their topic: `javascript.md` ("Update Dependencies: JavaScript"), `terraform.md`, `pins.md` ("Update Dependencies: Tool and Image Pins") and `linters.md`. A reader who opens this file, or sees it in a file list or a link preview, cannot tell it from the router. `home/.claude/skills/update-deps/version-locked.md` has the same bare H1 (F38), and the two should be fixed together.
- **Suggestion** — Change line 1 to `# Update Dependencies: Known Changelog Quirks`, and keep the `## Known Changelog Quirks` H2 so the four inbound `#known-changelog-quirks` links still resolve (see F158).
- **Recommendation** — Implement. It is a one-line edit that brings the file in line with four of its five sibling topic files.

### F41 🟢 Low Priority - "as Step 10 describes" no longer says which file Step 10 is in

- **Document** — `home/.claude/skills/update-deps/changelogs.md`
- **Location** — Gems with no changelog, line 34
- **Issue** — In the single original file, "Step 10" obviously meant the same document. In a standalone file it points to something the file doesn't contain. Sibling topic files link it: `javascript.md` line 156 and `terraform.md` lines 376 and 483 use `[Step 10](SKILL.md#step-10-build-the-final-commit-message)`. The wording was unlinked in the base too; the move is what made it ambiguous.
- **Suggestion** — Change it to `as [Step 10](SKILL.md#step-10-build-the-final-commit-message) describes`, and refill the line to stay within 100 columns.
- **Recommendation** — Implement. The other topic files already use this cheap cross-file link pattern.

### F42 🟢 Low Priority - The changelogs.md H3 headings mix sentence case and Title Case

- **Document** — `home/.claude/skills/update-deps/changelogs.md`
- **Location** — These H3 headings:
  - Gems with no changelog (line 31)
  - Changelogs without usable anchors (line 37)
  - Changelogs on another branch or repository (line 44)
  - Tool and image pins (line 49)
- **Issue** — The headings that aren't package names use sentence case. The file's H2 ("Known Changelog Quirks") and the rest of the skill's headings ("Verify the Bumps", "Close Open Security Alerts") use Title Case. This is inherited from the base, not introduced by the move. Nothing in the tree links to these four slugs (`grep -rn 'changelogs.md#'` finds only `#known-changelog-quirks`), so a recase breaks nothing.
- **Suggestion** — Recase them to "Gems with No Changelog", "Changelogs Without Usable Anchors", "Changelogs on Another Branch or Repository" and "Tool and Image Pins".
- **Recommendation** — Defer. The move was meant to be verbatim, and mixing a recase into it muddies that diff. It is better done in a later style pass.

### F43 ⚖️ Decision - Whether the two gather-state.sh scripts share their common block

- **Document** — `home/.claude/skills/handoff/scripts/gather-state.sh`
- **Location** — lines 14–32, and lines 21–39 of `home/.claude/skills/resume-handoff/scripts/gather-state.sh`
- **Issue** — The `gh` availability probe, the base resolution (pull request, then repository default, then assumed `main`) and the `range_base` fallback are about 20 lines that are verbatim the same in both scripts, apart from `gh pr view` versus `gh pr view "$branch"`. Neither file mentions the other, so a fix to one (F82, for example) can silently miss the other.
- **Options**
  - **(a) Keep two copies and add a one-line keep-in-sync note to each, naming the other.** Each skill stays self-contained, but drift is caught only by a reader who heeds the note. `reviewer-rules.md` already uses this pattern.
  - **(b) Extract a shared `lib` that both source.** One copy, but one skill's scripts would source a file in another skill's directory. That couples two skills that are installed and invoked independently, and it breaks if either is moved or renamed.
  - **(c) Leave as is.** No cost now, but drift goes unnoticed.
- **Recommended** — (a), because the skills are meant to stand alone and the shared block is small and stable.

### F44 🟢 Low Priority - The gather-state pull request parts conflate "none" with "not checked"

- **Document** — `home/.claude/skills/handoff/scripts/gather-state.sh`
- **Location** — lines 50–54 (and lines 65–69 of the resume-handoff copy)
- **Issue** — The header says a "not checked" line "is never the same as 'none'". The script's own output breaks that rule:
  - The pull request part prints "no pull request found, or gh unavailable" for both cases.
  - The comments part prints "not checked" when the branch simply has no pull request.

  In a throwaway repository with `gh` available and no pull request, the output was "no pull request found, or gh unavailable" followed by "not checked".
- **Suggestion** — Capture `gh pr view`'s stderr and print "none" when it reports no pull requests for the branch, and "not checked" otherwise. Do the same in both parts.
- **Recommendation** — Implement: the scripts exist to make that distinction, and SKILL.md tells the agent to record it.

## Accuracy

### F45 🟠 High Priority - The remaining `local-review` entry has the problem the change removed `doc-review` for

- **Document** — `home/.claude/agents/documentation-expert.md`
- **Location** — Frontmatter, `skills:` (lines 45–46)
- **Issue** — The branch removes `doc-review` because a `skills:` entry injects the skill's full content into the agent at startup. `home/.claude/skills/doc-review/SKILL.md` (Composing the Prompts, lines 143–147) states this as a rule: "Never preload this skill into the agents through a `skills:` declaration … it costs context and reaches no rule the agent needs." The Claude Code sub-agents docs confirm the mechanism: "The full content of each listed skill is injected into the subagent's context at startup". They also say: "If a listed skill is missing or disabled … Claude Code skips it and logs a warning to the debug log."
  - `local-review` is still listed, and that causes problems in two situations:
  - **Repositories without `/local-review`:** this includes the dotfiles repository. The entry points to nothing; `ls home/.claude/skills/ .claude/skills/` shows no `local-review`. Claude Code skips it on every start of this user-wide agent and logs a warning, so the line is dead config.
  - **Projects that have one:** I checked the project this repository's commands are modeled on. There it is a `.claude/commands/local-review.md` of about 2,081 lines (`wc -l`) with no frontmatter, so `disable-model-invocation` does not block preloading. If command files preload the way skills do, that whole orchestrator procedure lands in every documentation-expert in that project. That includes `/doc-review`'s reviewers and collator, which would then hold a second review procedure next to `reviewer-rules.md`, with its own file format and numbering rules. It would also contradict that command's own design premise: its collator section says "The collator does not read this file — it follows the prompt … a cross-reference to a section of this file reaches nobody."
  - Either way the entry is wrong: dead config if command files can't be preloaded, a large conflicting injection if they can.
- **Suggestion** — Delete `  - local-review` and the `skills:` key that would then be empty, so lines 45–46 go away. The agent keeps `Skill` in `tools:`, so it can still invoke either skill on demand. Mention the second removal in the same commit as the first, since they share a rationale.
- **Recommendation** — Implement: this is the same one-line fix with the same justification as the change under review, and leaving it in makes the branch half-apply its own rule.
- **Verification** — unverified: whether a `.claude/commands/*.md` file (as opposed to a `SKILL.md`) is actually preloaded through `skills:`. The skills docs say commands and skills "work the same way" but never address preloading. To settle it, start the agent in a project that has `.claude/commands/local-review.md` with debug logging on (`claude --debug`), dispatch a documentation-expert there, then search the debug log for a skipped-skill warning that names `local-review`. No warning plus a context size that grows by the command's length means it was injected. This writes a debug log and starts a session, so the reviewer did not run it.

### F46 🟡 Medium Priority - Both autosquash routes leave a stray commit when the working tree is dirty

- **Document** — `home/.claude/skills/commit/SKILL.md`
- **Location** — Rewording Under a `commit-msg` Hook (lines 164–182), and the fixup fallback in Reshaping History (lines 100–103)
- **Issue** — Both blocks create a commit first and then run `git rebase --autosquash`:
  - The reword route creates an `amend!` commit. `--fixup=reword:` ignores the index, as `man git-commit` says ("ignoring any changes staged in the index").
  - The fallback creates a `fixup!` commit.
  - `home/.gitconfig` sets no `rebase.autoStash`. A plain rebase refuses to start with unstaged or uncommitted changes, which is normal during a session.
  - The commit is already in place by then. HEAD is left with a stray `amend!` or `fixup!` commit, and the target is unchanged.
  - Line 181 says the chain stops "so the rebase never runs on a half-finished reword". That covers a rejecting hook but not this case.
  - The routes do not report this; they only promise the hook case. `git history fixup` is described as one that "leaves unstaged changes alone", which makes the gap easy to miss.
  - The sibling `.claude/skills/ship-it/SKILL.md` (Reword without squashing) guards the same flow with `git diff --cached --quiet || echo 'staged changes: stop'`.
- **Suggestion** — Start the reword chain with `git diff --quiet && git diff --cached --quiet &&`. Start the fixup fallback with `git diff --quiet &&`, since its staged change is meant to go in. Then add one sentence: stash or commit other work first, because a refused rebase leaves the `amend!` or `fixup!` commit on HEAD.
- **Recommendation** — Defer. This predates the branch and the branch's body changes are line breaks only, but it is a real trap and belongs in a follow-up.
- **Verification** — unverified: in a disposable repository under the scratchpad, make two commits, then leave an unstaged edit. Run `git commit --allow-empty --fixup=reword:HEAD~1 -m x && GIT_EDITOR=true git rebase --autosquash HEAD~2`. The claim is confirmed if the rebase prints `cannot rebase: You have unstaged changes` and `git log --oneline -1` shows the `amend!` commit on HEAD.

### F47 🟡 Medium Priority - Section references to the moved files are qualified with their file in some places and not others

- **Document** — `home/.claude/skills/doc-review/SKILL.md`
- **Location** — Who Does What (line 115); Re-checking Existing Findings (line 263); Walkthrough phases 1–3 (lines 351, 355, 385–386, 465, 470, 489); Recording the rulings, items 5, 7 and 8 (lines 443–454)
- **Issue** — The split added "in `review-file.md`" or "in `reviewer-rules.md`" to some references: File Name, Document Header, Tracking Finding Status at 291, Status Records a Decision at 325 and Redacting Sensitive Evidence at 312. Other references to sections in those same files were left bare:
  - Reviewing Without Editing (115) is in `reviewer-rules.md`.
  - Merging with Existing Findings (263, 452) is in `review-file.md`.
  - Status Records a Decision, Not a Recommendation (351, 445), Membership (355, 385, 470), Order (386, 465), Completion (452, 489) and Tracking Finding Status (443) are all in `review-file.md`.
  - Redacting Sensitive Evidence (454) is in `reviewer-rules.md`.

  Before the split, every name was a section of the one file. Now a reader of SKILL.md searches it for "Membership" and finds no definition. Membership, Order and Completion are bold bullets under Implementation groups, not headings, so they are especially hard to find.
- **Suggestion** — Qualify the first bare reference in each section with its file, e.g. "as Membership (Implementation groups in `review-file.md`) defines". For the recording agent's list, add one lead-in line: "Items 5 and 7 quote `review-file.md`; item 8 quotes `reviewer-rules.md`."
- **Recommendation** — Implement. These are mechanical edits, and without them the orchestrator has no pointer to the rules it applies during the walkthrough.

### F48 🟢 Low Priority - The `scripts/` entry says `test-post.sh` covers changes to any of the scripts, but it does not test `header.sh` and the entry omits `scrub-lib.sh`

- **Document** — `home/.claude/skills/doc-review/SKILL.md`
- **Location** — Opening file list, `scripts/` entry (lines 29–30)
- **Issue** — The entry lists `header.sh`, `scrub.sh` and `post.sh`, plus "`test-post.sh`, run after changing any of them". `test-post.sh`'s header says it holds "End-to-end cases for scrub.sh and post.sh … Run it after changing either script or scrub-lib.sh". It never runs `header.sh`. The shared `scrub-lib.sh`, which a maintainer is most likely to edit when changing the patterns, is not named at all.
- **Suggestion** — "`scripts/` — `header.sh`, `scrub.sh` and `post.sh`, which the steps below and `posting.md` run by their full path under the skill directory; `scrub-lib.sh`, the pattern set the last two share; and `test-post.sh`, run after changing `scrub.sh`, `post.sh` or `scrub-lib.sh`"
- **Recommendation** — Implement. As written, the entry overstates what the test covers.
- **Verification** — Verified by the reviewer by reading `home/.claude/skills/doc-review/scripts/test-post.sh` lines 1–6 and searching it for `header`: there are no matches.

### F49 🟡 Medium Priority - "The scrub's own filename list in PR Comment Format" no longer exists there

- **Document** — `home/.claude/skills/doc-review/reviewer-rules.md`
- **Location** — Redacting Sensitive Evidence, second paragraph (lines 388–390); also third paragraph (line 396)
- **Issue** — The text says "the scrub's own filename list in PR Comment Format is the proof that an authoring rule scoped to a single file is scoped too narrowly".
  - In the old command file, PR Comment Format held the scrub's `find` with all four `-name` patterns inline.
  - After the split, the list lives only in the `artifacts()` function of `home/.claude/skills/doc-review/scripts/scrub-lib.sh` (`*local-review*.md`, `*-DOC-REVIEW*.md`, `*-HANDOFF.md`, `*PLAN.md`).
  - `posting.md`'s PR Comment Format now names only `*local-review*.md` and `*-DOC-REVIEW.md` in passing, and says the list is in `scripts/scrub-lib.sh`.

  A reader who follows the reference finds no list. The proof the sentence relies on is in a script the sentence doesn't name. Line 396's "The scrub in PR Comment Format" is still roughly accurate, since `posting.md` describes the scrub and `scripts/scrub.sh` runs it. It has no file hint, though.
- **Suggestion** — Change the first part to "…and the scrub's own filename list (`artifacts` in `scripts/scrub-lib.sh`) is the proof…". Change line 396 to "The scrub (PR Comment Format in `posting.md`) is the backstop at publishing time".
- **Recommendation** — Implement: the split made the reference stale, and fixing it takes two phrases.
- **Verification** — `grep -n -A4 '^artifacts()' home/.claude/skills/doc-review/scripts/scrub-lib.sh` lists the four patterns. `grep -n 'HANDOFF\|PLAN' home/.claude/skills/doc-review/posting.md` shows no full list in PR Comment Format.

### F50 🟢 Low Priority - Three section cross-references in reviewer-rules.md lack the file hint the move added elsewhere

- **Document** — `home/.claude/skills/doc-review/reviewer-rules.md`
- **Location** — Recommendations, third paragraph (line 270–271, "see Walkthrough and Finding Selection"); Numbered Findings, **Concurred by** bullet (line 331, "see Collating the Reports") and **Ruling** bullet (line 336, "see Tracking Finding Status")
- **Issue** — The move added file hints to the cross-references into other files ("Composing the Prompts in SKILL.md", "PR Comment Format in `posting.md`"), but three were missed:
  - Walkthrough and Finding Selection is in `home/.claude/skills/doc-review/SKILL.md`.
  - Collating the Reports and Tracking Finding Status are in `home/.claude/skills/doc-review/review-file.md`.

  A reviewer reads only this file, so it searches this file for each one and fails. The collator does read `review-file.md`, but it gets no hint about which file to look in. The hint form also varies: "PR Comment Format in `posting.md`" (lines 56, 392) against "PR Comment Format (`posting.md`)" (line 302).
- **Suggestion** — Write "see Walkthrough and Finding Selection in SKILL.md", "see Collating the Reports in `review-file.md`" and "see Tracking Finding Status in `review-file.md`". Rewrite line 302 as "PR Comment Format in `posting.md` names a deferred one…" so every hint uses the "in `file`" form.
- **Recommendation** — Implement: low impact, since these name collator-only fields, but it finishes the hinting pass this branch started, at the cost of a few words.

### F51 🟡 Medium Priority - Document Header does not say who runs `header.sh`, from where, or what `<skill dir>` is

- **Document** — `home/.claude/skills/doc-review/review-file.md`
- **Location** — Document Header, lines 51–58
- **Issue** — The passage has four problems:
  - **Unclear subject.** "…and passes them to the collator. It runs `scripts/header.sh`…": the nearest noun before "It" is the collator, so a collator reading this file can take itself to be the one that runs the script.
  - **Placeholder never defined.** `<skill dir>` is not explained anywhere in this file. `posting.md` line 21 explains the same placeholder: "`<skill dir>` is the skill directory SKILL.md names".
  - **"From the skill directory" reads as a working directory.** `scripts/header.sh` finds each document with `git -C "$(dirname "$doc")"`. If the repository-relative paths the scope produces (e.g. `home/.claude/CLAUDE.md`) are run from the skill directory, they do not resolve, and the script prints `not in a repository` for both fields. `posting.md` uses the same phrase but adds "Every command below runs from the repository root"; this file does not.
  - **Scope order not stated.** The **Branch** row "takes the first document's branch", but the block does not say the documents are passed in scope order. SKILL.md's Dispatching the Collator does say so, where it gives the real command as `'${CLAUDE_SKILL_DIR}/scripts/header.sh'`.
- **Suggestion** — Replace the sentence from "It runs" to the block with: "The orchestrator runs `scripts/header.sh` from the repository root, passing every document in scope order (see Dispatching the Collator in SKILL.md); the collator never runs it and takes the values from its prompt. The script prints each document's path, branch and commit on a tab-separated line. `<skill dir>` is the skill directory SKILL.md names, written as a placeholder because this file is not substituted, so `${CLAUDE_SKILL_DIR}` would reach its reader literally:" and keep the block as it is.
- **Recommendation** — Implement. These are the lines the move rewrote, and the last clause stops a later editor from "fixing" the placeholder into a variable that never expands here.

### F52 🟡 Medium Priority - "(SKILL.md)" hint sends the collator to the wrong file for "Not recommended for this revision"

- **Document** — `home/.claude/skills/doc-review/review-file.md`
- **Location** — Collating the Reports, "Merge duplicates" bullet, line 174
- **Issue** — "File a split finding under Not recommended for this revision (SKILL.md)". The heading the collator files under is the checklist subsection this file defines: the skeleton at line 127, Membership at lines 440–447 and the Pre-Merge Checklist example at line 504. SKILL.md's `#### 2. Not recommended for this revision` is the walkthrough phase, not the checklist heading. SKILL.md is also the one file no agent is given (Composing the Prompts in SKILL.md), so the hint points the collator at text it cannot read and away from the rule it needs.
- **Suggestion** — Change "(SKILL.md)" to "(see Membership under Implementation groups)".
- **Recommendation** — Implement. The move added this hint, and it is wrong.

### F53 🟡 Medium Priority - The post command's placeholders in posting.md slip past post.sh's placeholder check

- **Document** — `home/.claude/skills/doc-review/posting.md`
- **Location** — PR Comment Format, the post command (lines 276–285)
- **Issue** — The command writes `--status '<status summary>' --stats '<stats line>'`, and line 284 says "the script refuses either while it still holds a bracketed placeholder". `post.sh` lines 41–43 test only for square brackets (`*'['*']'*`), which matches the `[status summary]` form that CLAUDE.md and test-post.sh case E use. If an agent copies the document's own command without filling it in, the heading reads `— <status summary>` and the stats line `**<stats line>**`, and both get posted.
- **Suggestion** — Write the two placeholders in the command as `'[status summary]'` and `'[stats line]'`, which is the form the check and CLAUDE.md's template use.
- **Recommendation** — Implement. The check was built for exactly this mistake, and the document's own command gets around it.
- **Verification** — unverified: the reviewer read `post.sh` lines 41–43 but did not run it. To confirm, run test-post.sh's case E with `--status '<status summary>'` and see it post.

### F54 ⚖️ Decision - The `.local` host term needs a path; a port alone does not count

- **Document** — `home/.claude/skills/doc-review/posting.md`
- **Location** — PR Comment Format, lines 123–125 ("`.local` must carry a port or path")
- **Issue** — The term in `scrub-lib.sh` line 26 is `[a-z0-9-]\.local(:[0-9]+)?/`, so the slash is always required. The reviewer ran that term with `grep -iE` under `LC_ALL=C` on three lines. `myhost.local:5432/x` and `myhost.local/x` matched; `db at myhost.local:5432 now` did not. So a host and port with no path, the usual shape of a database or dev-server address, passes both gates. The ship-it scrub.sh header repeats the claim ("requiring that port or path"). This is pre-existing and unchanged from the base.
- **Options**
  - **(a) Change the pattern to match the text:** `[a-z0-9-]\.local(:[0-9]+|/)`. The scrub catches `host.local:5432` as the document promises. The ship-it copy and the other project's /ship-it need the same sync, and test-post.sh needs a case.
  - **(b) Change the text to match the pattern:** "`.local` must be followed by a path, optionally after a port". No code changes, but a mDNS host with a port stays publishable.
- **Recommended** — (a). The document's wording describes the bound that was intended, and a host-and-port pair names the machine as clearly as a host-and-path pair.
- **Ruling** — (a), 2026-10-24 — change doc-review's `.local` term to `\.local(:[0-9]+|/)` in scripts/scrub-lib.sh, with a test-post.sh case; posting.md's text stays as written
- **Verification** — `printf 'db at myhost.local:5432 now\nsee myhost.local:5432/x\nsee myhost.local/x\n' | LC_ALL=C grep -inE '[a-z0-9-]\.local(:[0-9]+)?/'` printed only lines 2 and 3.

### F55 🟢 Low Priority - The posting.md sync comments are inaccurate about the dotfiles /ship-it copy and the tested set

- **Document** — `home/.claude/skills/doc-review/posting.md`
- **Location** — The two HTML comments, lines 5–16
- **Issue** — The first comment says each publisher carries its own pattern set "with the placeholder exemption built into `paths`". `.claude/skills/ship-it/scripts/scrub.sh` does not do this. Its exemption is a perl pre-pass over fixed forms, and its header lists that as an intended difference. The second comment says "the amended `keys`, `schemes` and `secrets` set in scripts/scrub-lib.sh was tested against credential samples" in another project's Step 8. But d1d0f27 on this branch has since changed the table term (backticked and bold key cells) in scrub-lib.sh and in ship-it's copy, but not, as far as this repository shows, in that project. So the set now in scrub-lib.sh is not the one that was tested there.
- **Suggestion** — In the first comment, write "with the placeholder exemption built into `paths`, or, in the dotfiles /ship-it, applied as the pre-pass its header lists". In the second, write "where an earlier form of the `keys`, `schemes` and `secrets` set in scripts/scrub-lib.sh was tested … ; the table term's backtick and bold allowance has not been synced there yet", or drop that clause once it has been synced.
- **Recommendation** — Implement. These comments are what a maintainer syncing either way relies on.
- **Verification** — Confirmed by the orchestrator with a read-only grep of other projects' `/ship-it` files: their copies still carry the old table term, with no backtick or asterisk allowance, so the "has not been synced there yet" clause applies.

### F56 🟢 Low Priority - Overstated claims about post.sh's refusals and splitting

- **Document** — `home/.claude/skills/doc-review/posting.md`
- **Location** — PR Comment Format, line 24 ("`post.sh` opens with the same two checks"), lines 285–286 ("Each gate refuses with a message that says what to fix and `do not post`") and lines 319–320 ("a fenced block inside one is never cut open")
- **Issue** — Three claims overstate what the script does:
  - `post.sh` runs the open-finding checks only after parsing its arguments, checking the placeholders and file readability, sourcing scrub-lib.sh and validating the cleared-findings file.
  - Several refusals don't say `do not post`: "review body is empty — refusing to post", "review file has no title…", "cannot read $post_file", "one section of the review is over the limit…", and a failed `git rev-parse` exits with git's own message.
  - The splitter in awk breaks at any line matching `^##+ `, including a non-indented heading inside a fenced block that quotes Markdown. The ship-it SKILL.md acknowledges this case for its own check. The fence claim is pre-existing.
- **Suggestion** — Write "post.sh runs the same two checks `/ship-it` runs…", then "Each refusal says why and exits non-zero: report it to the user and post nothing by another route". For the split, write "so a finding is never split across two comments; a heading at the start of a line inside a fenced block is still a cut point, so indent quoted Markdown as reviewer-rules.md's example does".
- **Recommendation** — Implement. These are wording fixes that keep the document's claims within what the script does.

### F57 🟡 Medium Priority - The walkthrough example's keep-in-sync comment names sections but not the files they are in

- **Document** — `home/.claude/skills/doc-review/walkthrough-example.md`
- **Location** — HTML comment, lines 6–7
- **Issue** — The comment says to keep this file in sync with "the Pre-Merge Checklist example and the Consolidated Summary example table … and with the F8 example under Tracking Finding Status". None of those sections is in this file, and the comment does not name the file they are in. In the base, all of them were in the same file as the example, so section names were enough. After the split they are all in `review-file.md`, and someone reading the comment here has no file to look in. The comment also leaves out an example the F5 question restates: the F5 ⚖️ Decision example under Numbered Findings in `home/.claude/skills/doc-review/reviewer-rules.md`, lines 349–359, which supplies the question's Issue wording, the costs of both options and the Recommended reason. That omission already existed at the base commit. The links in the other direction are incomplete too: `review-file.md` lines 478–479 still call this file "the Walkthrough and Finding Selection example" (F138), and lines 294–295 say "the walkthrough example" without a file name (F16).
- **Suggestion** — Replace the comment with:

  ```markdown
  <!-- Keep in sync with the Pre-Merge Checklist example, the Consolidated Summary example table
       and the F8 example under Tracking Finding Status in review-file.md, whose finding set this
       reuses, and with the F5 Decision example under Numbered Findings in reviewer-rules.md, whose
       Options and Recommended line the F5 question restates -->
  ```

- **Recommendation** — Implement: the move broke these references, and a sync comment that points nowhere is how examples drift apart.

### F58 🟢 Low Priority - The walkthrough example's closing paragraph cites "Tracking Finding Status" without naming its file

- **Document** — `home/.claude/skills/doc-review/walkthrough-example.md`
- **Location** — Closing paragraph, lines 37–38 ("in the form Tracking Finding Status shows")
- **Issue** — Tracking Finding Status is a section of `review-file.md`, not of this file. Elsewhere in the skill the file is named when a section in another file is cited: `SKILL.md` line 291 has "see Tracking Finding Status in `review-file.md`", and line 325 does the same. In the base the section was in the same file, so the bare name worked. The split introduced the problem.
- **Suggestion** — Change "in the form Tracking Finding Status shows" to "in the form Tracking Finding Status in `review-file.md` shows".
- **Recommendation** — Implement: a single phrase, and the split introduced it.

### F59 🟡 Medium Priority - Handoff's Header section points at shell variables and a command that Gathering State no longer shows

- **Document** — `home/.claude/skills/handoff/SKILL.md`
- **Location** — Document Structure › Header, lines 192–197
- **Issue** — The section says "The base branch is the `$base` resolved in **Gathering State**. When `base_source` is not the pull request…" and "Record **Commit** from `git rev-parse --short HEAD` in **Gathering State**." Both names now exist only inside `gather-state.sh`; the agent never sees them. The script's output is `base: <name> (<source>)` under `== base`, where the source is `pull request`, `repository default` or `assumed`, and the short SHA alone under `== head`. Gathering State no longer contains `git rev-parse --short HEAD` at all.
- **Suggestion** — Reword as: "The base branch is the name on the `base:` line of the script's `== base` part. When its source in parentheses is not `pull request`, say where it came from…" and "Record **Commit** from the `== head` line of the script's output."
- **Recommendation** — Implement: this sentence was written for the inline block, and an agent following it looks for variables it cannot see.

### F60 🟡 Medium Priority - "Print the same nothing" no longer describes the handoff script, and the comments part's "not checked" also means "no pull request"

- **Document** — `home/.claude/skills/handoff/SKILL.md`
- **Location** — Gathering State, lines 103–107
- **Issue** — The paragraph says a missing pull request and a broken `gh` "print the same nothing". The script now prints fallback text:
  - `== pull request` prints `no pull request found, or gh unavailable` in both cases.
  - `== pull request comments and reviews` prints `not checked` in both cases, including when `gh` works and the branch has no pull request.
  - The script's own header comment says a "not checked" line "is never the same as 'none'", but here "not checked" can mean exactly "none opened". The document does not warn the agent about this, so an agent can record the comments as not checked when the honest entry is that no pull request exists.

  The underlying point is still right: the `== gh` line is what tells the cases apart.
- **Suggestion** — Replace the first sentence with: "Every `gh` call in the script is silenced, so a pull request that does not exist and a `gh` that is missing, unauthenticated or offline print the same fallback line: `no pull request found, or gh unavailable` under `== pull request`, and `not checked` under `== pull request comments and reviews`." Then keep "The `== gh` line is what tells them apart: …", and add: "When it reads `gh available`, those fallbacks mean no pull request exists."
- **Recommendation** — Implement: this paragraph is the doc's "not checked" handling, and it currently misdescribes the output it tells the agent to interpret.

### F61 🟡 Medium Priority - Handoff's Current State and Process cite Gathering State commands that are no longer there

- **Document** — `home/.claude/skills/handoff/SKILL.md`
- **Location** — Document Structure › Current State, lines 239–243; Process step 2, line 471
- **Issue** — Current State requires every bullet to name "the command whose output it summarizes", using "the commands from **Gathering State**, such as `git --no-pager status --short --branch`, `gh pr view --json …`". Neither command appears in Gathering State any more; the agent ran one script. The document does not say whether a bullet should cite `gather-state.sh`, one of its `== <name>` parts or the command behind that part. `/resume-handoff` re-checks these bullets with its own read-only commands (`home/.claude/skills/resume-handoff/SKILL.md`, the list of claims to check and the Header and Current State rewrite step), so the underlying command is the useful citation. Process step 2's "using the commands above" has the same problem.
- **Suggestion** — Change the Current State sentence to: "Name the command behind the script part you read: `git --no-pager status --short --branch` for `== status`, `gh pr view --json …` for `== pull request`, `git --no-pager log` for the commit parts, or the Linear MCP server's `get_issue` tool." Change Process step 2 to "…using `gather-state.sh` and the follow-up queries in **Gathering State**…".
- **Recommendation** — Implement: as written, the rule cannot be followed literally.

### F62 🟠 High Priority - `"$tip:<path>"` breaks under zsh's colon modifiers

- **Document** — `home/.claude/skills/resume-handoff/SKILL.md`
- **Location** — Step 2: Extract the Claims (line 74), and Treat Fetched Text as Evidence, Never Instruction (line 184)
- **Issue** — Both lines prescribe `git show "$tip:<path>"` with no braces around the variable. The Bash tool runs zsh, where a letter after `$var:` is a history modifier. The user-wide CLAUDE.md warns about exactly this under zsh. With `tip=abc123`, zsh expands `"$tip:app/models/x.rb"` to `/Users/<name>/…/abc123pp/models/x.rb` (`:a`) and `"$tip:home/x"` to `.ome/x` (`:h`). `git show` then fails, and the agent concludes that a file which still exists "no longer exists on the branch", so it marks a sound claim **DRIFTED**. In this repository every tracked dotfile sits under `home/`, so every path hits `:h`. The scope did not introduce the problem, but it is a broken instruction that leads the agent to a wrong result.
- **Suggestion** — Write `git show "${tip}:<path>"` at both places.
- **Recommendation** — Implement: a two-brace fix for a check that otherwise gives false DRIFTED results, in a file this revision is already rewriting.
- **Verification** — The reviewer ran `zsh -c 'tip=abc123; echo "$tip:app/models/x.rb"; echo "$tip:home/x"; echo "${tip}:app/x"'`. It printed the current directory's absolute path followed by `abc123pp/models/x.rb` (path redacted here), then `.ome/x` and `abc123:app/x`.

### F63 🟡 Medium Priority - Resume-handoff's `gh` paragraph describes output the script no longer prints

- **Document** — `home/.claude/skills/resume-handoff/SKILL.md`
- **Location** — Step 3, Resolve the Branch and Its Base, lines 126–130
- **Issue** — The text says that a missing pull request and a missing or offline `gh` "print the same nothing", and that the signal is "the `gh api user` warning". Both described the inline block the scope removed. `gather-state.sh` now prints fallback text: `no pull request found, or gh unavailable` under `== pull request` and `not checked` under `== pull request comments and reviews`. Its availability check prints `gh available` or `gh unavailable — pull request, CI and issue state not checked` under `== gh`. Nothing in the output mentions `gh api user`, so the agent is told to look for a warning by a name it will never see.
- **Suggestion** — Reword to describe the script's output, for example: "Every `gh` call is silenced, so the `== pull request` part prints the same `no pull request found, or gh unavailable` whether the pull request is missing or `gh` is missing, unauthenticated or offline. When the `== gh` part says `gh unavailable`, every pull request, CI and issue claim is **UNVERIFIABLE**." Keep the sentence about `gh auth status`, and call the check "the script's `gh api user` check" if it is still named at all.
- **Recommendation** — Implement: this wording was left behind when the script replaced the block, and the agent relies on it to decide whether `gh` claims are UNVERIFIABLE.

### F64 🟡 Medium Priority - "The final part of `gather-state.sh`'s output" is often not that part

- **Document** — `home/.claude/skills/resume-handoff/SKILL.md`
- **Location** — Step 3, Also Check, "What the base absorbed" (lines 206–209); also the invocation at line 106
- **Issue** — The script prints `== commits on <base> since <updated> touching the files the handoff names` only when file arguments were passed *and* both the base and the tip resolved (`gather-state.sh` lines 71–77). Otherwise the last part is something else:
  - With no files, the last part is `commits on <branch> since <base>`, which lists the branch's own commits and could be read as "what landed on the base".
  - With an unresolved tip, the last part is `pull request comments and reviews`, and neither commit part prints at all.

  The invocation at line 106 also makes the files look required (`<file the handoff names>...`), but the script's usage marks them optional (`[file]...`). The other place that refers to script output (line 163) names the part by its header, which is the more reliable form.
- **Suggestion** — Refer to the part by its header: "The `commits on <base> since <updated> touching the files the handoff names` part of `gather-state.sh`'s output lists …". Add: "It is absent when no files were passed or when the base or tip did not resolve. An absent part was not checked; it does not mean nothing landed." Write the invocation's file list as `[<file the handoff names>...]`.
- **Recommendation** — Implement: the scope introduced the "final part" wording, and the misreading turns an unchecked claim into a confirmed one.

### F65 🟢 Low Priority - The reflog is said to be "empty" when it actually fails

- **Document** — `home/.claude/skills/resume-handoff/SKILL.md`
- **Location** — Step 3, When the Branch Moved, lines 151 and 154–155
- **Issue** — The text says the reflog "is empty when the tip came from `origin` or the pull request". In that case there is no `refs/heads/<branch>`, and `git reflog show <branch>` exits 128 with `fatal: ambiguous argument … unknown revision`. Because the command ends in `| head -20`, the pipeline still reports success. The scope did not introduce this, but it did edit this block.
- **Suggestion** — Say "it fails with `unknown revision` when the tip came from `origin` or the pull request, since there is no local branch to have a reflog". Alternatively, guard the line with `git show-ref --verify --quiet "refs/heads/${branch}" &&`.
- **Recommendation** — Implement: a one-clause correction in a block this revision already touched.
- **Verification** — The reviewer ran `git --no-pager reflog show --date=iso no-such-local-branch-xyz 2>&1 | head -3; echo "rc=${pipestatus[1]}"`. It printed `fatal: ambiguous argument …` and `rc=128`.

### F66 🟢 Low Priority - The loss check's own deletion and its exit 2 go unmentioned

- **Document** — `home/.claude/skills/resume-handoff/SKILL.md`
- **Location** — Step 4, lines 281–290
- **Issue** — "Check that nothing was lost, and delete the backup only if nothing was" reads as an instruction for the agent to delete the backup. In fact `check-loss.sh` deletes it and prints `nothing lost; removed <handoff>.bak` (line 35). The prose also covers exit 1 but not exit 2, which the script uses when the handoff or its `.bak` cannot be read.
- **Suggestion** — "Check that nothing was lost. The script removes the backup itself when nothing was, and prints `nothing lost; removed <handoff>.bak`." After the exit 1 sentence, add: "Exit 2 means the handoff or its backup could not be read: stop and tell the user."
- **Recommendation** — Implement: two short sentences that make the prose match what the script does.

### F67 🟢 Low Priority - Step 10 still hands the sub-agent "the whole … section" through a link it cannot resolve

- **Document** — `home/.claude/skills/update-deps/SKILL.md`
- **Location** — Step 10, Draft the Message, second bullet (lines 220–221)
- **Issue** — The text now reads "The conventions below, and the whole [Known Changelog Quirks](changelogs.md#known-changelog-quirks) section". The quirks are no longer a section of this file; they are the whole of `changelogs.md`. The relative link means nothing to the documentation-expert sub-agent, whose working directory is the app repository. `${CLAUDE_SKILL_DIR}` is substituted only in SKILL.md. Passed as written, the sub-agent may look for `changelogs.md` in the app repository and find nothing.
- **Suggestion** — Reword to "The conventions below, and the full contents of `${CLAUDE_SKILL_DIR}/changelogs.md` (Known Changelog Quirks), pasted into its prompt, so it does not rediscover a known quirk".
- **Recommendation** — Implement. The split introduced this, and the sub-agent is the one reader that cannot resolve the link.

### F68 🟠 High Priority - The `3d` age gate is not honored on Yarn 4.10.x, the oldest version the step says has the gate

- **Document** — `home/.claude/skills/update-deps/javascript.md`
- **Location** — Run Yarn with a Release-Age Gate and No Install Scripts (lines 26 and 34–41), plus the gated commands at lines 52 and 101
- **Issue** — The step sets the gate as `YARN_NPM_MINIMAL_AGE_GATE=3d` and says only "Yarn older than 4.10 has no gate". But on Yarn 4.10.x `npmMinimalAgeGate` is read as a number of minutes, and a day suffix is silently not honored. yarnpkg/berry#6991, reported on 4.10.3, shows `"7d"` letting a 5-day-old release through while `4320` excluded it. The maintainer replied that the only fix is to upgrade, and the reporter says duration suffixes came in a later release. So on 4.10.x the gated prefix gives no protection and prints no warning, which defeats the step's stated purpose.
  - A related problem: the instruction to read `yarn config get npmMinimalAgeGate` "in minutes" and compare it with `4320` assumes a numeric output. A repository that sets the gate as a duration string (`1w`) on a newer Yarn may print that string instead.
  - Third-party write-ups also disagree on whether newer Yarn turns the gate on by default (`1440` is cited for 4.18). That affects the "A `0` is not a reason to drop it" reasoning.
  - This problem predates the branch: the text moved verbatim.
- **Suggestion** — Write the gate as `YARN_NPM_MINIMAL_AGE_GATE=4320`, which every gate-capable Yarn reads as three days. Also say how to compare a duration-string value printed by `yarn config get`. The same prefix appears in version-locked.md and pins.md, so sweep all three files.
- **Recommendation** — Defer. Do it in a follow-up that changes the prefix in javascript.md, version-locked.md and pins.md together. This branch is a verbatim structural move, and the edit is a behavior change across three files. The fix is small, so schedule it soon.
- **Verification** — unverified. What the reviewer could confirm from the issue page: 4.10.3 ignores `7d` and honors `4320`. Still unconfirmed: the exact version that added duration parsing, and what `yarn config get` prints for a duration value. Settle both with `yarn set version 4.10.3 && YARN_NPM_MINIMAL_AGE_GATE=3d yarn config get npmMinimalAgeGate`, then the same on the current 4.x, in a throwaway Yarn project. Also read the Yarn 4.11 changelog entry for `npmMinimalAgeGate`.

### F69 🟡 Medium Priority - The hold-check repair restores a range hold without the age gate, after the gated re-resolution has already run

- **Document** — `home/.claude/skills/update-deps/javascript.md`
- **Location** — Re-resolve the Lock File, final paragraph (lines 129–130)
- **Issue** — "If the held package itself moved, restore it with `yarn up '<pkg>@<spec>'` and the restore prefix, and repeat the check." The restore prefix leaves out the gate. The step justifies that at lines 81–87 only because the gated `yarn up -R '*'` comes afterwards and moves a restored range back.
  - This repair runs after that re-resolution. A range hold (a tilde, or a caret on a prerelease) restored here can therefore take a release younger than three days, and nothing gates it.
  - The failure path at lines 110–112 already handles the same case ("If any restored hold is a range, re-run those restores … with the gated prefix"), so the two paragraphs disagree.
  - "the held version" is also undefined for a range hold.
  - This problem predates the branch.
- **Suggestion** — Repair an exact-version hold with the restore prefix and a range hold with the gated prefix, matching lines 110–112. For a range hold, say that "held" means the copy satisfies the restored range.
- **Recommendation** — Defer. The text predates the branch, and the move should stay verbatim. Pair this with F68's follow-up, since both change the prefix rules.

### F70 🟡 Medium Priority - `npx playwright --version` can download and run the newest Playwright instead of reporting the installed one

- **Document** — `home/.claude/skills/update-deps/version-locked.md`
- **Location** — Playwright, comparison block, line 26
- **Issue** — The block says it compares the two sides "as installed". However, `npx` looks only for a local `node_modules/.bin` binary. In a Yarn Berry repository that uses Plug'n'Play, which has no `node_modules`, `npx` falls back to downloading the package from the registry. The npm 11.20.0 docs (`npm help exec`) say: "When standard input is not a TTY or a CI environment is detected, --yes is assumed. The requested packages are installed to a folder in the npm cache". Without a TTY, the agent therefore gets the newest `playwright` from npm with no prompt, outside the age gate. The command reports that version rather than the locked one and executes the downloaded package. That undercuts the guarantee in `javascript.md` that "no newly resolved package runs code on this machine". A repository on `nodeLinker: node-modules` is unaffected. The text is unchanged from the base.
- **Suggestion** — Replace the line with `yarn playwright --version   # prints "Version <x.y.z>"`. Yarn runs the binary the project resolved under either linker and resolves nothing new.
- **Recommendation** — Defer. This is a verbatim move, and the fix should be checked against a Plug'n'Play repository first.
- **Verification** — The reviewer read `npm help exec` (npm 11.20.0), which states the non-TTY `--yes` default quoted above, and did not run `npx` in a Plug'n'Play repository.

### F71 🟡 Medium Priority - `--review` accepts any file, so the withheld-number check can be derived from the withheld copy itself

- **Document** — `home/.claude/skills/doc-review/scripts/post.sh`
- **Location** — argument parsing (line 26), open-findings check (lines 53–56) and the `ids` extraction for Gate 2 (lines 117–125)
- **Issue** — The old block fixed `review_file` to `$(git rev-parse --show-toplevel)/<name>-DOC-REVIEW.md`, so the open-findings check and the list of withheld numbers always came from the full root artifact. `post.sh` takes `--review` as a free path and never checks it, so nothing ties it to the file Gate 1 scanned or to the original review.
  - **The bypass:** pass the withheld copy as `--review`, either with no `--post` or with the same copy. The withheld numbers are then read from a file whose Sensitive Information heading and summary row are already gone. Any trace the withholding missed is posted.
  - **Reproduced** with a synthetic review: F2 was a Sensitive Information finding, and the copy dropped its `###` entry and summary row but kept `- [x] F2 rotate the value at line 4 of deploy.md`.
    - `--review <original> --post <copy>` refused (`withhold: F2 is still in the comment`).
    - `--review <copy>` posted (rc 0, one post) with that checklist line in the body. The heading also named the copy's temporary base name, which breaks how `/ship-it` finds the earlier comment.
- **Suggestion** — After `root` is set, refuse a review file that is not a root-level review artifact:

  ```bash
  [ "$(dirname -- "$review_file")" -ef "$root" ] \
    || { echo "post: --review must be the review file in $root — do not post" >&2; exit 1; }
  case "$(basename -- "$review_file")" in
    *-DOC-REVIEW*.md | *local-review*.md) ;;
    *) echo "post: --review is not a review artifact — do not post" >&2; exit 1 ;;
  esac
  ```

  Add a `test-post.sh` case that passes the copy as `--review`.
- **Recommendation** — Implement: the gate exists to catch exactly this kind of agent mistake. The old block's fixed prefix made it much harder, and the fix is a few lines.

### F72 🟡 Medium Priority - Gate 1 in `post.sh` passes silently when it scans no artifacts, unlike the old block (a regression)

- **Document** — `home/.claude/skills/doc-review/scripts/post.sh`
- **Location** — Gate 1 (lines 60–63), and the sourcing of `scrub-lib.sh` (line 49); `home/.claude/skills/doc-review/posting.md`, PR Comment Format, lines 59–63, 85–93 and 288–290
- **Issue** — In the old flow the scrub block ran in the same shell first and set `scrub_pid` last. It printed the files it scanned and refused an empty set, and the post block's guard would not run without it. `post.sh` sources only the library and calls `scan`. When `find` matches nothing, `grep_artifacts` prints nothing and exits 0, so Gate 1 passes on an empty set and no file list is printed.
  - posting.md's own rule is broken: "Empty output means nothing matched only if `grep` actually ran" and "Capture the file list and fail loudly when it is empty".
  - **Reproduced:**
    - From the repository holding a `*-HANDOFF.md` with a synthetic home path, `post.sh` refused (`unresolved hits`).
    - From a second repository with no artifacts, given the same absolute `--review`, it posted (rc 0, one post) with no warning.
    - In that run the pull request was also resolved from the *second* checkout's branch.
    - `scrub.sh` in the same directory correctly exited 2 (`nothing was scanned`).
  - Gate 2 still scans everything posted, so this is a lost gate and a wrong-checkout hazard, not a direct leak.
  - From the concurring report: posting.md says the empty-set and wrong-directory outcomes are made visible by "the readability checks, the exit-code branches and the echoed file list in the scripts", and that "the first [scrub] covers the artifacts". Only `scrub.sh` does that (lines 20–22). The silent pass also happens when `--review` names a file outside the root or one that does not match `*-DOC-REVIEW*.md`, and `post.sh` never checks that `--review` is one of the files scanned (see F71). Gate 1 is the re-verification the document promises.
- **Suggestion** — After sourcing the library in `post.sh`, check the artifact list as `scrub.sh` does:

  ```bash
  scanned="$(artifacts -print)"
  [ -n "$scanned" ] || { echo "scrub: no artifacts under $root — do not post" >&2; exit 1; }
  printf 'scrub: scanned these files\n%s\n' "$scanned" >&2
  ```

  Together with F71's root check, this also makes a wrong working directory fatal. The concurring report adds: also refuse when the `--review` path is not in the scanned list, and add a test-post.sh case for each, so posting.md's claims hold as written.
- **Recommendation** — Implement: it restores a check the old block had and the prose still promises, and the check costs two lines.
- **Verification** — unverified: create a scratch repository with `t-review.md` (not matching any artifact pattern) and the stub `gh` from test-post.sh, then run `bash home/.claude/skills/doc-review/scripts/post.sh --review "$PWD/t-review.md" --repo o/r --status 'all clear' --stats '1 finding — 1 fixed'`; it is expected to post rather than refuse. Not run by the orchestrator; the security reviewer's own reproduction above is reviewer evidence.
- **Concurred by** — `home/.claude/skills/doc-review/posting.md`, also 🟡 Medium Priority and Implement

### F73 🟡 Medium Priority - A `--post` path that names the review file differently makes `post.sh` delete the review file

- **Document** — `home/.claude/skills/doc-review/scripts/post.sh`
- **Location** — line 148, `[ "$post_file" = "$review_file" ] || rm -f -- "$post_file"`; header line 21 ("the review file itself is left for the caller")
- **Issue** — The guard compares path strings, not files. A relative path, a symlink or a `/private/var` versus `/var` spelling of the same file all differ as strings.
  - **Reproduced:** `--review <abs>/t-DOC-REVIEW.md --post t-DOC-REVIEW.md` from the root posted, then deleted the review file. The code-quality reviewer reproduced it independently with `--review "$repo/t-DOC-REVIEW.md" --post ./t-DOC-REVIEW.md`: the repository directory was empty afterwards.
  - That file is the only local record of the withheld Sensitive Information findings. The count line in the posted comment points readers to it ("see the local artifact"). Review files are untracked, so the local record is lost for good.
  - The old block had the same string comparison, but there the path was assembled in the block rather than taken from a command-line flag.
- **Suggestion** — Compare files rather than strings, the same `-ef` test `.claude/skills/ship-it/scripts/scrub.sh` line 60 already uses for its own same-file check:

  ```bash
  [ "$post_file" -ef "$review_file" ] || rm -f -- "$post_file"
  ```

  Apply the same `-ef` test to the two cleared-list deletions.
- **Recommendation** — Implement: a one-word change that protects the one artifact the withholding design depends on, against an unrecoverable data loss.
- **Concurred by** — `home/.claude/skills/doc-review/scripts/post.sh` (code-quality report), also 🟡 Medium Priority and Implement

### F74 🟡 Medium Priority - A column-aligned summary table defeats both the open-findings check and the summary-row Sensitive Information detection

- **Document** — `home/.claude/skills/doc-review/scripts/post.sh`
- **Location** — line 53 (`'^\| F[0-9]+ \|.*\| ❓ \|'`) and line 121 (`/^\| F[0-9]+ \|/`)
- **Issue** — Both patterns require exactly one space on each side of the finding number and the ❓. A table whose columns are padded to width breaks both. That is the layout Prettier writes, and the one an agent produces when it follows reviewer-rules' own "Tables — Aligned columns" criterion.
  - **Reproduced:** an aligned table holding a synthetic open row `| F1      | … | ❓     |` and a row `| F3      | … | Sensitive Information | … |`, where F3 sat under `## Observations` (the filed-elsewhere case the row check exists for). `post.sh` posted both (rc 0, one post).
  - This predates the branch; the old block had the identical patterns.
- **Suggestion** — Accept padding in both places:

  ```bash
  command grep -nE '^\|[[:space:]]*F[0-9]+[[:space:]]*\|.*\|[[:space:]]*❓[[:space:]]*\|' /dev/null "$review_file"
  ```

  In the `ids` awk, change the row test to `/^\|[[:space:]]*F[0-9]+[[:space:]]*\|/`. The `split` already trims the padding. Add an aligned-table case to `test-post.sh`.
- **Recommendation** — Implement: the withholding check guards a pointer to a live credential, and the fix is two regexes.

### F75 🟢 Low Priority - The open-findings `grep`s, the title `sed` and the `awk` passes run in the caller's locale

- **Document** — `home/.claude/skills/doc-review/scripts/post.sh`, `home/.claude/skills/doc-review/scripts/scrub-lib.sh`
- **Location** — `post.sh` lines 53–54, 67 and 117; the `uncleared` function in `scrub-lib.sh` (lines 56–59)
- **Issue** — posting.md requires `LC_ALL=C` for every scrub `grep`, because macOS tools misread lines holding an invalid byte under UTF-8. The pattern scans follow that rule; these checks do not.
  - **Reproduced** under `LANG=en_US.UTF-8`: a ❓ row holding a byte `\377` was missed by the open-findings `grep`. Under `LC_ALL=C` it was caught.
  - The post still refused, but only by accident: the `ids` awk died with `towc: multibyte conversion failure`, which the script reports as "cannot read the review file".
  - So the open-findings gate fails open on its own, the true cause is hidden, and the outcome depends on which awk is installed.
  - This predates the branch.
- **Suggestion** — Prefix `LC_ALL=C` to the two open-findings `grep`s, the title `sed`, the `ids` `awk` and the `awk` inside `uncleared`.
- **Recommendation** — Implement: a mechanical change that makes the refusal depend on the check rather than on an awk crash.

### F76 🟢 Low Priority - Several steps in `post.sh` ignore their own failure

- **Document** — `home/.claude/skills/doc-review/scripts/post.sh`
- **Location** — line 51 (cleared-findings validation), line 57 (`mktemp -d`), lines 78–87 (the splitting `awk`)
- **Issue** — Three steps carry on after a failure:
  - **Validation:** `! command grep -vxE 'F[0-9]+' "$cleared_findings"` treats grep's exit 2 (read error) as "valid". With a directory as `--cleared-findings` or `--cleared`, grep printed "Is a directory" and the run went on to `gh pr view`. It was then stopped by a later check, so the result was fail-closed only by accident.
  - **`mktemp`:** when `mktemp` fails (stubbed on PATH), `work_dir` is empty. awk then tries to write `/part-000`, and the script exits with the misleading "one section … over the limit". Where `/` is writable (a root container) the parts land world-readable in `/`, the `trap` removes nothing, and a stale `/comment-*` would be picked up by the glob.
  - **Splitting `awk`:** its exit status is never checked, so a partial split would post a truncated review.
- **Suggestion** — Make each failure fatal:

  ```bash
  work_dir="$(mktemp -d -t pr-comment)" && [ -d "$work_dir" ] \
    || { echo "mktemp failed — do not post" >&2; exit 1; }
  ```

  Then:
  - add `|| { echo "could not split the review — do not post" >&2; exit 1; }` after the splitting `awk`;
  - require `[ -f "$cleared_findings" ] || [ "$cleared_findings" = /dev/null ]`, and the same for `--cleared`, before validating either file.
- **Recommendation** — Implement: cheap hardening, and it replaces misleading messages with accurate ones.

### F77 🟢 Low Priority - The Sensitive Information section tracking treats a `## ` line inside a code fence as a new section

- **Document** — `home/.claude/skills/doc-review/scripts/post.sh`
- **Location** — `ids` awk, `/^## / { s = /^## Sensitive Information/ }` (line 119); the same blindness to fences applies to the split at line 85
- **Issue** — A finding in the Sensitive Information section that quotes Markdown containing `## Example` in a fence switches `s` off. Every later `### F` heading in that section is then missed.
  - **Reproduced:** F3 after such a fence was found only through its summary row.
  - Reviews of these skill files routinely quote `##` headings. Combined with F74, both detectors can miss the same finding.
  - The splitter also cuts at a fenced `## ` line. posting.md's claim that "a fenced block inside one is never cut open" therefore does not hold, though the only effect is rendering (see F56).
- **Suggestion** — Track fences in both awk programs, for example `/^(```|~~~)/ { fence = !fence }`, and test the heading only when `!fence`.
- **Recommendation** — Defer: the summary row is an independent second detector, so this matters mainly together with F74. Fix it in the same follow-up.

### F78 🟢 Low Priority - The widened key-cell term still misses quoted, HTML-coded and NBSP-padded key cells

- **Document** — `home/.claude/skills/doc-review/scripts/scrub-lib.sh`, `.claude/skills/ship-it/scripts/scrub.sh`
- **Location** — `scrub-lib.sh` line 36; `ship-it/scripts/scrub.sh` line 88
- **Issue** — The reviewer compared the old and new terms on 22 synthetic lines with `LC_ALL=C grep -iE`.
  - **Newly caught:** a key wrapped in backticks, double backticks, `**…**`, `*…*` or ``**`DB_…`**``.
  - **No regression:** no line the old term caught is missed now.
  - **Still missed by both:** `| "password" | x |`, `| 'PASSWORD' | x |`, `| <code>password</code> | x |`, `| [password](x) | x |`, `| ~~password~~ | x |` and a key cell padded with a non-breaking space (`\xC2\xA0`), which tables pasted from rendered pages carry.
  - The several-word form is documented as left to the reading pass; these single-word forms are not.
- **Suggestion** — Add the quote characters to both padding classes, ``[[:space:]*`"']*``, in both copies. Then either list the remaining forms in posting.md as left to the reading pass, or add `\xC2\xA0` to the padding class too, which works under `LC_ALL=C`.
- **Recommendation** — Implement the quotes now. They are the likeliest of these in documentation (env var tables often quote YAML keys) and cost one character class.

### F79 🟢 Low Priority - Mentions and cross-references from review text reach the posted comment unchecked

- **Document** — `home/.claude/skills/doc-review/scripts/post.sh`
- **Location** — Gate 2 (lines 116–139)
- **Issue** — Gate 2 blocks email addresses but not a bare `@login`, `#N` or `owner/repo#N`. The reviewer confirmed with the stub that `@octocat`, `#12` and `owner/repo#3` in the body and in `--stats` were posted as written.
  - A review quoting a document's prose, such as `@types/node` outside a code span or a scope name, can make GitHub notify that account.
  - A cross-repository reference can leave a backlink on another repository's issue.
  - The user's guidance forbids exactly that in published text, and the document under review is attacker-controllable.
  - Neither path leaks a scanned value.
- **Suggestion** — Have Gate 2 print a warning, not a block, for ``(^|[^a-z0-9_`/.-])@[a-z0-9-]+`` and `[a-z0-9_.-]+/[a-z0-9_.-]+#[0-9]+` outside code spans. Or tell reviewers in reviewer-rules to quote such tokens in backticks.
- **Recommendation** — Defer: low impact and prone to false positives, so it is better designed separately than added to this branch.
- **Verification** — unverified. Whether a mention in a posted comment notifies the account needs a live post on a throwaway repository: `gh pr comment <throwaway PR URL> --body 'test @<a second account you own>'`, then check that account's notifications. The reviewer did not run it because the real `gh` was off-limits.

### F80 🟠 High Priority - header.sh is not executable, so the documented invocation fails

- **Document** — `home/.claude/skills/doc-review/scripts/header.sh`
- **Location** — file mode; invoked from `home/.claude/skills/doc-review/SKILL.md`, Dispatching the Collator (line 267) and the `scripts/` entry in the opening list (lines 29–30), and from `home/.claude/skills/doc-review/review-file.md`, Document Header (line 57)
- **Issue** — `git ls-files -s` records `100644` for `header.sh`; every other script run by path (`scrub.sh`, `post.sh`, `test-post.sh`) is `100755`. Both `doc-review/SKILL.md` line 267 and `review-file.md` line 57 run it directly as `'<skill dir>/scripts/header.sh' <document>...`, and SKILL.md's opening list says the scripts are "run by their full path". Running it that way gives `permission denied` with exit 126. The header values the collator needs then never resolve, or an agent improvises `bash header.sh`. `test-post.sh` did not catch it because it never runs `header.sh` and runs the other scripts through `bash`, not by path (see F120).
- **Suggestion** — Run `chmod +x home/.claude/skills/doc-review/scripts/header.sh` and stage the mode change with `git add`, committing it as 100755 like its siblings. Do not prefix the call with `bash`: that would make it the one script invoked differently.
- **Recommendation** — Implement: a documented step of `/doc-review` is broken as shipped, and it is a one-bit fix to a step the procedure cannot skip.
- **Verification** — Verified by the doc-review SKILL.md reviewer (read-only): `git ls-files -s home/.claude/skills/doc-review/scripts` lists `header.sh` as 100644 and the other three as 100755. `test -x` on `header.sh` returns 1, and on `scrub.sh`, `post.sh` and `test-post.sh` returns 0. The documented invocation itself was not run.
- **Concurred by** — `home/.claude/skills/doc-review/SKILL.md`, also 🟠 High Priority and Implement

### F81 🟡 Medium Priority - The placeholder guard misses the placeholder form posting.md documents

- **Document** — `home/.claude/skills/doc-review/scripts/post.sh`
- **Location** — lines 41–43
- **Issue** — The guard rejects only `[...]`, which was the old block's placeholder. The documented invocation in `posting.md` (lines 277–279) now writes `--status '<status summary>' --stats '<stats line>'`. Run against a stub `gh` with exactly those values, `post.sh` exited 0 and posted ``## Document Review: t (`t-DOC-REVIEW.md`) — <status summary>`` and `**<stats line>**`. GitHub would also render the angle-bracketed text as an unknown HTML tag and hide it.
- **Suggestion** — Match both forms, `*'['*']'* | *'<'*'>'*)`, with the message naming both. Add a `test-post.sh` case using `'<status summary>'`.
- **Recommendation** — Implement: a one-line change, and the guard currently fails open on the form agents are told to fill.

### F82 🟡 Medium Priority - gh calls never pass --repo, so they can disagree with the remote the git calls use

- **Document** — `home/.claude/skills/handoff/scripts/gather-state.sh`
- **Location** — lines 15, 22, 24, 50 and 54 (and lines 22, 29, 31, 46, 65 and 69 of the resume-handoff copy)
- **Issue** — Both scripts accept a remote for the git refs but resolve the base, tip and pull request through `gh` with no `--repo`. In a clone with an `upstream` remote, `gh` can resolve to the parent repository (or refuse until `gh repo set-default` is run). The base could then come from one repository and the commit range from another. The user-wide CLAUDE.md requires `--repo` on every `gh` command in such a clone. This is not new (the old blocks did the same), but the scripts now advertise remote selection.
- **Suggestion** — Derive `OWNER/NAME` once from `git remote get-url "$remote"`, or accept it as an option, and pass `--repo` to every `gh` call in both scripts.
- **Recommendation** — Defer: inherited from the old blocks and needed in both copies. Do it together with F43's decision.

### F83 🟢 Low Priority - resume-handoff's gather-state.sh accepts any updated value and silently reports no commits

- **Document** — `home/.claude/skills/resume-handoff/scripts/gather-state.sh`
- **Location** — lines 12–13 and line 76
- **Issue** — The usage line says `<updated YYYY-MM-DD>`, but the value is never checked. In a scratch repository with a commit dated 2026-10-01, `--since="$d 00:00"` returned 1 commit for `2026-09-30`. It returned 0 for `garbage`, `10/24` or an empty value, each with exit 0. A malformed date therefore reads as "the base absorbed nothing" in the part SKILL.md relies on to spot Next Steps already done.
- **Suggestion** — Add `case $updated in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) echo "usage: …" >&2; exit 2 ;; esac` after the argument count check.
- **Recommendation** — Implement: three lines that turn a silent false negative into a usage error.

### F84 🟢 Low Priority - header.sh reports a nonexistent document as "untracked"

- **Document** — `home/.claude/skills/doc-review/scripts/header.sh`
- **Location** — lines 13–27
- **Issue** — `header.sh typo.md` printed `typo.md	main	untracked`, the same as a real new file. A document under a directory that does not exist prints "not in a repository". A mistyped scope path therefore reaches the review header looking valid. The old block behaved the same way, but there it ran once per document under the agent's eye.
- **Suggestion** — Start the loop with `[ -e "$doc" ] || { echo "header.sh: $doc does not exist" >&2; rc=2; continue; }` and exit with `rc` at the end.
- **Recommendation** — Implement: cheap, and the header is the review's provenance record.

### F85 🟢 Low Priority - post.sh accepts empty and flag-shaped option values

- **Document** — `home/.claude/skills/doc-review/scripts/post.sh`
- **Location** — lines 24–38
- **Issue** — `--post ""` is treated as "nothing withheld" and posts the review file itself. In a run with a stub `gh`, a review file with no Sensitive Information finding was posted. When there is one, Gate 2's withheld-number check still refuses, so this fails closed in practice. Separately, `--repo --status x` takes `--status` as the repository. An empty value for the withheld-copy path, the one input that controls what gets published, deserves an explicit refusal rather than a default.
- **Suggestion** — In the loop, refuse an empty value or one starting with `--`: `case $2 in ''|--*) echo "post: $1 needs a value — do not post" >&2; exit 1 ;; esac`.
- **Recommendation** — Implement: small, and it makes the empty-copy case fail where the mistake is made.

### F86 🟢 Low Priority - post.sh's mktemp call is GNU-incompatible and unchecked

- **Document** — `home/.claude/skills/doc-review/scripts/post.sh`
- **Location** — line 57
- **Issue** — `mktemp -d -t pr-comment` is the BSD form; GNU `mktemp` needs X's in the template and fails. The result is not checked, so on failure `work_dir` is empty and `awk` tries to write `/part-000`. The script then fails closed only by accident, through `[ "" -le 60000 ]` erroring. The line comes from the old block. The files are published dotfiles, but the user runs them on macOS.
- **Suggestion** — Use `work_dir="$(mktemp -d "${TMPDIR:-/tmp}/pr-comment.XXXXXX")" || { echo "cannot create a work directory — do not post" >&2; exit 1; }`.
- **Recommendation** — Implement: one line, and it removes an accidental fail-closed path.
- **Verification** — unverified: `docker run --rm debian:stable-slim mktemp -d -t pr-comment` should fail with "too few X's in template" (no GNU `mktemp` on the reviewer's machine).

### F87 🟢 Low Priority - check-loss.sh's section() ignores fences while headings() honors them

- **Document** — `home/.claude/skills/resume-handoff/scripts/check-loss.sh`
- **Location** — lines 17–19
- **Issue** — `headings` skips fenced blocks, but `section` ends a section at any `## ` line, fenced or not. In a test, a Dead Ends section held a fenced `## not a heading` line. Rewriting that line to `## changed` produced "nothing lost" and deleted the backup. Any line after a fenced `## ` line is outside every checked section. The old block had the same flaw.
- **Suggestion** — Give `section` the same fence toggle: `awk -v h="## $2" '/^(```|~~~)/ { fence = !fence } !fence && /^## / { on = ($0 == h) } on'`.
- **Recommendation** — Defer: inherited and rare, but worth doing with any next change to this script.

### F88 🟢 Low Priority - check-loss.sh's command grep comment gives a reason that does not apply to a script

- **Document** — `home/.claude/skills/resume-handoff/scripts/check-loss.sh`
- **Location** — lines 21–22
- **Issue** — The comment says "a session's grep can be a function running another grep". That held for the inline block, which ran in the session shell. A script run by path under bash does not inherit zsh functions: in the reviewer's session `type grep` reports a function from the shell snapshot, while `bash -c 'type grep'` reports `/usr/bin/grep`, and `BASH_ENV` is unset. The comment now states a rationale a reader cannot reproduce. `post.sh` and `scrub-lib.sh` use `command grep` without comment.
- **Suggestion** — Keep `command grep` for consistency with `scrub-lib.sh`, and either drop the comment or reword it to the reason that remains: "command grep, so a grep function exported by a bash parent cannot change the match".
- **Recommendation** — Implement: a comment that misstates why the code is as it is misleads the next editor.

### F89 🟠 High Priority - Gate 2's scan of the assembled comment has no case, and the suite passes with it deleted

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — the `check` cases, lines 89–176
- **Issue** — Every case that expects a scan refusal asserts "unresolved hits", which is Gate 1. Gate 1 scans only the artifacts in the repository root. The withheld copy given as `--post` lives outside the root, so Gate 1 never reads it. The `--status` and `--stats` text also exists only in the assembled comment. Gate 2 (`post.sh` lines 131–138) is the only gate on either. `posting.md` calls it "the one that matters". A mutant with lines 131–138 replaced by `:` passes all 28 checks. The real script refuses both of these with "assembled comment still has hits", and neither has a case:
  - a `--stats` value holding a home path
  - a `--post` copy holding a home path that the review file lacks
- **Suggestion** — Add both cases, each expecting 0 posts and the message `assembled comment still has hits`. Add a third whose `--post` copy holds a secret-shaped line, so the `secrets` pass of Gate 2 is covered as well as `ident`.
- **Recommendation** — Implement. This is the last check before publication, and the suite cannot currently detect its removal.

### F90 🟠 High Priority - `check` never asserts the exit status, so a refusal that exits 0 or a success that exits nonzero passes

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — `check`, lines 64–81 (the status is discarded at line 71)
- **Issue** — `check` compares only the post count and a substring of the output. Two mutants passed all 28 checks:
  - every refusal changed from `exit 1` to `exit 0`
  - a trailing `exit 3` after a successful post

  The skill's caller relies on the exit status, and so does any wrapper such as `/ship-it`. A gate that prints "do not post" but exits 0 reads as a success to a script.
- **Suggestion** — Capture `rc=$?` after the subshell and add a wanted-status argument (`ok` or `refuse`) that `check` asserts. An explicit argument is better than deriving the status from the post count, because the partial-failure case in F124 posts one part and must still exit nonzero.
- **Recommendation** — Implement. This is one field in the helper, and it hardens every existing case at once.

### F91 🟠 High Priority - No successful post omits `--post`, so the guard that keeps the review file alive is untested

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — cases A, D2 and Q (lines 89–95, 111–113 and 174–176)
- **Issue** — `post.sh` line 148 deletes `post_file` unless it equals the review file. Every successful case passes `--post`, so the equal branch never runs on success. A mutant that deletes `post_file` unconditionally passes all 28 checks. That mutant would delete the local review file, which is the only copy of the withheld findings, whenever nothing was withheld. The header of `post.sh` promises the opposite ("the review file itself is left for the caller").
- **Suggestion** — Add a successful case with no `--post` (a review with no Sensitive Information section) and assert `test -e "$repo/t-DOC-REVIEW.md"` afterwards. In case D2, also assert that the fresh `--cleared` file was deleted. Today only the `--post` copy and the `--cleared-findings` file are checked (line 95).
- **Recommendation** — Implement. Losing the local artifact cannot be undone, and the case is a few lines.

### F92 🟡 Medium Priority - Survival of working files on refusal is caught only by accident, under an unrelated label

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — `check` line 70, cases D to F (lines 104–123)
- **Issue** — `posting.md` says the copy and both cleared lists are deleted "once every part is posted", so they must survive any refusal. No case asserts that they do. The reviewer tested a mutant that moves the cleanup into the `EXIT` trap, so it also runs on refusal. It fails only "D2 only the cleared bare key", with the stray error `cp: …/cl: No such file`, because case D's refusal deleted the shared `$T/cl`. That label points away from the defect.

  The shared fixtures make this fragile:
  - `check` restores only `$T/cf`.
  - `$T/copy` is rewritten only by `review()`, and cases E, E2 and F reuse it without calling `review()`.
  - `$T/cl`, `$T/cl2` and `$T/cfbad` are never restored.
- **Suggestion** — Give every refusal case fresh copies of its inputs, as the success cases already do with `fresh`. Then add an explicit assertion after one Gate 1 refusal and one Gate 2 refusal that the `--post`, `--cleared` and `--cleared-findings` files still exist. Once each case owns its inputs, the restore line 70 can go.
- **Recommendation** — Implement. It turns an accidental catch into a named one and removes the cross-case coupling.

### F93 🟡 Medium Priority - The stub `gh` never checks `--repo` or the comment URL, and it can never fail

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — the stub, lines 15–25
- **Issue** — The stub ignores every argument except `$5`. A mutant that drops `--repo "$repo"` from `gh pr view` passes all 28 checks. `posting.md` names that flag as the fix for posting to a public upstream instead of the fork. Nothing checks either of these:
  - that `gh pr comment` receives the URL `gh pr view` printed
  - that it uses `--body-file`

  The stub also always succeeds, which leaves both `gh` failure paths without a case: "no pull request found for this branch" and "posting stopped at part i of total" (see F124). Its `case` has no default branch, so a new `gh` call added to `post.sh` would silently succeed.
- **Suggestion** — Make the stub append `"$*"` to an `argv` file. Add switches such as `GH_FAIL_VIEW` and `GH_FAIL_AT=<n>` and a `*) exit 1` default branch. Then assert the exact lines in case A, for example:

  ```bash
  expect "A resolves the PR in o/r" grep -qx 'pr view main --repo o/r --json url --jq .url' "$T/argv"
  expect "A posts to that URL" grep -q '^pr comment https://example.invalid/pull/1 --body-file ' "$T/argv"
  ```

  The reviewer ran a stub built this way against the real script. It recorded exactly those two lines, refused with "no pull request found for this branch in o/r" under `GH_FAIL_VIEW`, and stopped at part 2 under `GH_FAIL_AT=2`.
- **Recommendation** — Implement. The destination is the one thing a wrong post cannot take back.

### F94 🟡 Medium Priority - The heading assertion's `.` wildcards accept any delimiter around the file name

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — line 92
- **Issue** — `posting.md` says `/ship-it` finds an earlier comment by the backticked file name in the heading. The pattern `(.t-DOC-REVIEW.md.)` lets any single character stand in for each backtick. A mutant that prints `("%s")` instead of the backticked form passes all 28 checks.
- **Suggestion** — Match the whole line literally:

  ```bash
  heading='## Document Review: t (`t-DOC-REVIEW.md`) — all clear'
  expect "A heading" grep -qxF -- "$heading" "$T/posted-0"
  ```

- **Recommendation** — Implement. This is a one-line change that pins a contract another command depends on.

### F95 🟡 Medium Priority - Every test-post.sh case runs from the repository root, so the scan's anchor to the repository root is untested

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — `check` line 71 and `scrub_exits` line 182
- **Issue** — `posting.md` spends a paragraph on anchoring the scan to `git rev-parse --show-toplevel` rather than `.`. Two mutants with `root=.` pass all 28 checks:
  - In `post.sh`, the mutant posted a review while a `*-HANDOFF.md` in the root held a home path. Run from a subdirectory, the real script refused with "unresolved hits".
  - In `scrub.sh`, the mutant exited 2 ("nothing was scanned") from a subdirectory where the real script exits 1.
- **Suggestion** — Create `"$repo/sub"` and add one case for each script run from it. The `post.sh` case should put its hit in an artifact other than the one being posted, so Gate 2 cannot catch it instead.
- **Recommendation** — Implement. The documented failure is silent and total, and the case is short.

## Clarity and Structure

### F96 🟢 Low Priority - The ship-it Confirmations list limits the names-and-Linear question to reviews

- **Document** — `.claude/skills/ship-it/SKILL.md`
- **Location** — Confirmations, the bullet "posting a review whose scrub hit a secret-shaped line, or that names a person, organization or Linear link" (lines 813–814)
- **Issue** — In the body, the people, organizations and `linear.app/` question applies to every copy: a review, an untracked plan (Copy, redact and scrub) and the handoff comment ("Apply the redaction and name rules from Copy, redact and scrub to it", line 739). The Confirmations list, which reads as the complete set of questions, names only "a review". An agent using it as a checklist could post a plan or handoff without asking. This predates the branch.
- **Suggestion** — Change "posting a review whose scrub hit…" to "posting a review, plan or handoff comment whose scrub hit…".
- **Recommendation** — Defer: it predates the branch, and the body states the rule correctly.

### F97 🟢 Low Priority - "For this codebase" has nothing to refer to in a user-wide agent

- **Document** — `home/.claude/agents/documentation-expert.md`
- **Location** — Constraints, line 260
- **Issue** — "For this codebase: follow Markdown conventions, use fenced code blocks with language identifiers". The agent is global: `home/.claude/skills/doc-review/SKILL.md` line 13 calls it "a global agent defined in `~/.claude/agents/`", so "this codebase" changes meaning with every repository it runs in. The rest of the line also repeats the Formatting Conventions bullet on line 102. This was there before the branch.
- **Suggestion** — Delete line 260, since the fenced-code-block rule is already in Formatting Conventions.
- **Recommendation** — Defer: it predates the branch and is harmless. It fits better with the open description trim ([#148](https://github.com/) is description-only, so a separate follow-up) than with this branch.

### F98 🟠 High Priority - The orchestrator's trigger to read `review-file.md` fires after several steps that need it

- **Document** — `home/.claude/skills/doc-review/SKILL.md`
- **Location** — Lines 32–34 ("The orchestrator reads `review-file.md` before its first edit to the review file …")
- **Issue** — In the single-file command, the orchestrator had every rule in context. Now its only explicit triggers to read `review-file.md` are "before its first edit to the review file" and "before quoting a rule … into a recording agent's prompt". But it applies that file's rules much earlier, and in steps that involve no edit:
  - Scope confirmation (line 79) needs File Name to compute the review file's name and to find other review files on the same documents. File Name says "The orchestrator resolves its name from the scope and passes it to the collator". A guessed name sends the collator to the wrong file.
  - Composing the collator's prompt and Dispatching the Collator need Document Header (lines 183 and 268).
  - Re-checking Existing Findings needs the **Ruling** line semantics from Status Records a Decision.
  - Phases 1–3 need Membership, Order and Completion. If phases 1 and 2 have nothing to record, no batch is dispatched, so phase 3 can propose an order without the orchestrator ever having read Order.

  The "see X in `review-file.md`" cross-references mitigate this only for an orchestrator that follows each one.
- **Suggestion** — Replace lines 32–34 with: "The orchestrator reads `review-file.md` in full before resolving the scope, since File Name, Document Header, the status rules and the implementation groups all govern its own steps. It reads `reviewer-rules.md` before the walkthrough, for Redacting Sensitive Evidence and the recommendation rules it quotes."
- **Recommendation** — Implement. This is the main routing regression of the split, and the fix is one sentence.

### F99 🟡 Medium Priority - Orphaned lead-in "Instruct each reviewer to perform a thorough review covering:" now introduces `## After the Review`

- **Document** — `home/.claude/skills/doc-review/SKILL.md`
- **Location** — End of Composing the Prompts (line 195)
- **Issue** — In the old file, this sentence introduced `## Formatting` and the criteria that followed. The criteria moved to `reviewer-rules.md`, but the sentence stayed. It now ends with a colon directly above `## After the Review`, so it reads as if reviewers should "cover" the orchestrator's post-review procedure. It is also the only place that ever came close to an explicit "dispatch the reviewers" step. Without it, the procedure goes from composing the prompts to "once the reviewers return". The only mention of the dispatch is in Who Does What ("all dispatched in one message so they run concurrently").
- **Suggestion** — Replace the line with an explicit step: "Dispatch every reviewer in one message, in the session's own checkout, so they run concurrently; the review criteria reach each one through `reviewer-rules.md`."
- **Recommendation** — Implement. The sentence is misleading where it now sits, and replacing it closes a step gap.

### F100 🟢 Low Priority - The routing contract and the After the Review intro still argue from the single-file layout

- **Document** — `home/.claude/skills/doc-review/SKILL.md`
- **Location** — Composing the Prompts, routing-contract paragraph (lines 137–141); After the Review, intro (lines 199–203)
- **Issue** — The contract says "a rule only the collator needs lives in `review-file.md`, and the orchestrator's own procedure lives here". After the split, `review-file.md` also governs the orchestrator and is the source of the recording agents' quoted rules. Orchestrator-only procedure also lives in `posting.md` and `walkthrough-example.md`. So a maintainer adding a posting rule would be told to put it in SKILL.md. The After the Review intro justifies its placement with "which is why it sits in this file, which no agent is given". That was a real distinction when the extracts carried the other sections. Now all of SKILL.md is withheld from agents, and the sentence's two "which" clauses read awkwardly.
- **Suggestion** — In the contract: "… a rule the collator needs, and the orchestrator applies when it edits the file, lives in `review-file.md`; posting rules live in `posting.md`; the rest of the orchestrator's procedure lives here, which no agent is given." In the intro, drop "which is why it sits in this file, which no agent is given" and end the sentence at "collator".
- **Recommendation** — Implement. It costs two small edits and keeps the routing rule accurate for the next maintainer.

### F101 🟢 Low Priority - The Reviewer Output intro restates the new opening paragraph and reads oddly after the move

- **Document** — `home/.claude/skills/doc-review/reviewer-rules.md`
- **Location** — Reviewer Output, intro paragraph (lines 76–79); see also the opening paragraph (lines 3–6) and the Reviewing Without Editing intro (lines 87–88)
- **Issue** — The file says three times that both the reviewers and the collator read it.
  - Before the move, the Reviewer Output intro had a job: it marked where the extract ended ("Everything from `## Formatting` to the end of this section"). Now it is a statement about the whole file sitting under one section heading. It duplicates the opening paragraph.
  - Its maintainer guidance also lost its sense in the rewrite. "Curating this file is how a rules file decays back into a summary" uses "back" for a file that was never a summary. The original meant that trimming the section would make the extract a summary of the rules.
- **Suggestion** — Delete the Reviewer Output intro. Move its maintainer sentence to the end of the opening paragraph, reworded as "Write a rule a reviewer needs in this file, even when the collator or the orchestrator acts on it later; trimming it to a summary leaves the reviewers without the rule."
- **Recommendation** — Implement: removes a redundant paragraph and an unclear sentence, at the cost of one small edit.

### F102 🟢 Low Priority - The review-file.md opening implies the recording agents read this file

- **Document** — `home/.claude/skills/doc-review/review-file.md`
- **Location** — Review File, opening paragraph, lines 5–7
- **Issue** — "…which the orchestrator and the recording agents later edit under the same rules" can be read as the recording agents reading this file. They never do. SKILL.md says "The recording agents' rules travel inline instead" (Composing the Prompts) and lists the rules to quote under Recording the rulings. Someone who adds a recording-relevant rule here would expect it to reach those agents, and it would not.
- **Suggestion** — Append: "The recording agents never read it: the orchestrator quotes the rules they need into their prompts (see Recording the rulings in SKILL.md), so a rule they must follow is added to that list as well."
- **Recommendation** — Implement. One sentence, written while the routing contract is new.

### F103 🟡 Medium Priority - The "reading pass" the new key-cell paragraph relies on is never defined

- **Document** — `home/.claude/skills/doc-review/posting.md`
- **Location** — PR Comment Format, lines 167–169 (added on this branch in d1d0f27)
- **Issue** — The paragraph leaves a key cell of several words (`| Rollbar access token | <value> |`) "to the reading pass". No step in posting.md reads the copy for credentials. The term appears nowhere else in the skill: the reviewer grepped home/.claude/skills, .claude/skills and home/.claude/CLAUDE.md, and the only other occurrence is the commit message. The dotfiles /ship-it has such a pass ("Read the copy in full and replace…"), but `/doc-review`'s own posting path does not. A documented gap is pointed at a mitigation that does not exist, so a value without a known token prefix in such a row passes both gates.
- **Suggestion** — Either name the actual safeguard ("left to the authoring rule, Redacting Sensitive Evidence in reviewer-rules.md, which keeps the value out of the artifact") or add a step before the copy is posted: "Read the copy in full for a credential in a table row whose key cell is several words, and treat one as a blocked secret hit." The second option is the one that actually closes the gap.
- **Recommendation** — Implement. This is new text on this branch, and it currently rests on a step that isn't there.

### F104 🟡 Medium Priority - Gate 1, Gate 2 and the scrub-lib names are used in posting.md without saying where they come from

- **Document** — `home/.claude/skills/doc-review/posting.md`
- **Location** — PR Comment Format, lines 132–146 and 269–326
- **Issue** — The old section showed the block, with its `# Gate 1` and `# Gate 2` comments and the definitions of `paths`, `ident`, `secrets`, `scan`, `uncleared` and `grep_artifacts`. Now the reader meets several names with no visible source:
  - "Gate 2" first appears at line 140, mid-paragraph, before anything says what it is.
  - "Gate 1" is never named, although lines 285 and 321 talk about "each gate" and "Gate 2".
  - `scan`, `uncleared` and `grep_artifacts` (lines 144–145, 155) and `paths`, `ident` and `secrets` are named without saying that they are functions and variables in `scripts/scrub-lib.sh`.

  The HTML comment at line 12 says so, but a rendered or skimmed reading misses it.
- **Suggestion** — Extend the scrub-lib sentence at lines 65–68: "It defines the pattern variables `paths`, `hosts`, `ident`, `keys`, `schemes` and `secrets` and the functions `artifacts`, `grep_artifacts`, `uncleared` and `scan` that the rest of this section names." Then, where the post command is introduced, add: "`post.sh` runs Gate 1, `scan` over the artifacts, then assembles every part and runs Gate 2 over each part before any is posted."
- **Recommendation** — Implement. Two sentences give the reasoning that follows its referents back.

### F105 🟡 Medium Priority - Scrub output does not separate secret hits from identifying hits, and "Rewrite each hit" comes before the rule that forbids rewriting secrets

- **Document** — `home/.claude/skills/doc-review/posting.md`
- **Location** — PR Comment Format, lines 46 and 95–99, read against lines 155–157 and 181–183
- **Issue** — Line 95 says "Rewrite each hit **in the review document**" without qualification. Sixty lines later the reader learns that secret-shaped hits must never be rewritten, and that only path, host, address and username hits are. `scrub.sh` prints both passes in one unlabeled list (`scan` prints secret hits, then identifying hits), and a line can match both, as test-post.sh case I shows. So an agent following the document in order rewrites a credential before it reaches the rule against doing so. That hides the evidence the document says must reach the user. The ship-it scrub.sh labels its two passes differently. The unlabeled output is pre-existing; the unqualified rewrite instruction comes from the base.
- **Suggestion** — At line 95, write "Rewrite each path, host, address or username hit **in the review document** (a secret-shaped hit is never rewritten; see below)…". In `scan`, print a label line before each non-empty group (`scrub: secret-shaped hits — show the user, never rewrite` and `scrub: identifying hits — rewrite`), and say at line 46 that the output is grouped that way.
- **Recommendation** — Implement. The order of the text currently leads to the one action the document calls irreversible in effect.

### F106 🟡 Medium Priority - What goes in `--status` is not defined, and the "all clear" example is in the wrong slot

- **Document** — `home/.claude/skills/doc-review/posting.md`
- **Location** — PR Comment Format, lines 282–285 and 335–344
- **Issue** — Line 283 says `--status` and `--stats` are both filled "as the stats-line rule at the end of this section describes". That rule describes only the stats line. Its "all clear" example puts the verdict at the end of the stats string ("24 findings — 14 fixed, 2 refuted, 8 observations — all clear"). `post.sh`'s usage and test-post.sh pass "all clear" as `--status` and leave it out of `--stats`. Followed literally, the document gives `## … — <?>` with an undefined status and puts "all clear" in the bold line. Nothing says what the status slot holds when the review is not all clear: a deferred count, "N deferred", or something else.
- **Suggestion** — End the stats-line rule with: "`--status` takes the verdict: `all clear` when every actionable finding is ✅, otherwise a short phrase naming what keeps it from being all clear, such as `2 deferred, 1 ignored`. `--stats` takes the counts alone." Then rewrite the example as `--status 'all clear' --stats '24 findings — 14 fixed, 2 refuted, 8 observations'`.
- **Recommendation** — Implement. The first line of the public comment is filled from a slot this document never defines.

### F107 🟡 Medium Priority - The two list-file `mktemp` commands keep the path only in a shell variable

- **Document** — `home/.claude/skills/doc-review/posting.md`
- **Location** — PR Comment Format, line 175 (`cleared=$(mktemp -t scrub-cleared)`) and line 251 (`cleared_findings=$(mktemp -t doc-review-cleared-findings)`)
- **Issue** — Lines 262–263 say "Each command runs in a fresh shell, so pass every path explicitly rather than relying on a variable set in an earlier command". Both commands assign the path to a variable and print nothing, so in the next command the agent has no path to write the lines to, pass to `scrub.sh` or give `post.sh`. The withheld-copy command at lines 230–232 gets this right by echoing the path. These forms come from the old one-block design, where the variable did carry over.
- **Suggestion** — Write `mktemp -t scrub-cleared` and `mktemp -t doc-review-cleared-findings` as bare commands that print the path. Say to write the lines into it with the `Write` tool, which keeps trailing spaces exactly as given, and to pass the printed path to `scrub.sh` and to `post.sh` as `--cleared` and `--cleared-findings`.
- **Recommendation** — Implement. As written, the steps contradict the document's own fresh-shell rule.

### F108 🟢 Low Priority - Decision history in a normative posting.md section

- **Document** — `home/.claude/skills/doc-review/posting.md`
- **Location** — PR Comment Format, lines 185–190 ("The earlier claim that a credential reaches this step only by sharing a line with a path was wrong…") and lines 269–272 ("When the gate and the post were separate fenced blocks…")
- **Issue** — Both passages tell how the section got here rather than why it is as it is now. The first is entirely history. The second was rewritten on this branch and still opens with the former design. CLAUDE.md's Code Style puts before/after history in the commit message, and the paragraphs make the definition longer for every maintainer who syncs it.
- **Suggestion** — Cut lines 185–190, or reduce them to the present-tense rule: "Secret shapes are matched on their own, since a credential need not share a line with a path". At line 269, start from the reason: "A gate an agent can skip by copying the obvious block is not a control, so the re-verification and the post share one script and one exit path…"
- **Recommendation** — Defer. The text is correct as rationale, and trimming it is better done in a pass over the whole section than mixed into this conversion.

### F109 🟢 Low Priority - Read on its own, the walkthrough example's introduction gives neither the starting state nor which file wins if they disagree

- **Document** — `home/.claude/skills/doc-review/walkthrough-example.md`
- **Location** — Introduction, lines 3–4
- **Issue** — The transcript starts at "Question 1 of 1" and refers to G1, G2, G3 and G4. The state it starts from only appears in the closing paragraph: F2 ✅, F3 ⏸️ and F4 🚫 already settled, G3 complete, F5–F9 still ❓. A reader who opens this file directly, as `SKILL.md` line 28 expects the orchestrator to, has to reconstruct that state from `review-file.md`. Every other file in the skill opens by saying who reads it and what role it plays (see `reviewer-rules.md` lines 3–6 and `review-file.md` lines 5–7). This file does not say that it only illustrates the procedure and that `SKILL.md` governs where the two differ. That matters because an orchestrator may follow an example literally.
- **Suggestion** — Replace lines 3–4 with:

  ```markdown
  A worked example of the walkthrough in SKILL.md, from phase 1 to the proposed order, for the
  orchestrator. It illustrates the procedure and does not replace it: where the two differ, SKILL.md
  governs. It starts from the Pre-Merge Checklist example in `review-file.md` as shown there: F2, F3
  and F4 already settled and G3 complete, with F5 unruled and F6 and F8 not recommended.
  ```

- **Recommendation** — Implement: this is the "read on its own" gap the scope asked about, and the fix only touches the introduction.

### F110 🟡 Medium Priority - Handoff's output summary leaves out the "commit range not checked" case

- **Document** — `home/.claude/skills/handoff/SKILL.md`
- **Location** — Gathering State, lines 89–91
- **Issue** — The summary says the script prints "…the pull request and the branch's commits with their full messages." Two parts of the actual output are not covered:
  - When the base resolves neither as `refs/remotes/<remote>/<base>` nor locally, the script prints `base <name> not found locally or on <remote> — commit range not checked` under `== base` and leaves out both commit parts entirely. Nothing tells the agent that the commit list and the commit-trailer issue harvest (lines 109–113) are then "not checked", not "none". An absent section is the silent negative this skill warns about elsewhere.
  - The list also skips the `== pull request comments and reviews` part.
- **Suggestion** — Append: "When the base cannot be found, the `== base` part says the commit range was not checked and both commit parts are missing. Record the branch's commits, and any issue references they would have carried, as not checked." Add "its comments and reviews" after "the pull request" in the list.
- **Recommendation** — Implement: this is the "not checked" handling the change was meant to keep, and one sentence covers it.

### F111 🟡 Medium Priority - Instructions for work the handoff script now does read as tasks for the agent, and leave out the script's `main` fallback

- **Document** — `home/.claude/skills/handoff/SKILL.md`
- **Location** — Gathering State, lines 80–83 and 93–101
- **Issue** — Several sentences are still written as instructions to the agent:
  - "Resolve the base branch first — the commit ranges below need it…"
  - "Never hardcode `main`"
  - "Scope the commit ranges to the **base branch**, not `@{upstream}`"
  - "Take the range from the remote-tracking base when there is one"

  The script now does all four, and the commit ranges are inside it, not "below". Written as tasks, they can send an agent off to redo the work by hand. They also hide why the script is built this way, which is what a future editor needs before changing it. Lines 82–83 say that without a pull request "the fallback is the repository default", but when `gh` cannot be reached the script hardcodes `base=main` labeled `assumed`. The document never mentions that path, even though the Header example `(base: main, assumed)` depends on it.
- **Suggestion** — Recast these sentences as the script's design:
  - "The script resolves the base first… It never assumes `main` while `gh` can answer: a stacked branch gets its real base only from its pull request, the repository default comes next, and `main` labeled `assumed` is the last resort when `gh` cannot be reached. Confirm an `assumed` or `repository default` base with the user, or record it as such."
  - "It scopes the commit ranges to the base branch, not `@{upstream}`, because…"
  - "It takes the range from the remote-tracking base when there is one, because…"
- **Recommendation** — Implement: the rationale stays, and only the voice and one missing fallback change.

### F112 🟢 Low Priority - "The `00:00` matters" explains code the reader can no longer see

- **Document** — `home/.claude/skills/resume-handoff/SKILL.md`
- **Location** — Step 3, Also Check, "What the base absorbed" (lines 208–209)
- **Issue** — The `--since="$updated 00:00"` it refers to now lives only in `gather-state.sh` line 76. The skill no longer shows it, and the script has no comment explaining it. An agent reading the skill has nothing to act on, and someone editing the script has no warning against dropping `00:00`.
- **Suggestion** — Remove the sentence from SKILL.md. Move its rationale into a comment above `gather-state.sh` line 76, for example "a bare date means that date at the current time of day, which drops whatever landed earlier on it".
- **Recommendation** — Implement: the rationale belongs next to the code it protects.

### F113 🟢 Low Priority - "Open every later block … as the blocks below do" no longer fits

- **Document** — `home/.claude/skills/resume-handoff/SKILL.md`
- **Location** — Step 3, Resolve the Branch and Its Base, lines 97–99
- **Issue** — Before this change, the first block set `branch` and `updated` and later blocks set what they used. Now the next block is the script call, which takes arguments and sets nothing. Only the When the Branch Moved block sets variables (`branch`, `recorded`, `tip`), copied by hand from the handoff and from the script's `tip:` line. "As the blocks below do" now describes one block, and the reader is not told where the values come from until line 109.
- **Suggestion** — Move the paragraph after the description of the script's output and reword it: "Shell variables do not carry over between tool calls. Open every block that uses `branch`, `recorded` or `tip` by setting them from the handoff and the script's `tip:` line, as When the Branch Moved does, so an unset variable fails loudly instead of quietly standing in for the current checkout."
- **Recommendation** — Implement: the paragraph's anchor was removed by this revision.

### F114 🟡 Medium Priority - Version-Locked Packages stub names a read time that matches neither its first use nor its own reason

- **Document** — `home/.claude/skills/update-deps/SKILL.md`
- **Location** — Version-Locked Packages (lines 448–452); compare Step 2 (lines 100–104)
- **Issue** — The stub says to read `version-locked.md` in full "before Step 3". Its own reason, "each must be handled before that re-resolution", points to Step 4, not Step 3. Nothing in `version-locked.md` acts before or during Step 3:
  - Playwright is compared "After Step 3 and `yarn up '*'`".
  - Cocooned and Rails are fixed in Step 4's restore call or just after it.
  - `javascript.md` (line 74) already sends the reader to the file at the restore call.

  The earliest reader that needs the file is actually Step 2. When a Rails upgrade is in flight, Step 2 must judge whether the upgrade commit "lacks" the `@rails/*` bumps. That requires the npm version encoding in the Rails JavaScript Packages section of `version-locked.md` (patch × 100, prerelease exceptions), and Step 2 comes before the stub's "before Step 3". The stub also sits after Step 11, so a reader going through the steps in order meets it late.
  - From the concurring report: this file times its actions "After updating, verify", Playwright "After Step 3 and `yarn up '*'` have moved both sides", Cocooned "If for some reason only one side updated", Rails "After Step 4's restore" (F37), and every change lands "before Step 4's re-resolution". The only content that bears on Step 3 is the Playwright warning not to hold back the gem. In the original, Step 2 (Rails upgrade), Step 4 (three links: the prefix rule, the hold restore and the re-pin) and Important Notes pointed to this section, and Step 3 never did; all of those links survive in `SKILL.md` and `javascript.md`. A future editor should not read "before Step 3" as moving any check into Step 3: the checks belong between `yarn up '*'` and the re-resolution.
- **Suggestion** — Reword the stub so its timing and reason agree, for example: "Read `${CLAUDE_SKILL_DIR}/version-locked.md` in full before Step 2 when a Rails upgrade is in flight, and in any case before Step 4's restore call. Step 2 needs its Rails JavaScript Packages section to judge the upgrade commit. Its packages span the gems Step 3 updates and the JavaScript packages Step 4 re-resolves, and each must be handled before that re-resolution."
- **Recommendation** — Implement. The split introduced this stub, and its stated timing is the one thing in it an agent acts on.
- **Concurred by** — `home/.claude/skills/update-deps/version-locked.md`
- **Divergence** — `home/.claude/skills/update-deps/SKILL.md`'s report filed this at 🟡 Medium Priority, recommending Implement; `home/.claude/skills/update-deps/version-locked.md`'s report filed it as an ℹ️ Observation with no recommendation, judging the stub's reading time "early but harmless" and its second clause consistent with the file.

### F115 ⚖️ Decision - The `.tf` detection command now sits behind the routing decision that depends on it

- **Document** — `home/.claude/skills/update-deps/terraform.md`
- **Location** — Step 5: Decide Terraform Version Bumps, opening paragraph and first code block (lines 5–22)
- **Issue** — In the original single file, the agent reached Step 5's detection command naturally: `git ls-files --full-name ':/*.tf' ':(top,exclude)*.terraform/*'`. The text around it explained the details: the command exits 0 either way, it misses `.tf.json`, untracked and submodule files, and the exclude keeps out vendored module copies. After the split, the stub in `home/.claude/skills/update-deps/SKILL.md` (Step 5) says "Skip this step and Step 6 if the repository has no `.tf` files. Otherwise read `${CLAUDE_SKILL_DIR}/terraform.md`." So the agent has to decide whether `.tf` files exist *before* it reaches the command and caveats that answer that question. A naive check would wrongly skip all Terraform work in a repo whose configuration lives only in subdirectories (e.g. `infra/prod`). Examples of naive checks: `ls *.tf` at the root, or a check of the command's exit status. Meanwhile, this file's opening sentence ("Many repos have no Terraform configuration at all. Skip this step and Step 6 entirely if this repo has no `.tf` files") is now redundant on the path the stub sends agents down. The split introduced this; the original did not have it. The JavaScript stub has no such problem because "no `yarn.lock`" is a single root-file check.
- **Options**
  - **(a) Put the detection command in the SKILL.md stub.** The stub would say: run `git ls-files --full-name ':/*.tf' ':(top,exclude)*.terraform/*'` from the root, skip Steps 5 and 6 if it prints nothing, otherwise read terraform.md. This file keeps its opening as is. Cost: one command appears in two files and could drift.
  - **(b) Have the stub always send the agent into terraform.md**, which runs the check and skips the rest itself. Cost: a non-Terraform repo loads a file of about 560 lines just to learn it can skip, which undercuts the point of the split.
  - **(c) Move the check and its caveats (lines 5–22) into the stub and drop them from this file.** Step 5 here would start at Find the Current Pins. Cost: the "Why the `:/` pathspec prefix" note (line 516) says Step 5 "opens by `cd`-ing to the root", so that note and the in-file `cd` would need rewording.
- **Recommended** — (a). It restores the original order (detect, then decide) for the cost of one duplicated line. The decision stays where the command explains it, and non-Terraform runs stay cheap.
- **Ruling** — (a), 2026-10-24 — put the `.tf` detection command in the Step 5 stub of update-deps/SKILL.md; terraform.md keeps its opening

### F116 ⚖️ Decision - Run-wide steps sit under a file titled for pins

- **Document** — `home/.claude/skills/update-deps/pins.md`
- **Location** — `### Close Open Security Alerts` (line 76) and `### Stop If Nothing Changed` (line 96); the router stub in `home/.claude/skills/update-deps/SKILL.md`, Step 7 (lines 186–188), and Overview item 7 (line 25)
- **Issue** — Two of the file's four sections are not about tool or image pins:
  - Close Open Security Alerts bumps gems (`bundle update --conservative`) and npm packages (`yarn up`).
  - Stop If Nothing Changed is the gate for the whole run ("Steps 3 through 7 are the only steps that update dependencies").

  The nesting was the same in the original. Back then both sections sat in the one file a reader scrolled through. Now they sit behind a router stub, `home/.claude/skills/update-deps/SKILL.md` Step 7 (line 188): "Read `${CLAUDE_SKILL_DIR}/pins.md` in full and follow it". Overview item 7 describes the step only as "Update tool and image pins that live outside the package manifests". Someone editing SKILL.md, or an agent that skims the stub, gets no hint that the security-alert sweep and the stop gate live in this file. "In full" does keep an agent that obeys the stub from skipping them. SKILL.md lines 401 and 480 link here, which helps, but only from the PR-summary and Important Notes text.
  - From the concurring report: before the split, both were headings in SKILL.md's step list. The only signs that the run can end inside Step 7 are now the Important Notes link and the Step 2 back-reference from `pins.md`, so someone maintaining the router can no longer see where the run's exit lives.
- **Options**
  - **(a) Leave as is.** Keeps the move exactly verbatim. The run still works because the stub says "in full". The cost is that the gate and the alert sweep are hard to find for anyone editing SKILL.md.
  - **(b) Name both sections in the SKILL.md Step 7 stub.** For example: "…and follow it, including its security-alert sweep and its stop-if-nothing-changed gate" (the concurring report's wording: "It also bumps whatever closes an open security alert, and ends with the check that stops the run when nothing changed."). It is a one-line change outside this file, and the move stays verbatim.
  - **(c) Move the two sections back into SKILL.md as the end of Step 7, or as their own short section before Step 8.** The router would then own the run's control flow. This undoes part of the split and puts about 30 lines back into SKILL.md, against the branch's aim of a lean router.
- **Recommended** — (b). It costs one line, keeps the move verbatim as this scope describes, and makes both run-wide sections visible from the router. Option (c) is a structural change better left to a follow-up if the router keeps growing control logic.
- **Ruling** — (b), 2026-10-24 — name pins.md's security-alert sweep and its stop-if-nothing-changed gate in the Step 7 stub of update-deps/SKILL.md
- **Concurred by** — `home/.claude/skills/update-deps/SKILL.md`, which filed it as 🟢 Low Priority recommending Implement of the edit option (b) describes

### F117 🟢 Low Priority - Bare "Step 6" references in pins.md now point outside this file

- **Document** — `home/.claude/skills/update-deps/pins.md`
- **Location** — `### Verify the Bumps`, lines 64–67. Also "found in Step 5" (line 49) and "Step 4 re-resolved" (line 102).
- **Issue** — The file gives an instruction that depends on another step's procedure without saying where that step is: "re-run Step 6's `init -upgrade` in every root module with the new CLI, and plan again wherever Step 6 did". In the original, Step 6 was a few hundred lines above in the same file. Now it is in `home/.claude/skills/update-deps/terraform.md`, which pins.md links nowhere for Step 6. An agent whose context was compacted after Step 6, or a reader who opens pins.md directly, has to guess which file holds that command and its "plan wherever Step 6 did" rule. Step 5 has the same gap at line 49, though it is linked once at line 45.
- **Suggestion** — Link the first "Step 6" in Verify the Bumps to `terraform.md#step-6-re-resolve-and-verify-terraform-lock-files`. That slug matches the heading at terraform.md line 267 and is the one SKILL.md already uses.
- **Recommendation** — Implement. It is a one-link change in the spirit of this scope's link rewrites, and it covers the only bare reference that carries a command to re-run.

### F118 🟢 Low Priority - Step 9's "the output or diff" depends on Step 8, which the agent may not have read

- **Document** — `home/.claude/skills/update-deps/linters.md`
- **Location** — Step 9, first line (line 42)
- **Issue** — "Check the output or diff" refers back to Step 8's "the `gem_update` output or `git diff Gemfile.lock`". When RuboCop did not change, the `SKILL.md` stub sends the agent straight to "its Step 9". That agent never read Step 8 in this file, so "the output" refers to nothing here. The stub itself is fine because it follows the Step 8 stub, but this file is now entered at either step. The original had the same wording, so the problem is old, but splitting the file into separate entry points is what makes it matter now.
- **Suggestion** — Write it out in full: "Check the `gem_update` output or `git diff Gemfile.lock` for changes to the `haml_lint` gem (CLI: `haml-lint`)."
- **Recommendation** — Implement. It is a one-line edit and makes Step 9 readable on its own, as the new entry point needs.

### F119 ⚖️ Decision - changelogs.md is now read only before Step 10, but Step 7 and Step 10's first substep need it earlier

- **Document** — `home/.claude/skills/update-deps/changelogs.md`
- **Location** — The whole file. Its read timing is set by the stub at `home/.claude/skills/update-deps/SKILL.md` § Known Changelog Quirks (lines 454–457), and `home/.claude/skills/update-deps/pins.md` § Step 7 (line 54) relies on it.
- **Issue** — In the original single file, this section was always loaded, so every step that pointed to it had it at hand. The base pointed to it from four places:
  - Step 3, Update Bundler: where Bundler's notes live.
  - Step 7: "Two lookup traps are recorded under Known Changelog Quirks".
  - Step 10, Draft the Message: hand the sub-agent "the whole … section".
  - Step 10, item 2 of the agent's steps: the pin-trap pointer.

  The new stub says to read this file only "before Step 10 builds the changelog links". That causes three problems:
  - **(i) Step 7 runs without it.** The `jq` entry under "Tool and image pins" is a version-lookup trap that applies while Step 7 looks up "the newest stable upstream release". `pins.md` only links to the file and never says to read it. An agent that filters tags with `^v?[0-9]` at Step 7 gets nothing back for `jq`, and may conclude there is no newer release and leave the pin stale without a word. That is a behavior regression the move introduced. The concurring report adds that Elasticsearch's GitHub release page is only a pointer, the second Step 7 lookup trap, and that Step 3's Bundler subsection also points here.
  - **(ii) The trigger point is ambiguous.** "Before Step 10 builds the changelog links" can be read as just before item 2 ("Fill in missing changelog links"). Step 10's first substep, Read the Changelogs for Behavior Changes, already has to find Bundler's, `sass-embedded`'s, `appsignal`'s and `cancancan`'s notes, which is exactly what this file says where to find.
  - **(iii) The stub undersells the file.** It says the file lists items "whose changelogs need special handling". The `jq` entry is a tag-lookup trap, not a changelog quirk, so an agent reading the stub has no hint the file matters before Step 10.
- **Options**
  - **(a) Have the `SKILL.md` stub say to read this file before Step 3, next to `version-locked.md`.** This restores the original "always in context" behavior for Steps 3, 7 and 10 with a one-line edit, and this file stays as it is. The cost is about 50 lines loaded on every run, including runs with no pins.
  - **(b) Keep the stub's timing but make it say "before Step 10 begins", and add an explicit read instruction to `pins.md` above its lookup rules.** Because supporting files are not substituted, that instruction would have to read something like "read `changelogs.md` in this skill's directory, Tool and image pins", not use `${CLAUDE_SKILL_DIR}`. Loading stays lazy, but two files now carry read instructions for this one and must stay in sync.
  - **(c) Move the "Tool and image pins" subsection into `pins.md` at the point of use, and change the stub to "before Step 10 begins".** This puts each trap where it is used and makes this file purely about changelogs. The costs: Step 10 item 2's pointer and the Draft bullet ("the whole … section") would have to name both files, and the move would no longer be verbatim.
  - **(d) From the concurring report: change the stub to "Read `${CLAUDE_SKILL_DIR}/changelogs.md` before Step 7 looks up pin releases; Step 10 needs it again for the changelog links."** That report's case: the change is small, and it makes the stub's timing match the file's first use.
- **Recommended** — (a). It is the smallest change, matches how the base behaved and fixes (i) and (ii) together. It also follows the precedent `version-locked.md` already sets for a file that several steps need.
- **Ruling** — (a), 2026-10-24 — the stub says to read changelogs.md before Step 3, beside version-locked.md; F67 no longer waits on this finding
- **Concurred by** — `home/.claude/skills/update-deps/SKILL.md`
- **Divergence** — `home/.claude/skills/update-deps/changelogs.md`'s report filed this as a ⚖️ Decision recommending (a); `home/.claude/skills/update-deps/SKILL.md`'s report filed it as 🟢 Low Priority recommending Implement of the timing written here as (d).

### F120 🟡 Medium Priority - test-post.sh misses the defects above and does not cover what SKILL.md says it does

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — lines 71 and 182, and coverage as a whole
- **Issue** — `doc-review/SKILL.md` lines 29–30 say to run `test-post.sh` after changing `header.sh`, `scrub.sh` or `post.sh`. The suite has these gaps:
  - It never runs `header.sh`.
  - It runs `post.sh` and `scrub.sh` through `bash "$here/…"`, so a lost execute bit (F80) cannot fail it.
  - It tests the `[placeholder]` form but not the documented `<placeholder>` form (F81).
  - It does not cover the multi-part split, part labels or the over-limit refusal. The reviewer checked these by hand: three sections of about 49 KB each posted as "part 1 of 3" through "part 3 of 3", and a single 70 KB section was refused.
  - It does not cover a `--post` that names the review file (F73).

  `check-loss.sh`, the remaining script with real logic, has no tests at all.
- **Suggestion** — Run each script by path (`"$here/post.sh"`) and add `test -x` checks for every script the skill files run by path. Add `header.sh` cases (tracked, dirty, untracked, outside a repository, nonexistent), a `'<status summary>'` case, a two-part split case and a `--post ./<review file>` case. A small `test-check-loss.sh` can follow.
- **Recommendation** — Implement for the `test-post.sh` additions, which would have caught F80, F81 and F73. Defer `test-check-loss.sh`.

### F121 🟢 Low Priority - Neither gather-state.sh checks that it runs inside a repository

- **Document** — `home/.claude/skills/handoff/scripts/gather-state.sh`
- **Location** — top of the script (and of the resume-handoff copy)
- **Issue** — Run outside a repository, the handoff script printed a "fatal: not a git repository" for each git part and then `git diff --no-index`'s full usage text, and it exited 0. The skill calls it from whatever directory the session is in.
- **Suggestion** — Add `git rev-parse --git-dir >/dev/null 2>&1 || { echo "gather-state: not in a git repository" >&2; exit 2; }` at the top of both scripts.
- **Recommendation** — Implement: one line each, and it turns a wall of noise into one clear error.

### F122 🟢 Low Priority - check-loss.sh has no usage message, and a failed rm exits with the "loss" code

- **Document** — `home/.claude/skills/resume-handoff/scripts/check-loss.sh`
- **Location** — lines 11–14 and 35
- **Issue** — With no argument, the script prints `check-loss: cannot read  or .bak`. If `rm` fails after a clean comparison, the script exits 1, which the header defines as "a loss, printed".
- **Suggestion** — Add `[ $# -eq 1 ] || { echo "usage: check-loss.sh <handoff>" >&2; exit 2; }` and `rm -- "$backup" || exit 2`.
- **Recommendation** — Implement: keeps the documented exit codes truthful.

### F123 🟠 High Priority - Most of `scrub-lib.sh`'s pattern set has no case: deleting every token-prefix term passes the suite

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — cases C–Q, lines 100–176
- **Issue** — `scrub-lib.sh` is a separate copy of the pattern set from `.claude/skills/ship-it/scripts/scrub.sh`. Only the `ship-it` copy has a broad table of hit and pass cases (`test-scrub.sh`, 90 cases). `test-post.sh` exercises only these terms:
  - a credential-named key with a colon
  - the three table-key-cell forms
  - a home path
  - a `file://` URL
  - the resolved temp root
  - the bracketed account name

  A mutant that deletes the whole token-prefix block of `scrub-lib.sh` (lines 41–47: GitHub, AWS, Slack, Stripe, Anthropic and OpenAI, Google, GitLab, npm, SendGrid, CircleCI, DigitalOcean, Linear, JWT, bearer) passes all 28 checks. These terms also have no case: private addresses, email, `.local` and `.internal` hosts, the dash-encoded `-users-` form, `~user/` and the home-variable term. The terms where `ship-it/scripts/scrub.sh` documents an intentional difference from this copy are untested on this side too: the home variable, the `.local` port-or-path rule and the in-pattern placeholder.
- **Suggestion** — Add a fast loop that sources `scrub-lib.sh` (with `root` and `cleared` set) and greps one sample line per term with `-e "$secrets"` or `-e "$ident"`. Port the hit and pass lists from `test-scrub.sh` and adjust them for the differences in the `ship-it` script's header. Keep them as this script's own list, following `posting.md`'s rule to duplicate the check into each publisher. Assemble token samples from pieces, as `test-scrub.sh` does, so gitleaks stays quiet.
- **Recommendation** — Implement. The suite exists to catch drift in this copy, and right now it would not.

### F124 🟠 High Priority - Multi-part posting is entirely untested: splitting, labels, the all-parts gate and failure partway

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — no case. The behavior is in `post.sh` lines 76–147.
- **Issue** — Every fixture fits in one part. Three mutants pass all 28 checks:
  - `limit=999999999`, so nothing is ever split
  - the `(part i of n)` label dropped
  - Gate 2 run over `comment-001` only

  The last one defeats the property `posting.md` stresses: "Every part passes Gate 2 before the first is posted". These also have no case:
  - the refusal for a single section over the limit
  - the partial-post message when `gh` fails at part 2
  - the survival of working files after that failure

  The reviewer ran the real script with two 40,000-byte `##` sections. It posted 2 parts labeled "part 1 of 2" and "part 2 of 2", with the heading only in the first. One 80,000-byte section refused with "over the limit on its own". `GH_FAIL_AT=2` gave 1 post and "posting stopped at part 2 of 2".
- **Suggestion** — Build the large body at runtime (`head -c 40000 /dev/zero | tr '\0' a`) and add these cases:
  - two parts posted, with the labels and the single heading asserted
  - a withheld number present only in the second section, expecting 0 posts
  - one oversized section, expecting refusal
  - failure at part 2 (with the F93 stub), expecting 1 post, a nonzero exit, the message, and the `--post` copy still present
- **Recommendation** — Implement. A partial post is public and cannot be withdrawn cleanly.

### F125 🟡 Medium Priority - The open-findings gate is tested only through a ❓ row; the `- [ ]` checklist branch has no case

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — case G, lines 125–127
- **Issue** — `post.sh` checks two forms of open finding (lines 53–56), and `posting.md` names both. A mutant that drops the checklist test (`[ "$b" -eq 1 ]`) passes all 28 checks. The real script refuses a review holding an unchecked checklist item with "open findings above".
- **Suggestion** — Add a case beside G whose extra line is an unchecked checklist item, expecting 0 posts and `open findings above`.
- **Recommendation** — Implement. One case closes one branch of a documented gate.

### F126 🟡 Medium Priority - The cleared-lines file's own gates and `scrub.sh`'s cleared argument have no case

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — `scrub.sh` cases, lines 178–193, and the `--cleared` cases
- **Issue** — `scrub-lib.sh` refuses a cleared file that is unreadable or has a blank line (lines 16–18). A mutant without the blank-line check passes all 28 checks. The real `post.sh` refuses such a file with "has a blank line" and "scrub setup failed". `posting.md` tells the agent to run `scrub.sh <cleared file>` before posting, but the suite never passes `scrub.sh` an argument. That leaves `scrub.sh`'s exit 0 after clearing, and its exit 2 on a blank or unreadable cleared file, untested.
- **Suggestion** — Add these cases:
  - `post.sh` with a blank-line `--cleared`, expecting refusal and `has a blank line`
  - `post.sh` with an unreadable `--cleared`, expecting refusal and `cannot read`
  - `scrub_exits` taking an optional cleared path, with three expectations: exit 0 when the path clears the only secret hit, and exit 2 for a blank-line file or a missing file
- **Recommendation** — Implement. The blank-line refusal exists because a wrongly written file would otherwise clear hits silently.

### F127 🟡 Medium Priority - Several argument and precondition refusals in `post.sh` have no case

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — cases E, E2 and F, lines 115–123
- **Issue** — Only three precondition gates are covered: the `--status` placeholder, missing `--stats`, and malformed cleared findings. Each of the following refuses in the real script with its own message, but has no case:
  - unknown argument: "unknown argument"
  - a flag without a value: "--stats needs a value"
  - a `--stats` placeholder (only `--status` is tested): "still holds a [placeholder]"
  - an unreadable `--post`: "cannot read the review, post or cleared-findings file"
  - an empty `--post`: "review body is empty"
  - a review without a title line: "has no title on its first line"
  - `gh pr view` failing (F93): "no pull request found"

  Mutants without the unknown-argument, empty-body or title check each pass all 28 checks. `posting.md` gives the empty-body check a whole paragraph on why it exists.
- **Suggestion** — Add one `check` per gate, each expecting 0 posts and the message quoted above. With the F90 status field, also assert that each exits nonzero.
- **Recommendation** — Implement. They are cheap one-liners, and the empty-body case guards a documented fail-open.

### F128 🟡 Medium Priority - Two of the four artifact name patterns are never exercised

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — no case. Only `*-DOC-REVIEW*.md` (every case) and `*-HANDOFF.md` (case K) are covered.
- **Issue** — A mutant `artifacts()` without `*local-review*.md` and `*PLAN.md` passes all 28 checks. `posting.md` explains why `*local-review*.md` is a substring match: a carried review is named `<source-branch>-carried-local-review.md`. The real script refuses a home path in `b-carried-local-review.md` and in `x-PLAN.md`.
- **Suggestion** — Add one case for each, placing a home path in that artifact beside a clean review. Expect 0 posts and "unresolved hits", and remove the file afterwards as K does.
- **Recommendation** — Implement. These are two short cases covering the patterns the doc singles out.

### F129 🟢 Low Priority - The documented exemptions and bounds have no pass-through case

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — cases C, M and J
- **Issue** — Each of these mutants passes the suite:
  - removing the placeholder exemption `([^<]|$)` after `/users/`
  - removing the boundaries around the withheld number

  No case checks that these pass:
  - a placeholder alone, `/Users/<name>/app` (the real script posts it)
  - a withheld finding's number appearing only as part of a longer number, F20 or F12 (the real script posts it)

  No case covers a withheld number that `posting.md` names explicitly: one appearing only in a group heading. The real script refuses it. Both mutants fail closed, which is why this is Low.
- **Suggestion** — Add three cases:
  - a placeholder-only review, expecting 1 post
  - a copy mentioning F20 and F12 with the fixture's withheld finding removed, expecting 1 post
  - a copy whose only mention of the withheld number is a `### G1 — …` group heading, expecting refusal
- **Recommendation** — Implement. Over-blocking teaches the agent to override the gate, which `posting.md` warns against.

### F130 ⚖️ Decision - Whether to pin that the widened key-cell term blocks a backticked file name in a summary row

- **Document** — `.claude/skills/ship-it/scripts/test-scrub.sh`
- **Location** — lines 63–64 (the two new cases). The same applies to case Q of `home/.claude/skills/doc-review/scripts/test-post.sh`, line 174.
- **Issue** — The new term allows backticks around a key cell. As a result, a review summary row whose Location cell is a bare backticked file name containing a key word now blocks in both scripts. Examples are `auth.md`, `token.rb` and `secrets.yml`. At the base commit the `ship-it` script passed such a row. With a directory prefix (`docs/auth.md`) the row still passes. Neither suite has a case for this edge either way. Case Q sidesteps it by using `a.md` as its Location. The behavior fails closed and can be cleared, like the header-row blocking `posting.md` already accepts. It is still a new false positive that nothing records.
- **Options**
  - **(a) Pin it as accepted blocking.** Add an `expect 1` case to `test-scrub.sh`, a refusal case to `test-post.sh`, and one sentence beside the header-row note in `posting.md`. Cheap, and it makes any later change deliberate. It keeps the occasional clearing step.
  - **(b) Narrow the term and pin the pass.** Exempt a backticked cell that ends in a file extension, and add `expect 0` cases. This gives fewer prompts, but the patterns in two scripts plus `posting.md` all change, and a key named like a file could slip.
  - **(c) Leave it unpinned.** No work, but the next change to the term can flip the behavior silently in either direction.
- **Recommended** — (a). The block fails closed and the clearing flow already handles it. The gap is that nothing records the trade.
- **Ruling** — (a), 2026-10-24 — pin the backticked-file-name block as accepted: a blocking case in each test suite and one sentence beside the header-row note in posting.md

### F131 🟢 Low Priority - `scrub.sh`'s list of scanned files is never asserted

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — lines 186–188
- **Issue** — `posting.md` says listing the scanned files "is what makes the verdict checkable rather than merely quiet". The clean case asserts only `scrub: clean`. A mutant that drops the list passes all 28 checks.
- **Suggestion** — Add `expect "scrub.sh lists the review" grep -q 't-DOC-REVIEW.md$' "$T/out"` after the clean case.
- **Recommendation** — Implement. It is one line.

### F132 🟢 Low Priority - A stub bypass would send the real `gh` to github.com for a plausible repository slug

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — line 86 (`--repo o/r`) and the `PATH` prefix at line 71
- **Issue** — The suite relies only on `PATH` order to stay off the real `gh`. Suppose a future `post.sh` resolves `gh` some other way, or the stub fails to become executable. Then `gh pr view main --repo o/r` would query a real repository named `o/r` on github.com, and `gh pr comment` would follow the URL it returns. The stub's `example.invalid` URL protects only the comment step, and only while the stub is the one answering `pr view`.
- **Suggestion** — Pass a host-qualified `--repo example.invalid/o/r`, which `gh` accepts as `[HOST/]OWNER/REPO`. Alternatively, export `GH_CONFIG_DIR="$T/gh"` and an invalid `GH_TOKEN`, so a bypassed call fails to authenticate. Update the expected `argv` line from F93 to match.
- **Recommendation** — Implement. It is a one-token change that makes the suite safe if the stub is ever bypassed.
- **Verification** — unverified: whether `o/r` resolves on github.com. Run `gh repo view o/r --json url`. A URL in the output means a bypass would reach a real repository. The reviewer did not run it, because the review must not call the real `gh`.

### F133 🟢 Low Priority - `review()` writes two more fixtures without saying so, and `cf` is written in three places

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — `review()` lines 41–62, plus lines 70 and 87
- **Issue** — A reader of case B or C has to read `review()` to learn two things:
  - `$T/copy` is the review minus every line containing the fixture's withheld number.
  - `$T/cf` is reset there too.

  The same `printf 'F3\n' > "$T/cf"` appears at lines 61, 70 and 87. Case D then rewrites `$T/copy` by hand at line 106, repeating the `review()` logic.
- **Suggestion** — State in the comment above `review()` that it also writes the withheld copy and the cleared-findings file. Keep a single writer of `$T/cf` once F92 gives each case fresh inputs.
- **Recommendation** — Implement. It is a comment and two deleted lines, done together with F92.

## Spelling and Grammar

### F134 🟢 Low Priority - The commit skill's description uses a serial comma and has an unclear "one" and an object-less "fold"

- **Document** — `home/.claude/skills/commit/SKILL.md`
- **Location** — Frontmatter, `description`
- **Issue** — "Create a git commit for this session's changes, amend one, or reword or fold into an earlier commit" has three problems:
  - **Serial comma.** It has a serial comma before "or", against the user-wide rule of no serial comma.
  - **Unclear "one".** "amend one" could read as amending one of the session's changes, though Arguments means HEAD.
  - **No object for "fold".** "fold into" has no object, so it does not say what gets folded.

  The description is read on its own in the skill listing, so it should parse without the body.
- **Suggestion** — Use: "Commit this session's changes, amend the last commit, fold changes into an earlier commit or reword a commit's message, following the commit message guidelines. Use for every commit, amend and message edit."
- **Recommendation** — Implement. The frontmatter is new on this branch, and the description is the line that decides when the skill is used.

### F135 🟢 Low Priority - Script comment punctuation departs from the repository's comment rule

- **Document** — `home/.claude/skills/doc-review/scripts/scrub-lib.sh`
- **Location** — `scrub-lib.sh` lines 55, 61 and 66; `post.sh` lines 71 and 76; `test-post.sh` lines 178–179
- **Issue** — Several comments break the rules for single-sentence comments, the serial comma and multi-sentence punctuation:
  - Five single-sentence comments end with a period, which the rule says they should not have: "…exactly a line the user cleared.", "…never on a clean file (1).", "…since only a secret is cleared.", "…to exactly that pull request." and "…65,536-character body limit.". They were carried over from the old block.
  - `post.sh` line 71 uses a serial comma ("show it, and post").
  - The two-sentence comment at `test-post.sh` lines 178–179 has no final period.
- **Suggestion** — Drop the five final periods, change the serial comma to "show it and post" and add the final period to `test-post.sh` line 179.
- **Recommendation** — Implement: mechanical, and these are new files that should start compliant.

## Staleness

### F136 🟢 Low Priority - "these command files" in ship-it after the conversion to skills

- **Document** — `.claude/skills/ship-it/SKILL.md`
- **Location** — Ground Rules, "Write derived text with the `Write` tool, never a heredoc or `echo`" (line 44)
- **Issue** — "handoffs and reviews of these command files quote heredocs" refers to the files under `home/.claude/commands/`, which this branch turned into skills, and `.claude/commands/` no longer exists in this repository. The reason still holds (skill files quote heredocs too), but the noun names something that has gone. The same leftover appears in `home/.claude/skills/doc-review/posting.md` line 152 ("Any review of these command files"; F19).
- **Suggestion** — Change "these command files" to "these skill files".
- **Recommendation** — Implement: a two-word fix to wording this branch's conversion made stale.

### F137 🟡 Medium Priority - Wording in review-file.md that still assumes one command file

- **Document** — `home/.claude/skills/doc-review/review-file.md`
- **Location** — Document Header, line 98; Document Header, lines 133–134; Tracking Finding Status, line 316
- **Issue** — Three phrases still assume the rules sit in one command file:
  - Line 98 says "every cross-reference in this command assume it". There is no command any more.
  - Lines 133–134 say "in the order those criteria appear above". The criteria are in `reviewer-rules.md`; nothing above line 133 in this file lists them.
  - Line 316 defines "off the pre-merge path" and says "Every other use of the term in this file means the same thing". In the old command, "this file" covered the posting and walkthrough text too. Now the definition no longer reaches the term in `posting.md` (lines 34 and 340) or SKILL.md (line 375).
- **Suggestion** — Change them to "every cross-reference in this skill's files assumes it", "in the order `reviewer-rules.md` gives them" and "Every other use of the term in this skill's files means the same thing".
- **Recommendation** — Implement. The move should have caught all three, and the third changes what a definition covers.

### F138 🟢 Low Priority - Pre-Merge Checklist sync comment still names a section that moved out

- **Document** — `home/.claude/skills/doc-review/review-file.md`
- **Location** — Pre-Merge Checklist, comment at lines 478–479
- **Issue** — The comment says "Keep in sync with the Consolidated Summary example table and the Walkthrough and Finding Selection example". That example is now in `walkthrough-example.md`. The move updated the matching comment at lines 394–395 ("the walkthrough example in walkthrough-example.md") but not this one.
- **Suggestion** — Change it to "…and the walkthrough example in walkthrough-example.md, which reuse this finding set".
- **Recommendation** — Implement. It names a sync partner that no longer exists.

### F139 🟢 Low Priority - Stale "This command" wording in update-deps after the conversion to a skill

- **Document** — `home/.claude/skills/update-deps/SKILL.md`
- **Location** — Overview (line 16), "This command automates the full dependency update workflow"; also Step 11 (line 350), "use the `/commit` command"
- **Issue** — The file is now a skill (`skills/update-deps/SKILL.md`, with frontmatter), but the Overview still calls it "this command". Line 350's "`/commit` command" names what is now `home/.claude/skills/commit/SKILL.md`. The sibling skills share the same leftover:
  - `home/.claude/skills/handoff/SKILL.md` lines 81, 149 and 203
  - `home/.claude/skills/resume-handoff/SKILL.md` lines 19, 24, 223 and 323
  - `home/.claude/skills/doc-review/SKILL.md` lines 73, 92 and 372

  The scope as a whole has not chosen a word yet.
- **Suggestion** — Change line 16 to "This skill automates the full dependency update workflow:" and line 350 to "use the `/commit` skill". Whoever reviews the sibling skills can sweep their uses to the same word.
- **Recommendation** — Implement. Each change is a single word, and both are exactly the stale wording the branch's conversion leaves behind.

## Observations

### F140 ℹ️ Observation - The handoff reflow splits bold section names across lines

- **Document** — `home/.claude/skills/handoff/SKILL.md`
- **Location** — Merging with an Existing Handoff, steps 3–4 (lines 418–419 and 421–422)
- **Issue** — The 100-column reflow appears to avoid starting a line with `*` or `**`. That ends some lines early (lines 67, 93 and 133) and splits `**Start Here**` and `**Captured by**` across lines here. The output renders correctly, but `grep -n 'Start Here'` and `grep -n 'Captured by'` miss these steps. The next editor checking that every reference to a section was updated should search for a single word or use a multiline match.

### F141 💡 Observation (optional action) - One linters.md line was rewrapped when it didn't need to be

- **Document** — `home/.claude/skills/update-deps/linters.md`
- **Location** — Step 8, lines 28–29
- **Issue** — The reflow moved "but" from the end of line 28 to the start of line 29, leaving line 28 at 92 columns. The original line ending in "and 4 but" was 96 columns and fit. The only effect is an extra changed line in the diff against the original. Optional action: put "but" back at the end of line 28.

### F142 💡 Observation (optional action) - The linters.md title says "Updates" where the sibling titles name only the topic

- **Document** — `home/.claude/skills/update-deps/linters.md`
- **Location** — Title (line 1)
- **Issue** — The sibling topic files are titled "Update Dependencies: JavaScript", "…: Terraform" and "…: Tool and Image Pins". This one is "Update Dependencies: Linter Updates", which says "Update" twice. Optional action: retitle it "Update Dependencies: Linters".

### F143 ℹ️ Observation - The commit description's "every commit" has a deliberate exception in `/ship-it`

- **Document** — `home/.claude/skills/commit/SKILL.md`
- **Location** — Frontmatter, `description`
- **Issue** — The description ends "Use for every commit, amend and message edit." The sibling `.claude/skills/ship-it/SKILL.md` (Step 3: Squash and Reword) says "do not invoke it during this step", because `/commit`'s default mode commits the session's changes. Both are correct: the `/ship-it` text is in context when it applies, and this file's Reshaping History grants that exception. A future editor who strengthens the description, or who makes `/ship-it` invoke `/commit`, would undo the balance. Keep the wording "every" here, and keep the prohibition in `/ship-it`.

### F144 ℹ️ Observation - Moving the blocks into scripts also stopped Claude Code's shell-snapshot `find` and `grep` functions from being used

- **Document** — `home/.claude/skills/doc-review/scripts/scrub-lib.sh`
- **Location** — `artifacts` and `grep_artifacts`
- **Issue** — In the Bash tool, `find` and `grep` are shell functions loaded from a Claude Code shell snapshot (`type -a find` shows "a shell function from …/shell-snapshots/…"). The old inline block's bare `find` resolved to that function, while `command grep` already bypassed the `grep` one.
  - Inside `bash post.sh` or `bash scrub.sh`, both resolve to `/usr/bin` (checked with `bash -c 'type -a find grep'`).
  - Running the scan as a script removes that dependency on the session's shell. Inlining the scan back into a skill file would bring it back.

### F145 💡 Observation (optional action) - Refill split the Rails Style Guide link text

- **Document** — `home/.claude/CLAUDE.md`
- **Location** — Code Style, lines 171–172
- **Issue** — The refill broke the link text across two lines: `[Rails Style` / `Guide](https://rails.rubystyle.guide/)`. It renders the same, but a search for "Rails Style Guide" no longer finds the line, and a one-line link is easier to edit. Optional action: put the line break back before `[Rails Style Guide](…)`, as it was at d22496a.

### F146 ℹ️ Observation - "Do not invoke `/commit`" now also guards against automatic invocation

- **Document** — `.claude/skills/ship-it/SKILL.md`
- **Location** — Step 3: Squash and Reword, the paragraph "The procedures below write commit messages in place of `/commit`: do not invoke it during this step" (lines 179–182)
- **Issue** — Before this branch, `/commit` was a slash command and ran only when someone typed it. It is now a skill without `disable-model-invocation`, and its description ends "Use for every commit, amend and message edit". That is exactly what Step 3 does, so the model may reach for it unprompted. This sentence is what stops that, and its reason (the default mode commits the session's changes) still holds. A future edit that softens or drops the sentence would bring back a path where Step 3 commits unrelated session changes during a history rewrite.

### F147 💡 Observation (optional action) - The repeated write-check-commit logic could become a script

- **Document** — `home/.claude/skills/commit/SKILL.md`
- **Location** — Arguments (lines 26–36), Rewording Under a `commit-msg` Hook (lines 164–179), Process step 8 (lines 354–362)
- **Issue** — The `mktemp`, the `test -s && ! LC_ALL=en_US.UTF-8 grep -n '.\{73,\}'` check and the branch guard are fixed logic, repeated three times. Two of the copies need the warning "Run it with the list indentation removed" because the heredoc sits inside a list. The branch's stated aim includes moving fixed shell logic into scripts run through `${CLAUDE_SKILL_DIR}`. Optional action: add `scripts/check-message.sh <file>` to check emptiness and wrap, and keep only the heredoc and the git call inline.

### F148 💡 Observation (optional action) - The walkthrough transcript drops F6's question without marking the gap

- **Document** — `home/.claude/skills/doc-review/walkthrough-example.md`
- **Location** — Transcript, line 20 ("Not recommended 2 of 2")
- **Issue** — The phase 2 part of the transcript starts at item 2 of 2. Item 1, F6, is only mentioned in the closing paragraph, so a reader scanning the transcript may wonder where it went. Optional action: put a line such as `(Not recommended 1 of 2, F6, is put the same way and ruled Ignore.)` just above line 20.

### F149 ℹ️ Observation - The walkthrough's alternative ending states a selection rule that SKILL.md only implies

- **Document** — `home/.claude/skills/doc-review/walkthrough-example.md`
- **Location** — Closing paragraph, lines 41–43 ("and "all" would take G2 and G4")
- **Issue** — The closing clause says that with F5 unruled, "all" takes nothing from G1. That means "all" passes over the unruled ⚖️ itself, not only its waiting dependents. `SKILL.md` lines 469–472 say this only indirectly. Its rule is that "all" takes "every member that is not waiting", and in the Membership rule only dependents wait. The "never selected" wording is attached to naming a finding number. "So one unruled ⚖️ cannot make either select nothing" points the same way. The example is currently the only place this outcome is stated outright. Whoever next edits the selection rule in `SKILL.md` should check this clause too.

### F150 ℹ️ Observation - "This command" in resume-handoff matches the scope's convention

- **Document** — `home/.claude/skills/resume-handoff/SKILL.md`
- **Location** — Lines 19, 24, 223 and 323
- **Issue** — All four uses of "this command" mean the slash invocation, not the files. The sibling skills follow the same split. `home/.claude/skills/doc-review/SKILL.md` says "Four parties run this command" next to "this skill's files". `home/.claude/skills/handoff/SKILL.md` and `home/.claude/skills/update-deps/SKILL.md` also keep "this command", and the user-wide CLAUDE.md still says "the `/commit` slash command". Changing this file alone to "this skill" would break that consistency. If the wording should change, do it as one sweep across all four skills.

### F151 💡 Observation (optional action) - "Steps 10 and 11" is the only step reference left unlinked in javascript.md

- **Document** — `home/.claude/skills/update-deps/javascript.md`
- **Location** — Re-resolve the Lock File, line 119 ("before the changelog and commit steps (Steps 10 and 11)")
- **Issue** — Every other reference in the file to Step 10 or 11 links into `SKILL.md` (lines 39, 113 and 156). In the original single file, an unlinked step number could be found by scrolling. Here those steps live in a different file. Optional action: link them as `[Step 10](SKILL.md#step-10-build-the-final-commit-message)` and `[Step 11](SKILL.md#step-11-commit-push-and-create-the-pr)`.

### F152 💡 Observation (optional action) - "Each command runs in a fresh shell" sits awkwardly beside the single `cd` the step relies on

- **Document** — `home/.claude/skills/update-deps/javascript.md`
- **Location** — Opening paragraph (lines 5–12) and line 46
- **Issue** — The step does one `cd "$(git rev-parse --show-toplevel)"` and relies on it for "every command in it". Line 46 then says each command runs "in a fresh shell". In Claude Code the working directory persists between Bash calls while environment variables do not, so the step is right. But a literal reader could conclude the `cd` is lost too. Optional action: reword line 46 to "Environment variables do not carry over between commands, so an `export` would not help; write the prefix out on every command."

### F153 💡 Observation (optional action) - Unlinked step mentions in terraform.md now point outside the file

- **Document** — `home/.claude/skills/update-deps/terraform.md`
- **Location** — Step 5 opening (line 20, "Step 11 then refuses to stage"); Bump the Pins (line 193, "Steps 3 and 4"); Step 6 (line 306, "Steps 7–11"; line 356, "Step 11's `git add -- ':/*.terraform.lock.hcl'`")
- **Issue** — These plain-text mentions were in-page in the original. Read on its own, this file now names steps that live in `SKILL.md`, `javascript.md` and `pins.md` without saying where. Other mentions of the same steps are linked (lines 317, 376, 481–483), so a reader can infer the location. Line 356 cites a specific command in Step 11, so it is the one where a link would help most. Optional action: link "Step 11's" at line 356 (and "Step 11" at line 20) to `SKILL.md#step-11-commit-push-and-create-the-pr`, matching the four links the move already rewrote.

### F154 💡 Observation (optional action) - Point the pins.md lookup-traps link at its subsection

- **Document** — `home/.claude/skills/update-deps/pins.md`
- **Location** — `## Step 7: Update Tool and Image Pins`, lines 54–55
- **Issue** — "Two lookup traps are recorded under [Known Changelog Quirks](changelogs.md#known-changelog-quirks)" lands at the top of changelogs.md. The two traps (`jq` and Elasticsearch) are in its last subsection, `### Tool and image pins`. "Two" is also a count that goes stale the moment a third pin quirk is added there. Optional action: link `changelogs.md#tool-and-image-pins` and drop the count. For example: "Lookup traps for pins are recorded under [Tool and image pins](changelogs.md#tool-and-image-pins): tags that do not start with a digit, and release pages that only point elsewhere."

### F155 💡 Observation (optional action) - "The other entries" has no referent in pins.md

- **Document** — `home/.claude/skills/update-deps/pins.md`
- **Location** — `## Step 7: Update Tool and Image Pins`, lines 57–58
- **Issue** — "Record every bump for the commit message with its upstream release notes, in the same format as the other entries" relies on the reader having just recorded entries in Steps 3–6. That holds in normal flow. Read on its own, the file never says where the format is defined. Optional action: link "the same format" to `SKILL.md#commit-message-format-reference` (heading at SKILL.md line 435).

### F156 ℹ️ Observation - The repeated opening check in linters.md Step 8 is needed, not redundant

- **Document** — `home/.claude/skills/update-deps/linters.md`
- **Location** — Step 8, first paragraph (lines 5–6)
- **Issue** — The `SKILL.md` stub already checks for changes to `rubocop` or any `rubocop-*` gem, so a later editor may want to cut the repeated check from this file. Don't. The stub only decides whether to come here. This file's version is followed by "Which of them changed decides how much of this step to run", and that split (core `rubocop` versus plugin-only) decides whether item 3 runs. The split exists only in this file.

### F157 💡 Observation (optional action) - The version-locked.md prefix link could point at the subsection that defines the prefixes

- **Document** — `home/.claude/skills/update-deps/version-locked.md`
- **Location** — Section intro, line 7 (`[Step 4](javascript.md#step-4-update-javascript-dependencies)`)
- **Issue** — The link is offered as the definition of "the two prefixes", but it lands on the Step 4 heading. The definitions are in the "Run Yarn with a Release-Age Gate and No Install Scripts" subsection, 15 lines further down. Optionally, retarget the link to `javascript.md#run-yarn-with-a-release-age-gate-and-no-install-scripts`. The original linked to the step heading as well.

### F158 ℹ️ Observation - The `## Known Changelog Quirks` H2 has to stay, and `SKILL.md` has a heading with the same name

- **Document** — `home/.claude/skills/update-deps/changelogs.md`
- **Location** — Line 3
- **Issue** — Four links target `changelogs.md#known-changelog-quirks`: `SKILL.md` lines 150, 221 and 251 and `pins.md` line 54. With only one H2 under the H1 the heading can look redundant, but removing it or folding it into the H1 breaks all four. `SKILL.md` also keeps a `## Known Changelog Quirks` stub heading (line 454). A future edit that drops the `changelogs.md` prefix from one of those links would still resolve, but it would land silently on the two-line stub instead of on this content.

### F159 💡 Observation (optional action) - check-loss.sh's loss report puts the first item on the "lost:" line

- **Document** — `home/.claude/skills/resume-handoff/scripts/check-loss.sh`
- **Location** — lines 23–32
- **Issue** — Output reads `kept the backup — lost:< ## Objective`. A section's continuation lines appear unlabeled under `Objective: ## Objective`. Optionally start each entry with a newline (`lost="$lost"$'\n'…`, and the same for the `diff` output) and print `lost:` on a line of its own.

### F160 💡 Observation (optional action) - The awk field references keep the skill-file workaround

- **Document** — `home/.claude/skills/doc-review/scripts/scrub-lib.sh`
- **Location** — line 57, and `post.sh` lines 86 and 117–122
- **Issue** — `$(0)` and `$(2)` work around Claude Code's `$<digit>` substitution in skill files, which no longer applies to a script run by path. `check-loss.sh` uses `$0`, and the ship-it `scrub.sh` uses `$0` in the same `uncleared` awk. Optionally switch to `$0` and `$2` for consistency; keeping the form only matters if these lines may be pasted back into a skill file.

### F161 ℹ️ Observation - CI lints these scripts but runs neither test suite

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — `.github/workflows/ci.yml`, super-linter environment
- **Issue** — CI enables only `VALIDATE_BASH` (shellcheck). Neither `test-post.sh` nor `test-scrub.sh` runs, so they are guards only when someone remembers to run them. Super-linter's `VALIDATE_BASH_EXEC` would have caught F80, but it would also flag `scrub-lib.sh` and the ship-it scripts, which are deliberately non-executable, so it would need exclusions.

### F162 ℹ️ Observation - The test suite assumes macOS and a non-root user

- **Document** — `home/.claude/skills/doc-review/scripts/test-post.sh`
- **Location** — case K, lines 146–152
- **Issue** — Case K relies on `chmod 000` making the artifact unreadable, which is not true for root, as in a container CI. `post.sh` also calls `mktemp -d -t pr-comment`, a BSD form that GNU `mktemp` rejects because the template has too few `X`s (F86). The suite is deterministic on macOS as a regular user. Running it anywhere else would need those two points addressed first.

### F163 ℹ️ Observation - reviewer-rules.md names its sibling files bare because it is never substituted

- **Document** — `home/.claude/skills/doc-review/reviewer-rules.md`
- **Location** — Whole file (references to `posting.md`, SKILL.md)
- **Issue** — Agents read this file by absolute path. The harness does not load it as a skill, so `${CLAUDE_SKILL_DIR}` and argument placeholders inside it are never expanded. The file correctly names its sibling files by bare filename and shows no path or placeholder. A future editor copying a reference from SKILL.md, which does use `${CLAUDE_SKILL_DIR}`, would leave a literal `${CLAUDE_SKILL_DIR}` that no reviewer can resolve. `posting.md`'s `<skill dir>` convention is the established alternative if a path is ever needed here.

### F164 ℹ️ Observation - The `${CLAUDE_SKILL_DIR}` stubs are how the agent finds the files behind the bare-name links

- **Document** — `home/.claude/skills/update-deps/SKILL.md`
- **Location** — Steps 4, 5 and 7–9 and the Version-Locked Packages and Known Changelog Quirks stubs, compared with the inline links in Steps 2, 3, 10 and 11 and Important Notes
- **Issue** — The inline links use bare relative names (`version-locked.md#…`, `terraform.md#…`). Those resolve on GitHub but not from the session's working directory, which is the app repository being updated. An agent finds the files through the stubs' `${CLAUDE_SKILL_DIR}/<file>.md` paths, which are substituted only in SKILL.md. A future editor tidying the stubs into plain Markdown links like the others would leave the agent no absolute path to read. Keep one `${CLAUDE_SKILL_DIR}` path per topic file in SKILL.md.

### F165 💡 Observation (optional action) - The update-deps Overview could say that Steps 4–9 live in topic files

- **Document** — `home/.claude/skills/update-deps/SKILL.md`
- **Location** — Overview (lines 14–29)
- **Issue** — The Overview lists the eleven steps, as it did before the split, but does not say that SKILL.md now routes Steps 4–9 and two reference sections to other files. The list is still accurate. A maintainer only learns about the router layout by scrolling to the stubs. Optional action: after the list, add "Steps 4 through 9, the version-locked packages and the changelog quirks live in topic files beside this one; each stub below says when to read its file."

## Consolidated Summary

| Finding | Type | Category | Description | Document | Location | Recommendation | Group | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F1 | 🔴 Critical | Formatting | Refill joined the paste-marker example onto one line | `home/.claude/CLAUDE.md` | Workflow, paste-marker example; handoff Resume Prompt | Implement | G5 | ❓ |
| F2 | 🟢 Low | Formatting | Refill made the ship-it intro paragraph narrower | `.claude/skills/ship-it/SKILL.md` | Intro paragraph | Implement | G5 | ❓ |
| F3 | 🟢 Low | Formatting | Refill broke a line that already fit | `home/.claude/skills/commit/SKILL.md` | Body, lines 228–229 | Skip | — | ❓ |
| F4 | 🟢 Low | Formatting | Base name in Header examples not backticked | `home/.claude/skills/handoff/SKILL.md` | Document Structure › Header | Implement | G14 | ❓ |
| F5 | 🟡 Medium | Consistency | Skill sweep missed "where agents read them" | `home/.claude/CLAUDE.md` | Workflow, line 46 | Implement | G17 | ❓ |
| F6 | 🟢 Low | Consistency | `/commit` and `/doc-review` still called slash commands | `home/.claude/CLAUDE.md` | Committing Changes | Implement | G17 | ❓ |
| F7 | 🟢 Low | Consistency | Heredoc ground rule doesn't cover the squash todo list | `.claude/skills/ship-it/SKILL.md` | Ground Rules | Defer | — | ❓ |
| F8 | 🟡 Medium | Consistency | Older-Git fallback rebase has no branch guard | `home/.claude/skills/commit/SKILL.md` | Reshaping History | Defer | — | ❓ |
| F9 | 🟢 Low | Consistency | "Project command" names what is now a skill | `home/.claude/skills/commit/SKILL.md` | Reshaping History | Implement | G17 | ❓ |
| F10 | 🟠 High | Consistency | "Never post by another route" contradicts `/ship-it` | `home/.claude/skills/doc-review/SKILL.md` | Posting the Review | Implement | G8 | ❓ |
| F11 | 🟡 Medium | Consistency | Router names recording agents as readers of review-file.md | `home/.claude/skills/doc-review/SKILL.md` | Opening file list | Implement | G8 | ❓ |
| F12 | 🟢 Low | Consistency | "This command" and "the file" mixed in Who Does What | `home/.claude/skills/doc-review/SKILL.md` | Who Does What | Implement | G17 | ❓ |
| F13 | 🟡 Medium | Consistency | "This command" has no antecedent | `home/.claude/skills/doc-review/reviewer-rules.md` | Four passages | Implement | G17 | ❓ |
| F14 | 🟡 Medium | Consistency | Sensitive findings "always withheld" vs posting.md clearing | `home/.claude/skills/doc-review/reviewer-rules.md` | Sensitive Information | Implement | G16 | ❓ |
| F15 | 🟡 Medium | Consistency | File Name runs before SKILL.md says to read the file | `home/.claude/skills/doc-review/review-file.md` | File Name | Implement | G8 | ❓ |
| F16 | 🟢 Low | Consistency | Cross-file references missing file hints | `home/.claude/skills/doc-review/review-file.md` | Several sections | Implement | G13 | ❓ |
| F17 | 🟡 Medium | Consistency | Paragraphs still describe the removed inline blocks | `home/.claude/skills/doc-review/posting.md` | PR Comment Format | Implement | G16 | ❓ |
| F18 | 🟡 Medium | Consistency | Filename list reviewer-rules.md cites is gone | `home/.claude/skills/doc-review/posting.md` | PR Comment Format | Implement | G16 | ❓ |
| F19 | 🟢 Low | Consistency | Stale "command file" and "this command" wording | `home/.claude/skills/doc-review/posting.md` | PR Comment Format | Implement | G17 | ❓ |
| F20 | 🟢 Low | Consistency | Observation row "names no category" contradicts review-file.md | `home/.claude/skills/doc-review/posting.md` | Ask before withholding | Defer | — | ❓ |
| F21 | 🟢 Low | Consistency | SKILL.md calls the example "the whole walkthrough" | `home/.claude/skills/doc-review/walkthrough-example.md` | Introduction | Implement | G12 | ❓ |
| F22 | 🟢 Low | Consistency | F5's recommendation follows its options | `home/.claude/skills/doc-review/walkthrough-example.md` | Transcript | Implement | G12 | ❓ |
| F23 | 🟡 Medium | Consistency | "This command file" names a SKILL.md | `home/.claude/skills/handoff/SKILL.md` | Document Structure intro | Implement | G17 | ❓ |
| F24 | 🟢 Low | Consistency | The two gather-state.sh scripts take the remote differently | `home/.claude/skills/handoff/SKILL.md` | Gathering State | Implement | G3 | ❓ |
| F25 | ⚖️ Decision | Consistency | Handoff issue links: inline URL or reference-style | `home/.claude/skills/handoff/SKILL.md` | Header; References | Options (b) | G4 | ❓ |
| F26 | 🟢 Low | Consistency | Public-repository Linear URL rule missing | `home/.claude/skills/handoff/SKILL.md` | Output File | Defer | — | ❓ |
| F27 | 🟡 Medium | Consistency | Plans described as always tracked but stripped | `home/.claude/skills/handoff/SKILL.md` | Key Files & Entry Points | Defer | — | ❓ |
| F28 | 🟢 Low | Consistency | Doc-review artifact pattern narrower than siblings' | `home/.claude/skills/resume-handoff/SKILL.md` | Step 3, Also Check | Implement | G9 | ❓ |
| F29 | 🟢 Low | Consistency | Examples cite commands the agent no longer runs | `home/.claude/skills/resume-handoff/SKILL.md` | Step 5 table; Step 4 | Implement | G9 | ❓ |
| F30 | 🟢 Low | Consistency | `REMOTE` is half-documented | `home/.claude/skills/resume-handoff/SKILL.md` | Step 3 | Defer | — | ❓ |
| F31 | 🟢 Low | Consistency | Opening paragraph omits tool and image pins | `home/.claude/skills/update-deps/SKILL.md` | Opening paragraph | Implement | G15 | ❓ |
| F32 | 🟢 Low | Consistency | "this command" in javascript.md | `home/.claude/skills/update-deps/javascript.md` | Release-Age Gate, line 42 | Defer | — | ❓ |
| F33 | 🟢 Low | Consistency | Coverage restore hardcodes a platform list | `home/.claude/skills/update-deps/terraform.md` | Step 6 | Defer | — | ❓ |
| F34 | 🟢 Low | Consistency | "this command" in terraform.md | `home/.claude/skills/update-deps/terraform.md` | Bump the Pins | Defer | — | ❓ |
| F35 | 🟢 Low | Consistency | Bare "see Step 10" points outside the file | `home/.claude/skills/update-deps/linters.md` | Steps 8 and 9 | Implement | G15 | ❓ |
| F36 | 🟢 Low | Consistency | "Never skip linter checks" overstates the steps | `home/.claude/skills/update-deps/linters.md` | Steps 8 and 9 | Defer | — | ❓ |
| F37 | 🟡 Medium | Consistency | Rails check placed after the single restore call | `home/.claude/skills/update-deps/version-locked.md` | Rails JavaScript Packages | Defer | — | ❓ |
| F38 | 🟢 Low | Consistency | Bare `# Update Dependencies` H1 | `home/.claude/skills/update-deps/version-locked.md` | Line 1 | Implement | G15 | ❓ |
| F39 | 🟢 Low | Consistency | "during this command" after the conversion | `home/.claude/skills/update-deps/version-locked.md` | Playwright | Implement | G17 | ❓ |
| F40 | 🟡 Medium | Consistency | Bare `# Update Dependencies` H1 | `home/.claude/skills/update-deps/changelogs.md` | Line 1 | Implement | G15 | ❓ |
| F41 | 🟢 Low | Consistency | Unlinked "Step 10" | `home/.claude/skills/update-deps/changelogs.md` | Gems with no changelog | Implement | G15 | ❓ |
| F42 | 🟢 Low | Consistency | H3 headings mix sentence and Title Case | `home/.claude/skills/update-deps/changelogs.md` | H3 headings | Defer | — | ❓ |
| F43 | ⚖️ Decision | Consistency | Whether the gather-state scripts share their common block | `home/.claude/skills/handoff/scripts/gather-state.sh` | Lines 14–32 | Options (a) | G3 | ❓ |
| F44 | 🟢 Low | Consistency | Pull request parts conflate "none" and "not checked" | `home/.claude/skills/handoff/scripts/gather-state.sh` | Lines 50–54 | Implement | G3 | ❓ |
| F45 | 🟠 High | Accuracy | Remaining `local-review` preload | `home/.claude/agents/documentation-expert.md` | Frontmatter `skills:` | Implement | G6 | ❓ |
| F46 | 🟡 Medium | Accuracy | Autosquash routes leave a stray commit on a dirty tree | `home/.claude/skills/commit/SKILL.md` | Rewording Under a commit-msg Hook | Defer | — | ❓ |
| F47 | 🟡 Medium | Accuracy | Section references to moved files unqualified | `home/.claude/skills/doc-review/SKILL.md` | Several sections | Implement | G13 | ❓ |
| F48 | 🟢 Low | Accuracy | `scripts/` entry overstates test coverage | `home/.claude/skills/doc-review/SKILL.md` | Opening file list | Implement | G11 | ❓ |
| F49 | 🟡 Medium | Accuracy | "Filename list in PR Comment Format" no longer there | `home/.claude/skills/doc-review/reviewer-rules.md` | Redacting Sensitive Evidence | Implement | G16 | ❓ |
| F50 | 🟢 Low | Accuracy | Three references lack file hints | `home/.claude/skills/doc-review/reviewer-rules.md` | Recommendations; Numbered Findings | Implement | G13 | ❓ |
| F51 | 🟡 Medium | Accuracy | Who runs `header.sh`, from where, and `<skill dir>` | `home/.claude/skills/doc-review/review-file.md` | Document Header | Implement | G7 | ❓ |
| F52 | 🟡 Medium | Accuracy | "(SKILL.md)" hint points at the wrong file | `home/.claude/skills/doc-review/review-file.md` | Collating the Reports | Implement | G13 | ❓ |
| F53 | 🟡 Medium | Accuracy | Command placeholders slip past post.sh's check | `home/.claude/skills/doc-review/posting.md` | Post command | Implement | G10 | ❓ |
| F54 | ⚖️ Decision | Accuracy | `.local` term needs a path; a port alone passes | `home/.claude/skills/doc-review/posting.md` | PR Comment Format | Options (a) | G2 | ❓ |
| F55 | 🟢 Low | Accuracy | Sync comments inaccurate about ship-it and the tested set | `home/.claude/skills/doc-review/posting.md` | HTML comments | Implement | G2 | ❓ |
| F56 | 🟢 Low | Accuracy | Overstated claims about refusals and splitting | `home/.claude/skills/doc-review/posting.md` | PR Comment Format | Implement | G16 | ❓ |
| F57 | 🟡 Medium | Accuracy | Keep-in-sync comment names no files | `home/.claude/skills/doc-review/walkthrough-example.md` | HTML comment | Implement | G12 | ❓ |
| F58 | 🟢 Low | Accuracy | "Tracking Finding Status" cited without its file | `home/.claude/skills/doc-review/walkthrough-example.md` | Closing paragraph | Implement | G12 | ❓ |
| F59 | 🟡 Medium | Accuracy | Header points at variables the agent cannot see | `home/.claude/skills/handoff/SKILL.md` | Document Structure › Header | Implement | G14 | ❓ |
| F60 | 🟡 Medium | Accuracy | "Print the same nothing" misdescribes the output | `home/.claude/skills/handoff/SKILL.md` | Gathering State | Implement | G14 | ❓ |
| F61 | 🟡 Medium | Accuracy | Current State cites commands no longer in Gathering State | `home/.claude/skills/handoff/SKILL.md` | Current State; Process | Implement | G14 | ❓ |
| F62 | 🟠 High | Accuracy | `"$tip:<path>"` breaks under zsh colon modifiers | `home/.claude/skills/resume-handoff/SKILL.md` | Step 2; Treat Fetched Text | Implement | G9 | ❓ |
| F63 | 🟡 Medium | Accuracy | `gh` paragraph describes output no longer printed | `home/.claude/skills/resume-handoff/SKILL.md` | Step 3 | Implement | G9 | ❓ |
| F64 | 🟡 Medium | Accuracy | "The final part" of the output is often another part | `home/.claude/skills/resume-handoff/SKILL.md` | Step 3, Also Check | Implement | G9 | ❓ |
| F65 | 🟢 Low | Accuracy | Reflog called "empty" when it fails | `home/.claude/skills/resume-handoff/SKILL.md` | When the Branch Moved | Implement | G9 | ❓ |
| F66 | 🟢 Low | Accuracy | Loss check's deletion and exit 2 unmentioned | `home/.claude/skills/resume-handoff/SKILL.md` | Step 4 | Implement | G9 | ❓ |
| F67 | 🟢 Low | Accuracy | Step 10 hands the sub-agent an unresolvable link | `home/.claude/skills/update-deps/SKILL.md` | Step 10, Draft the Message | Implement | G1 | ❓ |
| F68 | 🟠 High | Accuracy | `3d` age gate not honored on Yarn 4.10.x | `home/.claude/skills/update-deps/javascript.md` | Release-Age Gate | Defer | — | ❓ |
| F69 | 🟡 Medium | Accuracy | Range hold repaired without the gate | `home/.claude/skills/update-deps/javascript.md` | Re-resolve the Lock File | Defer | — | ❓ |
| F70 | 🟡 Medium | Accuracy | `npx playwright` can download and run the newest release | `home/.claude/skills/update-deps/version-locked.md` | Playwright | Defer | — | ❓ |
| F71 | 🟡 Medium | Accuracy | `--review` accepts any file | `home/.claude/skills/doc-review/scripts/post.sh` | Argument parsing; `ids` | Implement | G10 | ❓ |
| F72 | 🟡 Medium | Accuracy | Gate 1 passes silently on an empty artifact set | `home/.claude/skills/doc-review/scripts/post.sh` | Gate 1 | Implement | G10 | ❓ |
| F73 | 🟡 Medium | Accuracy | Differently spelled `--post` deletes the review file | `home/.claude/skills/doc-review/scripts/post.sh` | Line 148 | Implement | G10 | ❓ |
| F74 | 🟡 Medium | Accuracy | Aligned summary table defeats both detectors | `home/.claude/skills/doc-review/scripts/post.sh` | Lines 53 and 121 | Implement | G10 | ❓ |
| F75 | 🟢 Low | Accuracy | Checks run in the caller's locale | `home/.claude/skills/doc-review/scripts/post.sh`, `home/.claude/skills/doc-review/scripts/scrub-lib.sh` | Open-findings greps; `uncleared` | Implement | G10 | ❓ |
| F76 | 🟢 Low | Accuracy | Several steps ignore their own failure | `home/.claude/skills/doc-review/scripts/post.sh` | Lines 51, 57, 78–87 | Implement | G10 | ❓ |
| F77 | 🟢 Low | Accuracy | Fenced `## ` line ends the Sensitive Information section | `home/.claude/skills/doc-review/scripts/post.sh` | `ids` awk | Defer | — | ❓ |
| F78 | 🟢 Low | Accuracy | Key-cell term misses quoted, HTML-coded and NBSP cells | `home/.claude/skills/doc-review/scripts/scrub-lib.sh`, `.claude/skills/ship-it/scripts/scrub.sh` | Key-cell term | Implement | G2 | ❓ |
| F79 | 🟢 Low | Accuracy | Mentions and cross-references posted unchecked | `home/.claude/skills/doc-review/scripts/post.sh` | Gate 2 | Defer | — | ❓ |
| F80 | 🟠 High | Accuracy | `header.sh` is not executable | `home/.claude/skills/doc-review/scripts/header.sh` | File mode | Implement | G7 | ❓ |
| F81 | 🟡 Medium | Accuracy | Placeholder guard misses the `<…>` form | `home/.claude/skills/doc-review/scripts/post.sh` | Lines 41–43 | Implement | G10 | ❓ |
| F82 | 🟡 Medium | Accuracy | `gh` calls never pass `--repo` | `home/.claude/skills/handoff/scripts/gather-state.sh` | `gh` calls | Defer | G3 | ❓ |
| F83 | 🟢 Low | Accuracy | Updated date never validated | `home/.claude/skills/resume-handoff/scripts/gather-state.sh` | Lines 12–13, 76 | Implement | G3 | ❓ |
| F84 | 🟢 Low | Accuracy | Nonexistent document reported as untracked | `home/.claude/skills/doc-review/scripts/header.sh` | Lines 13–27 | Implement | G7 | ❓ |
| F85 | 🟢 Low | Accuracy | Empty and flag-shaped option values accepted | `home/.claude/skills/doc-review/scripts/post.sh` | Lines 24–38 | Implement | G10 | ❓ |
| F86 | 🟢 Low | Accuracy | `mktemp` call GNU-incompatible and unchecked | `home/.claude/skills/doc-review/scripts/post.sh` | Line 57 | Implement | G10 | ❓ |
| F87 | 🟢 Low | Accuracy | `section()` ignores fences | `home/.claude/skills/resume-handoff/scripts/check-loss.sh` | Lines 17–19 | Defer | — | ❓ |
| F88 | 🟢 Low | Accuracy | `command grep` comment gives an inapplicable reason | `home/.claude/skills/resume-handoff/scripts/check-loss.sh` | Lines 21–22 | Implement | G9 | ❓ |
| F89 | 🟠 High | Accuracy | Gate 2 has no case | `home/.claude/skills/doc-review/scripts/test-post.sh` | `check` cases | Implement | G11 | ❓ |
| F90 | 🟠 High | Accuracy | `check` never asserts the exit status | `home/.claude/skills/doc-review/scripts/test-post.sh` | `check` | Implement | G11 | ❓ |
| F91 | 🟠 High | Accuracy | Guard keeping the review file alive untested | `home/.claude/skills/doc-review/scripts/test-post.sh` | Cases A, D2, Q | Implement | G11 | ❓ |
| F92 | 🟡 Medium | Accuracy | Working-file survival caught only by accident | `home/.claude/skills/doc-review/scripts/test-post.sh` | Cases D–F | Implement | G11 | ❓ |
| F93 | 🟡 Medium | Accuracy | Stub `gh` never checks `--repo` or the URL | `home/.claude/skills/doc-review/scripts/test-post.sh` | Stub | Implement | G11 | ❓ |
| F94 | 🟡 Medium | Accuracy | Heading assertion's wildcards accept any delimiter | `home/.claude/skills/doc-review/scripts/test-post.sh` | Line 92 | Implement | G11 | ❓ |
| F95 | 🟡 Medium | Accuracy | Scan's repository-root anchor untested | `home/.claude/skills/doc-review/scripts/test-post.sh` | `check`; `scrub_exits` | Implement | G11 | ❓ |
| F96 | 🟢 Low | Clarity | Confirmations list limits the names question to reviews | `.claude/skills/ship-it/SKILL.md` | Confirmations | Defer | — | ❓ |
| F97 | 🟢 Low | Clarity | "For this codebase" in a user-wide agent | `home/.claude/agents/documentation-expert.md` | Constraints | Defer | — | ❓ |
| F98 | 🟠 High | Clarity | Read trigger for review-file.md fires too late | `home/.claude/skills/doc-review/SKILL.md` | Lines 32–34 | Implement | G8 | ❓ |
| F99 | 🟡 Medium | Clarity | Orphaned lead-in now introduces After the Review | `home/.claude/skills/doc-review/SKILL.md` | Composing the Prompts | Implement | G8 | ❓ |
| F100 | 🟢 Low | Clarity | Routing contract argues from the single-file layout | `home/.claude/skills/doc-review/SKILL.md` | Composing the Prompts; After the Review | Implement | G8 | ❓ |
| F101 | 🟢 Low | Clarity | Reviewer Output intro restates the opening | `home/.claude/skills/doc-review/reviewer-rules.md` | Reviewer Output | Implement | G13 | ❓ |
| F102 | 🟢 Low | Clarity | Opening implies recording agents read the file | `home/.claude/skills/doc-review/review-file.md` | Review File | Implement | G8 | ❓ |
| F103 | 🟡 Medium | Clarity | "Reading pass" is never defined | `home/.claude/skills/doc-review/posting.md` | Lines 167–169 | Implement | G2 | ❓ |
| F104 | 🟡 Medium | Clarity | Gate and scrub-lib names used without a source | `home/.claude/skills/doc-review/posting.md` | PR Comment Format | Implement | G16 | ❓ |
| F105 | 🟡 Medium | Clarity | Unlabeled hits; "rewrite each hit" precedes its exception | `home/.claude/skills/doc-review/posting.md` | PR Comment Format | Implement | G16 | ❓ |
| F106 | 🟡 Medium | Clarity | `--status` content undefined | `home/.claude/skills/doc-review/posting.md` | PR Comment Format | Implement | G16 | ❓ |
| F107 | 🟡 Medium | Clarity | List-file `mktemp` paths kept only in variables | `home/.claude/skills/doc-review/posting.md` | Lines 175 and 251 | Implement | G16 | ❓ |
| F108 | 🟢 Low | Clarity | Decision history in a normative section | `home/.claude/skills/doc-review/posting.md` | PR Comment Format | Defer | — | ❓ |
| F109 | 🟢 Low | Clarity | Introduction gives no starting state or precedence | `home/.claude/skills/doc-review/walkthrough-example.md` | Introduction | Implement | G12 | ❓ |
| F110 | 🟡 Medium | Clarity | Output summary omits the unchecked commit range | `home/.claude/skills/handoff/SKILL.md` | Gathering State | Implement | G14 | ❓ |
| F111 | 🟡 Medium | Clarity | Script's work reads as agent tasks | `home/.claude/skills/handoff/SKILL.md` | Gathering State | Implement | G14 | ❓ |
| F112 | 🟢 Low | Clarity | `00:00` rationale explains unseen code | `home/.claude/skills/resume-handoff/SKILL.md` | Step 3, Also Check | Implement | G9 | ❓ |
| F113 | 🟢 Low | Clarity | "As the blocks below do" no longer fits | `home/.claude/skills/resume-handoff/SKILL.md` | Step 3 | Implement | G9 | ❓ |
| F114 | 🟡 Medium | Clarity | Version-Locked stub's read time matches neither use nor reason | `home/.claude/skills/update-deps/SKILL.md` | Version-Locked Packages | Implement | G1 | ❓ |
| F115 | ⚖️ Decision | Clarity | `.tf` detection sits behind the routing decision | `home/.claude/skills/update-deps/terraform.md` | Step 5 opening | Options (a) | G1 | ❓ |
| F116 | ⚖️ Decision | Clarity | Run-wide steps sit under a file titled for pins | `home/.claude/skills/update-deps/pins.md` | Two run-wide sections | Options (b) | G1 | ❓ |
| F117 | 🟢 Low | Clarity | Bare "Step 6" points outside the file | `home/.claude/skills/update-deps/pins.md` | Verify the Bumps | Implement | G15 | ❓ |
| F118 | 🟢 Low | Clarity | Step 9 depends on Step 8's wording | `home/.claude/skills/update-deps/linters.md` | Step 9 | Implement | G15 | ❓ |
| F119 | ⚖️ Decision | Clarity | changelogs.md is read too late for Step 7 | `home/.claude/skills/update-deps/changelogs.md` | Whole file; SKILL.md stub | Options (a) | G1 | ❓ |
| F120 | 🟡 Medium | Clarity | Suite misses the script defects and SKILL.md's claim | `home/.claude/skills/doc-review/scripts/test-post.sh` | Coverage | Implement | G11 | ❓ |
| F121 | 🟢 Low | Clarity | gather-state.sh never checks for a repository | `home/.claude/skills/handoff/scripts/gather-state.sh` | Top of both scripts | Implement | G3 | ❓ |
| F122 | 🟢 Low | Clarity | No usage message; failed `rm` exits with the loss code | `home/.claude/skills/resume-handoff/scripts/check-loss.sh` | Lines 11–14, 35 | Implement | G9 | ❓ |
| F123 | 🟠 High | Clarity | Most of scrub-lib.sh's pattern set has no case | `home/.claude/skills/doc-review/scripts/test-post.sh` | Cases C–Q | Implement | G11 | ❓ |
| F124 | 🟠 High | Clarity | Multi-part posting entirely untested | `home/.claude/skills/doc-review/scripts/test-post.sh` | No case | Implement | G11 | ❓ |
| F125 | 🟡 Medium | Clarity | `- [ ]` open-findings branch has no case | `home/.claude/skills/doc-review/scripts/test-post.sh` | Case G | Implement | G11 | ❓ |
| F126 | 🟡 Medium | Clarity | Cleared-file gates and scrub.sh's argument untested | `home/.claude/skills/doc-review/scripts/test-post.sh` | scrub.sh cases | Implement | G11 | ❓ |
| F127 | 🟡 Medium | Clarity | Argument and precondition refusals untested | `home/.claude/skills/doc-review/scripts/test-post.sh` | Cases E, E2, F | Implement | G11 | ❓ |
| F128 | 🟡 Medium | Clarity | Two artifact name patterns never exercised | `home/.claude/skills/doc-review/scripts/test-post.sh` | No case | Implement | G11 | ❓ |
| F129 | 🟢 Low | Clarity | Exemptions and bounds have no pass-through case | `home/.claude/skills/doc-review/scripts/test-post.sh` | Cases C, M, J | Implement | G11 | ❓ |
| F130 | ⚖️ Decision | Clarity | Whether to pin the backticked-file-name block | `.claude/skills/ship-it/scripts/test-scrub.sh` | Lines 63–64 | Options (a) | G2 | ❓ |
| F131 | 🟢 Low | Clarity | scrub.sh's scanned-file list never asserted | `home/.claude/skills/doc-review/scripts/test-post.sh` | Lines 186–188 | Implement | G11 | ❓ |
| F132 | 🟢 Low | Clarity | A stub bypass would reach github.com | `home/.claude/skills/doc-review/scripts/test-post.sh` | Line 86 | Implement | G11 | ❓ |
| F133 | 🟢 Low | Clarity | `review()` writes undocumented fixtures | `home/.claude/skills/doc-review/scripts/test-post.sh` | `review()` | Implement | G11 | ❓ |
| F134 | 🟢 Low | Spelling and Grammar | Description's serial comma, "one" and "fold" | `home/.claude/skills/commit/SKILL.md` | Frontmatter `description` | Implement | G18 | ❓ |
| F135 | 🟢 Low | Spelling and Grammar | Script comment punctuation | `home/.claude/skills/doc-review/scripts/scrub-lib.sh` | scrub-lib.sh, post.sh, test-post.sh comments | Implement | G19 | ❓ |
| F136 | 🟢 Low | Staleness | "these command files" after the conversion | `.claude/skills/ship-it/SKILL.md` | Ground Rules | Implement | G17 | ❓ |
| F137 | 🟡 Medium | Staleness | Wording that assumes one command file | `home/.claude/skills/doc-review/review-file.md` | Document Header; Tracking Finding Status | Implement | G17 | ❓ |
| F138 | 🟢 Low | Staleness | Sync comment names a section that moved out | `home/.claude/skills/doc-review/review-file.md` | Pre-Merge Checklist comment | Implement | G13 | ❓ |
| F139 | 🟢 Low | Staleness | "This command" and "`/commit` command" | `home/.claude/skills/update-deps/SKILL.md` | Overview; Step 11 | Implement | G17 | ❓ |
| F140 | ℹ️ Observation | Formatting | Reflow splits bold section names across lines | `home/.claude/skills/handoff/SKILL.md` | Merging with an Existing Handoff | — | — | — |
| F141 | 💡 Observation | Formatting | One line rewrapped needlessly | `home/.claude/skills/update-deps/linters.md` | Step 8 | — | — | — |
| F142 | 💡 Observation | Formatting | Title says "Updates" twice over | `home/.claude/skills/update-deps/linters.md` | Title | — | — | — |
| F143 | ℹ️ Observation | Consistency | "Every commit" has a deliberate `/ship-it` exception | `home/.claude/skills/commit/SKILL.md` | Frontmatter `description` | — | — | — |
| F144 | ℹ️ Observation | Accuracy | Scripts no longer use the shell-snapshot functions | `home/.claude/skills/doc-review/scripts/scrub-lib.sh` | `artifacts`, `grep_artifacts` | — | — | — |
| F145 | 💡 Observation | Clarity | Refill split the Rails Style Guide link text | `home/.claude/CLAUDE.md` | Code Style | — | — | — |
| F146 | ℹ️ Observation | Clarity | "Do not invoke `/commit`" now guards auto-invocation | `.claude/skills/ship-it/SKILL.md` | Step 3 | — | — | — |
| F147 | 💡 Observation | Clarity | Write-check-commit logic could become a script | `home/.claude/skills/commit/SKILL.md` | Arguments; Rewording; Process | — | — | — |
| F148 | 💡 Observation | Clarity | Transcript drops F6's question unmarked | `home/.claude/skills/doc-review/walkthrough-example.md` | Transcript | — | — | — |
| F149 | ℹ️ Observation | Clarity | Alternative ending states a rule SKILL.md implies | `home/.claude/skills/doc-review/walkthrough-example.md` | Closing paragraph | — | — | — |
| F150 | ℹ️ Observation | Clarity | "This command" matches the scope's convention | `home/.claude/skills/resume-handoff/SKILL.md` | Lines 19, 24, 223, 323 | — | — | — |
| F151 | 💡 Observation | Clarity | "Steps 10 and 11" left unlinked | `home/.claude/skills/update-deps/javascript.md` | Re-resolve the Lock File | — | — | — |
| F152 | 💡 Observation | Clarity | "Fresh shell" sits awkwardly beside the single `cd` | `home/.claude/skills/update-deps/javascript.md` | Opening; line 46 | — | — | — |
| F153 | 💡 Observation | Clarity | Unlinked step mentions point outside the file | `home/.claude/skills/update-deps/terraform.md` | Steps 5 and 6 | — | — | — |
| F154 | 💡 Observation | Clarity | Point the lookup-traps link at its subsection | `home/.claude/skills/update-deps/pins.md` | Step 7 | — | — | — |
| F155 | 💡 Observation | Clarity | "The other entries" has no referent | `home/.claude/skills/update-deps/pins.md` | Step 7 | — | — | — |
| F156 | ℹ️ Observation | Clarity | Step 8's repeated opening check is needed | `home/.claude/skills/update-deps/linters.md` | Step 8 | — | — | — |
| F157 | 💡 Observation | Clarity | Prefix link could target the defining subsection | `home/.claude/skills/update-deps/version-locked.md` | Section intro | — | — | — |
| F158 | ℹ️ Observation | Clarity | The Known Changelog Quirks H2 has to stay | `home/.claude/skills/update-deps/changelogs.md` | Line 3 | — | — | — |
| F159 | 💡 Observation | Clarity | Loss report puts the first item on the "lost:" line | `home/.claude/skills/resume-handoff/scripts/check-loss.sh` | Lines 23–32 | — | — | — |
| F160 | 💡 Observation | Clarity | awk field references keep the skill-file workaround | `home/.claude/skills/doc-review/scripts/scrub-lib.sh` | Line 57; post.sh | — | — | — |
| F161 | ℹ️ Observation | Clarity | CI lints the scripts but runs no test suite | `home/.claude/skills/doc-review/scripts/test-post.sh` | CI workflow | — | — | — |
| F162 | ℹ️ Observation | Clarity | Suite assumes macOS and a non-root user | `home/.claude/skills/doc-review/scripts/test-post.sh` | Case K | — | — | — |
| F163 | ℹ️ Observation | — | Sibling files named bare because the file is never substituted | `home/.claude/skills/doc-review/reviewer-rules.md` | Whole file | — | — | — |
| F164 | ℹ️ Observation | — | `${CLAUDE_SKILL_DIR}` stubs are how the agent finds topic files | `home/.claude/skills/update-deps/SKILL.md` | Router stubs | — | — | — |
| F165 | 💡 Observation | — | Overview could say Steps 4–9 live in topic files | `home/.claude/skills/update-deps/SKILL.md` | Overview | — | — | — |

## Pre-Merge Checklist

### G3 — Settle whether the gather-state scripts share code, then fix both

F43 is the first ⚖️ still unruled, and F82 waits on it; G9 and G14 describe the output F44 changes, so this group also goes ahead of them.

- [ ] ❓ F43 - Whether the two gather-state.sh scripts share their common block (sync notes / shared lib / leave; (a) recommended)
- [ ] ❓ F82 - Pass `--repo` to every `gh` call in both scripts (Defer — waits on F43)
- [ ] ❓ F24 - Take the remote the same way in both scripts
- [ ] ❓ F44 - Tell "none" from "not checked" in the pull request parts
- [ ] ❓ F121 - Refuse to run outside a repository
- [ ] ❓ F83 - Validate resume-handoff's updated date

### G4 — Settle the handoff's issue-link style

An unruled ⚖️ that edits either the handoff skill or the user-wide CLAUDE.md; nothing else waits on it.

- [ ] ❓ F25 - Issue links in a handoff (reference-style links / inline URLs and narrow CLAUDE.md; (b) recommended)

### G5 — Restore what the refill commit broke

The only 🔴 in the review; one fixup to 1d26aa3 also restores F2's paragraph.

- [ ] ❓ F1 - Restore the paste-marker example and the handoff Resume Prompt example
- [ ] ❓ F2 - Restore the ship-it intro paragraph's line breaks

### G6 — Drop the documentation-expert's remaining preload

🟠 and a one-line edit; its Verification check is still pending.

- [ ] ❓ F45 - Remove the `local-review` entry and the empty `skills:` key

### G7 — Make header.sh runnable and its documentation exact

🟠 on a step the procedure cannot skip; three small edits around one script.

- [ ] ❓ F80 - Commit header.sh as executable
- [ ] ❓ F51 - Say who runs header.sh, from where and what `<skill dir>` is
- [ ] ❓ F84 - Refuse a nonexistent document in header.sh

### G8 — Repair doc-review's read routing

🟠; the router and the rules files it routes to, fixed together so every file says the same about who reads what and when.

- [ ] ❓ F98 - Have the orchestrator read review-file.md before resolving the scope
- [ ] ❓ F10 - Limit "never post by another route" to this skill's own posting
- [ ] ❓ F15 - Say File Name is read while confirming the scope
- [ ] ❓ F11 - Say the recording agents get review-file.md's rules quoted, and why
- [ ] ❓ F102 - Say in review-file.md that the recording agents never read it
- [ ] ❓ F99 - Replace the orphaned lead-in with an explicit dispatch step
- [ ] ❓ F100 - Update the routing contract and the After the Review intro

### G9 — Bring resume-handoff in line with its scripts

🟠 for the zsh trap; after G3, since F63 describes output F44 changes.

- [ ] ❓ F62 - Brace `${tip}` before the colon
- [ ] ❓ F63 - Describe the script's `gh` fallback output
- [ ] ❓ F64 - Name the base-absorbed part by its header and mark the files optional
- [ ] ❓ F65 - Say the reflog fails, not empties, without a local branch
- [ ] ❓ F66 - Say check-loss.sh deletes the backup and what exit 2 means
- [ ] ❓ F28 - Widen the doc-review artifact pattern
- [ ] ❓ F29 - Cite gather-state.sh in the examples
- [ ] ❓ F112 - Move the `00:00` rationale into gather-state.sh
- [ ] ❓ F113 - Reword and move the shell-variables paragraph
- [ ] ❓ F88 - Correct check-loss.sh's `command grep` comment
- [ ] ❓ F122 - Add a usage message and truthful exit codes to check-loss.sh

### G10 — Harden post.sh

The script changes G11's new cases assert, so it goes ahead of G11; F53 and F81 fix one defect from both sides (the documented command and the guard), and F76 and F86 rewrite the same `mktemp` line.

- [ ] ❓ F72 - Refuse an empty artifact set in Gate 1
- [ ] ❓ F71 - Refuse a `--review` that is not a root review artifact
- [ ] ❓ F73 - Compare files, not strings, before deleting
- [ ] ❓ F74 - Accept padded table columns in both detectors
- [ ] ❓ F81 - Reject the `<placeholder>` form in the guard
- [ ] ❓ F53 - Write posting.md's command placeholders in the `[…]` form
- [ ] ❓ F75 - Run the remaining greps, `sed` and `awk` under `LC_ALL=C`
- [ ] ❓ F76 - Make validation, `mktemp` and split failures fatal
- [ ] ❓ F85 - Refuse empty and flag-shaped option values
- [ ] ❓ F86 - Use a portable, checked `mktemp` template

### G11 — Close test-post.sh's coverage gaps

🟠; one file, after G10 so the new cases cover the hardened script. F120 overlaps several cases below, and F48 corrects SKILL.md's claim about what the suite covers.

- [ ] ❓ F89 - Add Gate 2 cases
- [ ] ❓ F90 - Assert the exit status in `check`
- [ ] ❓ F91 - Add a successful post without `--post`
- [ ] ❓ F123 - Cover scrub-lib.sh's pattern set
- [ ] ❓ F124 - Cover multi-part posting
- [ ] ❓ F92 - Give refusal cases fresh inputs and assert the files survive
- [ ] ❓ F93 - Make the `gh` stub record its arguments and fail on demand
- [ ] ❓ F94 - Match the heading literally
- [ ] ❓ F95 - Run cases from a subdirectory
- [ ] ❓ F120 - Run scripts by path and add header.sh, placeholder, split and same-file cases
- [ ] ❓ F125 - Cover the `- [ ]` open-findings branch
- [ ] ❓ F126 - Cover the cleared file's gates and scrub.sh's argument
- [ ] ❓ F127 - Cover the argument and precondition refusals
- [ ] ❓ F128 - Cover the local-review and PLAN artifact names
- [ ] ❓ F48 - Correct SKILL.md's `scripts/` entry
- [ ] ❓ F129 - Add pass-through cases for the exemptions and bounds
- [ ] ❓ F131 - Assert scrub.sh's scanned-file list
- [ ] ❓ F132 - Host-qualify the test `--repo`
- [ ] ❓ F133 - Document `review()`'s side effects

### G1 — Settle the update-deps router stubs

Ruled 2026-10-24 (F115 (a), F116 (b), F119 (a)), so only the edits are left; 🟡 at most and five small edits to the update-deps router stubs.

- [ ] ❓ F115 - Where the `.tf` detection runs (ruled (a) — the Step 5 stub runs the detection command)
- [ ] ❓ F116 - Whether the Step 7 stub names pins.md's run-wide sections (ruled (b) — the stub names both sections)
- [ ] ❓ F119 - When changelogs.md is read (ruled (a) — before Step 3, beside version-locked.md)
- [ ] ❓ F67 - Hand the Step 10 sub-agent changelogs.md by its full path
- [ ] ❓ F114 - Align the Version-Locked Packages stub's read time with its first use

### G2 — Settle the scrub pattern terms

Ruled 2026-10-24 (F54 (a), F130 (a)), so only the edits are left; 🟡 at most, and after G11 so its new test-post.sh cases land in the restructured suite.

- [ ] ❓ F54 - Whether `.local` with a port alone blocks (ruled (a) — change the pattern, with a test-post.sh case)
- [ ] ❓ F130 - Whether to pin the backticked-file-name block (ruled (a) — pin it as accepted blocking)
- [ ] ❓ F78 - Add quote characters to the key-cell padding class in both copies
- [ ] ❓ F55 - Correct posting.md's sync comments on the ship-it pre-pass and the unsynced table term
- [ ] ❓ F103 - Define or replace the "reading pass" the key-cell paragraph relies on

### G12 — Make walkthrough-example.md stand alone

🟡 and, after G1 and G2, the smallest of the 🟡 groups; five edits to one new file and the SKILL.md sentence that points at it.

- [ ] ❓ F57 - Name the files in the keep-in-sync comment
- [ ] ❓ F58 - Name review-file.md beside Tracking Finding Status
- [ ] ❓ F21 - Say in SKILL.md that the example stops at the order proposal
- [ ] ❓ F22 - Move F5's Recommended line before its options
- [ ] ❓ F109 - State the starting state and SKILL.md's precedence in the introduction

### G13 — Qualify doc-review's cross-file references

🟡; the split left section names without their files in SKILL.md, reviewer-rules.md and review-file.md.

- [ ] ❓ F47 - Qualify SKILL.md's bare section references
- [ ] ❓ F52 - Point the "Not recommended" hint at Membership
- [ ] ❓ F16 - Add file hints in review-file.md
- [ ] ❓ F50 - Add file hints in reviewer-rules.md
- [ ] ❓ F138 - Update the Pre-Merge Checklist sync comment
- [ ] ❓ F101 - Fold the Reviewer Output intro into the opening paragraph

### G14 — Describe gather-state's output correctly in handoff

🟡; after G3, since F60 describes output F44 changes.

- [ ] ❓ F59 - Point the Header at the script's `base:` and `head` lines
- [ ] ❓ F60 - Describe the `gh` fallback lines and what `gh available` means
- [ ] ❓ F61 - Name the command behind each script part
- [ ] ❓ F110 - Cover the unchecked commit range and the comments part
- [ ] ❓ F111 - Recast the script's work as its design, with the `main` fallback
- [ ] ❓ F4 - Backtick the base name in the Header examples

### G15 — Let the update-deps topic files stand alone

🟡; titles, cross-file Step links and one opening paragraph, independent of G1's stubs.

- [ ] ❓ F40 - Retitle changelogs.md
- [ ] ❓ F38 - Retitle version-locked.md
- [ ] ❓ F41 - Link "Step 10" in changelogs.md
- [ ] ❓ F35 - Link "see Step 10" in linters.md
- [ ] ❓ F117 - Link "Step 6" in pins.md
- [ ] ❓ F118 - Spell out what Step 9 checks
- [ ] ❓ F31 - Name the pins in SKILL.md's opening paragraph

### G16 — Recast posting.md's leftovers from the inline blocks

🟡; posting.md prose that still describes the removed blocks, plus the two reviewer-rules.md passages that cite it.

- [ ] ❓ F17 - Recast the paragraphs that describe removed code
- [ ] ❓ F18 - Name the four artifact patterns
- [ ] ❓ F49 - Point reviewer-rules.md at the list in scrub-lib.sh
- [ ] ❓ F14 - Qualify "withheld from any published comment"
- [ ] ❓ F104 - Say where Gate 1, Gate 2 and the scrub-lib names come from
- [ ] ❓ F105 - Qualify "rewrite each hit" and label the two hit groups
- [ ] ❓ F106 - Define `--status` and fix the "all clear" example
- [ ] ❓ F107 - Print the list-file paths from `mktemp`
- [ ] ❓ F56 - Bring the refusal and splitting claims within what post.sh does

### G17 — Finish the command-to-skill terminology

🟡 and the largest group; one sweep across files that settles the word once (F150 records the skills' current split between "this command" for the invocation and "skill" for the files). F32 and F34 are the deferred update-deps instances.

- [ ] ❓ F5 - Add skills to "where agents read them"
- [ ] ❓ F13 - Replace "this command" with `/doc-review` in reviewer-rules.md
- [ ] ❓ F23 - Fix "this command file" in handoff
- [ ] ❓ F137 - Fix the single-command-file wording in review-file.md
- [ ] ❓ F6 - Call `/commit` and `/doc-review` skills in CLAUDE.md
- [ ] ❓ F9 - Write "project skill or command" in the commit skill and CLAUDE.md
- [ ] ❓ F12 - Make Who Does What's self-references agree
- [ ] ❓ F19 - Fix posting.md's "command file" wording
- [ ] ❓ F39 - Write "this run" in version-locked.md
- [ ] ❓ F136 - Write "these skill files" in ship-it
- [ ] ❓ F139 - Write "this skill" and "`/commit` skill" in update-deps

### G18 — Fix the commit skill's description

🟢 and one line; it decides when the skill is used.

- [ ] ❓ F134 - Rewrite the description without the serial comma

### G19 — Punctuate the scripts' comments

🟢 and mechanical; touches nothing another group edits.

- [ ] ❓ F135 - Fix the comment punctuation in scrub-lib.sh, post.sh and test-post.sh

### Not recommended for this revision

- [ ] ❓ F3 - Restore "body's" to its line (Skip — changes nothing a reader sees)
- [ ] ❓ F7 - Extend the heredoc ground rule to the squash todo list (Defer — predates the branch)
- [ ] ❓ F8 - Guard the older-Git fallback rebase (Defer — body changed only by line breaks)
- [ ] ❓ F20 - Give the real reason an observation row is moved (Defer — pre-existing; costs only an extra move)
- [ ] ❓ F26 - Add the public-repository Linear URL rule to the handoff (Defer — pre-existing with a `/ship-it` backstop)
- [ ] ❓ F27 - Make the handoff's plan statements conditional (Defer — pre-existing and outside the conversion)
- [ ] ❓ F30 - Document `REMOTE` fully in resume-handoff (Defer — only matters in multi-remote clones)
- [ ] ❓ F32 - Write "this run" in javascript.md (Defer — one pass over the update-deps files)
- [ ] ❓ F33 - Qualify the hardcoded platform list (Defer — pre-existing; a content pass on Terraform)
- [ ] ❓ F34 - Replace "this command" in terraform.md (Defer — one sweep across the update-deps files)
- [ ] ❓ F36 - Reword "Never skip linter checks" (Defer — pre-existing; fix belongs in SKILL.md)
- [ ] ❓ F37 - Move the Rails check before the restore call (Defer — verbatim move)
- [ ] ❓ F42 - Recase the changelogs.md H3 headings (Defer — later style pass)
- [ ] ❓ F46 - Guard both autosquash routes against a dirty tree (Defer — pre-existing; follow-up)
- [ ] ❓ F68 - Write the age gate in minutes across three files (Defer — behavior change across three files; schedule soon)
- [ ] ❓ F69 - Gate a range hold's repair (Defer — pair with F68)
- [ ] ❓ F70 - Use `yarn playwright --version` (Defer — check against a Plug'n'Play repository first)
- [ ] ❓ F77 - Track fences in post.sh's awk programs (Defer — pair with F74's follow-up)
- [ ] ❓ F79 - Warn on mentions and cross-references in Gate 2 (Defer — design separately)
- [ ] ❓ F87 - Track fences in check-loss.sh's `section()` (Defer — inherited and rare)
- [ ] ❓ F96 - Name plans and handoffs in the Confirmations list (Defer — the body states the rule)
- [ ] ❓ F97 - Delete "For this codebase" (Defer — fits the description-trim follow-up)
- [ ] ❓ F108 - Cut the decision history from posting.md (Defer — a pass over the whole section)
