# Handoff: Trim Claude Code agent descriptions without losing routing

| | |
|---|---|
| **Status** | In progress |
| **Created** | 2026-10-24 |
| **Updated** | 2026-10-24 |
| **Branch** | `trim-agent-descriptions` (base: `main`) |
| **Commit** | `24d3ffd` at capture |
| **Pull request** | https://github.com/mattmenefee/dotfiles/pull/148 |
| **Issues** | none |
| **Captured by** | Opus 5.5 (`claude-opus-5-5`) |

## Start Here

This branch trims the `description:` frontmatter of the seven agents in `home/.claude/agents/` from long paragraphs with `<example>` dialogues to short routing summaries. A `/doc-review` found the first trim had dropped routing triggers and misaligned the agents' handoffs to each other; all 21 actionable fixes were made and amended into the single commit `24d3ffd`, which is **not pushed yet** (the remote still has `89872d4`). The first action is to force-push with a lease, then rewrite the PR #148 body, which still describes the pre-review commit. Run `/resume-handoff trim-agent-descriptions-HANDOFF.md` before trusting anything below.

## Objective

Keep every agent's description short (they load into every Claude Code session) while losing none of the routing signal the old examples carried. The user asked: "run /doc-review and confirm that nothing is being lost or made worse by the changes on this branch". Done when the descriptions are short, every trigger the old text carried and the body supports is still named, every "use X instead" boundary agrees with its neighbor's claim, and PR #148 accurately describes the change.

## Scope

- In: the seven files under `home/.claude/agents/` — their `description:` values, plus the few body lines that contradicted a new boundary or an advertised capability
- Out: the agents' bodies beyond those lines; the three 💡 observations from the review (F24 release notes and architecture docs in documentation-expert, F25 multi-database in ruby-on-rails-expert, F26 a complementary code-reviewer clause in ui-ux-design-specialist), left optional
- Out: two pre-existing lines over 100 columns, `home/.claude/agents/documentation-expert.md:89` and `home/.claude/agents/security-reviewer.md:186`, not introduced by this branch

## Completed Work

1. `/doc-review` over the seven files (base `d22496a`): seven reviewers, one collator, 26 findings (23 actionable, two ⚖️ Decisions, 3 💡). Verified by reading the review file back.
1. Walkthrough rulings by the user: F1 (b), F8 (b), F13 Ignore, F18 Implement, F20 Implement, F23 Ignore, F12 wording "inline code documentation".
1. All nine implementation groups edited — written and checked (YAML parse and width check below); routing behavior itself not exercised:
   - `home/.claude/agents/code-best-practices-reviewer.md` — first-pass security check named, "also run security-reviewer", open-pull-request and improve-existing-code triggers, "to write, fix or review tests on their own use test-suite-architect", `e.g.,` → `e.g.` in the body
   - `home/.claude/agents/postgresql-expert.md` — JSONB (modeling, querying and indexing), upgrades, a production-administration sentence; body bullets narrowed to the database side of Active Record/N+1, multi-tenancy bullet added to Schema Design
   - `home/.claude/agents/ruby-on-rails-expert.md` — application performance, Kamal deployment and production debugging, "whenever the deliverable is tests use test-suite-architect"; Primary Responsibility 3 now "Keep suggested changes testable and name the specs they need"
   - `home/.claude/agents/test-suite-architect.md` — "in any language or framework", "end-to-end tests", serial comma removed, prefers itself over code-best-practices-reviewer for test reviews
   - `home/.claude/agents/security-reviewer.md` — SSRF, dependencies, outbound requests, security configuration, broader injection
   - `home/.claude/agents/ui-ux-design-specialist.md` — information architecture; "building" → "designing"
   - `home/.claude/agents/documentation-expert.md` — inline code documentation, technical specifications, serial comma removed
1. Amended into the branch's one commit, `89872d4` → `24d3ffd`, with the message rewritten to describe the full change.

## Current State

From `gather-state.sh` (`git status --short --branch`, `gh pr view --json …`), 2026-10-24:

- Branch `trim-agent-descriptions` is ahead 1, behind 1 of `origin/trim-agent-descriptions`: local `24d3ffd` replaces the pushed `89872d4` (an amend, not new work). Needs `--force-with-lease`.
- Working tree clean apart from two untracked working files: `trim-agent-descriptions-DOC-REVIEW.md` and this handoff. Neither is to be committed.
- PR #148 is open, not a draft, no reviews or comments. CI (Dotfiles CI lint, Super-Linter checks incl. MARKDOWN and YAML) passed on `89872d4`, not yet run on `24d3ffd`.
- **PR #148's body is stale.** It says only descriptions change and "every agent body is untouched" (false now), "~12.5k to ~2.4k characters" (now ~3.0k), "security audits go to `security-reviewer`" (now the code reviewer also does a first pass and says to also run security-reviewer), and its Test plan ticks "Diff against `main` confirms only description lines changed" (false now).
- The castle checkout `~/.homesick/repos/dotfiles` is on another branch, `convert-commands-to-skills` (`git worktree list`). Agent files under `~/.claude/agents/` therefore reflect that branch, not this one.

## Key Files & Entry Points

