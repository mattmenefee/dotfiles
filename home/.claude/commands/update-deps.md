# Update Dependencies

Update the app's Ruby and JavaScript dependencies, generate a detailed
changelog commit message, and open a pull request.

## Overview

This command automates the full dependency update workflow:

1. Determine the branch name and PR title
2. Create a feature branch from `main`
3. Update Ruby dependencies using `gem_update`
4. Update JavaScript dependencies using `yarn up`
5. Handle RuboCop version bumps
6. Handle haml-lint version bumps
7. Build the final commit message with anchored changelog links
8. Commit, push, and open a PR

## Process

### Step 1: Determine the Branch Name and PR Title

Check whether any `update-dependencies-*` branches already exist for the
current month:

```bash
git branch -r --list "origin/update-dependencies-*-$(date +%B-%Y | tr '[:upper:]' '[:lower:]')"
```

**Naming rules:**

- **First update of the month** — no prefix, just the month:
  `update-dependencies-march-2026`
- **Subsequent updates** — add a time-period qualifier:
  `early`, `mid`, `late`, `end-of`, or devise another qualifier as
  needed to avoid collisions (e.g. `update-dependencies-mid-late-march-2026`)

- **Branch**: `update-dependencies-{qualifier-}{month}-{year}`
  (all lowercase, hyphenated)
- **Title**: `Update the app's dependencies - {qualifier }{Month} {Year}`

Examples:

| Scenario | Branch | Title |
|----------|--------|-------|
| First of the month | `update-dependencies-march-2026` | `Update the app's dependencies - March 2026` |
| Second update | `update-dependencies-early-march-2026` | `Update the app's dependencies - early March 2026` |
| Third update | `update-dependencies-mid-march-2026` | `Update the app's dependencies - mid March 2026` |
| Fourth update | `update-dependencies-late-march-2026` | `Update the app's dependencies - late March 2026` |
| Close together | `update-dependencies-end-of-march-2026` | `Update the app's dependencies - end of March 2026` |

### Step 2: Create the Feature Branch

```bash
git checkout main && git pull
git checkout -b <branch-name>
```

### Step 3: Update Ruby Dependencies

Run `gem_update` to update all Ruby gems and get an initial draft of the
dependency changes:

```bash
gem_update 2>&1 | tee /tmp/gem-update-output.txt
```

`gem_update` runs `bundle update` internally and outputs a formatted
changelog with version diffs and changelog links. Capture this output —
it will be the starting point for the commit message body.

A successful run prints a list of gem updates with version diffs. If
no gems were updated, the output will indicate that the bundle is
already up to date.

### Step 4: Update JavaScript Dependencies

Update all JavaScript packages:

```bash
yarn up '*'
```

After updating, identify which **direct dependencies** (packages listed
in `package.json`) changed version by inspecting the `yarn.lock` diff:

```bash
git diff yarn.lock
```

Only direct dependencies listed in `package.json` should appear in the
commit message — ignore transitive dependency changes in `yarn.lock`.

