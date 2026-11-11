---
name: update-deps
description: >-
  Update an app's Ruby, JavaScript and Terraform dependencies and its tool and image pins, build a
  commit message from changelogs and open a pull request.
disable-model-invocation: true
model: sonnet
---

# Update Dependencies

Update the app's Ruby, JavaScript and Terraform dependencies and its tool and image pins, build a
detailed commit message from changelogs and open a pull request.

## Overview

This skill automates the full dependency update workflow:

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
10. Analyze the impact of every moved dependency, reading the code diff of each Deep one
11. Build the final commit message with anchored changelog links
12. Commit, push and open a PR

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
1st. `-i` matches the usual capitalized subject, and because the pattern is unanchored it also
catches a run whose subject begins `Upgrade Rails to … and update the app's dependencies` (see
[Step 12](#step-12-commit-push-and-create-the-pr)). Then list this month's run branches on the
remote itself, since local remote-tracking refs can be stale:

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
stop and ask the user whether to amend it (see
[Rails JavaScript Packages](version-locked.md#rails-javascript-packages)). Tell the user the
upgrade's own pull request should be closed in favor of this one once it is open, and say so in this
PR's body, so the same commits cannot merge twice. Otherwise start from an up-to-date `main`:

```bash
git checkout main && git pull
git checkout -b <branch-name>
```

### Step 3: Update Ruby Dependencies

First lift any release-age hold an earlier run left. List them with
`grep -n 'update-deps: release-age hold' Gemfile`. Delete each line whose marker ends at `hold`, and
on a line marked `bound only` remove just the `"< <version>"` bound and the marker (see
[Check Every Moved Gem's Release Age](#check-every-moved-gems-release-age)).

Run `gem_update` to update all Ruby gems and get an initial draft of the dependency changes:

```bash
out="$(mktemp -t gem-update)" && echo "$out" && BUNDLE_COOLDOWN=1 gem_update 2>&1 | tee "$out"
```

`BUNDLE_COOLDOWN=1` is the Ruby side of the release-age gate
[Step 4](#step-4-update-javascript-dependencies) applies to Yarn: Bundler skips any gem release
younger than one day and resolves the newest one old enough, across the whole tree, and prints the
releases it skipped. It overrides any `cooldown:` the Gemfile sets on a `source` line, so first read
the project's own cooldown for rubygems.org, in days: `bundle config get cooldown`, or else the
`cooldown:` on the Gemfile's `source "https://rubygems.org"` line. Drop the variable when that is
`1` or more, so a longer cooldown stands; a `0` is not a reason to drop it. A private source's own
`cooldown: 0` does not count: Bundler's documentation suggests it to exempt an internal server,
which usually sends no `created_at` for the cooldown to use anyway. Bundler without cooldown support
ignores the variable silently, which
[Check Every Moved Gem's Release Age](#check-every-moved-gems-release-age) below catches.

The variable loses to one place: the project's local configuration, which Bundler reads before the
environment. `bundle config get cooldown` labels such a value "Set for your local app", from
`.bundle/config`. When that value is below `1`, the variable changes nothing, and `gem_update` takes
no `--cooldown` flag, the only setting that outranks local configuration. Tell the user the gate
will not apply to `gem_update` and why, and let the release-age check below catch what it lets
through.

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

Production installs whichever Bundler the lock file's `BUNDLED WITH` line names. `bundle update`
runs that Bundler and leaves the line alone, so on its own it keeps Bundler wherever it was.
`gem_update` does not: it runs the newest Bundler installed on this machine and can rewrite the line
to that version, so a lock at 2.6.9 can come back at 4.0.24 with no Bundler step taken and no entry
in its output. Either way, update Bundler explicitly and read the line from the diff, which shows
both kinds of move:

```bash
bundle update --bundler
git diff Gemfile.lock | grep -E -A2 'BUNDLED WITH'
```

If the line moved, add a `bundler <old> → <new>` entry to the commit message, alphabetized with the
others, and mention it in the PR summary. If it did not, Bundler is already current. See
[Known Changelog Quirks](changelogs.md#known-changelog-quirks) for where its release notes live.

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

#### Check Every Moved Gem's Release Age

The cooldown cannot be trusted on its own. `gem_update` runs the newest Bundler installed on this
machine, not the one `BUNDLED WITH` names, and an older one has no cooldown. A gem server that sends
no per-version `created_at` lets every release through. And `bundle update --bundler` ignores the
cooldown altogether. So read the publish time of every gem version that `Gemfile.lock` now records
for the first time, the `BUNDLED WITH` Bundler included, from the RubyGems API:

```bash
git diff -U0 Gemfile.lock \
  | sed -nE 's/^\+    ([^ ]+) \(([^)]+)\)$/\1 \2/p; s/^\+ {2,3}([0-9][^ ]*)$/bundler \1/p' \
  | while read -r name version; do
      if ! json="$(curl -fsS "https://rubygems.org/api/v1/versions/${name}.json" 2>&1)"; then
        echo "${name} ${version}: lookup failed: ${json}"; continue
      fi
      printf '%s\n' "$json" \
        | jq -r --arg n "$name" --arg v "${version%%-*}" '
            (([.[] | select(.number == $v)][0] // {}).created_at // "unknown") as $c
            | if $c == "unknown" then "\($n) \($v): not on rubygems.org"
              else ((now - ($c | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601)) / 3600
                    | floor) as $h
              | "\($n) \($v): published \($c[0:16])Z, \($h)h ago\(
                  if $h < 24 then " (younger than one day)" else "" end)" end'
    done
```

`${version%%-*}` drops a platform suffix (`1.18.10-arm64-darwin`). Bundler 4 indents the
`BUNDLED WITH` version two spaces and Bundler 2 three, which the second `sed` pattern allows for.
Read the other lines this way:

- **`lookup failed: … 404`** — no gem of that name is on rubygems.org, so it comes from a Git source
  or a private server and is not gated here
- **`not on rubygems.org`** — the gem is there but that version is not, which again means another
  source
- **`lookup failed` with any other error** — a network or rate-limit failure, so that gem is
  unchecked, not passed. Run the script again before going on.
- **A gem whose `Gemfile.lock` block names another `remote:`** — its line reports the public gem of
  the same name, so it says nothing about the version locked

For each line marked `(younger than one day)`:

- **Bundler** — lock the newest Bundler at least one day old instead, with
  `bundle update --bundler=<version>`, and note it for the PR body
- **Any other gem** — the cooldown did not apply. Stop and tell the user which gems slipped through,
  and why, if the reason is plain: no cooldown in the Bundler `gem_update` loaded
  (`(cd / && ruby -rbundler -e 'puts Bundler::VERSION')`, run away from the project so its
  `BUNDLED WITH` does not choose the version), a local `cooldown` below `1` in `.bundle/config` (see
  [Step 3](#step-3-update-ruby-dependencies)) or a source with no `created_at`. Offer to install a
  Bundler with cooldown support and run the step again, when that is the reason, or to hold each one
  back with a marked temporary bound, which the next run's Step 3 removes before `gem_update`. For a
  transitive gem, add a line inside the same `group` block as the gem that depends on it, which
  `bundle exec gem dependency <name> --reverse-dependencies` names under "Used by", so a production
  install that skips the development and test groups does not gain it. `require: false` keeps
  `Bundler.require` from loading it at boot:

  ```ruby
  gem "<name>", "< <young-version>", require: false # update-deps: release-age hold
  ```

  For a gem the Gemfile already lists, add the `"< <young-version>"` bound to its existing line
  instead, with the marker `# update-deps: release-age hold, bound only`.

  A bound in the Gemfile alone leaves `Gemfile.lock` on the young version, and a frozen install in
  CI then refuses the pair. Re-resolve that gem under the gate with
  `bundle update <name> --conservative --cooldown 1`, so the lock file takes the older release, and
  record the resulting version change like any other. If Bundler reports a conflict because another
  gem needs the young version, remove the bound and tell the user which gem needs it. Then run the
  script above again.

A gem bumped to close a security alert, and any new dependency that bump brought in, is exempt, as
[Close Open Security Alerts](pins.md#close-open-security-alerts) explains.

#### Re-check the Project's Gem Holds

A project can hold a gem's Gemfile bound for a reason Bundler cannot see. For example, another gem
may activate it at runtime with `gem "<name>", …` outside its gemspec: Bundler resolves straight
past that check, and the mismatch raises `Gem::LoadError` only when that code path loads. Bundler
never moves a gem outside its Gemfile bound, so the usual failure is a hold left stale, too tight or
no longer matching what it tracks, which brings back the error the hold was set to prevent.

Read the project's `CLAUDE.md` and README for gem holds. For each, check the condition it names
against what moved in `git diff Gemfile.lock`. When the condition fired — for example "re-read the
activating line whenever `rails` moves" after a Rails bump — do what it says, reading an installed
gem's files with `bundle exec gem contents <gem>` and a `grep` for the line it names. Then either
confirm the hold still holds or put the change it needs to the user; never move a hold unasked. Note
each hold re-checked or changed for the commit message
([Step 11](#step-11-build-the-final-commit-message)) and the PR body
([Step 12](#step-12-commit-push-and-create-the-pr)).

### Step 4: Update JavaScript Dependencies

Skip this step if the repository has no `yarn.lock`. Otherwise read
`${CLAUDE_SKILL_DIR}/javascript.md` in full and follow it.

### Step 5: Decide Terraform Version Bumps

List the repository's tracked `.tf` files, leaving out the module copies `terraform init` vendors:

```bash
git ls-files --full-name ':/*.tf' ':(top,exclude)*.terraform/*'
```

It exits 0 whether or not it matched, so read its output: skip this step and Step 6 when it prints
nothing. Otherwise read `${CLAUDE_SKILL_DIR}/terraform.md` in full and follow both steps there. It
also holds the notes on why their commands are shaped as they are.

### Step 6: Re-resolve and Verify Terraform Lock Files

In `terraform.md`, after Step 5.

### Step 7: Update Tool and Image Pins

Read `${CLAUDE_SKILL_DIR}/pins.md` in full and follow it. Besides the pins, it bumps whatever closes
an open security alert, and ends with the check that stops the run when nothing changed.

### Step 8: Handle RuboCop Updates

Check the `gem_update` output or `git diff Gemfile.lock` for changes to `rubocop` or any `rubocop-*`
gem. If any changed, read `${CLAUDE_SKILL_DIR}/linters.md` and follow its Step 8.

### Step 9: Handle haml-lint Updates

Check the output or diff for changes to the `haml_lint` gem (CLI: `haml-lint`). If it changed, read
`${CLAUDE_SKILL_DIR}/linters.md` and follow its Step 9.

### Step 10: Analyze the Impact of Every Change

Read `${CLAUDE_SKILL_DIR}/impact.md` in full and follow it.

### Step 11: Build the Final Commit Message

#### Draft the Message

Launch a **documentation-expert** sub-agent (using the Agent tool) to refine the commit message.
Give it:

- The `gem_update` output from Step 3, with the Bundler and Git-sourced gem entries, any JavaScript
  dependency changes from Step 4, any tool and image pin bumps from Step 7 and every later gem or
  npm bump (release-age holds, the Bundler hold, security-alert fixes, version-locked packages),
  with each Ruby entry checked against `git diff Gemfile.lock` so a line `gem_update` printed for a
  version that no longer ships is corrected
- The conventions below, and the full contents of `${CLAUDE_SKILL_DIR}/changelogs.md` (Known
  Changelog Quirks), pasted into its prompt, so it does not rediscover a known quirk
- **Every verification result from this run** — specs run, plans run and their summary lines, usage
  audits and their conclusions and the impact file's verified findings — and the instruction that
  every behavioral claim in its prose must either cite one of these results or be phrased as what
  the changelog says. Without them it writes from the changelogs alone and can state as fact what
  this session has already shown to be false.
- The redaction list from [Write the Impact File](impact.md#write-the-impact-file), with its
  exemptions, pasted into its prompt: the verification results carry the values it forbids, and a
  commit message cannot be edited once merged
- Each gem hold re-checked or changed in
  [Re-check the Project's Gem Holds](#re-check-the-projects-gem-holds), and the result
- If Terraform changed, the evidence Steps 5 and 6 collected:
  - Each lock file's version changes against the Step 5 baseline, including transitive providers
    that no `required_providers` block names
  - The `Downloading <source> <version> for <name>` lines captured from `init -upgrade` in Step 6,
    the only record of a module bump
  - Each Git module's resolved commit SHA from Step 5

When the draft comes back, check each claim in its prose against those results before Step 12,
correct any it cannot support and remove any value the redaction list forbids.

The agent should:

1. Start with the `gem_update` output as the base for Ruby dependencies

2. **Fill in missing changelog links** — for any dependency where `gem_update` did not find a
   changelog URL, look it up:
   - Check the gem's metadata (`gem specification <name>`) for `changelog_uri`, `source_code_uri` or
     homepage
   - For npm packages, check the package's repository URL on the npm registry
   - For Terraform providers and registry modules, the registry API's `source` field names the
     repository (`curl -fsS "https://registry.terraform.io/v1/providers/$ns/$name" | jq -r .source`,
     or `/v1/modules/$ns/$name/$provider` for a module); use its releases page or changelog file. A
     Git module's changelog lives in the repository its `source` points at.
   - A Git-sourced gem keeps the `[compare]` link from Step 3 in place of a changelog
   - A tool or image pin from Step 7 links its upstream release page, minding the traps in the Known
     Changelog Quirks it was given

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

7. For each Deep dependency in the impact file's findings whose impact needs a change or is worth a
   reader knowing, add one or two sentences after the dependency list and the `yarn.lock` line (item
   5), each citing the verification that shows it. Leave out the findings whose impact is None.

8. If RuboCop or haml-lint fixes were needed (Steps 8 and 9), append to the end of the commit body,
   keeping only the sections that apply:

   ```text
   Fix the following RuboCop violations:
   - CopName: Brief description of the fix

   Fix the following haml-lint violations:
   - LinterName: Brief description of the fix
   ```

9. If a gem hold was re-checked or changed
   ([Re-check the Project's Gem Holds](#re-check-the-projects-gem-holds)), add one line per hold
   after the dependency list, naming the hold and the result

### Step 12: Commit, Push and Create the PR

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
# Plus any source files modified by bin/rubocop -A, bin/rails lint:haml or a Step 10 fix

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
image pin — needs an entry in the commit body from Step 11. Add any that is missing before going on.

Then use the `/commit` skill to create the commit. Provide the changelog body from Step 11 as
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

Create the PR with a summary body. The body is published, so no section of it may carry a value the
redaction list in [Write the Impact File](impact.md#write-the-impact-file) forbids:

```bash
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary

- Updated N Ruby dependencies and M JavaScript packages, plus P Terraform providers and modules
- [Notable updates, e.g. "Rails 8.1.1 → 8.1.2", "RuboCop 1.85 → 1.86 (with auto-fixes)"]

## Impact analysis

- [Each Deep dependency, e.g. "editor-gem 1.0.3 → 1.0.4 — needs a change: <one line of evidence>"]

## Test plan

- [ ] CI passes
- [ ] Smoke test the app locally
- [ ] [Each manual check the impact analysis recommends, e.g. "Edit a post in the browser"]
EOF
)" --assignee @me --label "<label>" --label "<label>"
```

Omit any category (Ruby, JavaScript, Terraform) that had no changes. Tailor the summary bullets to
highlight the most notable updates (major version bumps, security patches, linter upgrades that
required code changes, etc.). Also add a bullet for each of these that applies:

- **A Bundler bump** — [Step 3](#step-3-update-ruby-dependencies)
- **A gem hold re-checked or changed**, and why —
  [Re-check the Project's Gem Holds](#re-check-the-projects-gem-holds)
- **A Bundler or gem release held back** by the release-age check —
  [Check Every Moved Gem's Release Age](#check-every-moved-gems-release-age)
- **A gem or npm package that skipped a release-age gate** to close a security alert, with the alert
  and the release's date, and any new dependency it brought in —
  [Close Open Security Alerts](pins.md#close-open-security-alerts)
- **The security alerts this run closes** —
  [Close Open Security Alerts](pins.md#close-open-security-alerts)
- **Tool and image pin bumps** — [Step 7](pins.md#step-7-update-tool-and-image-pins)
- **A Rails upgrade shipping in this PR** — [Step 2](#step-2-create-the-feature-branch)

A Rails upgrade also goes in the title, as
`Upgrade Rails to <version> and update the app's dependencies - {qualifier }{Month} {Year}`. If any
Terraform providers **or modules** changed, add a
`- [ ] terraform plan shows no unexpected resource changes` checkbox to the test plan — a module
major changes inputs and outputs, which is at least as plan-visible as a provider bump.

[Step 10](impact.md#step-10-analyze-the-impact-of-every-change) fills the Impact analysis section:
one bullet per Deep dependency, giving its impact level and one line of evidence, summarized from
the impact file rather than pasted from an agent's report. Add each manual check it recommends, such
as a staging deploy for a deploy-path gem or a browser check for an editor, to the test plan as an
unticked item. Leave the section out when no dependency was Deep.

Step 4 decides what the PR body says about JavaScript. Add each that applies; a `yarn.lock` change
alone counts as a JavaScript change, so do not omit the category for it:

- **`yarn.lock` changed** — a summary bullet:
  `- Re-resolved yarn.lock so transitive dependencies take the newest versions their ranges allow`
- **No release-age gate** — the repository's Yarn is older than 4.10, so the run took releases of
  any age ([Step 4](javascript.md#step-4-update-javascript-dependencies))
- **Packages the gate moved down** — a transitive package the lock file held at a release younger
  than one day, moved back by the re-resolution, so a reviewer does not read it as a regression
  ([Step 4](javascript.md#step-4-update-javascript-dependencies))
- **The re-resolution failed** — and why, so the reviewer knows transitive dependencies did not move
  ([Step 4](javascript.md#step-4-update-javascript-dependencies))

Steps 5 and 6 also decide what else the PR body must say about Terraform. Add each that applies,
summarized and never pasted from Terraform's output, as
[Step 6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files) explains:

- **A provider or module major** — the plan's one-line summary, or, for a major the user chose to
  ship unplanned, a statement at the very top of the body that it is unplanned
  ([Step 5](terraform.md#step-5-decide-terraform-version-bumps))
- **A root module that could not be planned** — no credentials, `init -backend=false`, a module plan
  the user declined or a platform with no provider build — with the plan checkbox left unticked
  ([Step 6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files))
- **A platform that lost support** — which developers can no longer run that root module
  ([Step 6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files))
- **Root modules skipped**, and why
  ([Step 6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files))
- **Lock files not tracked**, when the repository ignores them
  ([Step 6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files))

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

Read `${CLAUDE_SKILL_DIR}/version-locked.md` in full in Step 2, once it finds a Rails upgrade in
flight, since Step 2 needs its Rails JavaScript Packages section to judge the upgrade commit, and in
any case before Step 4's restore call. Its packages span the gems Step 3 updates and the JavaScript
packages Step 4 re-resolves, and each must be handled before that re-resolution.

## Known Changelog Quirks

Read `${CLAUDE_SKILL_DIR}/changelogs.md` before Step 3. It lists the gems, packages and pins whose
changelogs or release tags need special handling, which Step 3's Bundler update, Step 7's release
lookups and Step 11's changelog links all rely on.

## Important Notes

- **Start from an up-to-date `main`**, or from a Rails upgrade the user chose to ship alongside —
  see [Step 2](#step-2-create-the-feature-branch)
- **Count this month's runs from history, not branches** — see
  [Step 1](#step-1-determine-the-branch-name-and-pr-title)
- **Every pin that moved gets a commit-message entry**, including Bundler, Git-sourced gems and tool
  and image pins — see [Step 12](#step-12-commit-push-and-create-the-pr)
- **Triage every moved dependency and read the code diff of each Deep one**, whatever its version
  number, and verify each finding before relaying it — see
  [Step 10](impact.md#step-10-analyze-the-impact-of-every-change)
- **Changelog links are required** — see [Step 11](#step-11-build-the-final-commit-message)
- **Always check for linter gem bumps**, and when one changed, finish its step before committing —
  see [Step 8](linters.md#step-8-handle-rubocop-updates) and
  [Step 9](linters.md#step-9-handle-haml-lint-updates)
- **Run `terraform init -upgrade` in every root module whenever the repo has `.tf` files** — even
  with no `.tf` edits, since range constraints and transitive providers move on their own, and a
  skipped root module leaves a stale lock file that makes `terraform plan` fail. See
  [Step 6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files).
- **Never commit a root module whose most recent `init` failed** — the `.tf` edits stand while the
  lock file does not move, producing a commit that can neither `init` nor `plan`. See
  [Step 6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files).
- **Version-locked packages** — see [Step 4](javascript.md#step-4-update-javascript-dependencies)
  and [Version-Locked Packages](version-locked.md#version-locked-packages)
- **Take no release younger than one day**, gem or npm, except to close a security alert — see
  [Step 3](#step-3-update-ruby-dependencies),
  [Step 4](javascript.md#step-4-update-javascript-dependencies) and
  [Close Open Security Alerts](pins.md#close-open-security-alerts). No gate covers a gem or npm
  package that follows a Git branch or tag or a gem from a server other than rubygems.org, nor a
  Terraform provider, registry module or Git module tag (see
  [Look Up the Latest Versions](terraform.md#look-up-the-latest-versions)), so those can move to a
  commit or release of any age; the gem and npm changes are listed for review in
  [Check Git-Sourced Gems](#check-git-sourced-gems),
  [Record the Direct Dependency Changes](javascript.md#record-the-direct-dependency-changes) and the
  release-age check's `404` and `not on rubygems.org` lines. Nor does one cover the tool, image and
  CircleCI orb pins in [Step 7](pins.md#step-7-update-tool-and-image-pins), which move to the newest
  release of any age.
- If no dependencies changed at all, inform the user and stop. A change to `yarn.lock` alone is put
  to the user first — see [Stop If Nothing Changed](pins.md#stop-if-nothing-changed).