- `home/.claude/agents/*.md` lines 1–10 — the seven `description:` blocks; the whole change lives there plus the body lines named in Completed Work
- `trim-agent-descriptions-DOC-REVIEW.md` — branch-local and untracked; `/ship-it` would post and delete it. Every actionable finding in it is ✅ or 🚫 and it passes the post gate (no ❓ row, no open box). Its substance is carried in this file.

## Decisions & Rationale

- **F1 (user):** code-best-practices-reviewer names a first-pass security check and says "for a dedicated vulnerability audit also run security-reviewer", rather than an either-or. The old description sent an auth module to this agent for design review; "also" keeps both reviews.
- **F8 (user):** reword only ruby-on-rails-expert's responsibility 3 and keep its Testing Excellence section, which the agent uses when writing Rails code with specs.
- **F13 and F23 ignored (user):** "reviews and improves documentation" already routes consistency work; "TDD" is understood and routing favors brevity.
- **F18 and F20 implemented (user)** despite Skip/Defer recommendations: one-word swap; the `e.g.,` fix rides along because G1 already edits that file.
- **F12 (user):** "inline code documentation", the old phrase, over "code comments and docstrings".
- **F4 wording (agent):** "JSONB (modeling, querying and indexing)" in parentheses so the comma list carries no nested "and".
- **F14 wording (agent):** the suggestion's second form, a separate "Also covers production administration: …" sentence, to avoid a serial comma.
- **Amend rather than a new commit (user):** `/commit amend into 89872d4`.
- **Size figure (agent):** the commit message says the descriptions shrink "to about a quarter of their former size" — measured 12,475 → 3,010 characters with `YAML.safe_load` over `d22496a` and the working tree. The old "roughly 2.5k fewer tokens" was dropped as unmeasured.

## Insights & Learnings

- Removing `<example>` blocks is not loss-free: the examples carried trigger situations ("my index action is slow", "I finished the auth module"), and once they are gone a neighbor's more specific wording ("slow queries") wins the router's match.
- Each "use X instead" sentence creates a pairing that must agree with X's own claim. Three mismatches surfaced: test reviews (code-best-practices-reviewer vs test-suite-architect), JSONB (ruby-on-rails-expert hands off all of it, postgresql-expert claimed only trade-offs) and test scope ("test suites" vs "whenever the deliverable is tests").
- A description that advertises a capability needs the body to back it: postgresql-expert's "multi-tenancy" had no body coverage until a Schema Design bullet was added.
- The router reads only descriptions, so a body/description contradiction (postgresql-expert's Active Record bullets) does not misroute; it confuses the next editor and the dispatched agent.
- `/doc-review` loaded from `~/.claude/skills/doc-review/` because the castle checkout is on `convert-commands-to-skills`; this branch's base still has `home/.claude/commands/doc-review.md`.

## Dead Ends

- None that closed a door. One edit to `ui-ux-design-specialist.md` matched on a substring and left a stray line break inside "Reviews the rendered page"; it was reflowed and re-checked.

## Open Questions

- **Non-blocking:** whether to act on the three 💡 observations (F24, F25, F26). Assumed no; they are optional and outside the routing losses.

## Next Steps

- [ ] 1. Force-push the amended commit: `git push --force-with-lease --force-if-includes` from the checkout on `trim-agent-descriptions` (needs the user's go-ahead)
- [ ] 2. Rewrite the PR #148 body to describe `24d3ffd`: body lines changed in postgresql-expert, ruby-on-rails-expert and code-best-practices-reviewer; ~12.5k → ~3.0k characters; the "also run security-reviewer" boundary; replace the stale test-plan item "only description lines changed" (needs the user's approval before editing the PR)
- [ ] 3. Confirm CI on the new head with `gh pr view 148 --repo mattmenefee/dotfiles --json headRefOid,statusCheckRollup` and check `git ls-remote origin refs/heads/trim-agent-descriptions` equals local `HEAD`
- [ ] 4. Leave PR #148 at "ready to merge"; the user merges it (the repository uses rebase and merge)

## Verification

- All seven frontmatter blocks parse with `YAML.safe_load` and yield a string `description` — run 2026-10-24 on the working tree that became `24d3ffd`
- Every line added by this branch is ≤ 100 columns (`git diff -U0 | grep '^+'` width check) — 2026-10-24
- Review file post gate: no `| F… | … | ❓ |` row and no `- [ ]` item (`grep` exit 1 for both) — 2026-10-24
- markdownlint — not run: no `markdownlint` or `markdownlint-cli2` installed locally; CI's MARKDOWN lint passed on `89872d4` only
- Routing behavior (does delegation land on the expected agent) — not exercised; PR #148's unticked test-plan item covers it after merge

## References

- PR #148 — https://github.com/mattmenefee/dotfiles/pull/148 — this branch; body stale as described above
- `d22496a` — base of the branch; holds the original long descriptions for comparison (`git show d22496a:home/.claude/agents/<file>`)
- `89872d4` — the pre-review commit still on the remote
- `24d3ffd` — the amended commit at capture

## Resume Prompt

```text
Run /resume-handoff trim-agent-descriptions-HANDOFF.md and show me what drifted. When I say go, start with item 1 of its "Next Steps" (force-push with a lease) and confirm before pushing or editing PR #148.
```

## Handoff History

- **2026-10-24** — Initial handoff: /doc-review run, all 21 actionable fixes made and amended into `24d3ffd`; push and PR body rewrite outstanding. Captured by Opus 5.5 (`claude-opus-5-5`)