Before proceeding, verify version-locked packages. See
[Version-Locked Packages](#version-locked-packages) below for Playwright
and Cocooned constraints.

For each direct JavaScript dependency that changed version, build a
changelog entry in the same format as `gem_update` output:

```text
* @scope/package-name 1.0.0 → 1.1.0
[changelog](https://github.com/owner/repo/blob/main/CHANGELOG.md#anchor)
```

Look up changelog URLs by checking the package's repository field on npm
or its GitHub releases page. Include anchor tags to the specific version
heading when available.

### Step 5: Handle RuboCop Updates

Check the `gem_update` output or `git diff Gemfile.lock` for changes to
`rubocop` or any `rubocop-*` gem.

If a RuboCop gem was updated:

1. Run `bin/rubocop -A` to auto-fix any new violations.
2. Review the output for violations that could not be auto-fixed and
   manually fix them.
3. After **all** violations are resolved, run:

   ```bash
   bin/rubocop --auto-gen-config --auto-gen-only-exclude --exclude-limit 1000
   ```

   This updates the timestamp and version in `.rubocop_todo.yml` (if
   it exists).
4. Note the RuboCop fixes for inclusion in the commit message body
   (see Step 7).

A clean `bin/rubocop -A` run exits 0 and reports "no offenses detected"
or lists only auto-corrected offenses. Any remaining offenses must be
fixed manually before proceeding.

### Step 6: Handle haml-lint Updates

Check the output or diff for changes to the `haml_lint` gem
(CLI: `haml-lint`).

If haml-lint was updated:

1. Run `bin/rails lint:haml` and manually fix any violations.
2. If `.haml-lint_todo.yml` exists, run:

   ```bash
   bin/haml-lint --auto-gen-config --auto-gen-exclude-limit 1000
   ```

   Then edit line 2 of `.haml-lint_todo.yml` to replace the full
   regeneration command (which includes all flags and options) with just:

   ```text
   # `bin/haml-lint --auto-gen-config --auto-gen-exclude-limit 1000`
   ```

A successful `bin/rails lint:haml` run exits 0 with no reported
offenses. Any violations must be fixed manually before proceeding.

### Step 7: Build the Final Commit Message

Launch a **documentation-expert** sub-agent (using the Agent tool) to
refine the commit message. Give it the `gem_update` output from Step 3,
any JavaScript dependency changes from Step 4, and the conventions
below.

The agent should:

1. Start with the `gem_update` output as the base for Ruby dependencies.

2. **Fill in missing changelog links** — for any dependency where
   `gem_update` did not find a changelog URL, look it up:
   - Check the gem's metadata (`gem specification <name>`) for
     `changelog_uri`, `source_code_uri`, or homepage
   - For npm packages, check the package's repository URL on the npm
     registry

   **Prefer GitHub releases** if the repo uses them (link to the
   specific release tag page). Otherwise, fall back to whichever
   changelog or history document the repo uses. Common file names
   (in various casing and extensions):
   - `CHANGELOG`, `CHANGES`, `HISTORY`, `NEWS`
   - Extensions: `.md`, `.txt`, `.textile`, `.rdoc`, or no extension

3. **Add anchor tags to changelog links** — if a changelog link points
   to a file but lacks an anchor tag for the specific version, follow
   the link and find the correct heading anchor. For example, change
   `[changelog](https://github.com/org/repo/blob/main/CHANGELOG.md)`
   to
   `[changelog](https://github.com/org/repo/blob/main/CHANGELOG.md#version-heading-slug)`.
   The anchor is derived from the actual heading text in the changelog —
   inspect the rendered page or heading source to find the correct slug.
   For GitHub releases links, link directly to the specific release tag
   (e.g. `https://github.com/org/repo/releases/tag/v1.2.0`).

4. Add any JavaScript dependency version changes in the same format,
   interleaved alphabetically with the Ruby dependencies.

5. If multi-version jumps occurred for a dependency, list each version's
   changelog on its own line with a version prefix:

   ```text
   * gem-name 1.0.0 → 1.2.0
   [v1.1.0 changelog](url)
   [v1.2.0 changelog](url)
   ```

6. If RuboCop fixes were needed (Step 5), append to the end of the
   commit body:

   ```text
   Fix the following RuboCop violations:
   - CopName: Brief description of the fix
   ```

### Step 8: Commit, Push, and Create the PR

Stage all files changed during this workflow:

```bash
# Core manifest files
git add Gemfile Gemfile.lock package.json yarn.lock

# Linter configuration and auto-fixed source files (if applicable)
git add .rubocop_todo.yml .haml-lint_todo.yml
# Plus any source files modified by bin/rubocop -A or bin/rails lint:haml
```

Then use the `/commit` command to create the commit. Provide the
changelog body from Step 7 as context so `/commit` can incorporate it
into the commit message.

Push and create the PR with appropriate labels:

```bash
git push -u origin HEAD
```

Determine which labels to apply:

- Always include `dependencies`
- Include `ruby` if any Ruby gems were updated
- Include `javascript` if any npm packages were updated

Only use labels that exist in the repository. Check with:

```bash
gh label list --search "dependencies"
gh label list --search "ruby"
gh label list --search "javascript"
```

Omit any labels that don't exist in the repo from the `--label` flag
below.

Create the PR with a summary body:

```bash
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary

- Updated N Ruby dependencies and M JavaScript packages
- [Notable updates, e.g. "Rails 8.1.1 → 8.1.2", "RuboCop 1.85 → 1.86 (with auto-fixes)"]

## Test plan

- [ ] CI passes
- [ ] Smoke test the app locally
EOF
)" --label "<comma-separated list of verified labels>"
```

Tailor the summary bullets to highlight the most notable updates (major
version bumps, security patches, linter upgrades that required code
changes, etc.).

## Commit Message Format Reference

Use the `→` character (U+2192) between old and new version numbers.
Each dependency entry is a bullet with the changelog link on the next
line:

```text
* name 1.0.0 → 1.1.0
[changelog](https://github.com/owner/repo/blob/main/CHANGELOG.md#version-heading-slug)
```

Entries are listed in **alphabetical order**. Ruby and JavaScript
dependencies are interleaved together in one list.

## Version-Locked Packages

Some packages must be updated in tandem because their versions must match
across ecosystems. After updating, verify these constraints and revert
any that break them.

### Playwright

The `playwright` npm package (pinned to an exact version in
`package.json`) and the `playwright-ruby-client` gem (pinned with `~>`
in `Gemfile`) must have **matching major.minor versions**. The npm
package often releases days or weeks before the Ruby gem catches up.

After updating, check whether both sides landed on the same version:

1. If `yarn up` bumped `playwright` to a version that doesn't yet have
   a matching `playwright-ruby-client` gem, revert the npm package:

   ```bash
   yarn up playwright@<matching-version>
   ```

2. If both updated successfully to the same new version, update the
   pinned version constraints in both manifest files:
   - `package.json`: update the exact `playwright` version
   - `Gemfile`: update the `~>` constraint for `playwright-ruby-client`

3. Do **not** hold back the Ruby gem if the npm package already matches —
   only revert the npm side when it gets ahead.

### Cocooned

The `@notus.sh/cocooned` npm package and the `cocooned` gem must have
**matching versions**. The maintainer typically releases both sides
simultaneously — mismatches are rare.

When a new version is available:

1. Both should update together. If for some reason only one side
   updated, revert it to match the other:

   ```bash
   # If the npm package got ahead:
   yarn up @notus.sh/cocooned@<gem-version>

   # If the gem got ahead:
   bundle update cocooned --conservative
   ```

2. Update the pinned version constraints in both manifest files:
   - `Gemfile`: update the `~>` constraint for `cocooned`
   - `package.json`: update the `^` constraint for `@notus.sh/cocooned`

## Important Notes

- **Start from an up-to-date `main`** — see Step 2.
- **Changelog links are required** — see Step 7.
- **Never skip linter checks** — see Steps 5 and 6.
- **Version-locked packages** — see Step 4 and
  [Version-Locked Packages](#version-locked-packages).
- If no dependencies changed at all, inform the user and stop.
