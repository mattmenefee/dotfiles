# Update Dependencies: Terraform

## Step 5: Decide Terraform Version Bumps

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

### Find the Current Pins

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

### Look Up the Latest Versions

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
  not (`aws-ia/vpc_endpoints/aws` is a real registry module), following `moduleRegistryNamePattern`
  in `hashicorp/terraform-registry-address`.
- **A Git module URL** — `^(https://|git@)[A-Za-z0-9._@:/-]+$`, applied to the repository URL rather
  than the whole `source`. Extract it first: strip a leading `git::`, then everything from the first
  `?`, then any `//subdirectory` that follows the repository path (the `//` after `.git` or the
  repository name, not the one in `https://`). From
  `git::https://github.com/org/repo.git//modules/foo?ref=v1.2.3` that leaves
  `https://github.com/org/repo.git`. Validate the `ref=` value on its own: a version tag must match
  `^v?[0-9]+(\.[0-9]+)*$`, the same filter the tag lookup below applies, and a commit SHA must match
  `^[0-9a-f]{7,40}$`.
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
`"https://registry.terraform.io/v1/modules/$ns/$name/$provider"` — and **the hostname rule above
applies here too**. Module source addresses carry an optional host in the same leading position, so
`app.terraform.io/acme/vpc/aws` and `tfe.internal/platform/vpc/aws` are both valid. Query the public
registry only for a bare three-part source or one prefixed with exactly `registry.terraform.io`; for
anything else, skip the module rather than dropping the host. Reducing `tfe.internal/acme/vpc/aws`
to `acme/vpc/aws` either 404s or, worse, returns the version of an unrelated public module to be
written into a private module's pin. Modules with a local path source
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
which can rank an older tag first. Keep its two outcomes apart. A non-zero `ls-remote` is a **lookup
failure** — a network outage, a private-repo 403, a mistyped URL — and you must stop and report it,
never record it as "no update available". Only when `ls-remote` succeeds and the filter still prints
nothing does the repository genuinely have no version tags; leave the `ref=` alone and say so rather
than guessing. The pipeline prints the **tag as it actually exists**, so use its output verbatim in
`ref=` and never re-derive the `v` prefix from the existing `ref=`. Treat a module major like a
provider major — skim the repository's release notes first, since module inputs and outputs change
across majors.

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

### Bump the Pins

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
of this pair. Scope matters: by this point the changes from Steps 3 and 4 (`Gemfile.lock`,
`yarn.lock` and any `Gemfile` or `package.json` edits for version-locked packages) are uncommitted,
and a broad revert discards them with no reflog to recover from.

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
component given increase, so `~> 2.99` means `>= 2.99, < 3.0` — it admits `2.99` and every later
`2.x`, which makes `2.100.0` **inside** it and `2.5.0` outside — while `~> 2.99.0` admits only
`2.99.x`.

Several things can cross a major version boundary in one step. For providers: replacing an exact pin
with the registry's latest, letting an unbounded range such as `>= 2.5` drift forward and a
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

Do not decide whether to skip [Step 6](#step-6-re-resolve-and-verify-terraform-lock-files) from Step
5's results — that condition is not decidable from the data Step 5 gathers. A range constraint can
move with no `.tf` edit, and a transitive provider pulled in by a child module never appears in Step
5's greps at all, so "nothing has a newer version available" is exactly the case Step 6 exists to
catch. Skip Step 6 only when the repo has no `.tf` files. Otherwise run it even when you made no
`.tf` edits, and let its result decide: if `init -upgrade` leaves every lock file unchanged, then
there is nothing to commit.

## Step 6: Re-resolve and Verify Terraform Lock Files

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
[Step 5](#step-5-decide-terraform-version-bumps), naming the exact files, then **continue with Steps
7–11 for the remaining updates**. Say in the PR body which root modules were skipped and why, and
omit the `terraform` label if no Terraform change remains. `gem_update` and `yarn up` have already
rewritten the tree by this point, and those updates are validated and worth shipping. Abandon the
whole run only when the tree cannot be returned to a consistent state.

Leave `.terraform/` alone either way. You cannot tell whether the failed run created it or merely
wrote into one that was already there — Terraform does not report that — and it is not a disposable
cache: it holds the selected workspace name in `.terraform/environment` and the initialized backend
configuration in `.terraform/terraform.tfstate`. Deleting it silently drops the operator back to the
`default` workspace, so the next `terraform apply` they run believing they are on `staging` is not.
[Step 11](SKILL.md#step-11-commit-push-and-create-the-pr) already excludes `.terraform/` from the
commit, so removing it buys nothing. If the repository does not gitignore it, say so in your report
and let the user decide.

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
the module moved, so it is the only thing [Step 10](SKILL.md#step-10-build-the-final-commit-message)
has to cite.

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
source runs whatever program the module names, with the credentials the session holds. `init` checks
provider packages against their signatures but checks nothing about module code, so a moved tag or a
compromised module release runs during the plan. So before planning a root module, check which of
its modules this run bumped:

- **No module bumped, or every bumped module comes from a source the user controls** — plan without
  asking. Provider-only bumps fall here, since their packages are signature-checked
- **Any other module bumped** — stop and ask the user before planning that root module, naming each
  such module, its old and new version and the credentials the session holds. If they decline, treat
  the root module as one you could not plan

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
business contending with a real `apply` that a colleague may be running. Pass it through the wrapper
too if the wrapper accepts plan flags.

A plan shows drift as well as the bump. When it reports changes, compare each one against the
release notes of every version crossed. A change no release note explains — a firewall rule someone
added through a provider's console, say — is existing drift, not an effect of the bump. Report it
separately in the PR body, so the plan checkbox speaks only to what the bump does.

`plan` needs real provider and backend credentials, so `No valid credential sources found` or
`Backend initialization required` where they are absent is not a dependency problem.
`Error: Inconsistent dependency lock file` **is** one — it means `init -upgrade` did not run or did
not succeed in that directory, so go back and re-run it rather than waving the failure through. When
you cannot plan at all, say so in the PR body and leave its checkbox unticked rather than skipping
it silently.

**Summarize Terraform output in the PR body and the commit message — never paste it raw.** Backend
and credential errors are not generic: they embed account IDs, IAM principal ARNs and state bucket
names. A successful plan is no safer, since it prints every attribute the provider did not mark
`Sensitive`. None of that is a credential, but all of it is reconnaissance, and a PR body is
permanent and public to everyone with repository access. "Could not plan `infra/prod` — no backend
credentials in this environment" is the entire message. To evidence the plan checkbox, quote the
one-line summary (`Plan: 0 to add, 3 to change, 0 to destroy`) and nothing else.

Then stage the lock file along with the `.tf` changes (see
[Step 11](SKILL.md#step-11-commit-push-and-create-the-pr)), and record each version change for the
commit message (see [Step 10](SKILL.md#step-10-build-the-final-commit-message)).

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
prereleases. At the time of writing the provider endpoint returned `5.5.0-pre.1` for `heroku/heroku`
while stable sat at `5.4.0` — an arbitrary provider that happened to demonstrate it. The specific
numbers move; the behavior does not. If that provider now looks unremarkable, check another rather
than concluding the warning is stale.

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
