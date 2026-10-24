# Update Dependencies: JavaScript

## Step 4: Update JavaScript Dependencies

Skip this step if the repository has no `yarn.lock`. Run every command in it from the repository
root, where Yarn keeps the lock file, and read the Yarn version and the repository's own release-age
gate first:

```bash
cd "$(git rev-parse --show-toplevel)"
yarn --version
yarn config get npmMinimalAgeGate
```

If `yarn --version` prints `1.x`, stop and tell the user: this step needs Yarn 2 or later, and Yarn
Classic has no `yarn up`.

### Run Yarn with a Release-Age Gate and No Install Scripts

The commands below take the newest release of every package in the tree, including releases
published minutes ago. Every `yarn` command in this step and in [Version-Locked
Packages](version-locked.md#version-locked-packages) that resolves packages — `yarn up` in any form
— carries one of two prefixes, so a malicious release has had time to be caught and pulled before it
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
  body (see [Step 11](SKILL.md#step-11-commit-push-and-create-the-pr)). The gate guards against
  taking a new release, which is why the restore prefix leaves it out. If it refuses a version a
  gated command needs, stop and tell the user rather than dropping the gate.
- **`YARN_ENABLE_SCRIPTS=false`** stops postinstall and build scripts. Nothing later in this command
  builds the app, so the only cost is that a package with a build step stays unbuilt until the next
  plain `yarn install` on a developer machine.

Each command runs in a fresh shell, where an `export` would not carry over, so write the prefix out
on every command.

### Update the Direct Dependencies and Restore Holds

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
Then check the [Version-Locked Packages](version-locked.md#version-locked-packages), which name the
version a hold must take, and put every hold back in one call with the restore prefix:

```bash
YARN_ENABLE_SCRIPTS=false yarn up '<pkg>@<spec>' '<pkg>@<spec>'
```

This call leaves out the age gate on purpose. With the gate on, a hold bumped in the last three days
is quarantined, and Yarn fails the whole call over it, restoring none of the holds. An exact spec
restores a version the repository already commits, so it takes nothing new. A restored range — a
tilde, or a caret on a prerelease — can resolve to a release younger than three days; the gated
re-resolution below moves it back. A hold that must move to a version the repository does not yet
commit (a re-pin under [Version-Locked Packages](version-locked.md#version-locked-packages)) is a
new release: run it in its own call, with the gated prefix.

Holds can also live outside the direct ranges. A `resolutions` block in `package.json` survives the
re-resolution below. A hold the lock file alone keeps — a transitive package left below its newest
release with no `resolutions` entry — does not, so if the project's `CLAUDE.md` or README documents
one, ask the user whether to move it into `resolutions` before going on.

### Re-resolve the Lock File

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
re-resolution failed and why, note it for the PR body (see [Step
11](SKILL.md#step-11-commit-push-and-create-the-pr)) and carry on with the hold check and Record the
Direct Dependency Changes below, which work from the lock file as it stands. If the error is
`YN0028` (the lockfile would be modified), Yarn has turned on immutable installs because it believes
it is running in CI; retry once with `YARN_ENABLE_IMMUTABLE_INSTALLS=false` added to the prefix.

Re-resolve here, before the changelog and commit steps (Steps 10 and 11), so they work from the lock
file that ships.

Then check that every hold survived. For each version-locked package and each hold restored above,
list every resolved copy:

```bash
yarn why <pkg>
```

Every copy should be at the held version. If the held package itself moved, restore it with
`yarn up '<pkg>@<spec>'` and the restore prefix, and repeat the check. A second copy at another
version is reported to the user, not worked around: a transitive range the hold used to satisfy can
now resolve higher — a `jquery: >=1.11` dependency taking jQuery 4 beside a held 3.7.1 — and only
the user can say whether it needs a `resolutions` entry.

### Record the Direct Dependency Changes

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
out. When `yarn.lock` changed at all, [Step 10](SKILL.md#step-10-build-the-final-commit-message)
adds one line saying the lock file was re-resolved, which stands in for them.

For each direct JavaScript dependency that changed version, build a changelog entry in the same
format as `gem_update` output:

```text
* @scope/package-name 1.0.0 → 1.1.0
[changelog](https://github.com/owner/repo/blob/main/CHANGELOG.md#anchor)
```

Look up changelog URLs by checking the package's repository field on npm or its GitHub releases
page. Include anchor tags to the specific version heading when available.
