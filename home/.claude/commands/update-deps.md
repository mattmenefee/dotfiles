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
files. Every command in both steps must run from the repository root — the `git` queries print
root-relative paths, and the `terraform -chdir` and `git status` commands that consume those paths
break anywhere else — so start by going there:

```bash
cd "$(git rev-parse --show-toplevel)"
git ls-files --full-name ':/*.tf' ':(top,exclude)*.terraform/*'
```

This exits 0 whether or not it matched, so read its output rather than its status. It does not see
`.tf.json` files, untracked files, or files inside submodules; handle those by hand in the rare repo
that has them. The exclude keeps the module copies that `terraform init` vendors into `.terraform/`
out of every listing in this step, matching Steps 6 and 10 — without it you can end up editing a
vendored copy that Step 10 then refuses to stage. See
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
Terraform's validation is never the gate. Assign each value to a variable, quote every use, and
validate it first:

| Value | Must match | Notes |
| --- | --- | --- |
| `<namespace>`, `<name>` | `^[A-Za-z0-9][A-Za-z0-9-]*$` | The registry's own rule. Also catches unresolved interpolation (`${var.ns}/aws`) and trailing whitespace, which would otherwise 404 confusingly. |
| A Git module URL | `^(https://\|git@)[A-Za-z0-9._@:/-]+$` | |
| `<terraform-directory>` | no `$`, backtick, `;`, `\|`, `&`, or newline | Quoting is not enough on its own: `terraform -chdir="$(id)"` still substitutes inside double quotes, and `$(id)` is a legal committable directory name. |

Anything that fails these is not a dependency you can look up automatically — stop and report it
rather than working around it.

The block's `source` value supplies `<namespace>/<name>`. Strip the hostname only when it is exactly
`registry.terraform.io`; any other hostname means a private registry, so skip that provider rather
than stripping the host — the public registry may answer for the same `<namespace>/<name>` with an
entirely unrelated provider. A bare two-part source (`source = "hashicorp/aws"`, the common case)
has no host to strip and is always the public registry:

```bash
curl -fsS --max-time 10 https://registry.terraform.io/v1/providers/<namespace>/<name> \
  | jq -er '[.versions[] | select(test("^[0-9]+(\\.[0-9]+)*$"))]
            | sort_by(split(".") | map(tonumber))
            | last // error("no stable release found")'
```

Do not use the response's `.version` field. It reports the highest semver version **including
prereleases**, and Terraform will pin to a prerelease without complaint. At the time of writing the
endpoint returned `5.5.0-pre.1` for `heroku/heroku` while stable sat at `5.4.0` — an arbitrary
provider that happened to demonstrate it, not one you are expected to use. The specific numbers
move; the behavior does not. If that provider now looks unremarkable, check another rather than
concluding the warning is stale. The filter above discards prereleases and sorts numerically, so
`2.100.0` correctly beats `2.99.1`.

Registry modules answer the same way at
`https://registry.terraform.io/v1/modules/<namespace>/<name>/<provider>` — and **the hostname rule
above applies here too**. Module source addresses carry an optional host in the same leading
position, so `app.terraform.io/acme/vpc/aws` and `tfe.internal/platform/vpc/aws` are both valid.
Query the public registry only for a bare three-part source or one prefixed with exactly
`registry.terraform.io`; for anything else, skip the module rather than dropping the host. Reducing
`tfe.internal/acme/vpc/aws` to `acme/vpc/aws` either 404s or, worse, returns the version of an
unrelated public module to be written into a private module's pin. Modules with a local path source
(`source = "../../modules/network"`) are versioned by this repository — skip them.

Modules sourced from Git (`source = "git::https://github.com/org/repo.git//modules/foo?ref=v1.2.3"`)
or a private registry have no public version API. List the repository's version tags and bump the
`ref=` value directly:

```bash
if ! tags=$(git ls-remote --tags --refs https://github.com/org/repo.git); then
  echo "STOP: ls-remote failed - do not record this as 'no tags'" >&2
  exit 1
fi
printf '%s\n' "$tags" | sed 's|.*refs/tags/||' \
  | grep -E '^v?[0-9]+(\.[0-9]+)*$' \
  | awk '{k=$0; sub(/^v/,"",k); print k" "$0}' \
  | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n \
  | tail -1 | awk '{print $2}'
```

Do not reach for `git ls-remote --sort=-v:refname | head -1`. That sort ranks `v3.0.0-rc1` above
`v2.1.0`, ranks every `v`-prefixed tag above every bare-numeric one — so a repo that dropped the
prefix at `2.0.0` reports the older `v1.10.0`, the exact silent downgrade you are trying to avoid —
and ranks floating tags like `stable` and `latest` in among the versions. The `grep` above discards
prereleases and non-version tags, and the numeric sort compares field by field.

Branch on `git ls-remote`'s exit status rather than piping it straight into `head`: a pipeline's
exit status is the last command's, so an unreachable or unauthorized repository prints to stderr and
the pipeline still exits 0 — the same trap `-fsS`/`jq -e` guard against for curl. `|| echo` is no
substitute for the `if`: `echo` succeeds, so `$?` is 0 and the empty `$tags` flows on into a filter
that prints nothing. Keep the two outcomes apart. A non-zero `ls-remote` is a **lookup failure** — a
network outage, a private-repo 403, a mistyped URL — and you must stop and report it, never record
it as "no update available". Only when `ls-remote` succeeds and the filter still prints nothing does
the repository genuinely have no version tags; leave the `ref=` alone and say so rather than
guessing. The pipeline sorts on the version with any `v` stripped but prints the **tag as it
actually exists**, so use its output verbatim in `ref=`. Do not re-derive the prefix from the
existing `ref=`: a repository whose convention changed will have an existing `ref=6.6.1` alongside a
real tag of `v6.6.1`, and writing the reconstructed name produces `couldn't find remote ref` — which
Step 6 would then misread as a bad edit. Treat a module major like a provider major — skim the
repository's release notes first, since module inputs and outputs change across majors.

Know what a `ref=` bump is worth as a pin, because it is the weakest one in this workflow. A tag is
mutable and force-pushable, so a module repository whose release tag is moved delivers different
code under an unchanged `ref=` on the next `init` — and unlike a provider, there is no checksum
recorded anywhere to notice it. A reviewer looking at `ref=v1.2.3 → ref=v1.4.0` has no artifact to
verify against. For modules you do not control, resolve the tag to its commit SHA — `git ls-remote
--tags` prints it in the first column, alongside the ref — and record that SHA in the commit
message, so the review has something fixed to point at.

#### Bump the Pins

Confirm the CLI is available before editing anything: `terraform version` should print a version and
exit 0. If it is not on `PATH` you get exit 127; under a version manager you may instead get a shim
error such as `mise ERROR No version is set for shim: terraform` until a version is selected. Either
way, stop and tell the user rather than making `.tf` edits you cannot re-resolve — and if you have
already made them, revert them first:

```bash
git restore --source=HEAD --staged --worktree -- <the exact .tf files you edited>
git clean -f -- <any .tf files you created>
```

Name the exact files — never a glob, never a directory. `git checkout -- <paths>` is the wrong
primitive here: it restores from the index rather than from `HEAD`, so once anything has been staged
it exits 0, reports nothing, and leaves the bad edit in place *and staged*. It also cannot remove a
`.tf` file you created. Scope matters just as much: by this point `Gemfile.lock`, `yarn.lock`,
`.rubocop_todo.yml`, and every RuboCop autofix from Steps 3, 4, and 7 are uncommitted, and a broad
revert discards all of them with no reflog to recover from.

Having the CLI is not the same as having a *usable* one, so check what the configuration will accept
from it:

```bash
git grep -nE --full-name 'required_version' -- ':/*.tf' ':(top,exclude)*.terraform/*'
```

