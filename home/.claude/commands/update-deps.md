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
1st. `-i` also catches a run whose subject begins `Upgrade Rails to … and update the app's
dependencies` (see [Step 11](#step-11-commit-push-and-create-the-pr)). Then list this month's run
branches on the remote itself, since local remote-tracking refs can be stale:

```bash
git ls-remote --heads origin "update-dependencies-*$(date +%B-%Y | tr '[:upper:]' '[:lower:]')"
```

Count a listed branch as an open run only when `git merge-base --is-ancestor <its-sha> origin/main`
exits 1. Exit 0 means it is already merged and counted above, as it is in a repository that keeps
branches after merging; exit 128 means the commit is not local yet, so `git fetch origin <branch>`
and check again.

Counting branches alone undercounts: a repository that deletes branches on merge keeps only the
runs still open, so after a merged run the check reports "first of the month" and the new run
reuses its branch name and commit subject. Add the two counts and take the qualifier for the next
run.

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
stop and ask the user whether to amend it (see [Version-Locked Packages](#version-locked-packages)).
Tell the user the upgrade's own pull request should be closed in favor of this one once it is open,
and say so in this PR's body, so the same commits cannot merge twice. Otherwise start from an
up-to-date `main`:

```bash
git checkout main && git pull
git checkout -b <branch-name>
```

### Step 3: Update Ruby Dependencies

Run `gem_update` to update all Ruby gems and get an initial draft of the dependency changes:

```bash
gem_update 2>&1 | tee /tmp/gem-update-output.txt
```

The pipeline's status is `tee`'s, so read `gem_update`'s own: `${pipestatus[1]}` in zsh,
`${PIPESTATUS[0]}` in bash, not `$?`. A non-zero value means `gem_update` failed.

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
others, and mention it in the PR summary. If it did not, Bundler is already current. See
[Known Changelog Quirks](#known-changelog-quirks) for where its release notes live.

#### Check Git-Sourced Gems

A gem pinned to a Git branch (`gem 'name', github: 'owner/repo', branch: 'main'`) follows the
branch head. It moves as a `revision:` change in the lock file's `GIT` block while its version
number stays put, so `gem_update` lists nothing:

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

Skip this step if the repository has no `yarn.lock`. Run every command in it from the repository
root, where Yarn keeps the lock file, and read the Yarn version and the repository's own release-age
gate first:

```bash
cd "$(git rev-parse --show-toplevel)"
yarn --version
yarn config get npmMinimalAgeGate
```

If `yarn --version` prints `1.x`, stop and tell the user: this step needs Yarn 2 or later, and
Yarn Classic has no `yarn up`.

#### Run Yarn with a Release-Age Gate and No Install Scripts

The commands below take the newest release of every package in the tree, including releases
published minutes ago. Every `yarn` command in this step and in
[Version-Locked Packages](#version-locked-packages) that resolves packages — `yarn up` in any form —
carries one of two prefixes, so a malicious release has had time to be caught and pulled before it
can land, and no newly resolved package runs code on this machine:

- **The gated prefix**, `YARN_ENABLE_SCRIPTS=false YARN_NPM_MINIMAL_AGE_GATE=3d`, for every command
  that can take a release the repository does not yet commit
- **The restore prefix**, `YARN_ENABLE_SCRIPTS=false`, only for putting a hold back at an exact
  version the repository already commits (see the hold restore below)

Commands that resolve nothing — `yarn --version`, `yarn config get`, `yarn why` — take neither. The
two variables:

- **`YARN_NPM_MINIMAL_AGE_GATE=3d`** skips any release younger than three days and takes the newest
  one old enough. `yarn config get npmMinimalAgeGate` printed the repository's own gate in minutes:
  drop the variable when that is `4320` or more, so a longer gate stands. A `0` is not a reason to
  drop it — a repository that turns the gate off for everyday `yarn add` still gets one during a
  dependency run. Yarn older than 4.10 has no gate, so drop the variable there and say so in the PR
  body (see [Step 11](#step-11-commit-push-and-create-the-pr)). The gate guards against taking a
  new release, which is why the restore prefix leaves it out. If it refuses a version a gated
  command needs, stop and tell the user rather than dropping the gate.
- **`YARN_ENABLE_SCRIPTS=false`** stops postinstall and build scripts. Nothing later in this command
  builds the app, so the only cost is that a package with a build step stays unbuilt until the next
  plain `yarn install` on a developer machine.

Each command runs in a fresh shell, where an `export` would not carry over, so write the prefix out
on every command.

#### Update the Direct Dependencies and Restore Holds

```bash
YARN_ENABLE_SCRIPTS=false YARN_NPM_MINIMAL_AGE_GATE=3d yarn up '*'
```

`yarn up '*'` rewrites the range of every direct dependency, in every workspace manifest, to
`^<latest>`, where `latest` is the package's `latest` dist-tag. That undoes deliberate holds in two
ways that print no warning:

- **It widens operators.** An exact pin (`3.7.1`) or a tilde (`~3.0.1`) becomes a caret (`^4.0.0`,
  `^3.0.1`)
- **It can move a package down.** When `latest` lags the tag a project tracks — a prerelease line,
  or a package whose `latest` was never moved forward — the new range names an older release
  (`1.0.0-beta.7` becomes `1.0.0-beta.4`)

Read the manifest diff for both:

```bash
git diff -- package.json '**/package.json'
```

Restore every operator that changed and every version that moved down, unless the project's
`CLAUDE.md` or README says that hold has ended; ask the user when unsure. For a prerelease or a
version that moved down, `npm view <pkg> dist-tags --json` shows which tag the project was tracking.
Then check the [Version-Locked Packages](#version-locked-packages), which name the version a hold
must take, and put every hold back in one call with the restore prefix:

```bash
YARN_ENABLE_SCRIPTS=false yarn up '<pkg>@<spec>' '<pkg>@<spec>'
```

This call leaves out the age gate on purpose. With the gate on, a hold bumped in the last three days
is quarantined, and Yarn fails the whole call over it, restoring none of the holds. An exact spec
restores a version the repository already commits, so it takes nothing new. A restored range — a
tilde, or a caret on a prerelease — can resolve to a release younger than three days; the gated
re-resolution below moves it back. A hold that must move to a version the repository does not yet
commit (a re-pin under [Version-Locked Packages](#version-locked-packages)) is a new release: run it
in its own call, with the gated prefix.

Holds can also live outside the direct ranges. A `resolutions` block in `package.json` survives the
re-resolution below. A hold the lock file alone keeps — a transitive package left below its newest
release with no `resolutions` entry — does not, so if the project's `CLAUDE.md` or README documents
one, ask the user whether to move it into `resolutions` before going on.

#### Re-resolve the Lock File

`yarn up '*'` re-resolves direct dependencies only. A transitive dependency whose range did not
change keeps the version the lock file already records, even when a newer release satisfies it. Once
every manifest holds its final ranges, re-resolve every range in the lock file:

```bash
YARN_ENABLE_SCRIPTS=false YARN_NPM_MINIMAL_AGE_GATE=3d yarn up -R '*'
```

That is the gated prefix. `-R` re-resolves every range matching the pattern, transitive ones
included, and leaves the manifests alone. It produces the same lock file as deleting `yarn.lock` and
reinstalling, without the moment where the repository has none. A `resolutions` block still applies.
Under the age gate, a transitive package the lock file holds at a release younger than three days
moves back to the newest one old enough; that is the gate working, not a regression to report.

If it exits non-zero, `yarn.lock` still holds the result of the commands above, including any
restored range the ungated restore resolved. If any restored hold is a range, re-run those restores
in one call with the gated prefix, and tell the user if the gate refuses one. Then tell the user the
re-resolution failed and why, note it for the PR body (see
[Step 11](#step-11-commit-push-and-create-the-pr)) and carry on with the hold check and Record the
Direct Dependency Changes below, which work from the lock file as it stands. If the error is
`YN0028` (the lockfile would be modified), Yarn has turned on immutable installs because it believes
it is running in CI; retry once with `YARN_ENABLE_IMMUTABLE_INSTALLS=false` added to the prefix.

Re-resolve here, before the changelog and commit steps (Steps 10 and 11), so they work from the
lock file that ships.

Then check that every hold survived. For each version-locked package and each hold restored above,
list every resolved copy:

```bash
yarn why <pkg>
```

Every copy should be at the held version. If the held package itself moved, restore it with `yarn up
'<pkg>@<spec>'` and the restore prefix, and repeat the check. A second copy at another version is
reported to the user, not worked around: a transitive range the hold used to satisfy can now resolve
higher — a `jquery: >=1.11` dependency taking jQuery 4 beside a held 3.7.1 — and only the user can
say whether it needs a `resolutions` entry.

#### Record the Direct Dependency Changes

The `yarn.lock` diff is now mostly transitive changes, so start from the manifests. Every direct
dependency whose range changed is listed by:

```bash
git diff -- package.json '**/package.json'
```

For each, read the old and new `version:` of its entry — the line beginning `"<name>@npm:` — in
`git diff yarn.lock`, and skip any whose resolved version did not change. Then look for direct
dependencies that moved without a manifest change: those sourced from Git or a URL follow a branch
or tag, and only their lock entry shows it:

```bash
git diff yarn.lock | grep -E '^\+  resolution: ' | grep -vE '@(npm|workspace|patch):'
```

Record each line that names a direct dependency as a direct change.

Only direct dependencies appear in the commit message's dependency list — leave transitive changes
out. When `yarn.lock` changed at all, [Step 10](#step-10-build-the-final-commit-message) adds one
line saying the lock file was re-resolved, which stands in for them.

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
files. Every command in both steps must run from the repository root — the `git` queries print
root-relative paths, and the `terraform -chdir` and `git status` commands that consume those paths
break anywhere else — so start by going there:

```bash
cd "$(git rev-parse --show-toplevel)"
git ls-files --full-name ':/*.tf' ':(top,exclude)*.terraform/*'
```

This exits 0 whether or not it matched, so read its output rather than its status. It does not see
`.tf.json` files, untracked files or files inside submodules; handle those by hand in the rare repo
that has them. The exclude keeps the module copies that `terraform init` vendors into `.terraform/`
out of every listing in this step, matching Steps 6 and 11 — without it you can end up editing a
vendored copy that Step 11 then refuses to stage. See
[Terraform Update Notes](#terraform-update-notes) for why the pathspecs and flags in this step are
written the way they are.

#### Find the Current Pins

```bash
git grep -nE --full-name -A3 '^[^#]*required_providers' -- ':/*.tf' ':(top,exclude)*.terraform/*'
git grep -nE --full-name -A3 '^[[:space:]]*module[[:space:]]' \
  -- ':/*.tf' ':(top,exclude)*.terraform/*'
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
git grep --full-name -A2 -e '^provider "' -- ':/*.terraform.lock.hcl' ':(top,exclude)*.terraform/*'
```

`-A2` rather than `-A1`: `constraints` is the line after `version`, and Step 6 asks you to check
both against this baseline. Keep the file prefixes and both captured lines — do not collapse them
with `-h | sort -u`. Without the version you cannot see a provider move at all, and without the
filename you cannot tell apart two root modules that pin the same provider at different versions.
Anything here that is not in a `required_providers` block is transitive: you cannot pin it directly,
but a module bump can move it, so include any version change it undergoes in the commit message.

#### Look Up the Latest Versions

Terraform has no `bundle outdated` equivalent, so query the registry directly for each provider.

Every placeholder in this step is filled from a string read out of a checked-in `.tf` file, so treat
those strings as untrusted input. HCL string literals accept arbitrary characters, and a `source` of
`hashicorp/aws$(...)` substituted into an unquoted URL runs the substitution before `curl` is ever
invoked. Terraform would reject that address, but you read and use it *before* `init` runs, so
Terraform's validation is never the gate. Assign each value to a variable, quote every use and
validate it first against these patterns (`grep -E` syntax):

- **Provider `<namespace>` and `<name>`** — `^[A-Za-z0-9][A-Za-z0-9-]*$`. This also catches
  unresolved interpolation (`${var.ns}/aws`) and trailing whitespace, which would otherwise 404
  confusingly.
- **Module `<namespace>` and `<name>`** — `^[0-9A-Za-z]([0-9A-Za-z_-]*[0-9A-Za-z])?$`, and the
  module's `<provider>` — `^[0-9a-z]{1,64}$`. Module names allow underscores where provider names do
  not (`aws-ia/vpc_endpoints/aws` is a real registry module), following
  `moduleRegistryNamePattern` in `hashicorp/terraform-registry-address`.
- **A Git module URL** — `^(https://|git@)[A-Za-z0-9._@:/-]+$`, applied to the repository URL
  rather than the whole `source`. Extract it first: strip a leading `git::`, then everything from
  the first `?`, then any `//subdirectory` that follows the repository path (the `//` after
  `.git` or the repository name, not the one in `https://`). From
  `git::https://github.com/org/repo.git//modules/foo?ref=v1.2.3` that leaves
  `https://github.com/org/repo.git`. Validate the `ref=` value on its own: a version tag must match
  `^v?[0-9]+(\.[0-9]+)*$`, the same filter the tag lookup below applies, and a commit SHA must
  match `^[0-9a-f]{7,40}$`.
- **`<terraform-directory>`** — `^[A-Za-z0-9._/ -]+$`. An allowlist, because a denylist misses
  characters: a committed directory named `x">out"` closes the quotes in
  `terraform -chdir="x">out""` and redirects the command's output into a file. Quoting alone is not
  enough either: `terraform -chdir="$(id)"` still substitutes inside double quotes, and `$(id)` is a
  legal committable directory name. Better still, assign the directory to a variable and pass
  `-chdir="$dir"`, so no substituted text is ever parsed as shell syntax.

Anything that fails these is not a dependency you can look up automatically — stop and report it
rather than working around it.

The block's `source` value supplies `<namespace>/<name>`. Strip the hostname only when it is exactly
`registry.terraform.io`; any other hostname means a private registry, so skip that provider rather
than stripping the host — the public registry may answer for the same `<namespace>/<name>` with an
entirely unrelated provider. A bare two-part source (`source = "hashicorp/aws"`, the common case)
has no host to strip and is always the public registry:

```bash
ns=hashicorp name=aws   # from the block's source, both validated as above
curl -fsS --max-time 10 "https://registry.terraform.io/v1/providers/$ns/$name" \
  | jq -er '[.versions[] | select(test("^[0-9]+(\\.[0-9]+)*$"))]
            | sort_by(split(".") | map(tonumber))
            | last // error("no stable release found")'
```

Do not use the response's `.version` field: it includes prereleases, and Terraform will pin to one
without complaint. The filter above discards prereleases and sorts numerically, so `2.100.0`
correctly beats `2.99.1`.

Registry modules answer the same way at
`"https://registry.terraform.io/v1/modules/$ns/$name/$provider"` — and **the hostname rule
above applies here too**. Module source addresses carry an optional host in the same leading
position, so `app.terraform.io/acme/vpc/aws` and `tfe.internal/platform/vpc/aws` are both valid.
Query the public registry only for a bare three-part source or one prefixed with exactly
`registry.terraform.io`; for anything else, skip the module rather than dropping the host. Reducing
`tfe.internal/acme/vpc/aws` to `acme/vpc/aws` either 404s or, worse, returns the version of an
unrelated public module to be written into a private module's pin. Modules with a local path source
(`source = "../../modules/network"`) are versioned by this repository — skip them.

Modules sourced from Git (`source = "git::https://github.com/org/repo.git//modules/foo?ref=v1.2.3"`)
or a private registry have no public version API. List the repository's version tags and bump the
`ref=` value directly. That is only right when the existing `ref=` is a version tag; a commit SHA, a
branch name or a missing `ref=` each need different handling, which the Modules table under Bump the
Pins gives:

```bash
url=https://github.com/org/repo.git   # extracted from source and validated as above
if ! tags=$(git ls-remote --tags --refs "$url"); then
  echo "STOP: ls-remote failed - do not record this as 'no tags'" >&2
  exit 1
fi
printf '%s\n' "$tags" | sed 's|.*refs/tags/||' \
  | grep -E '^v?[0-9]+(\.[0-9]+)*$' \
  | awk '{k=$(0); sub(/^v/,"",k); n=split(k,p,".")
          key=""; for (i=1; i<=4; i++) key=key sprintf("%09d", (i<=n ? p[i] : 0))
          print key, $(0)}' \
  | LC_ALL=C sort | tail -1 | awk '{print $(2)}'
```

Use the pipeline as written rather than `git ls-remote --sort=-v:refname` or `sort -t.`, both of
which can rank an older tag first. Keep its two outcomes apart. A non-zero `ls-remote` is a
**lookup failure** — a network outage, a private-repo 403, a mistyped URL — and you must stop and
report it, never record it as "no update available". Only when `ls-remote` succeeds and the filter
still prints nothing does the repository genuinely have no version tags; leave the `ref=` alone and
say so rather than guessing. The pipeline prints the **tag as it actually exists**, so use its
output verbatim in `ref=` and never re-derive the `v` prefix from the existing `ref=`. Treat a
module major like a provider major — skim the repository's release notes first, since module inputs
and outputs change across majors.

Know what a `ref=` bump is worth as a pin, because it is the weakest one in this workflow. A tag is
mutable and force-pushable, so a module repository whose release tag is moved delivers different
code under an unchanged `ref=` on the next `init` — and unlike a provider, there is no checksum
recorded anywhere to notice it. A reviewer looking at `ref=v1.2.3 → ref=v1.4.0` has no artifact to
verify against. For modules you do not control, resolve the tag to its commit SHA and record that
SHA in the commit message, so the review has something fixed to point at. `--refs` hides the line
you need, so query the tag without it:

```bash
git ls-remote --tags "$url" "refs/tags/$tag" "refs/tags/$tag^{}"
```

Take the ID from the `^{}` line. A release is usually an annotated tag, whose own line holds the tag
object's ID rather than the commit's; only the peeled `^{}` line holds the commit. A lightweight tag
has no `^{}` line, and the ID on its own line is already the commit.

#### Bump the Pins

Confirm the CLI is available before editing anything: `terraform version` should print a version and
exit 0. If it is not on `PATH` you get exit 127; under a version manager you may instead get a shim
error such as `mise ERROR No version is set for shim: terraform`.

A shim error does not always mean a missing CLI. When the version is pinned in a mise file
(`mise.toml`, `.mise.toml`) or `.tool-versions` *below* the repository root — beside the Terraform
configuration, say — the shim resolves no version from the root but works from that directory. Look
for one first:

```bash
git ls-files --full-name ':/*mise.toml' ':/*mise/config.toml' ':/*.tool-versions'
```

If one sits above the Terraform directory, the CLI is fine and only the working directory is wrong.
Run every `terraform` command in Steps 5 and 6 from that directory in a subshell, with `-chdir`
relative to it, so the rest of the step stays at the root — for a pin in `infra/mise.toml` and a
root module at `infra/prod`, `(cd infra && terraform -chdir=prod version)`. The `git` queries keep
their `:/` prefix, which already works from any directory.

If no such file explains it, stop and tell the user rather than making `.tf` edits you cannot
re-resolve — and if you have already made them, revert them first:

```bash
git restore --source=HEAD --staged --worktree -- <the exact .tf files you edited>
git clean -f -- <any .tf files you created>
```

Name the exact files — never a glob, never a directory — and do not use `git checkout --` in place
of this pair. Scope matters: by this point the changes from Steps 3 and 4
(`Gemfile.lock`, `yarn.lock` and any `Gemfile` or `package.json` edits for version-locked packages)
are uncommitted, and a broad revert discards them with no reflog to recover from.

Having the CLI is not the same as having a *usable* one, so check what the configuration will accept
from it:

```bash
git grep -nE --full-name 'required_version' -- ':/*.tf' ':(top,exclude)*.terraform/*'
```

If any `required_version` excludes the installed CLI, every `init` in that module fails before it
does any provider work, with `Error: Unsupported Terraform Core version`. Install a CLI the
configuration accepts, or stop and tell the user which version is needed. **Never widen or bump
`required_version` to make the error go away.** It is a deliberate constraint on which Terraform may
touch that state, it is not a dependency this command updates and changing it during a routine
dependency refresh buries an infrastructure decision in a bump PR.

Compare each result against the version in the constraint, numerically field by field rather than as
strings. What to do next depends on the form of the pin — and providers and modules follow different
rules, so read them from separate tables.

**Providers** — `required_providers` entries:

| Constraint form | Example | Action |
| --- | --- | --- |
| Exact pin, no operator | `version = "2.99.0"` | Edit the `.tf` file to the new version. `init -upgrade` cannot advance an exact pin on its own, so skipping this means the provider never updates. |
| Range | `~> 2.99`, `>= 2.5` | Edit only if the new release falls outside the range; otherwise `init -upgrade` picks it up with no `.tf` change. |
| No `version` at all | only a `source` line | Nothing governs it. `init -upgrade` takes the newest release published, crossing majors with no `.tf` diff and no `constraints` line recorded. Check the lock file's `version` before and after. |

**Modules** — `module` blocks, in the root module and in child modules alike:

| Module `source` | Example | Action |
| --- | --- | --- |
| Local path | `source = "../../modules/net"` | Versioned by this repository — leave it alone. A local-path module cannot carry a `version` argument at all; Terraform rejects one with `Error: Invalid registry module source address`. |
| Registry, with `version` | `source = "cloudposse/label/null"`, `version = "~> 0.24.0"` | Same two rules as a provider constraint: edit an exact pin, and edit a range only if the new release falls outside it. |
| Registry, no `version` | `source = "cloudposse/label/null"` | Nothing governs it, and `init -upgrade` takes the newest stable release, crossing majors silently. Add an explicit constraint rather than leaving it open. |
| Git `ref=` | `source = "git::https://github.com/org/repo.git//modules/foo?ref=v1.2.3"` | A version tag: edit the `ref=` to the new tag. A commit SHA: keep a SHA, moving it to the peeled commit of the newer release tag, since replacing it with a tag weakens the pin. A branch name or no `ref=` at all: leave it alone and report it, since moving it to a tag changes what the pin means. |

Do not carry provider-shaped verification over to the module tables: a module bump leaves no
lock-file diff to check, so [Step 6](#step-6-re-resolve-and-verify-terraform-lock-files) captures
its evidence from the `init` output instead.

Count the constraint's segments before deciding "outside" a range. `~>` lets only the right-most
component given increase, so `~> 2.99` means `>= 2.99, < 3.0` — it admits `2.99`
and every later `2.x`, which makes `2.100.0` **inside** it and `2.5.0` outside — while `~> 2.99.0`
admits only `2.99.x`.

Several things can cross a major version boundary in one step. For providers: replacing an exact
pin with the registry's latest, letting an unbounded range such as `>= 2.5` drift forward and a
root-module bare `source`. The latter two are the more dangerous, because no `.tf` line changes —
the only trace is a `version` line in the lock file diff, which is easy to skim past. For modules: a
registry module with no `version`, which `init -upgrade` moves across majors silently and which
leaves no lock-file trace at all, and a Git `ref=` bump to a new major tag. Skim the provider's or
module's release notes for breaking changes before taking a major bump in any of these cases.

Your own reading of the release notes is not the checkpoint, though — it is preparation for one. A
provider or module major does not get committed on your judgment alone: **stop and ask the user
before committing one**, and say which resources the release notes flag as requiring replacement. If
[Step 6](#step-6-re-resolve-and-verify-terraform-lock-files) managed to run a plan, quote its
summary line — `Plan: 0 to add, 3 to change, 0 to destroy` — in the PR body. If it could not, offer
the user the two honest options: drop the major and keep the minor bumps, or open the major as its
own PR whose body says plainly at the top that it is unplanned. An unplanned major that reads like a
routine bump is the worst outcome this workflow can produce, and the rest of this step exists to
catch it.

Do not decide whether to skip [Step 6](#step-6-re-resolve-and-verify-terraform-lock-files) from
Step 5's results — that condition is not decidable from the data Step 5 gathers. A range constraint
can move with no `.tf` edit, and a transitive provider pulled in by a child module never appears in
Step 5's greps at all, so "nothing has a newer version available" is exactly the case Step 6 exists
to catch. Skip Step 6 only when the repo has no `.tf` files. Otherwise run it even when you made no
`.tf` edits, and let its result decide: if `init -upgrade` leaves every lock file unchanged, then
there is nothing to commit.

### Step 6: Re-resolve and Verify Terraform Lock Files

**Never commit a root module whose most recent `terraform init` exited non-zero.** A failed `init`
leaves the lock file untouched while your Step 5 edits stand, and staging that pair produces a
commit that can neither `init` nor `plan`. The rule is per root module: fix the failure and re-run,
or revert that root module's changes as described below. Root modules whose `init` succeeded are
unaffected, and so are the Ruby and JavaScript updates.

Read the error before deciding what to do.

`no available releases match the given constraints` or any HCL syntax error means the edit you just
made is wrong — fix it in place and re-run.

`does not have a package available for your current platform` is a different animal and does **not**
mean your edit is wrong. It usually means the provider publishes no build for the platform you are
on, commonly `darwin_arm64`. Do not revert a legitimate bump over it and do not hand-edit the lock
file. Do not name the missing platform in `providers lock` either: a `-platform` with no build makes
the whole command fail and write nothing. Record the hashes for the platforms that do have builds:

```bash
terraform -chdir="<terraform-directory>" providers lock -platform=linux_amd64
```

Adapt that platform list rather than copying it: it must name every other platform that runs
Terraform against this repository — each developer machine plus CI, which is `linux_amd64` on GitHub
Actions and CircleCI unless the job asks for an ARM runner. The example assumes x86 Linux CI is the
only other platform. A platform you omit here is one whose hashes the lock file will not carry.

Nobody on the missing platform can `init` or `plan` this root module afterwards, and that includes
you, so the plan below cannot run here either. Tell the user which platform lost support, and offer
a provider version that does publish a build for it as the alternative to keeping the bump. If they
keep it, say in the PR body that developers on that platform cannot run this root module.

If the provider genuinely publishes nothing for any platform you need, report it as unavailable
rather than working around it.

Only stop for failures you cannot resolve locally. Stopping means dropping that root module's
Terraform work, not abandoning the run: revert that root module's `.tf` edits and any lock-file
changes with the `git restore`/`git clean` pair from
[Step 5](#step-5-decide-terraform-version-bumps), naming the exact files, then **continue with
Steps 7–11 for the remaining updates**. Say in the PR body which root modules were skipped and
why, and omit the `terraform` label if no Terraform change remains. `gem_update` and `yarn up` have
already rewritten the tree by this point, and those updates are validated and worth shipping.
Abandon the whole run only when the tree cannot be returned to a consistent state.

Leave `.terraform/` alone either way. You cannot tell whether the failed run created it or merely
wrote into one that was already there — Terraform does not report that — and it is not a disposable
cache: it holds the selected workspace name in `.terraform/environment` and the initialized backend
configuration in `.terraform/terraform.tfstate`. Deleting it silently drops the operator back to the
`default` workspace, so the next `terraform apply` they run believing they are on `staging` is not.
[Step 11](#step-11-commit-push-and-create-the-pr) already excludes `.terraform/` from the commit, so
removing it buys nothing. If the repository does not gitignore it, say so in your report and let the
user decide.

You **must** run `terraform init -upgrade` in **every** root module, not only the ones whose `.tf`
files changed in Step 5. A range constraint updates without any `.tf` edit at all, so a list built
from changed files would skip exactly those modules. Root modules usually own a lock file, so start
there:

```bash
git ls-files -z --full-name ':/*.terraform.lock.hcl' ':(top,exclude)*.terraform/*' \
  | xargs -0 -n1 dirname | sort -u
```

Child modules never own a lock file, so this excludes them automatically. The `-z`/`-0` pair matters
— plain word splitting mangles paths containing spaces into directories that do not exist — and the
exclude keeps vendored copies under `.terraform/` from being mistaken for root modules.

**An empty result here does not mean there is nothing to do.** In a repo where Step 5 found `.tf`
files, an empty or short listing means one of three things:

- A root module that declares no providers never gets a lock file — and its `module` versions are
  exactly the ones Step 5 just edited.
- The repository gitignores `.terraform.lock.hcl`, so `git ls-files` reports none of them.
- The root module is brand new and has never been initialized.

All three end the same way: `init -upgrade` is silently skipped *after* Step 5 has already edited
`.tf` files, which is precisely the commit this step opens by forbidding. So whenever the lock-file
listing comes back empty, or returns fewer directories than the repo plainly has, enumerate the
candidates instead:

```bash
git ls-files -z --full-name ':/*.tf' ':(top,exclude)*.terraform/*' \
  | xargs -0 -n1 dirname | sort -u
```

Treat a candidate as a root module if it declares a `backend` or `cloud` block, declares a
`provider` block or is simply a directory you would run `terraform apply` in, and run
`init -upgrade` in every one. If the repo clearly uses providers but tracks no lock files at all,
check `.gitignore` and say in the PR body that lock files are not tracked — otherwise Step 11's
`git add -- ':/*.terraform.lock.hcl'` aborts with `fatal: pathspec … did not match any files` and
leaves your `.tf` changes unstaged.

Run this once per root module, quoting the directory in case it contains spaces:

```bash
terraform -chdir="<terraform-directory>" init -upgrade -input=false
```

Check the exit status, not just the output — and do not pipe `init` or `plan` into `tail` or `grep`
to shorten it. A pipeline's status is its last command's, so `… | tail -8; echo $?` prints `0`
whatever `init` did, and a shim error on stderr never reaches the pipe at all. Run it unpiped, or
read the first command's own status (`${pipestatus[1]}` in zsh, `${PIPESTATUS[0]}` in bash), and
then confirm with the lock-file check below either way. A successful run exits 0 and reports
"Terraform has been successfully initialized!" — and, when a provider selection actually moved, also
notes that it changed the selections recorded in `.terraform.lock.hcl`. A module bump succeeds
without that second message, which is expected rather than a sign the run did nothing — the lock
file records nothing about modules. Its evidence is the `Downloading <source> <version> for <name>`
line in the output instead. Copy that line out as you go: no file in the repository will show that
the module moved, so it is the only thing [Step 10](#step-10-build-the-final-commit-message) has to
cite.

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

`Currently selected workspace "default" does not exist` is not a dependency failure either. A
backend that declares `workspaces { prefix = … }` has no `default` workspace, so in a checkout whose
`.terraform/environment` names none, every `init` stops there, with or without `-backend=false`. Do
not `terraform workspace select` past it: that writes `.terraform/environment` and changes which
state the operator's next command touches, for the reason the `.terraform/` warning above gives. If
`init` cannot get past it, drop that root module's Terraform work as described above.

Read the lock file diff, but be clear about what it can tell you. The `version` and `constraints`
lines and the set of `provider "<host>/<namespace>/<name>"` blocks are checkable — confirm each
version matches the pin you wrote, and that no provider block or registry hostname appeared that you
did not expect. Diff it against the baseline you captured in Step 5, since a module bump can move a
provider that no `required_providers` block mentions. The `h1:`/`zh:` hash lines are not checkable:
`-upgrade` discards the previously trusted hashes and records whatever the registry serves now, so a
substituted package would look entirely normal here. Do not treat scanning the hashes as
verification.

What the hash lines *can* tell you is whether you just narrowed the lock file's platform coverage.
When a version moves, `-upgrade` records an `h1:` for the platform you are on and no other, so a
lock file built for both macOS and Linux comes back covering only yours. Nothing fails locally; a CI
job running `init -lockfile=readonly` on Linux does, and the usual remedies for that — deleting the
lock file, or adding `-upgrade` to CI — throw away pinning entirely. Count before and after:

```bash
grep -c 'h1:' "<terraform-directory>/.terraform.lock.hcl"
```

If the count dropped, restore the coverage rather than committing the narrowed file:

```bash
terraform -chdir="<terraform-directory>" providers lock \
  -platform=darwin_arm64 -platform=linux_amd64
```

Where credentials are available, run a plan in each affected root module before opening the PR — a
provider major can turn an in-place update into a destroy-and-recreate, and the plan diff is the
only thing that surfaces that.

Planning runs code that nobody has reviewed yet. `plan` reads data sources, and an `external` data
source runs whatever program the module names, with the credentials the session holds. `init`
checks provider packages against their signatures but checks nothing about module code, so a moved
tag or a compromised module release runs during the plan. So before planning a root module, check
which of its modules this run bumped:

- **No module bumped, or every bumped module comes from a source the user controls** — plan
  without asking. Provider-only bumps fall here, since their packages are signature-checked
- **Any other module bumped** — stop and ask the user before planning that root module, naming each
  such module, its old and new version and the credentials the session holds. If they decline,
  treat the root module as one you could not plan

A bare `plan` often has no credentials, because the repository loads them through its own wrapper —
a script under any `scripts/` or `bin/` directory, a `Makefile` target or whatever the project's
`CLAUDE.md` or README names — which may also write gitignored variable files the plan needs. Look
for one first:

```bash
git ls-files | grep -iE '(^|/)(scripts|bin)/[^/]*terraform'
```

Read it, and plan through it, using only its plan action. Otherwise plan directly:

```bash
terraform -chdir="<terraform-directory>" plan -input=false -lock=false
```

`-lock=false` matters here: `plan` takes a state lock by default, and a dependency PR has no
business contending with a real `apply` that a colleague may be running. Pass it through the
wrapper too if the wrapper accepts plan flags.

A plan shows drift as well as the bump. When it reports changes, compare each one against the
release notes of every version crossed. A change no release note explains — a firewall rule someone
added through a provider's console, say — is existing drift, not an effect of the bump. Report it
separately in the PR body, so the plan checkbox speaks only to what the bump does.

`plan` needs real provider and backend credentials, so `No valid credential sources found` or
`Backend initialization required` where they are absent is not a dependency problem. `Error:
Inconsistent dependency lock file` **is** one — it means `init -upgrade` did not run or did not
succeed in that directory, so go back and re-run it rather than waving the failure through. When you
cannot plan at all, say so in the PR body and leave its checkbox unticked rather than skipping it
silently.

**Summarize Terraform output in the PR body and the commit message — never paste it raw.** Backend
and credential errors are not generic: they embed account IDs, IAM principal ARNs and state bucket
names. A successful plan is no safer, since it prints every attribute the provider did not mark
`Sensitive`. None of that is a credential, but all of it is reconnaissance, and a PR body is
permanent and public to everyone with repository access. "Could not plan `infra/prod` — no backend
credentials in this environment" is the entire message. To evidence the plan checkbox, quote the
one-line summary (`Plan: 0 to add, 3 to change, 0 to destroy`) and nothing else.

Then stage the lock file along with the `.tf` changes (see
[Step 11](#step-11-commit-push-and-create-the-pr)), and record each version change for the commit
message (see [Step 10](#step-10-build-the-final-commit-message)).

### Step 7: Update Tool and Image Pins

Many repositories pin versions where no package manager looks: a tool version manager, CI and
Compose image tags, provisioning roles. Left out of the run they go stale silently; bumped by hand
and left out of the commit message, they ship unrecorded. List the candidates:

```bash
git ls-files --full-name ':/*mise.toml' ':/*mise/config.toml' ':/*.tool-versions' \
  ':/*.node-version' ':/*.nvmrc' ':/*requirements.yml'
git grep -nE --full-name '^[[:space:]]*(-[[:space:]]+)?image:' -- ':/.circleci/*.yml' \
  ':/.github/workflows/*.yml' ':/.github/workflows/*.yaml' ':/*docker-compose*.y*ml' \
  ':/*compose.y*ml'
git grep -niE --full-name '^[[:space:]]*FROM[[:space:]]' -- ':/*Dockerfile*' ':/*Containerfile*'
git grep -nE --full-name '^[[:space:]]*[a-z0-9_]+_version:[[:space:]]' -- ':/*.yml' ':/*.yaml'
```

`git ls-files` exits 0 either way, and `git grep` exits 1 when it finds nothing, which is not an
error here; read the output. The optional list dash in the `image:` pattern is what catches
CircleCI, which lists its Docker images as sequence items (`- image: cimg/ruby:<tag>`). A Dockerfile
base image is a pin like any other; one written as `FROM ruby:${RUBY_VERSION}` takes its version
from an `ARG` line, so bump it there.

The last search lists every YAML key ending in `_version`, wherever it lives, such as an Ansible
`redis_version: 8.10.2`. Bump only a value that pins which release of a third-party tool or service
gets installed. Skip a value built from Jinja `{{ }}` or set to `latest`; the `min_ansible_version`
key in a role's `meta/main.yml`, which states the Ansible version the role needs; the project's own
version in a docs or site config; and a CI matrix or per-environment set that lists several versions
on purpose, which does not move together.

Add any other pin the project's `CLAUDE.md` or README names.

For each pin, look up the newest stable upstream release and bump to it, following these rules:

- **The same pin in several files moves together.** An image tag that appears in both the CI config
  and the Compose file, or a tool pinned in two mise files, takes one version everywhere
- **An image or variable that names a language runtime follows that runtime's version file.** A
  Ruby image (`cimg/ruby`, `ruby`) or a `ruby_version` variable stays at `.ruby-version`'s version
  and is left alone with it; a Node image (`cimg/node`, `node`) or a `nodejs_version` or
  `node_version` variable moves only with `.node-version` or `.nvmrc`, to the same version. Bumping
  one alone runs CI or a server on a runtime the app does not pin
- **A major waits for the user.** Bump within the current major without asking. Stop and ask before
  a major, naming what its release notes say breaks, as
  [Step 5](#step-5-decide-terraform-version-bumps) does for a Terraform major
- **A major-only pin moves only by a major.** A pin such as `"18"`, `"9.x"` or `node = "22"`
  already admits every release in its major, so there is nothing to bump within it; a major bump
  waits for the user like any other
- **A Terraform CLI pin must still satisfy every `required_version`** found in Step 5. Never widen
  `required_version` to fit a new CLI
- **Leave `.ruby-version` and CI orb versions alone** unless the user asks: a Ruby upgrade is its
  own change, and orbs follow their own release process

Two lookup traps are recorded under [Known Changelog Quirks](#known-changelog-quirks): tags that do
not start with a digit, and release pages that only point elsewhere.

Record every bump for the commit message with its upstream release notes, in the same format as the
other entries. [Step 11](#step-11-commit-push-and-create-the-pr) checks that every staged pin
change has one.

#### Verify the Bumps

After bumping a mise pin, install it and run it from the directory that holds the pin — `mise
install`, then `<tool> --version`, which should print the new version. If the Terraform CLI moved,
Steps 5 and 6 ran `init` and any plan with the old one, so re-run Step 6's `init -upgrade` in every
root module with the new CLI, and plan again wherever Step 6 did. Otherwise the lock files and plan
in the PR come from a CLI it no longer pins.

A provisioning pin cannot be run here, and the role that reads it installs from its own source — an
apt or yum repository, a vendor package repository or a download URL — which can lag the newest
upstream release or name it differently. Before bumping one, confirm the new version exists where
the role's tasks install from. Then add an unchecked
`- [ ] Provision a host with the new <service> version` item to the PR's test plan, since nothing
in this run exercised it.

#### Close Open Security Alerts

Check the repository's open security alerts, so the run neither closes one silently nor skips the
one bump that would close it:

```bash
gh api 'repos/{owner}/{repo}/dependabot/alerts?state=open' --paginate \
  --jq '.[] | [.number, .dependency.package.name,
               (.security_vulnerability.first_patched_version.identifier // "no fix")] | @tsv'
```

Bump anything with a fix that this run has not already reached, like any other update: a gem with
`bundle update <gem> --conservative`, a transitive npm package with the gated
`yarn up -R '<pkg>'` and a direct one with the gated `yarn up '<pkg>'` (both from
[Step 4](#step-4-update-javascript-dependencies)). If the fix lies outside every range that holds
the package, tell the user rather than adding a `resolutions` entry. Record each bump like any
other, and note every alert the run closes for the PR summary in
[Step 11](#step-11-commit-push-and-create-the-pr). Never dismiss an alert without the user's
say-so. A `403` or `404` means alerts are off or out of reach for this token; say so and carry on.

#### Stop If Nothing Changed

Steps 3 through 7 are the only steps that update dependencies, so whether there is anything to ship
is known now. If `git status --porcelain` prints nothing, tell the user that no dependency moved,
offer to delete the empty branch from [Step 2](#step-2-create-the-feature-branch) and stop here. If
it lists only `yarn.lock` — no gem, direct package, Terraform pin or tool pin moved, only the
transitive dependencies Step 4 re-resolved — ask the user whether to ship a lock-file-only refresh.
If they decline, run `git restore yarn.lock`, offer to delete the branch and stop.

### Step 8: Handle RuboCop Updates

Check the `gem_update` output or `git diff Gemfile.lock` for changes to `rubocop` or any `rubocop-*`
gem. Which of them changed decides how much of this step to run.

If `rubocop` itself was updated, whether or not any plugin was too:

1. Run `bin/rubocop -A` to auto-fix any new violations.
2. Review the output for violations that could not be auto-fixed and manually fix them.
3. After **all** violations are resolved, regenerate `.rubocop_todo.yml` (if it exists). Blank it
   first: `.rubocop.yml` inherits from the todo, so regenerating it in place treats every offense
   it excludes as already handled and writes a todo with no rules — un-grandfathering them all, so
   a plain `bin/rubocop` fails even though `bin/rubocop -A` just reported clean:

   ```bash
   printf '# Placeholder\n' > .rubocop_todo.yml
   bin/rubocop --auto-gen-config --auto-gen-only-exclude --exclude-limit 1000
   bin/rubocop   # must still report no offenses
   ```

   The diff should be the header (version and timestamp) plus any real shrinkage. If `bin/rubocop`
   reports offenses, the regeneration lost exclusions: restore the file with
   `git restore .rubocop_todo.yml` and investigate before going on.
4. Note the RuboCop fixes for inclusion in the commit message body (see Step 10).

If only `rubocop-*` plugins were updated (for example `rubocop-rails`), run items 1, 2 and 4 but
**not** item 3. The `.rubocop_todo.yml` header records only the core RuboCop version, so
regenerating it after a plugin-only bump changes nothing but the timestamp. If a regeneration
happened anyway, restore the file rather than committing the timestamp-only diff:

```bash
git restore --source=HEAD --staged --worktree .rubocop_todo.yml
```

A clean `bin/rubocop -A` run exits 0 and reports "no offenses detected" or lists only auto-corrected
offenses. Any remaining offenses must be fixed manually before proceeding.

### Step 9: Handle haml-lint Updates

Check the output or diff for changes to the `haml_lint` gem (CLI: `haml-lint`).

If haml-lint was updated:

1. Run `bin/rails lint:haml` and manually fix any violations.
2. If `.haml-lint_todo.yml` exists, regenerate it and confirm afterwards:

   ```bash
   bin/haml-lint --auto-gen-config --auto-gen-exclude-limit 1000
   bin/rails lint:haml   # must still report no offenses
   ```

   Unlike `.rubocop_todo.yml` in [Step 8](#step-8-handle-rubocop-updates), the haml-lint todo
   survives an in-place regeneration, so it needs no blanking first. The regeneration can exit
   non-zero over a file the `lint:haml` task does not lint, such as a generator template under
   `lib/templates/`; judge it by `bin/rails lint:haml`.

   Then edit line 2 of `.haml-lint_todo.yml` to replace the full regeneration command (which
   includes all flags and options) with just:

   ```text
   # `bin/haml-lint --auto-gen-config --auto-gen-exclude-limit 1000`
   ```

3. Note the haml-lint fixes for inclusion in the commit message body (see Step 10).

A successful `bin/rails lint:haml` run exits 0 with no reported offenses. Any violations must be
fixed manually before proceeding.

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
- The conventions below, and the whole [Known Changelog Quirks](#known-changelog-quirks) section, so
  it does not rediscover a known quirk
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
   - Check the gem's metadata (`gem specification <name>`) for `changelog_uri`, `source_code_uri`
     or homepage
   - For npm packages, check the package's repository URL on the npm registry
   - For Terraform providers and registry modules, the registry API's `source` field names the
     repository (`curl -fsS "https://registry.terraform.io/v1/providers/$ns/$name" | jq -r .source`,
     or `/v1/modules/$ns/$name/$provider` for a module); use its releases page or changelog file.
     A Git module's changelog lives in the repository its `source` points at
   - A Git-sourced gem keeps the `[compare]` link from Step 3 in place of a changelog
   - A tool or image pin from Step 7 links its upstream release page, minding the traps in
     [Known Changelog Quirks](#known-changelog-quirks)

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
([Step 3](#step-3-update-ruby-dependencies)), tool and image pin bumps
([Step 7](#step-7-update-tool-and-image-pins)), the security alerts this run closes and a Rails
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
  any age ([Step 4](#step-4-update-javascript-dependencies))
- **The re-resolution failed** — and why, so the reviewer knows transitive dependencies did not move
  ([Step 4](#step-4-update-javascript-dependencies))

Steps 5 and 6 also decide what else the PR body must say about Terraform. Add each that applies,
summarized and never pasted from Terraform's output, as
[Step 6](#step-6-re-resolve-and-verify-terraform-lock-files) explains:

- **A provider or module major** — the plan's one-line summary, or, for a major the user chose to
  ship unplanned, a statement at the very top of the body that it is unplanned
  ([Step 5](#step-5-decide-terraform-version-bumps))
- **A root module that could not be planned** — no credentials, `init -backend=false`, a module plan
  the user declined or a platform with no provider build — with the plan checkbox left unticked
  ([Step 6](#step-6-re-resolve-and-verify-terraform-lock-files))
- **A platform that lost support** — which developers can no longer run that root module
  ([Step 6](#step-6-re-resolve-and-verify-terraform-lock-files))
- **Root modules skipped**, and why ([Step 6](#step-6-re-resolve-and-verify-terraform-lock-files))
- **Lock files not tracked**, when the repository ignores them
  ([Step 6](#step-6-re-resolve-and-verify-terraform-lock-files))

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

Some packages must be updated in tandem because their versions must match across ecosystems. After
updating, verify these constraints and revert any that break them. Each `yarn up` here takes one of
the two prefixes from [Step 4](#step-4-update-javascript-dependencies): the restore prefix when the
target is the version the repository already commits, and the gated prefix otherwise. Make these
changes before Step 4's re-resolution — inside Step 4's single restore call when the prefix is the
restore prefix — so `yarn up -R '*'` and the `yarn why` check see them.

### Playwright

The `playwright` npm package and the `playwright-ruby-client` gem must match **exactly**, patch
included. The gem supports one driver version, which it names in
`Playwright::COMPATIBLE_PLAYWRIGHT_VERSION`, and the npm package must equal it. The gem is often not
in the `Gemfile` at all — it can arrive through `capybara-playwright-driver` — so read the version
from the installed gem rather than from a manifest. The npm package usually releases first, and a
newer npm **patch** is as much a mismatch as a newer minor.

After [Step 3](#step-3-update-ruby-dependencies) and `yarn up '*'` have moved both sides, compare
them as installed:

```bash
bundle exec ruby -e 'require "playwright"; puts Playwright::COMPATIBLE_PLAYWRIGHT_VERSION'
npx playwright --version   # prints "Version <x.y.z>"
```

1. If they differ, the gem's value wins. Move the npm side to it, which writes an exact pin:

   ```bash
   YARN_ENABLE_SCRIPTS=false YARN_NPM_MINIMAL_AGE_GATE=3d yarn up playwright@<compatible-version>
   ```

   That is the gated prefix, for a version the repository does not yet commit. When the gem did not
   move and `<compatible-version>` is the version already committed, use the restore prefix instead,
   in Step 4's restore call.

   Do **not** hold back the Ruby gem to match an older npm package — only the npm side moves.

2. If the `Gemfile` declares the gem (`grep -n playwright-ruby-client Gemfile`), update its `~>`
   constraint to the new version. If it does not, there is nothing to edit there.

3. Run the repository's own check, if it has one:

   ```bash
   grep -rl COMPATIBLE_PLAYWRIGHT_VERSION spec
   bin/rspec <each file it lists>
   ```

   With no such spec, rerun the comparison above; it is the check.

4. Before running any system spec locally, install the browser build the new version expects, with
   the repository's own script if it has one (for example `yarn playwright:install`). Nothing
   installs it when the npm version changes, and install scripts are off during this command. A CI
   image that bundles its own browsers is unaffected.

### Cocooned

The `@notus.sh/cocooned` npm package and the `cocooned` gem must have **matching versions**. The
maintainer typically releases both sides simultaneously — mismatches are rare.

When a new version is available:

1. Both should update together. If for some reason only one side updated, revert it to match the
   other:

   ```bash
   # If the npm package got ahead (writes an exact pin). The gated prefix, unless <gem-version> is
   # the version already committed — then the restore prefix, in Step 4's restore call:
   YARN_ENABLE_SCRIPTS=false YARN_NPM_MINIMAL_AGE_GATE=3d yarn up @notus.sh/cocooned@<gem-version>

   # If the gem got ahead, first set the cocooned constraint in Gemfile to <npm-version> exactly:
   # bundle update never moves a gem below what the Gemfile already allows
   bundle update cocooned --conservative
   ```

2. Update the version constraints in both manifest files:
   - `Gemfile`: while the sides differ, keep the exact version from item 1; once they match, use a
     `~>` constraint for `cocooned`
   - `package.json`: while the sides differ, keep the exact pin from item 1; once they match,
     restore the project's usual operator (`^` or `~`) for `@notus.sh/cocooned`. A range must not
     stand in for a hold: Step 4's re-resolution sends it to the newest release it admits, which is
     the version the hold blocks

### Rails JavaScript Packages

The `@rails/*` npm packages the app uses (`@rails/actioncable`, `@rails/actiontext`,
`@rails/activestorage` and the like) track the `rails` gem. Rails encodes the gem's version on npm
with the patch multiplied by 100 and any fourth segment added to it: gem 8.1.4 is npm `8.1.400`, and
the security release 8.1.2.1 is npm `8.1.201`. A prerelease gem does not follow that rule: gem
`8.1.0.beta1` is npm `8.1.0-beta1`, so for one, read the matching npm version from `npm view
@rails/actioncable versions --json` rather than deriving it. Their `latest` dist-tag is sometimes
left behind on an older release line, and `yarn up '*'` follows it down — walking an app on Rails
8.1 back to `^7.2.302` with no warning. After Step 4's restore, check each against the gem:

```bash
bundle exec rails --version
grep -n '"@rails/' package.json
```

Restore any whose range no longer starts at the gem's npm version with
`yarn up '@rails/<name>@^<npm-version>'`, using the matching prefix: the restore prefix when that
version is already committed, and the gated prefix when it is not — after a Rails bump in Step 3,
for one. When a Rails upgrade ships in the same PR ([Step 2](#step-2-create-the-feature-branch)),
these bumps belong in the upgrade commit, not the dependency commit. If the upgrade commit does not
already carry them, stop and ask the user whether to amend it; never rewrite it on your own.

## Terraform Update Notes

Why the commands in [Step 5](#step-5-decide-terraform-version-bumps) and
[Step 6](#step-6-re-resolve-and-verify-terraform-lock-files) are shaped the way they are. Consult
this when you need the reasoning; the steps themselves are self-contained.

**Why `-upgrade` is mandatory.** Version constraints in the `.tf` files and the resolved versions in
`.terraform.lock.hcl` are tracked separately, so bumping a constraint alone leaves the lock file
stale. Whenever the locked selection conflicts with the configuration, plain `terraform init`
reports `Failed to query available provider packages … must use terraform init -upgrade` — whether
or not the providers are already installed. What the installed state changes is which error `plan`
gives first: `Error: Inconsistent dependency lock file` when the providers are present, naming the
one whose locked selection no longer matches, and `Required plugins are not installed` when they are
not. That second message is a trap, because it advises running plain `terraform init`, which then
fails with the `-upgrade` error above. A plain `init` cannot fix any of these; it honors the
versions already recorded in the lock file, and only `-upgrade` re-resolves them.

**Why `-input=false`.** It keeps `init` from stopping at an interactive prompt (backend migration,
missing credentials) with no TTY to answer it, erroring out instead of hanging.

**Why `-fsS` and `jq -e`.** A bare `curl -s ... | jq -r .version` prints `null` and **exits 0** on a
404, which reads as "no newer release exists" and silently skips the bump. The pipeline's status is
jq's, not curl's, so the failure never surfaces. `-f` makes curl exit non-zero, `-S` restores the
error message and `jq -e` propagates a non-zero status instead of printing `null`.

**Why the `:/` pathspec prefix.** It anchors matching to the repository root, so the `git` commands
select the same files from any directory. It does not normalize the *printed* paths, which is why
the read-only queries also pass `--full-name` — without it, `git ls-files` and `git grep` print
paths relative to the current directory while `git diff` prints them relative to the root. Note the
limit of that guarantee: it covers the `git` queries, not the `terraform -chdir` and
`git status`/`git diff` commands that consume the root-relative paths they print. Those break in a
subdirectory, which is why [Step 5](#step-5-decide-terraform-version-bumps) opens by `cd`-ing to the
root rather than merely asking you to be there.

**Why not the registry's `.version` field.** It reports the highest semver version including
prereleases. At the time of writing the provider endpoint returned `5.5.0-pre.1` for
`heroku/heroku` while stable sat at `5.4.0` — an arbitrary provider that happened to demonstrate it.
The specific numbers move; the behavior does not. If that provider now looks unremarkable, check
another rather than concluding the warning is stale.

**Why the Git tag pipeline sorts as it does.** `git ls-remote --sort=-v:refname | head -1` ranks
`v3.0.0-rc1` above `v2.1.0`, ranks every `v`-prefixed tag above every bare-numeric one — so a repo
that dropped the prefix at `2.0.0` reports the older `v1.10.0`, a silent downgrade — and ranks
floating tags like `stable` and `latest` in among the versions. The pipeline's `grep` discards
prereleases and non-version tags, and its `awk` step builds a fixed-width key from up to four
version fields, padding missing ones with zero, so a plain sort compares field by field: `v1.2.1`
beats `v1.2` and `1.10.0` beats `1.9.9`. Sorting `<version> <tag>` lines with `sort -t.` instead
fails without a fixed width, because a short version's tag text spills into the later sort keys and
`v1.2` ranks above `v1.2.1`.

**Why the `if` around `ls-remote`.** A pipeline's exit status is the last command's, so an
unreachable or unauthorized repository piped straight into the filter prints to stderr and the
pipeline still exits 0 — the same trap `-fsS`/`jq -e` guard against for curl. `|| echo` is no
substitute for the `if`: `echo` succeeds, so `$?` is 0 and the empty `$tags` flows on into a filter
that prints nothing, which reads as "no newer tag".

**Why the tag is used verbatim.** The pipeline sorts with any `v` stripped but prints the tag as it
exists. A repository whose convention changed will have an existing `ref=6.6.1` alongside a real tag
of `v6.6.1`, and a name reconstructed from the old `ref=` produces `couldn't find remote ref` —
which Step 6 would then misread as a bad edit.

**Why `git restore --source=HEAD`, not `git checkout --`.** `git checkout -- <paths>` restores from
the index rather than from `HEAD`, so once anything has been staged it exits 0, reports nothing and
leaves the bad edit in place *and staged*. It also cannot remove a `.tf` file you created, which is
what the `git clean` half of the pair is for.

**Module bumps and the lock file.** The lock file records provider selections only, so no module
bump changes it. `-upgrade` is not what fetches a new module source: a Git `ref=` bump is picked up
by plain `terraform init`, which is what HashiCorp's module-sources documentation prescribes for any
change to a `source` argument. The case that genuinely needs `-upgrade` is the one that is easy to
miss — a **registry** module under a range constraint, where plain `init` keeps whatever version is
already downloaded and only `-upgrade` re-resolves the range. Running `init -upgrade` in every root
module, as [Step 6](#step-6-re-resolve-and-verify-terraform-lock-files) requires, covers both. What
neither leaves behind is a diff: the resolved module version is recorded only in the gitignored
`.terraform/modules/modules.json`, so the `Downloading <source> <version> for <name>` line in the
`init` output is the only evidence the bump happened.

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

### Bundler

Since 4.0.0, Bundler and RubyGems share version numbers and release tags. Link the joint release
page, `https://github.com/ruby/rubygems/releases/tag/v<version>`. The notes are also in the root
`CHANGELOG.md` of `ruby/rubygems`, under each version's `### Bundler` subsection.
`CHANGELOG-bundler.md` no longer exists on `master`; pre-4.0 history is in
`doc/CHANGELOG-bundler-2.x.md`.

### google-protobuf

The gem's `4.<x>.<y>` maps to the protobuf release tag `v<x>.<y>`: 4.35.0 is
`https://github.com/protocolbuffers/protobuf/releases/tag/v35.0`.

### Gems with no changelog

`playwright-ruby-client` and `capybara-playwright-driver` publish no changelog and no GitHub
releases, so link [Diffend](https://my.diffend.io) as Step 10 describes.
`active_storage_validations` is not one of them: it keeps `CHANGES.md` and publishes releases.

### Changelogs without usable anchors

- **`msgpack`** keeps a plain-text `ChangeLog` with no headings to anchor, so link the file itself
- **`ssrf_filter`** puts the release date in each heading, so its slugs carry the date as well as
  the version — 1.6.0 slugs to the form `#160-982026`. Read the slug from the rendered page rather
  than deriving it

### Changelogs on another branch or repository

- **`appsignal`** 4.10.x patch releases are documented only on the `4.x-stable` branch, not `main`
- **`cancancan`** has moved to `coorasse/cancancan`. The old URLs redirect, but link the new home

### Tool and image pins

- **`jq`** tags its releases `jq-1.8.2`, so a `^v?[0-9]` tag filter returns nothing. Match the
  `jq-` prefix
- **Elasticsearch**'s GitHub release page is only a pointer. Link the real notes on `elastic.co`

## Important Notes

- **Start from an up-to-date `main`**, or from a Rails upgrade the user chose to ship alongside —
  see [Step 2](#step-2-create-the-feature-branch).
- **Count this month's runs from history, not branches** — see
  [Step 1](#step-1-determine-the-branch-name-and-pr-title).
- **Every pin that moved gets a commit-message entry**, including Bundler, Git-sourced gems and tool
  and image pins — see [Step 11](#step-11-commit-push-and-create-the-pr).
- **Changelog links are required** — see [Step 10](#step-10-build-the-final-commit-message).
- **Never skip linter checks** — see [Step 8](#step-8-handle-rubocop-updates) and
  [Step 9](#step-9-handle-haml-lint-updates).
- **Run `terraform init -upgrade` in every root module whenever the repo has `.tf` files** — even
  with no `.tf` edits, since range constraints and transitive providers move on their own, and a
  skipped root module leaves a stale lock file that makes `terraform plan` fail. See
  [Step 6](#step-6-re-resolve-and-verify-terraform-lock-files).
- **Never commit a root module whose most recent `init` failed** — the `.tf` edits stand while the
  lock file does not move, producing a commit that can neither `init` nor `plan`. See
  [Step 6](#step-6-re-resolve-and-verify-terraform-lock-files).
- **Version-locked packages** — see [Step 4](#step-4-update-javascript-dependencies) and
  [Version-Locked Packages](#version-locked-packages).
- If no dependencies changed at all, inform the user and stop. A change to `yarn.lock` alone is put
  to the user first — see [Stop If Nothing Changed](#stop-if-nothing-changed).
