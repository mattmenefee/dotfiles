# Update Dependencies: Tool and Image Pins

## Step 7: Update Tool and Image Pins

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
git grep -nE --full-name '^[[:space:]]+[A-Za-z0-9_-]+:[[:space:]]*[[:punct:]]?[a-z0-9-]+/[a-z0-9_-]+@' \
  -- ':/.circleci/*.yml'
```

`git ls-files` exits 0 either way, and `git grep` exits 1 when it finds nothing, which is not an
error here; read the output. The optional list dash in the `image:` pattern is what catches
CircleCI, which lists its Docker images as sequence items (`- image: cimg/ruby:<tag>`). A Dockerfile
base image is a pin like any other; one written as `FROM ruby:${RUBY_VERSION}` takes its version
from an `ARG` line, so bump it there.

The fourth search lists every YAML key ending in `_version`, wherever it lives, such as an Ansible
`redis_version: 8.10.2`. Bump only a value that pins which release of a third-party tool or service
gets installed. Skip a value built from Jinja `{{ }}` or set to `latest`; the `min_ansible_version`
key in a role's `meta/main.yml`, which states the Ansible version the role needs; the project's own
version in a docs or site config; and a CI matrix or per-environment set that lists several versions
on purpose, which does not move together.

The last search lists the CircleCI orbs, each an `orbs:` entry naming `<namespace>/<orb>@<version>`.
An orb defined inline under `orbs:` has no version and does not show. Skip a reference to
`@volatile`, which already follows the latest release, or to a `@dev:` label, which names an
unpublished build.

Add any other pin the project's `CLAUDE.md` or README names.

For each pin, look up the newest stable upstream release and bump to it, following these rules:

- **The same pin in several files moves together.** An image tag that appears in both the CI config
  and the Compose file, or a tool pinned in two mise files, takes one version everywhere
- **An image or variable that names a language runtime follows that runtime's version file.** A Ruby
  image (`cimg/ruby`, `ruby`) or a `ruby_version` variable stays at `.ruby-version`'s version and is
  left alone with it; a Node image (`cimg/node`, `node`) or a `nodejs_version` or `node_version`
  variable moves only with `.node-version` or `.nvmrc`, to the same version. Bumping one alone runs
  CI or a server on a runtime the app does not pin
- **A major waits for the user.** Bump within the current major without asking. Stop and ask before
  a major, naming what its release notes say breaks, as
  [Step 5](terraform.md#step-5-decide-terraform-version-bumps) does for a Terraform major
- **A major-only pin moves only by a major.** A pin such as `"18"`, `"9.x"` or `node = "22"` already
  admits every release in its major, so there is nothing to bump within it; a major bump waits for
  the user like any other
- **A Terraform CLI pin must still satisfy every `required_version`** found in Step 5. Never widen
  `required_version` to fit a new CLI
- **Leave `.ruby-version` alone** unless the user asks: a Ruby upgrade is its own change
- **An orb keeps its pin's precision.** Read the published versions from the orb registry:

  ```bash
  circleci orb get '<namespace>/<orb>' --json --jq '.latest_version'
  circleci orb get '<namespace>/<orb>' --json \
    --jq '[.versions[].version | select(startswith("<major>."))] | sort_by(split(".") | map(tonumber)) | last'
  ```

  The second prints the newest release within the pin's current major. Bump a full `1.2.3` pin to
  that version, and a `1.2` pin, which already admits every patch, to its major and minor alone
  (`1.5`, not `1.5.1`); a `1` pin is major-only, as above. When the first prints a newer major, ask
  as for any major: a major orb release can rename or remove a job, command or parameter the config
  uses, so compare its release notes and its `circleci orb diff` (see
  [Read the Code Diff of Each Deep Dependency](impact.md#read-the-code-diff-of-each-deep-dependency))
  with the config before asking. These commands come from the preview CircleCI CLI
  (`circleci@next`); if `circleci orb get --help` fails, tell the user and leave the orbs unbumped.
- **A provisioning pin moves only to a version its role's install source carries.** The role that
  reads it installs from its own source — an apt or yum repository, a vendor package repository or a
  download URL — which can lag the newest upstream release or name it differently, so confirm the
  new version exists where the role's tasks install from before bumping it.

Lookup traps are recorded under [Known Changelog Quirks](changelogs.md#known-changelog-quirks): tags
that do not start with a digit, release pages that only point elsewhere and orbs, whose registry
carries no release notes.

Record every bump for the commit message with its upstream release notes, in the same format as the
other entries. [Step 12](SKILL.md#step-12-commit-push-and-create-the-pr) checks that every staged
pin change has one.

### Update the Package Manager Pin

A root `package.json` can pin the package manager that Corepack runs for the repository, in its
`packageManager` field (`"packageManager": "yarn@4.19.0"`). No package manager updates that field on
its own, so read it:

```bash
cd "$(git rev-parse --show-toplevel)"
test -f package.json && jq -r '.packageManager // empty' package.json
```

Skip this section when it prints nothing, and when
[Step 4](javascript.md#update-the-package-manager) already handled a Yarn pin, whether or not it
moved. Otherwise the value is `<name>@<version>`, sometimes followed by a Corepack integrity hash
(`+sha512.<hex>`, or `+sha224.<hex>` from an older Corepack). Leave a `yarn@1.x` pin alone: Yarn
Classic is frozen, and moving to Yarn 2 or later is a migration, not a bump.

Find the newest stable release — no prerelease suffix — within the pin's current major that was
published at least one day ago. No package manager applies a release-age gate when it replaces
itself, so this lookup is the gate. Yarn 2 and later publishes to npm as `@yarnpkg/cli-dist`, and
pnpm and npm under their own names. Set `<major>` to the pin's major version:

```bash
cutoff="$(date -u -v-1d +%Y-%m-%dT%H:%M:%S)"
npm view <package> time --json | jq -r --arg cutoff "$cutoff" --arg major '<major>' '
  to_entries
  | map(select((.key | test("^" + $major + "\\.[0-9]+\\.[0-9]+$")) and .value < $cutoff))
  | sort_by(.key | split(".") | map(tonumber)) | last | .key // empty'
