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
- **An image or variable that names a language runtime follows that runtime's version file.** A Ruby
  image (`cimg/ruby`, `ruby`) or a `ruby_version` variable stays at `.ruby-version`'s version and is
  left alone with it; a Node image (`cimg/node`, `node`) or a `nodejs_version` or `node_version`
  variable moves only with `.node-version` or `.nvmrc`, to the same version. Bumping one alone runs
  CI or a server on a runtime the app does not pin
- **A major waits for the user.** Bump within the current major without asking. Stop and ask before
  a major, naming what its release notes say breaks, as [Step
  5](terraform.md#step-5-decide-terraform-version-bumps) does for a Terraform major
- **A major-only pin moves only by a major.** A pin such as `"18"`, `"9.x"` or `node = "22"` already
  admits every release in its major, so there is nothing to bump within it; a major bump waits for
  the user like any other
- **A Terraform CLI pin must still satisfy every `required_version`** found in Step 5. Never widen
  `required_version` to fit a new CLI
- **Leave `.ruby-version` and CI orb versions alone** unless the user asks: a Ruby upgrade is its
  own change, and orbs follow their own release process

Two lookup traps are recorded under [Known Changelog Quirks](changelogs.md#known-changelog-quirks):
tags that do not start with a digit, and release pages that only point elsewhere.

Record every bump for the commit message with its upstream release notes, in the same format as the
other entries. [Step 11](SKILL.md#step-11-commit-push-and-create-the-pr) checks that every staged
pin change has one.

### Verify the Bumps

After bumping a mise pin, install it and run it from the directory that holds the pin —
`mise install`, then `<tool> --version`, which should print the new version. If the Terraform CLI
moved, Steps 5 and 6 ran `init` and any plan with the old one, so re-run Step 6's `init -upgrade` in
every root module with the new CLI, and plan again wherever Step 6 did. Otherwise the lock files and
plan in the PR come from a CLI it no longer pins.

A provisioning pin cannot be run here, and the role that reads it installs from its own source — an
apt or yum repository, a vendor package repository or a download URL — which can lag the newest
upstream release or name it differently. Before bumping one, confirm the new version exists where
the role's tasks install from. Then add an unchecked
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
`bundle update <gem> --conservative`, a transitive npm package with the gated `yarn up -R '<pkg>'`
and a direct one with the gated `yarn up '<pkg>'` (both from [Step
4](javascript.md#step-4-update-javascript-dependencies)). If the fix lies outside every range that
holds the package, tell the user rather than adding a `resolutions` entry. Record each bump like any
other, and note every alert the run closes for the PR summary in [Step
11](SKILL.md#step-11-commit-push-and-create-the-pr). Never dismiss an alert without the user's
say-so. A `403` or `404` means alerts are off or out of reach for this token; say so and carry on.

### Stop If Nothing Changed

Steps 3 through 7 are the only steps that update dependencies, so whether there is anything to ship
is known now. If `git status --porcelain` prints nothing, tell the user that no dependency moved,
offer to delete the empty branch from [Step 2](SKILL.md#step-2-create-the-feature-branch) and stop
here. If it lists only `yarn.lock` — no gem, direct package, Terraform pin or tool pin moved, only
the transitive dependencies Step 4 re-resolved — ask the user whether to ship a lock-file-only
refresh. If they decline, run `git restore yarn.lock`, offer to delete the branch and stop.
