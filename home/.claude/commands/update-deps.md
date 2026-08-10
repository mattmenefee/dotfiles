# Update Dependencies

Update the app's Ruby, JavaScript, and Terraform dependencies, build a detailed commit message from
changelogs, and open a pull request.

## Overview

This command automates the full dependency update workflow:

1. Determine the branch name and PR title
2. Create a feature branch from `main`
3. Update Ruby dependencies using `gem_update`
4. Update JavaScript dependencies using `yarn up`
5. Decide Terraform provider and module version bumps, if the repo uses Terraform
6. Re-resolve and verify the Terraform lock files
7. Handle RuboCop version bumps
8. Handle haml-lint version bumps
9. Build the final commit message with anchored changelog links
10. Commit, push, and open a PR

## Process

### Step 1: Determine the Branch Name and PR Title

Check whether any `update-dependencies-*` branches already exist for the current month:

```bash
git branch -r --list "origin/update-dependencies-*$(date +%B-%Y | tr '[:upper:]' '[:lower:]')"
```

**Naming rules:**

- **First update of the month** — no prefix, just the month: `update-dependencies-march-2026`
- **Subsequent updates** — add a time-period qualifier: `early`, `mid`, `late`, `end-of`, or devise
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

```bash
git checkout main && git pull
git checkout -b <branch-name>
```

### Step 3: Update Ruby Dependencies

Run `gem_update` to update all Ruby gems and get an initial draft of the dependency changes:

```bash
gem_update 2>&1 | tee /tmp/gem-update-output.txt
```

`gem_update` is the CLI provided by the `gem_updater` gem (installed via `gem install gem_updater`)
that runs `bundle update` internally and outputs a formatted changelog with version diffs and
changelog links. Capture this output — it will be the starting point for the commit message body. If
`gem_update` is not available, run `bundle update` directly and manually build the changelog from
the `Gemfile.lock` diff.

A successful run prints a list of gem updates with version diffs. If no gems were updated, the
output will indicate that the bundle is already up to date.

### Step 4: Update JavaScript Dependencies

Update all JavaScript packages:

```bash
yarn up '*'
```

After updating, identify which **direct dependencies** (packages listed in `package.json`) changed
version by inspecting the `yarn.lock` diff:

```bash
git diff yarn.lock
```

Only direct dependencies listed in `package.json` should appear in the commit message — ignore
transitive dependency changes in `yarn.lock`.

