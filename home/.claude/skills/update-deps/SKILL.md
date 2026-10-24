---
name: update-deps
description: >-
  Update an app's Ruby, JavaScript and Terraform dependencies and its tool and image pins, build a
  commit message from changelogs and open a pull request.
disable-model-invocation: true
---

# Update Dependencies

Update the app's Ruby, JavaScript and Terraform dependencies, build a detailed commit message from
changelogs and open a pull request.

## Overview

This command automates the full dependency update workflow:

1. Determine the branch name and PR title
2. Create a feature branch from `main`, or from a Rails upgrade in flight
3. Update Ruby dependencies using `gem_update`, then Bundler and any Git-sourced gems
4. Update JavaScript dependencies using `yarn up`, then re-resolve every transitive dependency with
   `yarn up -R`
5. Decide Terraform provider and module version bumps, if the repo uses Terraform
6. Re-resolve and verify the Terraform lock files
7. Update tool and image pins that live outside the package manifests
8. Handle RuboCop version bumps
9. Handle haml-lint version bumps
10. Build the final commit message with anchored changelog links
11. Commit, push and open a PR

## Process

### Step 1: Determine the Branch Name and PR Title

Count this month's earlier runs from history, which survives a branch deleted on merge:

```bash
git fetch origin main
git log origin/main --format='%h  %ad  %s' --date=short --no-merges \
  --since="$(date +%Y-%m-01) 00:00" -i --grep="update the app's dependencies"
```

