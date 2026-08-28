# Document Review: worktree isolation guidance (four repos)

| | |
|---|---|
| **Scope** | dotfiles `isolate-review-agents-in-worktrees` @ `7ef4981`; alice `isolate-review-agents-in-worktrees` @ `30170c4cf`; KleinsShopRite `local-review-command` @ `9387541`; ORE `isolate-review-agents-in-worktrees` @ `4f60233` |
| **Reviewed** | 2026-08-04 |
| **Reviewers** | 4 × documentation-expert, Opus 5 (`claude-opus-5[1m]`), each in an isolated worktree |
| **Findings** | 72 total — 6 Critical, 12 High, 16 Medium, 13 Low, 25 observations |

## Review History

### 2026-08-04 — Initial review

Four documentation-expert agents reviewed one repo each. Findings prefixed D (dotfiles),
A (alice), K (KleinsShopRite), O (ORE). The orchestrator independently re-verified every
Critical finding against primary sources before recording it.

## Orchestrator Verification

Six claims were re-checked directly rather than taken on the reviewers' word. All six held.

| Claim | Source of truth | Verdict |
|---|---|---|
| `worktree.baseRef: head` is not in effect (A3, K2, O2) | `~/.claude/settings.json` is a **regular file** dated Jul 29 with no `worktree` key; `~/.claude/{CLAUDE.md,agents,commands}` are symlinks to the repo but `settings.json` is not | ✅ Confirmed |
| Reviewer worktrees were cut from `origin/main` | A reviewer's worktree was at `ea4cbda` = `origin/main`, while branch HEAD was `7ef4981` | ✅ Confirmed empirically |
| `bin/rails db:drop` drops the development database (A1, K1) | `activerecord-8.1.3.1` `databases.rake:63` — "Without RAILS_ENV or when RAILS_ENV is development, it defaults to dropping the development and test databases" | ✅ Confirmed |
| KSR's own linter rejects the new section (K9) | `bin/lint-markdown .claude/commands/local-review.md` → **21 MD013 errors**, exit 2; `.markdown-lint.yml` is `default: true`, so MD013 = 80 | ✅ Confirmed |
| A worktree checks out an empty submodule (O1) | Sandbox `git init` superproject + submodule: main checkout `ore/` populated, linked worktree `ore/` **empty** | ✅ Confirmed |
| Shell state does not persist between an agent's Bash calls (A2, K3) | Harness contract: "Working directory persists between calls… Shell state (env vars, functions) does not persist" | ✅ Confirmed |

### Correction to an earlier claim

Both PR test plans state "markdownlint clean on every changed file." **That verification was
invalid.** It ran alice's `bin/lint-markdown` against files in other repos; that script computes
the path relative to alice's root and `exit 0`s when it does not match
`^\.claude/(commands|agents)/.+\.md$`. Every out-of-repo file was silently skipped, not linted.

Re-checked with each repo's own configuration:

- **alice** — genuinely linted and clean (no repo config; `bin/mdl` with no `.mdlrc`)
- **ORE** — `.markdownlint.yml` sets `MD013: line_length: 100`; all added lines ≤ 99 ✅
- **KleinsShopRite** — `.markdown-lint.yml` is `default: true` → MD013 = 80 → **21 errors** ❌
- **dotfiles** — no linter; the 100-character preference applies and is met

`D14` (four lines at 101 characters) is a **false positive**: the reviewer counted bytes, and em
dashes are 3 bytes each. No line exceeds 100 *characters*; the longest is exactly 100.

## Critical Findings

### F-C1 🔴 The `worktree.baseRef` setting was never deployed — every claim resting on it is false

**Found independently by three reviewers (A3, K2, O2).** `~/.claude/settings.json` is a real file,
not a symlink into the dotfiles castle, so editing `home/.claude/settings.json` changed nothing.
Reviewer worktrees are therefore cut from the default branch and contain **none of the change set**
— not merely the uncommitted part the docs warn about. A reviewer would confidently review code
that does not include the change under review, and nothing in its output would reveal it.

The live and repo copies have also drifted in both directions, so symlinking is not a no-op:

```text
repo only:   "worktree": {"baseRef": "head"}
repo=true / live=false:   enabledPlugins["learning-output-style@claude-code-plugins"]
live only:   "skillOverrides": {"rails-audit-thoughtbot": "off"}
```

**Recommendation: Implement** — the feature does not work at all until this is resolved, and the
documentation asserts it does.