Before proceeding, verify version-locked packages. See
[Version-Locked Packages](#version-locked-packages) below for Playwright and Cocooned constraints.

For each direct JavaScript dependency that changed version, build a changelog entry in the same
format as `gem_update` output:

```text
* @scope/package-name 1.0.0 → 1.1.0
[changelog](https://github.com/owner/repo/blob/main/CHANGELOG.md#anchor)
```

Look up changelog URLs by checking the package's repository field on npm or its GitHub releases
page. Include anchor tags to the specific version heading when available.

### Step 5: Decide Terraform Version Bumps

Many repos have no Terraform configuration at all. Skip this step and
[Step 6](#step-6-re-resolve-and-verify-terraform-lock-files) entirely if this repo has no `.tf`
files. Run every command in both steps from the repository root:

```bash
git ls-files --full-name ':/*.tf'
```

This exits 0 whether or not it matched, so read its output rather than its status. It does not see
`.tf.json` files, untracked files, or files inside submodules; handle those by hand in the rare repo
that has them. See [Terraform Update Notes](#terraform-update-notes) for why the pathspecs and flags
in this step are written the way they are.

#### Find the current pins

```bash
git grep -nE --full-name -A3 '^[^#]*required_providers' -- ':/*.tf'
git grep -nE --full-name -A3 '^[[:space:]]*module[[:space:]]' -- ':/*.tf'
```

`git grep` exits 1 when it finds nothing, which is not an error here. Both commands show only a few
lines of context, so a block with several providers or a long module block **will be truncated with
no warning** — open each matched file at the printed line number and read the whole block rather
than trusting the grep output.

`required_providers` is also not the full provider list. Child modules declare their own providers,
which land in the root module's lock file without ever appearing in these greps. Record what the
lock files already hold, with versions and per root module, as a baseline to diff against in
[Step 6](#step-6-re-resolve-and-verify-terraform-lock-files):

```bash
git grep --full-name -A1 -e '^provider "' -- ':/*.terraform.lock.hcl'
```

Keep the file prefixes and the `version` lines — do not collapse them with `-h | sort -u`. Without
the version you cannot see a provider move at all, and without the filename you cannot tell apart
two root modules that pin the same provider at different versions. Anything here that is not in a
`required_providers` block is transitive: you cannot pin it directly, but a module bump can move it,
so include any version change it undergoes in the commit message.

#### Look up the latest versions

Terraform has no `bundle outdated` equivalent, so query the registry directly for each provider. The
block's `source` value supplies `<namespace>/<name>`. Strip the hostname only when it is exactly
`registry.terraform.io`; any other hostname means a private registry, so skip that provider rather
than stripping the host — the public registry may answer for the same `<namespace>/<name>` with an
entirely unrelated provider:

```bash
curl -fsS --max-time 10 https://registry.terraform.io/v1/providers/<namespace>/<name> \
  | jq -er '[.versions[] | select(test("^[0-9]+(\\.[0-9]+)*$"))]
            | sort_by(split(".") | map(tonumber))
            | last // error("no stable release found")'
```

Do not use the response's `.version` field. It reports the highest semver version **including
prereleases** — it returns `5.5.0-pre.1` for `heroku/heroku` while stable sits at `5.4.0` — and
Terraform will pin to a prerelease without complaint. The filter above discards prereleases and
sorts numerically, so `2.100.0` correctly beats `2.99.1`.

Registry modules answer the same way at
`https://registry.terraform.io/v1/modules/<namespace>/<name>/<provider>`. Modules with a local path
source (`source = "../../modules/network"`) are versioned by this repository — skip them.

Modules sourced from Git (`source = "git::https://github.com/org/repo.git//modules/foo?ref=v1.2.3"`)
or a private registry have no public version API. List the repository's version tags and bump the
`ref=` value directly:

```bash
tags=$(git ls-remote --tags --refs https://github.com/org/repo.git) || echo "lookup failed"
printf '%s\n' "$tags" | sed 's|.*refs/tags/||' \
  | grep -E '^v?[0-9]+(\.[0-9]+)*$' \
  | sed 's/^v//' \
  | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n \
  | tail -1
```

Do not reach for `git ls-remote --sort=-v:refname | head -1`. That sort ranks `v3.0.0-rc1` above
`v2.1.0`, ranks every `v`-prefixed tag above every bare-numeric one — so a repo that dropped the
prefix at `2.0.0` reports the older `v1.10.0`, the exact silent downgrade you are trying to avoid —
and ranks floating tags like `stable` and `latest` in among the versions. The `grep` above discards
prereleases and non-version tags, and the numeric sort compares field by field.

Assign `git ls-remote` to a variable rather than piping it straight into `head`: a pipeline's exit
status is the last command's, so an unreachable or unauthorized repository prints to stderr and the
pipeline still exits 0 — the same trap `-fsS`/`jq -e` guard against for curl. Empty output means the
repository has no version tags; leave the `ref=` alone and say so rather than guessing. The command
prints a bare version, so re-apply whatever prefix the existing `ref=` uses. Treat a module major
like a provider major — skim the repository's release notes first, since module inputs and outputs
change across majors.

#### Bump the pins

Confirm the CLI is available before editing anything: `terraform version` should print a version and
exit 0. If it is not on `PATH` you get exit 127; under a version manager you may instead get a shim
error such as `mise ERROR No version is set for shim: terraform` until a version is selected. Either
way, stop and tell the user rather than making `.tf` edits you cannot re-resolve — and if you have
already made them, revert with `git checkout -- <paths>` first.

Compare each result against the version in the constraint, numerically field by field rather than as
strings. What to do next depends on the constraint's form:

| Constraint form | Example | Action |
| --- | --- | --- |
| Exact pin, no operator | `version = "2.99.0"` | Edit the `.tf` file to the new version. `init -upgrade` cannot advance an exact pin on its own, so skipping this means the provider never updates. |
| Range | `~> 2.99`, `>= 2.5` | Edit only if the new release falls outside the range; otherwise `init -upgrade` picks it up with no `.tf` change. |
| Bare `source`, no `version`, **child** module | `source = "../../modules/net"` | Leave it alone — the root module's constraint governs, and a second pin here can only conflict with it. |
| Bare `source`, no `version`, **root** module | — | Nothing governs it. `init -upgrade` takes the newest release published, crossing majors with no `.tf` diff and no `constraints` line recorded. Check the lock file's `version` before and after. |

Count the constraint's segments before deciding "outside" a range. `~>` frees only the component one
level less precise than the last one given, so `~> 2.99` admits any `2.x` up to (not including)
`3.0` — `2.100.0` is **inside** it — while `~> 2.99.0` admits only `2.99.x`.

Three things can cross a major version boundary in one step: replacing an exact pin with the
registry's latest, letting an unbounded range such as `>= 2.5` drift forward, and a root-module bare
`source`. The latter two are the more dangerous, because no `.tf` line changes — the only trace is a
`version` line in the lock file diff, which is easy to skim past. Skim the provider's release notes
for breaking changes before taking a major bump in any of the three cases.

If nothing has a newer version available, there is nothing to commit — skip
[Step 6](#step-6-re-resolve-and-verify-terraform-lock-files) as well.

### Step 6: Re-resolve and Verify Terraform Lock Files

**If `terraform init` exits non-zero anywhere in this step, stop — do not go on to Step 10.** A
failed `init` leaves the lock file untouched while your Step 5 edits stand, and staging that pair
produces a commit that can neither `init` nor `plan`. Read the error before deciding what to do:
`no available releases match the given constraints`, `does not have a package available for your
current platform`, or any HCL syntax error means the edit you just made is wrong — fix it in place
and re-run. Only stop for failures you cannot resolve locally, and when you do, revert that module's
`.tf` edits, delete any `.terraform/` directory the failed run created if the repository does not
ignore it, and report rather than committing a half-updated state.

You **must** run `terraform init -upgrade` in **every** root module, not only the ones whose `.tf`
files changed in Step 5. A range constraint updates without any `.tf` edit at all, so a list built
from changed files would skip exactly those modules. Root modules are the directories that own a
lock file:

```bash
git ls-files -z --full-name ':/*.terraform.lock.hcl' ':(top,exclude)*.terraform/*' \
  | xargs -0 -n1 dirname | sort -u
```

Child modules never own a lock file, so this excludes them automatically. Add any brand-new root
module that does not have one yet. The `-z`/`-0` pair matters — plain word splitting mangles paths
containing spaces into directories that do not exist — and the exclude keeps vendored copies under
`.terraform/` from being mistaken for root modules.

Run this once per root module, quoting the directory in case it contains spaces:

```bash
terraform -chdir="<terraform-directory>" init -upgrade -input=false
```

Check the exit status, not just the output. A successful run exits 0 and reports "Terraform has been
successfully initialized!" — and, when a provider selection actually moved, also notes that it
changed the selections recorded in `.terraform.lock.hcl`. A pure module `ref=` bump succeeds without
that second message, which is expected rather than a sign the run did nothing.

Terraform installs the providers it can reach before failing, so `Installed …` lines in the output
of a failed run do not mean the lock file was written. Confirm with both of these — a brand-new root
module's lock file is untracked, so `git diff` alone shows nothing whether or not it was written:

```bash
git status --porcelain -- "<terraform-directory>/.terraform.lock.hcl"
git diff -- "<terraform-directory>/.terraform.lock.hcl"
```

If `init` fails on backend credentials rather than on providers, retry with `-backend=false`, which
still installs providers and writes the lock file. It leaves the backend uninitialized either way,
so `terraform plan` in that directory will report `Backend initialization required` — note in the PR
body that you could not plan it.

Read the lock file diff, but be clear about what it can tell you. The `version` and `constraints`
lines and the set of `provider "<host>/<namespace>/<name>"` blocks are checkable — confirm each
version matches the pin you wrote, and that no provider block or registry hostname appeared that you
did not expect. Diff it against the baseline you captured in Step 5, since a module bump can move a
provider that no `required_providers` block mentions. The `h1:`/`zh:` hash lines are not checkable:
`-upgrade` discards the previously trusted hashes and records whatever the registry serves now, so a
substituted package would look entirely normal here. Do not treat scanning the hashes as
verification.

Where credentials are available, run a plan in each affected root module before opening the PR — a
provider major can turn an in-place update into a destroy-and-recreate, and the plan diff is the
only thing that surfaces that:

```bash
terraform -chdir="<terraform-directory>" plan -input=false
```

`plan` needs real provider and backend credentials, so `No valid credential sources found` or
`Backend initialization required` where they are absent is not a dependency problem. `Error:
Inconsistent dependency lock file` **is** one — it means `init -upgrade` did not run or did not
succeed in that directory, so go back and re-run it rather than waving the failure through. When you
cannot plan at all, say so in the PR body and leave its checkbox unticked rather than skipping it
silently.

Then stage the lock file along with the `.tf` changes (see
[Step 10](#step-10-commit-push-and-create-the-pr)), and record each version change for the commit
message (see [Step 9](#step-9-build-the-final-commit-message)).

### Step 7: Handle RuboCop Updates

Check the `gem_update` output or `git diff Gemfile.lock` for changes to `rubocop` or any `rubocop-*`
gem.

If a RuboCop gem was updated:

1. Run `bin/rubocop -A` to auto-fix any new violations.
2. Review the output for violations that could not be auto-fixed and manually fix them.
3. After **all** violations are resolved, run:

   ```bash
   bin/rubocop --auto-gen-config --auto-gen-only-exclude --exclude-limit 1000
   ```

   This updates the timestamp and version in `.rubocop_todo.yml` (if it exists).
4. Note the RuboCop fixes for inclusion in the commit message body (see Step 9).

A clean `bin/rubocop -A` run exits 0 and reports "no offenses detected" or lists only auto-corrected
offenses. Any remaining offenses must be fixed manually before proceeding.

### Step 8: Handle haml-lint Updates

Check the output or diff for changes to the `haml_lint` gem (CLI: `haml-lint`).

If haml-lint was updated:

1. Run `bin/rails lint:haml` and manually fix any violations.
2. If `.haml-lint_todo.yml` exists, run:

   ```bash
   bin/haml-lint --auto-gen-config --auto-gen-exclude-limit 1000
   ```

   Then edit line 2 of `.haml-lint_todo.yml` to replace the full regeneration command (which
   includes all flags and options) with just:

   ```text
   # `bin/haml-lint --auto-gen-config --auto-gen-exclude-limit 1000`
   ```

A successful `bin/rails lint:haml` run exits 0 with no reported offenses. Any violations must be
fixed manually before proceeding.

### Step 9: Build the Final Commit Message

Launch a **documentation-expert** sub-agent (using the Agent tool) to refine the commit message.
Give it the `gem_update` output from Step 3, any JavaScript dependency changes from Step 4, any
Terraform provider and module changes from Step 5, and the conventions below.

The agent should:

1. Start with the `gem_update` output as the base for Ruby dependencies.

2. **Fill in missing changelog links** — for any dependency where `gem_update` did not find a
   changelog URL, look it up:
   - Check the gem's metadata (`gem specification <name>`) for `changelog_uri`, `source_code_uri`,
     or homepage
   - For npm packages, check the package's repository URL on the npm registry

   **Prefer GitHub releases** if the repo uses them (link to the specific release tag page).
   Otherwise, fall back to whichever changelog or history document the repo uses. Common file names
   (in various casing and extensions):
   - `CHANGELOG`, `CHANGES`, `HISTORY`, `NEWS`
   - Extensions: `.md`, `.txt`, `.textile`, `.rdoc`, or no extension

   **Diffend fallback for Ruby gems** — if a gem has no changelog, no GitHub releases with
   meaningful notes, and no history file, use [Diffend](https://my.diffend.io) as a last resort.
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

4. Add any JavaScript and Terraform dependency version changes in the same format, interleaved
   alphabetically with the Ruby dependencies.

5. If multi-version jumps occurred for a dependency, list each version's changelog on its own line
   with a version prefix:

   ```text
   * gem-name 1.0.0 → 1.2.0
   [v1.1.0 changelog](url)
   [v1.2.0 changelog](url)
   ```

6. If RuboCop fixes were needed (Step 7), append to the end of the commit body:

   ```text
   Fix the following RuboCop violations:
   - CopName: Brief description of the fix
   ```

### Step 10: Commit, Push, and Create the PR

Stage all files changed during this workflow:

```bash
# Core manifest files
git add Gemfile Gemfile.lock package.json yarn.lock

# Linter configuration and auto-fixed source files (if applicable)
git add .rubocop_todo.yml .haml-lint_todo.yml
# Plus any source files modified by bin/rubocop -A or bin/rails lint:haml

# Changed Terraform manifests and the lock files rewritten by terraform init -upgrade.
# Prefer staging the exact paths identified in Steps 5 and 6. If you glob, keep the two pathspecs
# on separate commands: git add validates every pathspec before staging anything, so one that
# matches nothing aborts the whole invocation and silently leaves the .tf changes unstaged.
# Omit either line entirely for repos that have no such files. The exclude keeps the modules that
# terraform init vendors into .terraform/ out of the commit; both magic prefixes anchor to the
# repository root so the commands behave the same from any directory.
git add -- ':/*.tf' ':(top,exclude)*.terraform/*'
git add -- ':/*.terraform.lock.hcl' ':(top,exclude)*.terraform/*'
```

Then use the `/commit` command to create the commit. Provide the changelog body from Step 9 as
context so `/commit` can incorporate it into the commit message.

Push and create the PR with appropriate labels:

```bash
git push -u origin HEAD
```

Determine which labels to apply:

- Always include `dependencies`
- Include `ruby` if any Ruby gems were updated
- Include `javascript` if any npm packages were updated
- Include `terraform` if any Terraform providers or modules were updated

Only use labels that exist in the repository. Check with:

```bash
gh label list --search "dependencies"
gh label list --search "ruby"
gh label list --search "javascript"
gh label list --search "terraform"
```

Omit any labels that don't exist in the repo from the `--label` flag below.

Create the PR with a summary body:

```bash
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary

- Updated N Ruby dependencies, M JavaScript packages, and P Terraform providers
- [Notable updates, e.g. "Rails 8.1.1 → 8.1.2", "RuboCop 1.85 → 1.86 (with auto-fixes)"]

## Test plan

- [ ] CI passes
- [ ] Smoke test the app locally
EOF
)" --label "<comma-separated list of verified labels>"
```

Omit any category (Ruby, JavaScript, Terraform) that had no changes. Tailor the summary bullets to
highlight the most notable updates (major version bumps, security patches, linter upgrades that
required code changes, etc.). If Terraform providers changed, add a
`- [ ] terraform plan shows no unexpected resource changes` checkbox to the test plan.

## Commit Message Format Reference

Use the `→` character (U+2192) between old and new version numbers. Each dependency entry is a
bullet with the changelog link on the next line:

```text
* name 1.0.0 → 1.1.0
[changelog](https://github.com/owner/repo/blob/main/CHANGELOG.md#version-heading-slug)
```

Entries are listed in **alphabetical order**. Ruby, JavaScript, and Terraform dependencies are
interleaved together in one list.

## Version-Locked Packages

Some packages must be updated in tandem because their versions must match across ecosystems. After
updating, verify these constraints and revert any that break them.

### Playwright

The `playwright` npm package (pinned to an exact version in `package.json`) and the
`playwright-ruby-client` gem (pinned with `~>` in `Gemfile`) must have **matching major.minor
versions**. The npm package often releases days or weeks before the Ruby gem catches up.

After updating, check whether both sides landed on the same version:

1. If `yarn up` bumped `playwright` to a version that doesn't yet have a matching
   `playwright-ruby-client` gem, revert the npm package:

   ```bash
   yarn up playwright@<matching-version>
   ```

2. If both updated successfully to the same new version, update the pinned version constraints in
   both manifest files:
   - `package.json`: update the exact `playwright` version
   - `Gemfile`: update the `~>` constraint for `playwright-ruby-client`

3. Do **not** hold back the Ruby gem if the npm package already matches — only revert the npm side
   when it gets ahead.

### Cocooned

The `@notus.sh/cocooned` npm package and the `cocooned` gem must have **matching versions**. The
maintainer typically releases both sides simultaneously — mismatches are rare.

When a new version is available:

1. Both should update together. If for some reason only one side updated, revert it to match the
   other:

   ```bash
   # If the npm package got ahead:
   yarn up @notus.sh/cocooned@<gem-version>

   # If the gem got ahead:
   bundle update cocooned --conservative
   ```

2. Update the pinned version constraints in both manifest files:
   - `Gemfile`: update the `~>` constraint for `cocooned`
   - `package.json`: update the `^` constraint for `@notus.sh/cocooned`

## Terraform Update Notes

Why the commands in [Step 5](#step-5-decide-terraform-version-bumps) and
[Step 6](#step-6-re-resolve-and-verify-terraform-lock-files) are shaped the way they are. Consult
this when you need the reasoning; the steps themselves are self-contained.

**Why `-upgrade` is mandatory.** Version constraints in the `.tf` files and the resolved versions in
`.terraform.lock.hcl` are tracked separately, so bumping a constraint alone leaves the lock file
stale. In a working directory that is already initialized, `terraform plan` then fails with
`Error: Inconsistent dependency lock file`, naming the provider whose locked selection no longer
matches the configuration. Where the providers are not installed locally at all, the same staleness
surfaces earlier and differently — `init` reports `Failed to query available provider packages …
must use terraform init -upgrade`, and `plan` reports `Required plugins are not installed`. A plain
`terraform init` will not fix any of these; it honors the versions already recorded in the lock
file, and only `-upgrade` re-resolves them.

**Why `-input=false`.** It keeps `init` from stopping at an interactive prompt (backend migration,
missing credentials) with no TTY to answer it, erroring out instead of hanging.

**Why `-fsS` and `jq -e`.** A bare `curl -s ... | jq -r .version` prints `null` and **exits 0** on a
404, which reads as "no newer release exists" and silently skips the bump. The pipeline's status is
jq's, not curl's, so the failure never surfaces. `-f` makes curl exit non-zero, `-S` restores the
error message, and `jq -e` propagates a non-zero status instead of printing `null`.

**Why the `:/` pathspec prefix.** It anchors matching to the repository root, so the commands select
the same files from any directory. It does not normalize the *printed* paths, which is why the
read-only queries also pass `--full-name` — without it, `git ls-files` and `git grep` print paths
relative to the current directory while `git diff` prints them relative to the root.

**Module bumps and the lock file.** The lock file records provider selections only. A pure module
`ref=` bump will not change it, but `init -upgrade` is still needed in that root module to fetch the
new module source.

## Known Changelog Quirks

### sass-embedded

The `sass-embedded` Ruby gem wraps the Dart Sass compiler but does not maintain its own changelog or
GitHub releases. Its version number tracks the compiler, so use the Dart Sass changelog at
[sass/dart-sass](https://github.com/sass/dart-sass/blob/main/CHANGELOG.md) and anchor to the
matching version heading (e.g. `#11030` for 1.103.0).

Do **not** treat the sister host
[sass/embedded-host-node](https://github.com/sass/embedded-host-node/blob/main/CHANGELOG.md) as a
lockstep source. It is a separate release train whose changelog can lag the compiler by one or more
versions, so the entry for the version being shipped may simply not exist there yet. Reach for it
only for host-specific notes that the Dart Sass changelog does not cover.

## Important Notes

- **Start from an up-to-date `main`** — see [Step 2](#step-2-create-the-feature-branch).
- **Changelog links are required** — see [Step 9](#step-9-build-the-final-commit-message).
- **Never skip linter checks** — see [Step 7](#step-7-handle-rubocop-updates) and
  [Step 8](#step-8-handle-haml-lint-updates).
- **Always run `terraform init -upgrade` after a Terraform dependency changes** — otherwise the lock
  file goes stale and `terraform plan` fails. See
  [Step 6](#step-6-re-resolve-and-verify-terraform-lock-files).
- **Never commit a Terraform change whose `init` failed** — the `.tf` edits stand while the lock
  file does not move, producing a commit that can neither `init` nor `plan`. See
  [Step 6](#step-6-re-resolve-and-verify-terraform-lock-files).
- **Version-locked packages** — see [Step 4](#step-4-update-javascript-dependencies) and
  [Version-Locked Packages](#version-locked-packages).
- If no dependencies changed at all, inform the user and stop.