Each subject it prints is one earlier run this month. The explicit `00:00` matters: Git fills a
date-only `--since` with the current time of day, which drops every run committed earlier on the
1st. `-i` also catches a run whose subject begins
`Upgrade Rails to … and update the app's dependencies` (see [Step
11](#step-11-commit-push-and-create-the-pr)). Then list this month's run branches on the remote
itself, since local remote-tracking refs can be stale:

```bash
git ls-remote --heads origin "update-dependencies-*$(date +%B-%Y | tr '[:upper:]' '[:lower:]')"
```

Count a listed branch as an open run only when `git merge-base --is-ancestor <its-sha> origin/main`
exits 1. Exit 0 means it is already merged and counted above, as it is in a repository that keeps
branches after merging; exit 128 means the commit is not local yet, so `git fetch origin <branch>`
and check again.

Counting branches alone undercounts: a repository that deletes branches on merge keeps only the runs
still open, so after a merged run the check reports "first of the month" and the new run reuses its
branch name and commit subject. Add the two counts and take the qualifier for the next run.

**Naming rules:**

- **First update of the month** — no prefix, just the month: `update-dependencies-march-2026`
- **Subsequent updates** — add a time-period qualifier: `early`, `mid`, `late`, `end-of` or devise
  another qualifier as needed to avoid collisions (e.g. `update-dependencies-mid-late-march-2026`)

- **Branch**: `update-dependencies-{qualifier-}{month}-{year}` (all lowercase, hyphenated)
- **Title**: `Update the app's dependencies - {qualifier }{Month} {Year}`

Examples:

| Scenario | Branch | Title |
| ---------- | -------- | ------- |
| First of the month | `update-dependencies-{month}-{year}` | `Update the app's dependencies - {Month} {Year}` |
| Second update | `update-dependencies-early-{month}-{year}` | `Update the app's dependencies - early {Month} {Year}` |
| Third update | `update-dependencies-mid-{month}-{year}` | `Update the app's dependencies - mid {Month} {Year}` |
| Fourth update | `update-dependencies-late-{month}-{year}` | `Update the app's dependencies - late {Month} {Year}` |
| Close together | `update-dependencies-end-of-{month}-{year}` | `Update the app's dependencies - end of {Month} {Year}` |

### Step 2: Create the Feature Branch

First check whether a Rails upgrade is in flight — an open pull request or a local branch preparing
one:

```bash
gh pr list --state open --search 'Rails in:title' --json number,title,headRefName
git branch --list '*rails*'
```

If one is, ask the user whether this run should ship with it. When they agree, the upgrade ships in
the dependency PR **ahead of the dependency commit**, on a branch made from the upgrade's own:

```bash
git fetch origin <upgrade-branch>
git checkout -b <branch-name> origin/<upgrade-branch>
```

Keep every commit the upgrade branch carries, in order, and leave them as they are. If it is behind
`main`, ask the user before rebasing it, since a stale base means the run resolves against an old
tree. The `@rails/*` npm bumps belong in the upgrade commit rather than this one; if it lacks them,
stop and ask the user whether to amend it (see [Version-Locked
Packages](version-locked.md#version-locked-packages)). Tell the user the upgrade's own pull request
should be closed in favor of this one once it is open, and say so in this PR's body, so the same
commits cannot merge twice. Otherwise start from an up-to-date `main`:

```bash
git checkout main && git pull
git checkout -b <branch-name>
```

### Step 3: Update Ruby Dependencies

Run `gem_update` to update all Ruby gems and get an initial draft of the dependency changes:

```bash
out="$(mktemp -t gem-update)" && echo "$out" && gem_update 2>&1 | tee "$out"
```

The first line printed is the private file the output is saved to; a later command reads it by that
path, since a variable does not outlive its shell. A fixed path under `/tmp` would follow a stale or
planted symlink and collide with a concurrent run. The pipeline's status is `tee`'s, so read
`gem_update`'s own: `${pipestatus[1]}` in zsh, `${PIPESTATUS[0]}` in bash, not `$?`. A non-zero
value means `gem_update` failed.

`gem_update` is the CLI provided by the `gem_updater` gem (installed via `gem install gem_updater`)
that runs `bundle update` internally and outputs a formatted changelog with version diffs and
changelog links. Capture this output — it will be the starting point for the commit message body. If
`gem_update` is not available, run `bundle update` directly and manually build the changelog from
the `Gemfile.lock` diff.

A successful run prints a list of gem updates with version diffs. If no gems were updated, the
output will indicate that the bundle is already up to date.

`gem_update` lists only gems whose version number moved, which misses two kinds of Ruby change.

#### Update Bundler

`bundle update` moves gems but never the lock file's `BUNDLED WITH` line, so Bundler stays wherever
it was. Production installs whichever Bundler that line names, so update it explicitly:

```bash
bundle update --bundler
git diff Gemfile.lock | grep -E -A2 'BUNDLED WITH'
```

If the line moved, add a `bundler <old> → <new>` entry to the commit message, alphabetized with the
others, and mention it in the PR summary. If it did not, Bundler is already current. See [Known
Changelog Quirks](changelogs.md#known-changelog-quirks) for where its release notes live.

#### Check Git-Sourced Gems

A gem pinned to a Git branch (`gem 'name', github: 'owner/repo', branch: 'main'`) follows the branch
head. It moves as a `revision:` change in the lock file's `GIT` block while its version number stays
put, so `gem_update` lists nothing:

```bash
git diff -U4 Gemfile.lock | grep -E '^[ +-] +(remote|revision):'
```

For each `revision:` that moved, read what changed between the two commits — the `lib/` files and
any changelog — with `gh api repos/<owner>/<repo>/compare/<old>...<new>`, and give it its own
commit-message entry. There is no changelog anchor to cite, so link the comparison:

```text
* name <old-sha> → <new-sha>
[compare](https://github.com/<owner>/<repo>/compare/<old-sha>...<new-sha>)
```

### Step 4: Update JavaScript Dependencies

Skip this step if the repository has no `yarn.lock`. Otherwise read
`${CLAUDE_SKILL_DIR}/javascript.md` in full and follow it.

### Step 5: Decide Terraform Version Bumps

Skip this step and Step 6 if the repository has no `.tf` files. Otherwise read
`${CLAUDE_SKILL_DIR}/terraform.md` in full and follow both steps there. It also holds the notes on
why their commands are shaped as they are.

### Step 6: Re-resolve and Verify Terraform Lock Files

In `terraform.md`, after Step 5.

### Step 7: Update Tool and Image Pins

Read `${CLAUDE_SKILL_DIR}/pins.md` in full and follow it.

### Step 8: Handle RuboCop Updates

Check the `gem_update` output or `git diff Gemfile.lock` for changes to `rubocop` or any `rubocop-*`
gem. If any changed, read `${CLAUDE_SKILL_DIR}/linters.md` and follow its Step 8.

### Step 9: Handle haml-lint Updates

Check the output or diff for changes to the `haml_lint` gem (CLI: `haml-lint`). If it changed, read
`${CLAUDE_SKILL_DIR}/linters.md` and follow its Step 9.

### Step 10: Build the Final Commit Message

#### Read the Changelogs for Behavior Changes

A minor or patch release can change behavior that matters, so do not reserve release-note scrutiny
for majors. Before building the message, read the changelog of every **direct** dependency that
changed — gems, npm packages, Bundler, Git-sourced gems and tool pins — for entries marked
`WARNING`, `BREAKING`, `security` or `deprecat`. For any flagged entry in an authorization,
authentication, sanitization or serialization library, find where the app uses the behavior it
describes and decide whether the app is affected. Run the specs that cover that usage, not only the
linters. Each conclusion goes into the commit body, and each check you ran is a verification result
for the sub-agent below.

#### Draft the Message

Launch a **documentation-expert** sub-agent (using the Agent tool) to refine the commit message.
Give it:

- The `gem_update` output from Step 3, with the Bundler and Git-sourced gem entries, any JavaScript
  dependency changes from Step 4 and any tool and image pin bumps from Step 7
- The conventions below, and the whole [Known Changelog
  Quirks](changelogs.md#known-changelog-quirks) section, so it does not rediscover a known quirk
- **Every verification result from this run** — specs run, plans run and their summary lines, usage
  audits and their conclusions — and the instruction that every behavioral claim in its prose must
  either cite one of these results or be phrased as what the changelog says. Without them it writes
  from the changelogs alone and can state as fact what this session has already shown to be false
- If Terraform changed, the evidence Steps 5 and 6 collected:
  - Each lock file's version changes against the Step 5 baseline, including transitive providers
    that no `required_providers` block names
  - The `Downloading <source> <version> for <name>` lines captured from `init -upgrade` in Step 6,
    the only record of a module bump
  - Each Git module's resolved commit SHA from Step 5

When the draft comes back, check each claim in its prose against those results before Step 11, and
correct any it cannot support.

The agent should:

1. Start with the `gem_update` output as the base for Ruby dependencies.

2. **Fill in missing changelog links** — for any dependency where `gem_update` did not find a
   changelog URL, look it up:
   - Check the gem's metadata (`gem specification <name>`) for `changelog_uri`, `source_code_uri` or
     homepage
   - For npm packages, check the package's repository URL on the npm registry
   - For Terraform providers and registry modules, the registry API's `source` field names the
     repository (`curl -fsS "https://registry.terraform.io/v1/providers/$ns/$name" | jq -r .source`,
     or `/v1/modules/$ns/$name/$provider` for a module); use its releases page or changelog file. A
     Git module's changelog lives in the repository its `source` points at
   - A Git-sourced gem keeps the `[compare]` link from Step 3 in place of a changelog
   - A tool or image pin from Step 7 links its upstream release page, minding the traps in [Known
     Changelog Quirks](changelogs.md#known-changelog-quirks)

   **Prefer GitHub releases** if the repo uses them (link to the specific release tag page).
   Otherwise, fall back to whichever changelog or history document the repo uses. Common file names
   (in various casing and extensions):
   - `CHANGELOG`, `CHANGES`, `HISTORY`, `NEWS`
   - Extensions: `.md`, `.txt`, `.textile`, `.rdoc` or no extension

   **Diffend fallback for Ruby gems** — if a gem has no changelog, no GitHub releases with
   meaningful notes and no history file, use [Diffend](https://my.diffend.io) as a last resort.
   Diffend shows a file-level diff between gem versions. Link format:
   `https://my.diffend.io/gems/<gem-name>/<old-version>/<new-version>`. Diffend only works for
   RubyGems — do not use it for npm packages.

3. **Add anchor tags to changelog links** — if a changelog link points to a file but lacks an anchor
   tag for the specific version, follow the link and find the correct heading anchor. For example,
   change `[changelog](https://github.com/org/repo/blob/main/CHANGELOG.md)` to
   `[changelog](https://github.com/org/repo/blob/main/CHANGELOG.md#version-heading-slug)`. The
   anchor is derived from the actual heading text in the changelog — inspect the rendered page or
   heading source to find the correct slug. For GitHub releases links, link directly to the specific
   release tag (e.g. `https://github.com/org/repo/releases/tag/v1.2.0`).

4. Add any JavaScript, Terraform, Bundler, Git-sourced gem and tool or image pin changes in the same
   format, interleaved alphabetically with the Ruby dependencies. Name a provider by its source
   address and a module by its block name and source type, and give a Git module's commit SHA beside
   its version:

   ```text
   * hashicorp/aws 5.80.0 → 5.81.0
   * vpc module (Git) v1.2.3 → v1.4.0 (commit <sha>)
   ```

5. If `yarn.lock` changed, add this line after the dependency list, which names direct dependencies
   only:

   ```text
   Re-resolve yarn.lock so transitive dependencies take the newest versions their ranges allow.
   ```

6. If multi-version jumps occurred for a dependency, list each version's changelog on its own line
   with a version prefix:

   ```text
   * gem-name 1.0.0 → 1.2.0
   [v1.1.0 changelog](url)
   [v1.2.0 changelog](url)
   ```

7. If RuboCop or haml-lint fixes were needed (Steps 8 and 9), append to the end of the commit body,
   keeping only the sections that apply:

   ```text
   Fix the following RuboCop violations:
   - CopName: Brief description of the fix

   Fix the following haml-lint violations:
   - LinterName: Brief description of the fix
   ```

### Step 11: Commit, Push and Create the PR

Stage all files changed during this workflow:

```bash
# Manifests and linter configuration. Stage each file only if it exists: git add validates every
# pathspec before staging anything, so one missing file (no yarn.lock in a repo without JavaScript,
# no .haml-lint_todo.yml without Haml) aborts the whole invocation and stages nothing.
# .rubocop_todo.yml changes only when the rubocop gem itself was bumped (see Step 8).
for f in Gemfile Gemfile.lock package.json yarn.lock .rubocop_todo.yml .haml-lint_todo.yml; do
  if [ -e "$f" ]; then git add -- "$f"; fi
done
# Workspace manifests that yarn up rewrote below the root (none outside a workspace repository)
git diff --name-only -- '**/package.json' | while IFS= read -r f; do git add -- "$f"; done
# Plus any source files modified by bin/rubocop -A or bin/rails lint:haml

# Changed Terraform manifests and the lock files rewritten by terraform init -upgrade.
# Prefer staging the exact paths identified in Steps 5 and 6. If you glob, keep :/*.tf and
# :/*.terraform.lock.hcl in separate git add invocations: git add validates every pathspec before
# staging anything, so one that matches nothing aborts the whole invocation and leaves the .tf
# changes unstaged. Git prints a fatal: line and exits 128, but that is easy to miss.
# Omit either line entirely for repos that have no such files. The exclude keeps the modules that
# terraform init vendors into .terraform/ out of the commit; both magic prefixes anchor to the
# repository root so the commands behave the same from any directory.
git add -- ':/*.tf' ':(top,exclude)*.terraform/*'
git add -- ':/*.terraform.lock.hcl' ':(top,exclude)*.terraform/*'

# Plus the exact files Step 7 bumped (mise files, CI and Compose files, requirements.yml, ...)
```

Then make sure every pin that changed has an entry in the message. List the staged changes outside
the lock files:

```bash
git diff --cached --stat -- . ':!*.lock' ':!yarn.lock' ':!*.terraform.lock.hcl'
```

Every version that moved in those files — a manifest pin, a Terraform constraint, a Step 7 tool or
image pin — needs an entry in the commit body from Step 10. Add any that is missing before going on.

Then use the `/commit` command to create the commit. Provide the changelog body from Step 10 as
context so `/commit` can incorporate it into the commit message. If a Rails upgrade ships in this PR
(see [Step 2](#step-2-create-the-feature-branch)), its commit stays first and this one goes after
it.

Push and create the PR with appropriate labels:

```bash
git push -u origin HEAD
```

Determine which labels to apply:

- Always include `dependencies`
- Include `ruby` if any Ruby gems were updated
- Include `javascript` if any npm packages were updated or `yarn.lock` changed
- Include `terraform` if any Terraform providers or modules were updated

Only use labels that exist in the repository. `gh label list --search` ranks by fuzzy relevance
rather than filtering, so it cannot confirm a name exists. Match the full list exactly instead; this
prints each candidate that exists:

```bash
gh label list --limit 1000 --json name --jq '.[].name' \
  | grep -Fx -e dependencies -e ruby -e javascript -e terraform
```

Pass one `--label` flag per label it printed, and omit the rest. Repeating the flag avoids the
comma-separated form, where a space after a comma becomes part of the next label's name.

Create the PR with a summary body:

```bash
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary

- Updated N Ruby dependencies and M JavaScript packages, plus P Terraform providers and modules
- [Notable updates, e.g. "Rails 8.1.1 → 8.1.2", "RuboCop 1.85 → 1.86 (with auto-fixes)"]

## Test plan

- [ ] CI passes
- [ ] Smoke test the app locally
EOF
)" --label "<label>" --label "<label>"
```

Omit any category (Ruby, JavaScript, Terraform) that had no changes. Tailor the summary bullets to
highlight the most notable updates (major version bumps, security patches, linter upgrades that
required code changes, etc.). Also add a bullet for each of these that applies: a Bundler bump
([Step 3](#step-3-update-ruby-dependencies)), tool and image pin bumps ([Step
7](pins.md#step-7-update-tool-and-image-pins)), the security alerts this run closes and a Rails
upgrade shipping in this PR — which also goes in the title, as
`Upgrade Rails to <version> and update the app's dependencies - {qualifier }{Month} {Year}`. If any
Terraform providers **or modules** changed, add a
`- [ ] terraform plan shows no unexpected resource changes` checkbox to the test plan — a module
major changes inputs and outputs, which is at least as plan-visible as a provider bump.

Step 4 decides what the PR body says about JavaScript. Add each that applies; a `yarn.lock` change
alone counts as a JavaScript change, so do not omit the category for it:

- **`yarn.lock` changed** — a summary bullet:
  `- Re-resolved yarn.lock so transitive dependencies take the newest versions their ranges allow`
- **No release-age gate** — the repository's Yarn is older than 4.10, so the run took releases of
  any age ([Step 4](javascript.md#step-4-update-javascript-dependencies))
- **The re-resolution failed** — and why, so the reviewer knows transitive dependencies did not move
  ([Step 4](javascript.md#step-4-update-javascript-dependencies))

Steps 5 and 6 also decide what else the PR body must say about Terraform. Add each that applies,
summarized and never pasted from Terraform's output, as [Step
6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files) explains:

- **A provider or module major** — the plan's one-line summary, or, for a major the user chose to
  ship unplanned, a statement at the very top of the body that it is unplanned ([Step
  5](terraform.md#step-5-decide-terraform-version-bumps))
- **A root module that could not be planned** — no credentials, `init -backend=false`, a module plan
  the user declined or a platform with no provider build — with the plan checkbox left unticked
  ([Step 6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files))
- **A platform that lost support** — which developers can no longer run that root module ([Step
  6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files))
- **Root modules skipped**, and why ([Step
  6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files))
- **Lock files not tracked**, when the repository ignores them ([Step
  6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files))

## Commit Message Format Reference

Use the `→` character (U+2192) between old and new version numbers. Each dependency entry is a
bullet with the changelog link on the next line:

```text
* name 1.0.0 → 1.1.0
[changelog](https://github.com/owner/repo/blob/main/CHANGELOG.md#version-heading-slug)
```

Entries are listed in **alphabetical order**. Ruby, JavaScript and Terraform dependencies are
interleaved together in one list.

## Version-Locked Packages

Read `${CLAUDE_SKILL_DIR}/version-locked.md` in full before Step 3. Its packages span the gems Step
3 updates and the JavaScript packages Step 4 re-resolves, and each must be handled before that
re-resolution.

## Known Changelog Quirks

Read `${CLAUDE_SKILL_DIR}/changelogs.md` before Step 10 builds the changelog links. It lists the
gems, packages and pins whose changelogs need special handling.

## Important Notes

- **Start from an up-to-date `main`**, or from a Rails upgrade the user chose to ship alongside —
  see [Step 2](#step-2-create-the-feature-branch).
- **Count this month's runs from history, not branches** — see [Step
  1](#step-1-determine-the-branch-name-and-pr-title).
- **Every pin that moved gets a commit-message entry**, including Bundler, Git-sourced gems and tool
  and image pins — see [Step 11](#step-11-commit-push-and-create-the-pr).
- **Changelog links are required** — see [Step 10](#step-10-build-the-final-commit-message).
- **Never skip linter checks** — see [Step 8](linters.md#step-8-handle-rubocop-updates) and [Step
  9](linters.md#step-9-handle-haml-lint-updates).
- **Run `terraform init -upgrade` in every root module whenever the repo has `.tf` files** — even
  with no `.tf` edits, since range constraints and transitive providers move on their own, and a
  skipped root module leaves a stale lock file that makes `terraform plan` fail. See [Step
  6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files).
- **Never commit a root module whose most recent `init` failed** — the `.tf` edits stand while the
  lock file does not move, producing a commit that can neither `init` nor `plan`. See [Step
  6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files).
- **Version-locked packages** — see [Step 4](javascript.md#step-4-update-javascript-dependencies)
  and [Version-Locked Packages](version-locked.md#version-locked-packages).
- If no dependencies changed at all, inform the user and stop. A change to `yarn.lock` alone is put
  to the user first — see [Stop If Nothing Changed](pins.md#stop-if-nothing-changed).