### F-C2 🔴 `bin/rails db:drop` destroys the shared development database (A1, K1)

Prescribed as the cleanup step in both alice and KleinsShopRite. With `RAILS_ENV` unset it drops
development *and* test. Since one PostgreSQL server serves every worktree — the section's own
premise — this destroys `alice_development` for all nine checkouts. Fix: `RAILS_ENV=test bin/rails
db:drop`, or `dropdb "$TEST_DATABASE"`.

**Recommendation: Implement** — a documented command that causes data loss.

### F-C3 🔴 The `export`ed variables never reach the command that runs the specs (A2, K3)

Shell state does not survive between an agent's Bash calls. The snippet exports `TEST_DATABASE`
and `CHEWY_PREFIX`, then the reviewer runs `bin/rspec` in a *later* call where both are gone — so
every reviewer converges on the shared `alice_test` and truncates the others mid-run. Silently.
This is the exact failure the section exists to prevent. Fix: write them to `.env.test.local`
inside the worktree (dotenv loads it first in the test environment, and it is gitignored), or
prefix every command individually.

**Recommendation: Implement** — the recipe cannot work as written.

### F-C4 🔴 ORE reviewer worktrees have an empty `ore/` submodule (O1)

`git worktree add` does not populate submodules, and `git submodule update --init` re-clones rather
than reusing the superproject's objects. Four of five ORE agents are pointed at paths under `ore/`,
and a submodule-bump branch — routine here — would present as an empty change set. Verified in a
sandbox.

**Recommendation: Implement** — the isolation change silently reduces ORE review coverage to the
non-submodule tree.

### F-C5 🔴 The Chewy prefix nests under the default, so a normal spec run deletes it (A4)

`CHEWY_PREFIX="test_${SUFFIX}"` yields `alice_test_<suffix>_*`. `Chewy.massacre` — run before every
`:elasticsearch` example via `spec/support/reset.rb` — deletes `alice_test_*`, which matches. The
namespacing is one-way and "Nothing else can hold those names" is false. Fix: a sibling namespace,
`CHEWY_PREFIX="agent_${SUFFIX}"`.

**Recommendation: Implement** — a one-word change closes a collision the section promises to close.

### F-C6 🔴 KleinsShopRite's new section breaks the repo's own lint gate (K9)

21 MD013 errors at 80 characters, in a file that passed clean before the commit. `bin/lint-markdown`
exits 2 and is wired to a `PostToolUse` hook for `**/*.md`, so the file now blocks its own future
edits. The global 100-character preference explicitly defers to a project's own linter.

**Recommendation: Implement** — mechanical, and it currently breaks tooling.

## High-Priority Findings

| # | Repo | Finding | Recommendation |
|---|---|---|---|
| D6 / A13 | dotfiles, alice | "the only file it should write is the review" contradicts the same file's Interactive Finding Selection step and the PR-comment step | Implement |
| D7 | dotfiles | `doc-review.md` prescribes `EnterWorktree` unconditionally; it errors when the agent is already isolated. The agent files get this right — `doc-review.md` diverges from its own agent | Implement |
| D10 | dotfiles | An isolated agent's Bash is confined to its worktree — `git -C <main checkout>` is refused outright, as are compound commands. Unstated, and every spawned agent hits it | Implement |
| K7 / O8 | KSR, ORE | "Return the checkout clean" contradicts the run's own output file, and the collating documentation-expert is not excluded from isolation — isolating it writes `local-review.md` into a worktree that is then swept, losing the review with no error | Implement |
| A5 | alice | `.worktreeinclude`'s comment argues against copying `.env.development.local`, then copies it | Implement |
| A6 | alice | The resource-claiming recipe is written to the reviewer but sits outside the "relay these constraints" list, so it never reaches them | Implement |
| A7 | alice | A fresh worktree has no built assets (`app/assets/builds/*` gitignored); any spec rendering the layout fails | Implement |
| O2 | ORE | Same as F-C1, stated locally: the `baseRef` dependency is unstated and machine-specific | Implement |
| O3 | ORE | The no-build / no-`ctest` rule sits outside the relayed bullets and switches person, so an orchestrator relays three bullets and drops it | Implement |
| O4 | ORE | `git diff HEAD` renders submodule changes as a gitlink only — uncommitted `ore/` work is invisible. Use `--submodule=diff` | Implement |
| K3 | KSR | Same as F-C3 | Implement |