If any `required_version` excludes the installed CLI, every `init` in that module fails before it
does any provider work, with `Error: Unsupported Terraform Core version`. Install a CLI the
configuration accepts, or stop and tell the user which version is needed. **Never widen or bump
`required_version` to make the error go away.** It is a deliberate constraint on which Terraform may
touch that state, it is not a dependency this command updates, and changing it during a routine
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
| Git `ref=` | `source = "git::https://github.com/org/repo.git//modules/foo?ref=v1.2.3"` | Edit the `ref=` to the new tag. |

Do not carry provider-shaped verification over to the module tables. The lock file records
**provider** selections only — Terraform does not remember version selections for remote modules —
so no module bump produces a lock-file diff, and there is no `version` line to check before and
after. The `Downloading <source> <version> for <name>` line in `terraform init` output is the only
evidence that a module moved, which makes it the only thing the commit message can cite. Capture it
as [Step 6](#step-6-re-resolve-and-verify-terraform-lock-files) runs.

Count the constraint's segments before deciding "outside" a range. `~>` frees only the component one
level less precise than the last one given, so `~> 2.99` means `>= 2.99, < 3.0` — it admits `2.99`
and every later `2.x`, which makes `2.100.0` **inside** it and `2.5.0` outside — while `~> 2.99.0`
admits only `2.99.x`.

Three things can cross a major version boundary in one step: replacing an exact pin with the
registry's latest, letting an unbounded range such as `>= 2.5` drift forward, and a root-module bare
`source`. The latter two are the more dangerous, because no `.tf` line changes — the only trace is a
`version` line in the lock file diff, which is easy to skim past. Skim the provider's release notes
for breaking changes before taking a major bump in any of the three cases.

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

**If `terraform init` exits non-zero anywhere in this step, no Terraform change may be committed.**
A failed `init` leaves the lock file untouched while your Step 5 edits stand, and staging that pair
produces a commit that can neither `init` nor `plan`. That bars the Terraform work, not the whole
run — see below for what to do with the Ruby and JavaScript updates. Read the error before deciding
what to do:
`no available releases match the given constraints` or any HCL syntax error means the edit you just
made is wrong — fix it in place and re-run.

`does not have a package available for your current platform` is a different animal and does **not**
mean your edit is wrong. It usually means the provider publishes no build for the platform you are
on, commonly `darwin_arm64`. Do not revert a legitimate bump over it and do not hand-edit the lock
file; record the hashes for the platforms that do have builds instead:

```bash
terraform -chdir="<terraform-directory>" providers lock \
  -platform=darwin_arm64 -platform=linux_amd64
```

Adapt that platform list rather than copying it: it must name every platform that runs Terraform
against this repository — each developer machine plus CI, which is `linux_amd64` on GitHub Actions
and CircleCI unless the job asks for an ARM runner. The pair above assumes an Apple Silicon Mac and
x86 Linux CI. A platform you omit here is one whose hashes the lock file will not carry.

If the provider genuinely publishes nothing for any platform you need, report it as unavailable
rather than working around it.

Only stop for failures you cannot resolve locally. Stopping means dropping the Terraform work, not
abandoning the run: revert that root module's `.tf` edits and any lock-file changes with the
`git restore`/`git clean` pair from [Step 5](#step-5-decide-terraform-version-bumps), naming the
exact files, then **continue with Steps 7–10 for the Ruby and JavaScript updates alone**. Omit the
`terraform` label, and say in the PR body that Terraform was skipped and why. `gem_update` and
`yarn up` have already rewritten the tree by this point, and those updates are validated and worth
shipping. Abandon the whole run only when the tree cannot be returned to a consistent state.

Leave `.terraform/` alone either way. You cannot tell whether the failed run created it or merely
wrote into one that was already there — Terraform does not report that — and it is not a disposable
cache: it holds the selected workspace name in `.terraform/environment` and the initialized backend
configuration in `.terraform/terraform.tfstate`. Deleting it silently drops the operator back to the
`default` workspace, so the next `terraform apply` they run believing they are on `staging` is not.
[Step 10](#step-10-commit-push-and-create-the-pr) already excludes `.terraform/` from the commit, so
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
`provider` block, or is simply a directory you would run `terraform apply` in, and run
`init -upgrade` in every one. If the repo clearly uses providers but tracks no lock files at all,
check `.gitignore` and say in the PR body that lock files are not tracked — otherwise Step 10's
`git add -- ':/*.terraform.lock.hcl'` aborts with `fatal: pathspec … did not match any files` and
leaves your `.tf` changes unstaged.

Run this once per root module, quoting the directory in case it contains spaces:

```bash
terraform -chdir="<terraform-directory>" init -upgrade -input=false
```

Check the exit status, not just the output. A successful run exits 0 and reports "Terraform has been
successfully initialized!" — and, when a provider selection actually moved, also notes that it
changed the selections recorded in `.terraform.lock.hcl`. A module bump succeeds without that second
message, which is expected rather than a sign the run did nothing — the lock file records nothing
about modules. Its evidence is the `Downloading <source> <version> for <name>` line in the output
instead. Copy that line out as you go: no file in the repository will show that the module moved, so
it is the only thing [Step 9](#step-9-build-the-final-commit-message) has to cite.

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
only thing that surfaces that:

```bash
terraform -chdir="<terraform-directory>" plan -input=false -lock=false
```

`-lock=false` matters here: `plan` takes a state lock by default, and a dependency PR has no
business contending with a real `apply` that a colleague may be running.

`plan` needs real provider and backend credentials, so `No valid credential sources found` or
`Backend initialization required` where they are absent is not a dependency problem. `Error:
Inconsistent dependency lock file` **is** one — it means `init -upgrade` did not run or did not
succeed in that directory, so go back and re-run it rather than waving the failure through. When you
cannot plan at all, say so in the PR body and leave its checkbox unticked rather than skipping it
silently.

**Summarize Terraform output in the PR body and the commit message — never paste it raw.** Backend
and credential errors are not generic: they embed account IDs, IAM principal ARNs, and state bucket
names. A successful plan is no safer, since it prints every attribute the provider did not mark
`Sensitive`. None of that is a credential, but all of it is reconnaissance, and a PR body is
permanent and public to everyone with repository access. "Could not plan `infra/prod` — no backend
credentials in this environment" is the entire message. To evidence the plan checkbox, quote the
one-line summary (`Plan: 0 to add, 3 to change, 0 to destroy`) and nothing else.

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
# Prefer staging the exact paths identified in Steps 5 and 6. If you glob, keep :/*.tf and
# :/*.terraform.lock.hcl in separate git add invocations: git add validates every pathspec before
# staging anything, so one that matches nothing aborts the whole invocation and silently leaves
# the .tf changes unstaged.
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

- Updated N Ruby dependencies, M JavaScript packages, and P Terraform providers and modules
- [Notable updates, e.g. "Rails 8.1.1 → 8.1.2", "RuboCop 1.85 → 1.86 (with auto-fixes)"]

## Test plan

- [ ] CI passes
- [ ] Smoke test the app locally
EOF
)" --label "<comma-separated list of verified labels>"
```

Omit any category (Ruby, JavaScript, Terraform) that had no changes. Tailor the summary bullets to
highlight the most notable updates (major version bumps, security patches, linter upgrades that
required code changes, etc.). If any Terraform providers **or modules** changed, add a
`- [ ] terraform plan shows no unexpected resource changes` checkbox to the test plan — a module
major changes inputs and outputs, which is at least as plan-visible as a provider bump.

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
error message, and `jq -e` propagates a non-zero status instead of printing `null`.

**Why the `:/` pathspec prefix.** It anchors matching to the repository root, so the `git` commands
select the same files from any directory. It does not normalize the *printed* paths, which is why
the read-only queries also pass `--full-name` — without it, `git ls-files` and `git grep` print
paths relative to the current directory while `git diff` prints them relative to the root. Note the
limit of that guarantee: it covers the `git` queries, not the `terraform -chdir` and
`git status`/`git diff` commands that consume the root-relative paths they print. Those break in a
subdirectory, which is why [Step 5](#step-5-decide-terraform-version-bumps) opens by `cd`-ing to the
root rather than merely asking you to be there.

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
