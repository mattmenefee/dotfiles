# Update Dependencies: Impact Analysis

## Step 10: Analyze the Impact of Every Change

Release notes say what a maintainer meant to change, not what the app will see. A patch release can
move a hook or widen an allow list under a note that carries no warning keyword, and a changelog can
report no behavior change over a diff that has several. So triage every dependency that moved, and
read the code diff of each Deep one, whose release touches something the app relies on, whatever its
version number. Run this step after [Steps 8 and 9](linters.md#step-8-handle-rubocop-updates), on
the dependency set that ships: a linter bump is a moved dependency like any other, and
`bin/rubocop -A` rewrites source, so `file:line` evidence taken before it can go stale.

### List What Moved

List every dependency that moved, direct and transitive:

- **Gems** — each spec line that changed in `git diff Gemfile.lock` (the four-space-indented
  `name (version)` lines), Bundler and the Git-sourced gems from
  [Step 3](SKILL.md#step-3-update-ruby-dependencies) and the linter gems
  [Steps 8 and 9](linters.md#step-8-handle-rubocop-updates) handled
- **npm packages** — each `"<name>@npm:` entry whose `version:` changed in `git diff yarn.lock`,
  transitive ones included, and the Git and URL dependencies
  [Step 4](javascript.md#step-4-update-javascript-dependencies) recorded
- **Terraform** — the providers and modules
  [Steps 5 and 6](terraform.md#step-5-decide-terraform-version-bumps) recorded
- **Tool and image pins** — the bumps [Step 7](pins.md#step-7-update-tool-and-image-pins) recorded

### Triage Into Two Tiers

Sort each dependency into a tier by what its release touches, never by its version number or the
keywords in its notes:

- **Deep** — a direct dependency, or a transitive one on a path the app relies on, whose release
  touches any of these: sanitization or HTML rendering, authentication or authorization,
  serialization or persisted formats, content the app stores (an editor that writes markup), the
  deploy or SSH path, request building or signing, test framework semantics (matchers, mocks,
  example groups) or a Terraform provider resource type the configuration uses. A dependency the
  project's `CLAUDE.md` names in a hold or a specialized-agent trigger is always Deep.
- **Quick** — everything else. For a direct dependency, read its changelog entry, and where the
  entry is boilerplate, such as a code-generated SDK bump or a packaging fix, read the file list of
  its diff (below) instead. A transitive one gets no changelog read: record in one line why it is
  not on a Deep path, from `yarn why <pkg>` for an npm package or the dependency entries in
  `Gemfile.lock` for a gem. When the reading or the path check shows a Deep touchpoint, move the
  dependency to Deep; otherwise record "no Deep touchpoint" with the evidence that shows it.

### Read the Code Diff of Each Deep Dependency

Read the code diff, not only the release notes. Three sources are fastest:

- **Gems** — `bundle update` normally leaves both versions installed, so compare them locally, with
  no network. List both directories first, since a platform gem's directory ends in its platform
  (`nokogiri-<version>-arm64-darwin`):

  ```bash
  gems="$(gem env gemdir)/gems"
  ls "$gems" | grep '^<name>-[0-9]'
  diff -ruN "$gems/<old directory>" "$gems/<new directory>"
  ```

  When the new version is missing there, the project installs gems elsewhere, and
  `bundle info --path <name>` prints where it lives. When the old one is gone, fetch and unpack it
  in a private directory, never the project root, or compare on GitHub as below:

  ```bash
  dir="$(mktemp -d)" && (cd "$dir" && gem fetch <name> -v <old> && gem unpack <name>-<old>.gem)
  ```

- **npm packages, and anything else on GitHub** — read the file list first, to see whether CSS,
  public API or stored-format code changed, and then only those files' hunks:

  ```bash
  gh api 'repos/<owner>/<repo>/compare/<old>...<new>' --jq '.files[].filename'
  gh api 'repos/<owner>/<repo>/compare/<old>...<new>' \
    --jq '.files[] | select(.filename == "<path>") | .patch'
  ```

  Pass each release's tag as the repository names it: `v1.2.3`, `1.2.3` or `<pkg>@1.2.3` in a
  monorepo. The file list stops at 300 files; past that, compare the published packages locally,
  each fetched into a private directory with `npm pack <pkg>@<version> --pack-destination "$dir"`,
  `$dir` being a `mktemp -d` directory as above.

- **Terraform providers** — compare the files the release changed with the resource and data source
  types the configuration uses. The second listing reads the module copies
  [Step 6](terraform.md#step-6-re-resolve-and-verify-terraform-lock-files)'s `init -upgrade`
  downloaded into each root module's `.terraform/modules/`: they are untracked, but they hold the
  resources a registry or Git module creates:

  ```bash
  git grep -ohE '^(resource|data) "[a-z0-9_]+"' -- ':/*.tf' ':(top,exclude)*.terraform/*' | sort -u
  find . -path '*/.terraform/modules/*' -name '*.tf' \
    -exec grep -hoE '^(resource|data) "[a-z0-9_]+"' {} + | sort -u
  ```

Then find the app's touchpoints, with grep or an LSP, for each class, method, hook, option and
configuration key the diff changes, and give each Deep dependency one impact level with `file:line`
evidence:

- **None** — the app never reaches the changed code
- **Low** — the app reaches it, but what the app sees or stores does not change
- **Needs a change** — the app breaks, or behaves differently in a way that matters, until its own
  code changes

Two checks settle what reading alone cannot:

- **Eager loading** — for any change to boot, initializers or hook order (`on_load`,
  `after_initialize`, `to_prepare`), check the behavior with eager loading both on and off. An
  initializer that runs after an engine's hook under lazy loading can run before it under eager
  loading, which production enables and CI often does. `config/environments/test.rb` shows what
  turns it on in test, often an environment variable such as `CI`.
- **Probes** — a `bin/rails runner` check, or a plain-Ruby probe of a matcher or API run once
  against each installed version (`gem '<name>', '<version>'` before the `require` selects one),
  answers a question faster than reading. Run a matcher probe inside an object that includes
  `RSpec::Matchers`: at the top level, `include` resolves to `Module#include` rather than the
  matcher, and the probe reports nonsense.

### Delegate by Domain

When more than one dependency is Deep, delegate the reading by domain; a single Deep dependency the
main session reads itself. Send each domain to the specialized agent the project's `CLAUDE.md` names
for it, such as a Rails, frontend, infrastructure or security agent, and fall back to a
general-purpose agent where it names none. Send them all in one message so they run in parallel, and
give each its dependencies with their old and new versions, the diff sources and impact levels above
and the eager-loading and probe checks.

The agents work read-only in this checkout: no edits, commits or spec runs. Several agents running
specs in one checkout corrupt each other's test database, and an isolated worktree is no way around
that: an ad hoc worktree has no credentials, so the app cannot boot there, and a project's rules may
forbid copying keys into one. An agent that needs a spec to settle a question names the command, and
the main session runs it.

### Verify Before Relaying

Whether the main session or an agent read the diff, the main session runs the specs that cover each
touchpoint before recording its impact, after whatever check the project's `CLAUDE.md` requires
before running specs in a shared checkout. An agent's finding is a lead, not a result. Before
recording one:

- Re-check its load-bearing claim against the live source: the installed gem's file, the compare
  diff or the app's `file:line`. Most findings rest on one or two such claims, each checkable in a
  single command.
- Run every spec an agent recommends.
- Fix a finding the bump causes in the dependency commit itself, since a commit that fails CI must
  not land, and run `bin/rubocop -A` over the Ruby files the fix changed and `bin/rails lint:haml`
  when it changed a Haml file. Ask the user about a pre-existing problem the analysis merely
  surfaced; do not fix it unasked.

### Write the Impact File

Save the verified findings to `<branch>-IMPACT.md` in the project root. Like a review or handoff
file, it is an untracked working document: leave it out of the commit and out of `.gitignore`, and
do not hard-wrap it — one line per paragraph or table row — since a ship command may post it with
its line breaks intact. Write it knowing it will be published: summarize plan and command output
rather than pasting it. Write none of these, quoted or summarized:

- Credentials
- Hostnames, IP addresses and CIDR ranges of the project's or the user's own infrastructure, the
  user's own IP address included, even one allowed through a firewall only for this run
- Account IDs and cloud resource names, IDs and ARNs, state bucket names included
- The SSH keys installed on hosts: their owners, comments, types, fingerprints and the keys
  themselves, and the accounts they log in as
- Anything read from the user's machine outside the project checkout, such as `~/.ssh` or a local
  tool's configuration

Cite the project's own files by path relative to the project root, and the specs and probes run
against them by command and result, but keep the values above out of what you quote from them.
Published package source that the code diff compares, installed gem directories and fetched packages
included, is not the user's: quote it, with the home directory written as `~`, along with any host
or range it contains, such as one a release adds to an allow list. The exemption covers only values
found in the package itself; the same value read from the project's own configuration stays out.

```markdown
# Dependency Impact Analysis

| | |
| --- | --- |
| **Branch** | `<branch>` |
| **Base** | `<short SHA of HEAD>`; the analysis covers the uncommitted dependency changes on top of it |
| **Created** | <YYYY-MM-DD> |
| **Dependencies analyzed** | <n> Deep, <n> Quick |

## Summary

| Finding | Severity | Category | Dependency | Impact | Status |
| --- | --- | --- | --- | --- | --- |
| F1 | 🔴 Critical | Security | <name> <old> → <new> | Needs a change | ✅ |
| F2 | 🟢 Low | Test framework | <name> <old> → <new> | Low | 🚫 |

## Deep Dependencies

### F1 🔴 Critical - <name> <old> → <new>: <domain, e.g. sanitization> — <one-line impact>

- **Tier** — Deep: <what it touches, and any `CLAUDE.md` hold or agent trigger>
- **What changed** — <the change the diff shows, which may differ from the release notes>
- **Touchpoints** — `<file>:<line>`, …
- **Impact** — <None, Low or Needs a change, and why>
- **Evidence** — <the command or spec run that shows it, and its result>
- **Manual check** — <a check no command here can run, or none>
- **Status** — <what was done, or the user's ruling>

## Quick Dependencies

- <name> <old> → <new> — no Deep touchpoint: <evidence>
```

Give every Deep dependency a finding, one whose impact is None included, so the file shows it was
read. A severity comes from the review files' scale, 🔴 Critical, 🟠 High, 🟡 Medium or 🟢 Low, with
⚖️ Decision for a choice the user must make. The Status cell takes ✅ (fixed), ⏸️ (deferred), 🚫 (no
action needed) and ❓ (awaiting the user), the same glyphs review files use, and never a blank cell
or a dash, which would read as settled. Unlike a review file's, most of these statuses are the
session's to set, since an impact backed by evidence is a measurement rather than a defect awaiting
triage: a finding whose impact is None or Low and needs no change takes 🟢 Low and 🚫, with its
evidence on its Status line, and one that needed a change takes ✅ once the fix is in the working
tree and its specs pass, so it ships in the dependency commit. Keep ❓ for a pre-existing problem put
to the user and for a ⚖️ Decision. A ship command's check for open review rows then works on this
file as it stands, once its discovery also matches `*-IMPACT.md`; its stats should count 🚫 here as
no action, not as ignored.

File a finding that weakens security, such as a sanitizer, authentication, authorization or
request-signing regression, under the category `Security`, and name the domain in its heading: a
ship command's check for a deferred 🟠 High weakness looks for that category, not for the domain.

This skill never posts the impact file. A project whose ship command posts review and handoff files
to the pull request should post it the same way, as a sanitized copy in a collapsed comment, once no
finding is ❓. Elsewhere, the PR body's Impact analysis section
([Step 12](SKILL.md#step-12-commit-push-and-create-the-pr)) and the commit body's impact sentences
([Step 11](SKILL.md#step-11-build-the-final-commit-message)) are the only published record.