## Medium and Low Findings

Recorded in full from each reviewer; abbreviated here.

**dotfiles** — D1 "gets swept" overstates (the sweep skips worktrees holding work); D2 permission
approvals write to the main checkout and are missing from the shared-state list; D3 `git worktree
prune` is a no-op after `remove`; D8 "advise — do not fix" needs an "unless asked" carve-out;
D9 five different names for the main checkout; D11 "page ranges" assumes PDFs; D17 the `wtlist`
comment describes a narrower filter than the code (`.claude/worktrees/` also matches named
`--worktree` sessions). D12, D15 recommended **Skip**.

**alice** — A8 index cleanup has no command; A9 the port probe has no stated use case and Capybara
self-assigns; A10 the `3000 + position` formula is wrong for the main checkout; A11 the suffix is
not lowercased and Elasticsearch rejects uppercase index names; A14 the agents directory is now
half-converted to real headings (**Defer**). A12, A15 recommended **Skip**.

**KleinsShopRite** — K4 the database name is 57/63 bytes — no truncation today, but `${PWD##*/}`
breaks if the reviewer has `cd`'d into a subdirectory; K5 the port probe computes a value nothing
uses; K6 `git diff HEAD` omits untracked files; K8 system specs need `yarn install` in the
worktree; K10–K12 punctuation and phrasing.

**ORE** — O6 "changing code to verify is expected" is withdrawn two paragraphs later by the build
ban; O7 "unverified" has no slot in the finding format; O9 `.markdownlintignore` was not updated
alongside `.gitignore`; O10 "clean" should be "unchanged". O11 **Defer**; O12, O13 **Skip**.

## Observations Worth Acting On

- **A21 / K13** — `config/credentials/*.key` copies production (and staging) keys into every
  throwaway worktree. Only `config/master.key` is needed to boot. Narrowing the pattern costs
  nothing.
- **A21 footnote, out of scope** — `.yarnrc.yml` is tracked in alice and contains a live Font
  Awesome Pro `npmAuthToken`. Pre-existing and possibly intentional for a private registry, but
  flagged since a secrets sweep was in the brief.
- **O5** — the `memory: project` → Edit/Write claim is correct, with the caveat that it has no
  effect when auto memory is disabled.
- **D16 / A19 / O15–O17** — the mechanical rollout is clean: the conduct section is byte-identical
  across all 15 editing agents, correctly placed, and every agent that is told to call
  `EnterWorktree` actually has it.

## Overall Assessment

The prose is strong — mechanism-first, well-voiced, and every cross-reference resolves. The problem
is underneath it: the executable core was never run end to end. Four independent defects (F-C1
through F-C3, plus F-C5) each cause precisely the damage the guidance promises to prevent, and each
fails silently. The agent-file changes, the heading conversion, and the `.gitignore` work are sound
and need not hold up the branches.

The single most important item is F-C1. Until `~/.claude/settings.json` actually carries
`worktree.baseRef: head`, worktree-isolated reviewers review the wrong tree — which also means the
four reviews above were only valid because each agent was handed absolute paths into the main
checkout rather than relying on its worktree.

## Checklist

- [ ] F-C1 — Deploy `worktree.baseRef: head` and reconcile the drifted settings file
- [ ] F-C2 — `RAILS_ENV=test bin/rails db:drop` in alice and KSR
- [ ] F-C3 — Stop relying on `export`; persist via `.env.test.local` or per-command prefixes
- [ ] F-C4 — Document the empty `ore/` submodule and how reviewers should read it
- [ ] F-C5 — Switch alice's Chewy prefix to a sibling namespace
- [ ] F-C6 — Rewrap KSR's section at 80 characters until `bin/lint-markdown` exits 0
- [ ] D6 / A13 — Scope "do not edit" to the review phase
- [ ] D7 — Make the `EnterWorktree` instruction conditional
- [ ] D10 — Document that an isolated agent's shell cannot reach the main checkout
- [ ] K7 / O8 — Exempt the review output file; state the collator is not isolated
- [ ] A5, A6, A7 — Settle the `.worktreeinclude` contradiction; relay the recipe; add built assets
- [ ] O2, O3, O4 — State the `baseRef` dependency; relay the no-build rule; `--submodule=diff`
- [ ] Medium/Low sweep — D1, D2, D3, D8, D9, D11, D17, A8–A11, K4–K6, K8, K10–K12, O6, O7, O9, O10