```

If it prints the pinned version or an older one, which happens when the pin itself is under a day
old, there is nothing to bump. If it prints nothing, check that the `date` command printed a cutoff
and that `<major>` is right, and tell the user if both are. A newer major waits for the user, as for
any other pin; `npm view <package> dist-tags.latest` shows whether one exists.

Check `corepack --version` before any bump: a hash can be written back, and the bump confirmed, only
through Corepack. Node no longer ships it from version 25, so if the check fails, tell the user and
leave the pin unbumped. Then bump the pin as follows; Yarn's own command also moves the files that
go with it:

- **Yarn** — `yarn set version <version>`, adding `--no-yarn-path` when `.yarnrc.yml` sets no
  `yarnPath`: run outside Corepack, Yarn would otherwise vendor a release and add a `yarnPath` of
  its own. It rewrites `packageManager`, and when `.yarnrc.yml` sets `yarnPath`, it also downloads
  `.yarn/releases/yarn-<version>.cjs`, deletes the old release and points `yarnPath` at the new one.
  It drops an integrity hash without a warning, so when the old pin carried one, run
  `YARN_ENABLE_SCRIPTS=false corepack use yarn@<version>` afterwards to write it back. That runs an
  install, which in Step 4 re-resolves nothing the lock file already records. In Step 7, which
  reaches a Yarn pin only in a repository with no `yarn.lock`, the install resolves the whole tree
  ungated and creates `yarn.lock`, `.pnp.cjs` and `.yarn`. Delete every file it added that
  `git status --porcelain` shows as untracked before Step 12, which stages any `yarn.lock` that
  exists.
- **pnpm or npm** — edit the version in the field by hand. When the old pin carried a hash, run
  `pnpm_config_ignore_scripts=true corepack use pnpm@<version>` or
  `npm_config_ignore_scripts=true corepack use npm@<version>` instead, which writes the field with a
  fresh hash and runs an install with no dependency scripts; pnpm ignores the `npm_config_` form.
  The pnpm install rewrites `pnpm-lock.yaml` even when nothing resolves differently; the npm install
  changes `package-lock.json` only when something does.

[Step 12](SKILL.md#step-12-commit-push-and-create-the-pr) stages `package.json` and whichever of
`.yarnrc.yml`, `.yarn/releases`, the Plug'n'Play files and the lock file changed, the old release's
deletion included.

Then run `corepack <name> --version` from the repository root, which should print the new version. A
bare `npm --version` would not: `corepack enable` installs no npm shim by default, so it runs the
system npm. Record the bump for the commit message with its release notes like any other pin;
[Tool and Image Pins](changelogs.md#tool-and-image-pins) says where Yarn's live, and pnpm and npm
publish theirs as ordinary GitHub releases.

### Verify the Bumps

After bumping a mise pin, install it and run it from the directory that holds the pin —
`mise install`, then `<tool> --version`, which should print the new version. If the Terraform CLI
moved, Steps 5 and 6 ran `init` and any plan with the old one, so re-run
[Step 6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files)'s `init -upgrade` in every
root module with the new CLI, and plan again wherever Step 6 did. Otherwise the lock files and plan
in the PR come from a CLI it no longer pins.

After bumping an orb, run `circleci config validate <file>` on each CircleCI config file that
changed. It resolves every orb against the registry and exits nonzero, naming the reference, when a
version does not exist or the config no longer compiles against the new one. A private orb resolves
only with a token for its organization, which the CLI takes from `--org`, a `circleci project link`
binding or the git remote, in that order; pass `--org <vcs>/<org>` when the remote does not name the
orb's organization. When validation still cannot reach the orb, say so rather than calling the bump
verified.

A provisioning pin cannot be run here, so add an unchecked
`- [ ] Provision a host with the new <service> version` item to the PR's test plan, since nothing in
this run exercised it.

### Close Open Security Alerts

Check the repository's open security alerts, so the run neither closes one silently nor skips the
one bump that would close it:

```bash
gh api 'repos/{owner}/{repo}/dependabot/alerts?state=open' --paginate \
  --jq '.[] | [.number, .dependency.package.name,
               (.security_vulnerability.first_patched_version.identifier // "no fix")] | @tsv'
```

Bump anything with a fix that this run has not already reached, like any other update: a gem with
`bundle update <gem> --conservative --cooldown 1`, and an npm package with the gated prefix from
[Run Yarn with a Release-Age Gate and No Install Scripts](javascript.md#run-yarn-with-a-release-age-gate-and-no-install-scripts),
which also says when to drop the gate variable — a transitive package with the first command below
and a direct one with the second:

```bash
YARN_ENABLE_SCRIPTS=false YARN_NPM_MINIMAL_AGE_GATE=1440 yarn up -R '<pkg>'
YARN_ENABLE_SCRIPTS=false YARN_NPM_MINIMAL_AGE_GATE=1440 yarn up '<pkg>@<operator><patched-version>'
```

`<operator>` is the one the package's range had before the bump, none for an exact pin, so a hold
Step 4 restored stays a hold: a bare `yarn up '<pkg>'` rewrites the range to `^<latest>`, turning an
exact `3.7.1` into `^4.0.0`. A direct package still short of a fix after Step 4 is usually one Step
4 put back as a hold, so this matters most here. `--cooldown 1` is the gem gate from
[Step 3](SKILL.md#step-3-update-ruby-dependencies), omitted under the same rule; unlike the
variable, the flag outranks the project's local configuration. A Bundler without cooldown support
rejects the flag rather than ignoring it, so drop it there. If the fix lies outside every range that
holds the package, tell the user rather than adding a `resolutions` entry. Record each bump like any
other, and note every alert the run closes for the PR summary in
[Step 12](SKILL.md#step-12-commit-push-and-create-the-pr). Never dismiss an alert without the user's
say-so. A `403` or `404` means alerts are off or out of reach for this token; say so and carry on.

A fix younger than the release-age gate does not wait for it: an open alert is a known
vulnerability, while the gate guards against a compromise not yet known. The gated gem bump and the
gated transitive npm bump do not fail on a young fix when an older release satisfies their ranges:
each skips the fix, resolves the newest release old enough and exits 0, so compare the version it
resolved with the alert's patched version. The gated direct npm bump names the patched version, so
the gate refuses it instead (`YN0082` … `No candidates found`, exit 1). When a gated bump came up
short or was refused, take only that package past the gate:

- **A gem** — rerun the bump as `bundle update <gem> --conservative --cooldown 0`. The flag outranks
  every other cooldown setting, the project's local configuration included, so none holds the fix
  back; `--conservative` keeps the rest of the tree where it is.
- **A direct npm dependency** — the same spec with the restore prefix,
  `YARN_ENABLE_SCRIPTS=false yarn up '<pkg>@<operator><patched-version>'`
- **A transitive npm package** — `YARN_ENABLE_SCRIPTS=false yarn up -R '<pkg>'`. `-R` takes no
  version (Yarn rejects one with `Ranges aren't allowed when using --recursive`), so it moves the
  package to the newest release its ranges allow, which can be newer than the patched one; read its
  new `version:` in `git diff yarn.lock`.

An ungated bump also resolves, without the gate, any new dependency the patched release declares, so
read the lock file diff afterwards and name each package that came in this way beside the bypass in
the PR body.

After any gem bump in this step, and after any made under
[Version-Locked Packages](version-locked.md#version-locked-packages), run the script in
[Check Every Moved Gem's Release Age](SKILL.md#check-every-moved-gems-release-age) again, where only
a gem bumped past the gate above, or a new dependency it brought in, may show as younger than one
day, and repeat [Re-check the Project's Gem Holds](SKILL.md#re-check-the-projects-gem-holds) for
what moved. After any npm bump in this step, repeat Step 4's hold check for that package —
`yarn why` and the two checks after it, in
[Re-resolve the Lock File](javascript.md#re-resolve-the-lock-file).

### Stop If Nothing Changed

Steps 3 through 7 are the only steps that update dependencies, so whether there is anything to ship
is known now. Read the tracked changes only, since working documents Step 2's checkout carried
across show as untracked: if `git status --porcelain --untracked-files=no` prints nothing, tell the
user that no dependency moved, offer to delete the empty branch from
[Step 2](SKILL.md#step-2-create-the-feature-branch) and stop here. If it lists only `yarn.lock`, and
in a Plug'n'Play repository that commits them `.pnp.cjs`, `.pnp.loader.mjs` and files under
`.yarn/cache/` — no gem, direct package, Terraform pin or tool pin moved, only the transitive
dependencies Step 4 re-resolved — ask the user whether to ship a lock-file-only refresh. If they
decline, run `git restore` on each file it listed, remove the new archives
`git status --porcelain -- .yarn/cache` shows as untracked, offer to delete the branch and stop.
