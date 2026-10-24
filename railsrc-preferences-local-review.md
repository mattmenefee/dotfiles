# Code Review: 15 files on railsrc-preferences

| | |
| --- | --- |
| **Scope** | Changes on branch railsrc-preferences since merge-base b989ea7 with main (commits 60c0caa, 84aece5, 17ad3f7, 22f4736, b4d0577) |
| **Branch** | `railsrc-preferences` |
| **Reviewed** | 2026-10-24 |
| **Reviewers** | Rails (ruby-on-rails-expert), code quality (code-best-practices-reviewer), security (security-reviewer), testing and CI (test-suite-architect), deployment and operations (another project's infrastructure-expert), front-end build (another project's frontend-javascript-expert) |
| **Reviewed by** | Opus 5.5 (`claude-opus-5-5`), all six reviewers |
| **Collated by** | Opus 5.5 (`claude-opus-5-5`) |

## Files

| File | Commit |
| --- | --- |
| `home/.railsrc` | `60c0caa` |
| `home/.rails/template.rb` | `b4d0577` |
| `home/.rails/files/app/assets/stylesheets/application.scss` | `60c0caa` |
| `home/.rails/files/app/views/layouts/application.html.haml.tt` | `22f4736` |
| `home/.rails/files/app/views/layouts/mailer.html.haml` | `22f4736` |
| `home/.rails/files/app/views/layouts/mailer.text.haml` | `22f4736` |
| `home/.rails/files/config/initializers/dartsass.rb` | `60c0caa` |
| `home/.rails/files/esbuild.config.mjs` | `60c0caa` |
| `home/.rails/files/github/ci_jobs.yml` | `b4d0577` |
| `home/.rails/files/kamal/redis_accessory.yml` | `84aece5` |
| `home/.rails/files/lib/tasks/postcss.rake` | `60c0caa` |
| `home/.rails/files/postcss.config.js` | `60c0caa` |
| `home/.rails/files/rubocop.yml` | `60c0caa` |
| `home/.rails/files/spec/support/factory_bot.rb` | `60c0caa` |
| `home/.rails/files/spec/support/shoulda_matchers.rb` | `60c0caa` |

## Review History

### 2026-10-24 — Initial review by Opus 5.5 (`claude-opus-5-5`)

Six reviewers reported (Rails, code quality, security, testing and CI, deployment and operations, front-end build). Duplicates were merged into 46 findings, F1–F46; one claim was withdrawn under Checked and refuted after the orchestrator's check.

### 2026-10-24 — Reconciled by Opus 5.5 (`claude-opus-5-5`) (F1–F4, F6–F11, F13, F14, F16–F20, F23–F30 fixed; G1–G7 and G9–G14 closed; branch rebased onto `b989ea7`, SHAs remapped)

## Overall Assessment

The branch has no 🔴 Critical or 🟠 High finding, and two actionable findings remain open, both ruled. Every ⚖️ Decision is ruled and its edit is in (F12 deferred to a follow-up branch), and 25 findings are ✅ Fixed in the fourteen commits from `e23deeb` to `6af622c`, closing G1–G7 and G9–G14, each verified against a regenerated app as its Status line records. G15 (F31) remains: reword `60c0caa`'s message to drop its serial commas, a history rewrite that needs another force-push. G16 (F22) remains: generate new apps with Yarn 4, which waits on a machine change (Yarn 4 as corepack's global default) before the template can write `.yarnrc.yml` with `nodeLinker: node-modules` and switch the CI job to `--immutable`. Under Not recommended, F5 and F21 are ignored and F15 is deferred with F12. One claim, that the `bin/rubocop -A` comment describes an abort that cannot happen, was checked and refuted. All six reviewers and the collator ran on Opus 5.5 (`claude-opus-5-5`).

## Correctness

### F1 ~~🟡 Medium Priority - The `REDIS_URL` and redis-gem edits fail silently, unlike the job-role edit beside them~~ ✅ Fixed

- **File** — `home/.rails/template.rb`
- **Location** — `setup_kamal` (template.rb:76); top level (template.rb:15)
- **Issue** — `setup_kamal_worker` uses `gsub_file!` because, as 17ad3f7 says, a reshaped Rails block should stop `rails new` rather than deploy without a worker. The edits it depends on don't follow the same rule. `setup_kamal` writes `REDIS_URL` with plain `gsub_file` against the string `"  # clear:\n"`; Thor's `actually_gsub_file` raises only for the bang form. If Rails 8.2 renames or re-indents that commented line (it sits inside an `<% if skip_solid? -%>` branch of `deploy.yml.tt`), `rails new` exits 0 with no `REDIS_URL`, the web and job containers fall back to `redis://localhost:6379`, and the first `perform_later` in production raises a connection error. `uncomment_lines 'Gemfile', /gem "redis"/` is also non-bang `gsub_file`; if it misses, production Action Cable (cable.yml `adapter: redis`) fails with a LoadError on the first WebSocket connection, again with no signal at generation time.
- **Suggestion** — Change template.rb:76 to `gsub_file!`. Thor 1.5 has no `uncomment_lines!`, so replace line 15 with the regex `uncomment_lines` builds internally: `gsub_file! 'Gemfile', /^(\s*)#[[:blank:]]?(.*gem "redis")/, '\1\2'` (or a three-line `uncomment_lines!` helper beside `source_paths`, which F14 can reuse).
- **Recommendation** — Implement; it applies the policy 17ad3f7 already states, at the cost of one character on line 76.
- **Concurred by** — Rails (R2, which also names the top-level `inject_into_file 'Gemfile', after: "group :development, :test do\n"`, whose plain form only warns "File unchanged!", and suggests `inject_into_file!` for it; it adds that with no `REDIS_URL` Sidekiq in the `job` role defaults to `localhost:6379` and crash-loops while `perform_later` in web requests raises), deployment and operations (R1, which adds that production Action Cable falls back to `cable.yml`'s `redis://localhost:6379/1` and that the job role still reports healthy, because Kamal only checks that a non-proxied container is still running after `readiness_delay`)
- **Status** — ✅ Fixed: `e23deeb` uncomments the redis gem with the raising `uncomment_lines!` helper and injects the Gemfile group with `inject_into_file!`; `a78bf11` replaced the `REDIS_URL` gsub with `inject_into_file!` into `env.secret`

## Security

### F2 ~~⚖️ Decision - The Valkey accessory accepts unauthenticated connections from every container on the host's shared `kamal` network~~ ✅ Fixed

- **File** — `home/.rails/files/kamal/redis_accessory.yml`
- **Location** — `home/.rails/files/kamal/redis_accessory.yml:1-11`, `home/.rails/template.rb:73-82` (`setup_kamal`)
- **Issue** — The commit message and the accessory's comment treat "no port is published" as the trust boundary, but the boundary is the Docker network, and on a Kamal host that network is shared. Kamal 2.12 runs every app container on a hard-coded network named `kamal` (`kamal-2.12.0/lib/kamal/commands/app.rb:21`), and accessories default to the same network (`configuration/accessory.rb:4`, `DEFAULT_NETWORK = "kamal"`), so every app deployed to the host, its accessories and kamal-proxy all join it. Rails' deploy.yml comment advertises "multiple apps on a single web server", and this template is meant for every new app, so several generated apps sharing a host is the expected topology. The app connects with `redis://<service>-redis:6379/0` — no password — so the server must accept unauthenticated non-loopback clients (protected mode off, no `requirepass`). A foothold in any container on that host — an RCE in a sibling app, a compromised npm or gem dependency in another service — therefore reaches this app's Valkey and can inject Sidekiq jobs (`Sidekiq::Processor` does `Object.const_get(job_hash["class"])` and calls `perform` with attacker-chosen arguments, so any loaded job class runs against arbitrary records, in a process holding `RAILS_MASTER_KEY`); inject Turbo Stream HTML into every subscribed browser, because Action Cable's production adapter uses the same instance (`config/cable.yml` reads `REDIS_URL`) and a `PUBLISH` to a `<service>_production:` channel is live XSS; and read or alter every queued job's arguments, plus run Lua via `EVAL`, which unpatched builds expose to the October 2025 Lua-engine use-after-free (CVE-2025-49844). Exploitation needs a prior foothold, so this is defense in depth rather than direct exposure, but the blast radius crosses app boundaries and the template replicates it into every app.
- **Options**
  - **(a) Require a password, sourced from a Kamal secret.** In the accessory: `env: secret: [REDIS_PASSWORD]` and `cmd: sh -c 'exec docker-entrypoint.sh valkey-server --appendonly yes --requirepass "$REDIS_PASSWORD"'` (single quotes keep the remote SSH shell from expanding it; re-entering `docker-entrypoint.sh` keeps the image's root drop, which a bare `sh -c 'exec valkey-server …'` would lose). In `setup_kamal`: put `REDIS_URL` under `env.secret` instead of `env.clear`, and append to `.kamal/secrets` `REDIS_PASSWORD=$(rails credentials:fetch redis.password)` and `REDIS_URL=redis://:$REDIS_PASSWORD@<service>-redis:6379/0`, the same `credentials:fetch` pattern Rails' own example uses (Kamal's Dotenv parse substitutes the earlier variable). Cost: each new app needs a URL-safe password (e.g. `openssl rand -hex 32`) in credentials before first `kamal setup` — until then deploy stops with "Secret 'REDIS_PASSWORD' not found", which fails closed — and about ten more template lines that track Rails' `.kamal/secrets` shape.
  - **(b) Keep it unauthenticated and say so.** Rewrite the accessory comment to state that every container on the host's `kamal` network can read and write this Valkey, so an app sharing a host trusts every other tenant on it. No code cost; the cross-app exposure remains wherever apps share a host.
  - **(c) Give each app its own Docker network.** Accessory `network: <service>` plus adding the network to the app roles via `options`. Cost: a `docker-setup` hook to create it, reliance on Docker accepting a second `--network` alongside Kamal's hard-coded one, and app and accessory on networks Kamal does not manage — fragile across Kamal upgrades.
- **Recommended** — (a): it closes the cross-tenant path at the server, needs no app code (Sidekiq and Action Cable both take the password from `REDIS_URL`), and fails closed when the secret is missing.
- **Verification** — unverified: on a host with a deployed generated app, `docker run --rm --network kamal valkey/valkey:8 valkey-cli -h <service>-redis PING` from outside the app's containers; `PONG` confirms, `NOAUTH Authentication required` refutes. For option (a), after `kamal accessory reboot redis`: `docker exec <service>-redis valkey-cli PING` should print `NOAUTH`, and `docker exec <service>-redis ps -o user,args` should show the server running as `valkey`, not `root`.
- **Concurred by** — Rails (R3), deployment and operations (R3)
- **Divergence** — Security filed this as a ⚖️ Decision recommending (a). Rails and deployment and operations each filed it 🟢 Low, recommended Defer, with a fix shaped like (a) (a `requirepass` from a Kamal secret, with `REDIS_URL` moved to `env.secret`): Rails because "it matters only on a host shared with other apps, and the fix drags in `.kamal/secrets` handling"; deployment and operations because it "adds secret plumbing to every new app for a risk that exists only on shared hosts", noting another project's migration has the same gap and that it is contained on a single-app host.
- **Status** — ✅ Fixed: ruled (a) Password from secret; F3, F6 and F27 are worked against the password-protected accessory; `a78bf11` starts Valkey with `--requirepass "$REDIS_PASSWORD"` from a Kamal secret through the image's entrypoint, moves `REDIS_URL` to `env.secret` built in `.kamal/secrets`, and generates the password into the app's credentials during `rails new`. Verified locally in Docker: `PING` without the password returns `NOAUTH`, `valkey-server` runs as UID 999, and Kamal renders the same `docker run` line

### F3 ~~🟡 Medium Priority - The accessory comment steers a later host move toward a public, unauthenticated port~~ ✅ Fixed

- **File** — `home/.rails/files/kamal/redis_accessory.yml`
- **Location** — `home/.rails/files/kamal/redis_accessory.yml:4-6`
- **Issue** — The comment says moving the accessory "means pointing REDIS_URL at that host instead". That move requires publishing the port, and the generated `config/deploy.yml` still carries Rails' commented `redis` example just above the appended block (probe `config/deploy.yml:107-112`) with a bare `port: 6379`. A developer who follows the comment and copies that line binds Valkey to `0.0.0.0` on the new host. Docker's published ports insert iptables rules ahead of ufw or firewalld, so the host firewall the developer believes is protecting it does not (Kamal's own accessory docs warn about this). Combined with F2's missing password, the result is an internet-reachable unauthenticated Valkey — the configuration mass scanners find within hours and use for job injection, Lua and `CONFIG SET`-based cryptominer drops. If F2 (a) lands, the risk drops to a password-protected but plaintext port, about 🟢 Low.
- **Suggestion** — Extend the comment so the safe path is the one written down, e.g. "Moving it to another host means publishing its port on that host's private address only (`port: "10.0.0.2:6379:6379"`) and pointing REDIS_URL there; Docker's published ports bypass the host firewall".
- **Recommendation** — Implement: a comment-only change that closes the most likely route to real public exposure.
- **Concurred by** — deployment and operations (R2, at the same severity and recommendation, suggesting `port: "<private-ip>:6379:6379"`, never a bare `6379`), Rails (R15, whose second point says "pointing REDIS_URL at that host" understates the move because it would also need a published `port:`, and suggests "…means publishing a port and pointing REDIS_URL at that host instead."; it filed this 🟢 Low under Conventions and Style together with F27's missing period)
- **Status** — ✅ Fixed: `a78bf11` rewrites the comment: a host move means publishing the port on a private address only, never a bare 6379

### F4 ~~🟢 Low Priority - Nothing in a generated app updates or audits the npm packages the template adds~~ ✅ Fixed

- **File** — `home/.rails/template.rb`
- **Location** — `setup_bootstrap` and `setup_postcss` (`home/.rails/template.rb:49-64`); `setup_ci` (`home/.rails/template.rb:103-113`) is where the fix belongs
- **Issue** — The template adds `bootstrap` and `@popperjs/core` to the browser bundle and `postcss`, `postcss-cli` and `autoprefixer` to the production asset build, but none of the generated app's checks cover them: the generated `.github/dependabot.yml` lists only the `bundler` and `github-actions` ecosystems, Rails' `scan_js` job is importmap-only and so absent here, and `bundler-audit` does not read `yarn.lock`. A Bootstrap or PostCSS advisory therefore produces no pull request and no CI failure — only a Dependabot alert, and only if someone enabled alerts on the repository, which is not the default for a private one — and the pinned versions ship to production for the life of the app.
- **Suggestion** — In `setup_ci`, append an `npm` entry to `.github/dependabot.yml` (Dependabot's `npm` ecosystem reads `yarn.lock`):

  ```yaml
  - package-ecosystem: npm
    directory: "/"
    schedule:
      interval: weekly
    open-pull-requests-limit: 10
  ```

- **Recommendation** — Implement: five lines matching the file's existing entries give every generated app update PRs for its JavaScript dependencies.
- **Status** — ✅ Fixed: `bd297e8` appends an `npm` entry to `.github/dependabot.yml`; the generated file lists bundler, github-actions and npm

### F5 ~~🟢 Low Priority - Appended CI jobs pin actions by tag and declare no token permissions~~ 🚫 Ignored

- **File** — `home/.rails/files/github/ci_jobs.yml`
- **Location** — `home/.rails/files/github/ci_jobs.yml:7,10,15,42,45,50`; the whole workflow has no `permissions:` block
- **Issue** — `actions/checkout@v6`, `ruby/setup-ruby@v1`, `actions/cache@v4` and `actions/setup-node@v7` are mutable tags, so a retagged release would run in every generated app's CI (the pattern of the 2025 compromise of a third-party action), and without a `permissions:` block the `GITHUB_TOKEN` takes the repository or organization default, which some organizations still set to read-write. The exposure is small: the trigger is `pull_request` (not `pull_request_target`), so fork runs get a read-only token and no secrets; the workflow references no secrets; every action is first-party GitHub or Ruby-org; the jobs copy Rails' own `ci.yml.tt` except `setup-node`, which exists at v7 (v7.1.0, released 2026-10-08); and the generated Dependabot config already covers the `github-actions` ecosystem.
- **Suggestion** — If adopted, prepend `permissions:\n  contents: read` to the workflow in `setup_ci`, and pin each action to a commit SHA with a version comment.
- **Recommendation** — Skip: it matches Rails' generated workflow, which the owner's keep-framework-defaults rule favors, and no secret or write scope is at stake.
- **Status** — 🚫 Ignored: "Ignore (Recommended)" — matches Rails' generated workflow; no secret or write scope at stake

## Deployment and Operations

### F6 ~~🟡 Medium Priority - No memory cap or explicit eviction policy for a queue that shares the web host~~ ✅ Fixed

- **File** — `home/.rails/files/kamal/redis_accessory.yml`
- **Location** — `cmd: valkey-server --appendonly yes` (line 9)
- **Issue** — With no `maxmemory`, Valkey grows without limit on the same host as Puma and Sidekiq; a backlog of large job arguments or a retry storm (the retry set is uncapped) can exhaust host memory, and the kernel's OOM killer then picks the largest process — often Puma — rather than failing writes cleanly. The eviction policy is also left implicit. The default `noeviction` is the right one for Sidekiq, but nothing in the file records why, so someone who later moves the Rails cache into the same instance and adds an LRU policy will silently evict queued jobs. Another project's migration sets `--maxmemory 512mb --maxmemory-policy noeviction` (plus an explicit `--appendfsync everysec`) and gives its reason in its Redis recovery doc; on this point that project is right.
- **Suggestion** — `cmd: valkey-server --appendonly yes --maxmemory 256mb --maxmemory-policy noeviction` (size to taste), with a comment that `noeviction` makes Valkey refuse writes when full rather than drop jobs.
- **Recommendation** — Implement: one line that removes a host-level failure mode from every generated app.
- **Status** — ✅ Fixed: `a78bf11` adds `--maxmemory 256mb --maxmemory-policy noeviction` with a comment on why; `CONFIG GET maxmemory-policy` returned `noeviction` in a local container

### F7 ~~🟢 Low Priority - The job-role rewrite strips `  # ` anywhere in a line, not only at its start~~ ✅ Fixed

- **File** — `home/.rails/template.rb`
- **Location** — `setup_kamal_worker` (template.rb:89)
- **Issue** — `role.gsub('  # ', '  ')` replaces every occurrence of two-spaces-hash-space, not just the comment marker at column 0. The match regex `(?:  # .*\n)*?` accepts any commented line inside the role, so if Rails adds a nested comment to it (as it already does in the non-skip-solid `clear:` block), a line `  #   # Run jobs on a dedicated host` loses both its marker and its inner `  # `, becoming the bare `    Run jobs on a dedicated host` — invalid YAML. `gsub_file!` still sees a change, so `rails new` exits 0 and the break surfaces at the first `kamal` command.
- **Suggestion** — Anchor the replacement: `role.gsub(/^  # /, '  ')`.
- **Recommendation** — Implement; a one-token change that closes the gap the bang was meant to close.
- **Status** — ✅ Fixed: `e23deeb` strips only the leading marker with `role.gsub(/^  # /, '  ')`

### F8 ~~🟢 Low Priority - RuboCop and its plugins ship in the production image~~ ✅ Fixed

- **File** — `home/.rails/template.rb`
- **Location** — `gem_group :test`
- **Issue** — The generated Dockerfile sets `BUNDLE_WITHOUT="development"` only, so `:test` gems are installed in the image. Putting `rubocop` and its seven plugins (plus `parser`, `rubocop-ast` and the rest) in `:test` bakes a linter into every production image; Rails' own `rubocop-rails-omakase` sits in `:development, :test`, which also ships, because Bundler installs a gem unless all of its groups are excluded.
- **Suggestion** — Move the eight RuboCop gems into a `gem_group :development` (or inject them into the existing `group :development do`); the CI lint job's `bundler-cache` installs all groups, so linting is unaffected.
- **Recommendation** — Implement: a move within the template that shrinks the image with no behavior change.
- **Status** — ✅ Fixed: `ec14f79` injects the RuboCop gems into Rails' existing `group :development`

## Testing and CI

### F9 ~~⚖️ Decision - A new app's first CI test run fails because it has no `db/schema.rb`~~ ✅ Fixed

- **File** — `home/.rails/files/github/ci_jobs.yml` (with `home/.rails/template.rb`)
- **Location** — `ci_jobs.yml:64` (`run: bin/rails db:test:prepare spec`); `template.rb` `setup_ci`
- **Issue** — Nearly every new app's first push is a commit with no migrations, so CI goes red and stays red until someone adds one. Unfixed I'd rate it 🟠 High: the template's own aim is that a new app "starts green" — it writes `.rubocop_todo.yml` for exactly that reason, and `b4d0577` exists to restore CI. The commit message names the gap, but nothing in the generated app does, so the developer meets it as a failed run. The failure point is not the one the brief describes. Reading activerecord-8.1.4, `maintain_test_schema!` → `load_schema_if_pending!` → `any_schema_needs_update?` → `DatabaseTasks.schema_up_to_date?` does `return true unless file && File.exist?(file)`, so it neither loads nor raises when the file is missing. The abort comes from `db:test:prepare` → `db:test:load_schema` → `DatabaseTasks.load_schema` → `check_schema_file`, which calls `Kernel.abort` with "db/schema.rb doesn't exist yet". The CI command dies there, before RSpec starts. That changes the fix: editing `rails_helper.rb` would not help. Stock Rails 8.1.4 runs the same `db:test:prepare` in its own `test` job, so a stock app without migrations should fail identically — inherited, not introduced, but the template is where it can be fixed. Local `bin/ci` differs: `bin/setup` runs `db:prepare`, which creates both databases, and `bin/rails spec` then finds no examples and exits 0, so the developer's machine passes while GitHub fails.
- **Options**
  - **(a) Have the template write a placeholder `db/schema.rb`** — as `home/.rails/files/db/schema.rb.tt` rendered with `template`, holding `ActiveRecord::Schema[<%= Rails::VERSION::STRING.to_f %>].define(version: 0)` with `enable_extension "pg_catalog.plpgsql"`. It needs no database at generation time, `db:test:prepare` and `bin/setup` load it, and the first `db:migrate` overwrites it with Rails' real dump, so any drift self-heals. Cost: one more hand-kept file whose header differs from Rails' dumper output until that first migration; `.rubocop.yml` already excludes `db/schema.rb`. Rails' report offers the same fix (`ActiveRecord::Schema[8.1].define(version: 0) { enable_extension "pg_catalog.plpgsql" }`) and adds that it is "Green from the first push, but the file is not Rails-dumped, can produce a small diff on the first `db:migrate`, and departs from a framework default."
  - **(b) Run `rails_command 'db:create db:migrate'` in `after_bundle`.** The schema is exactly Rails'. Cost: every `rails new` needs a running PostgreSQL and creates databases as a side effect, and generation fails when PostgreSQL is down.
  - **(c) Guard the CI step** (e.g. `[ -f db/schema.rb ]`). Cost: the copied job diverges from Rails', the guard also skips `dartsass:build`, which `db:test:prepare` carries, and it leaves `bin/ci` and GitHub inconsistent.
  - **(d) Leave it and note it in the generated `README.md`.** Cost: no work now; every new app's first CI run is red.
  - **(e) Accept Rails' behavior and add a why-comment** above `Run tests` saying the step aborts until the first migration writes `db/schema.rb`. Costs one comment line; first CI run stays red.
  - **(f) Leave as is.** The commit message already states the limitation; nothing in the generated app does.
- **Recommended** — (a) / (e) — Testing and CI recommends (a): it is the only option that makes the first push green without needing a database at generation time, and the first migration replaces it. Rails recommends (e), because the behavior is Rails' own and disappears with the first migration, and the owner's rules favor keeping framework defaults.
- **Verification** — Failure point confirmed: `check_schema_file` in activerecord-8.1.4 `tasks/database_tasks.rb:498-504` calls `Kernel.abort` with "doesn't exist yet", so the CI command aborts inside `db:test:prepare`, before RSpec. The brief given to reviewers wrongly placed it in `maintain_test_schema!`; Testing and CI and Rails both corrected that. Whether stock Rails fails the same way: unverified — `rails _8.1.4_ new stock -d postgresql --skip-bundle=false` with no template, then `RAILS_ENV=test bin/rails db:test:prepare` against a running Postgres; an abort with "db/schema.rb doesn't exist yet" confirms it. Testing and CI's runtime check was not run: in a disposable copy of a freshly generated app before any migration, with PostgreSQL running, `RAILS_ENV=test bin/rails db:create && RAILS_ENV=test bin/rails db:test:prepare; echo $?` should print the "doesn't exist yet" abort and `1`, and `RAILS_ENV=test bin/rails spec; echo $?` should print "0 examples" and `0`.
- **Concurred by** — Rails (R5)
- **Divergence** — Testing and CI filed a ⚖️ recommending (a), its own (a), and rates the problem 🟠 High if left unfixed. Rails filed a ⚖️ recommending (e), its own (a), treating the failure as inherited Rails behavior; Rails' options (a), (b) and (c) appear here as (e), (a) and (f).
- **Status** — ✅ Fixed: ruled Run db:migrate: the template runs `bin/rails db:create db:migrate` in `after_bundle` so Rails writes `db/schema.rb` (a new option, proposed by the user); `560e524` runs `db:create db:migrate` in `after_bundle`, so Rails writes `db/schema.rb`; on a generated app with no migrations, `RAILS_ENV=test bin/rails db:test:prepare spec` exited 0

### F10 ~~⚖️ Decision - `bin/ci`'s RSpec step never builds the Sass bundle, unlike the GitHub job~~ ✅ Fixed

- **File** — `home/.rails/template.rb`
- **Location** — `setup_ci`, `step "Tests: RSpec", "bin/rails spec"`
- **Issue** — dartsass-rails 0.5.1 hooks `dartsass:build` onto `test:prepare` if that exists, else onto `db:test:prepare`. Without the test_unit railtie there is no `test:prepare`, so `bin/rails spec` — which runs only `spec:prepare` (and with it `javascript:build`) — never compiles CSS. The GitHub job runs `db:test:prepare spec` and comments that this is "so the specs see compiled assets". Locally, specs run against whatever `app/assets/builds/application.css` was last built (gitignored), or none on a fresh clone. Propshaft's `stylesheet_link_tag :app` silently skips a missing file, so nothing raises — the run just differs from CI, and once there are system specs a visibility assertion that depends on Bootstrap classes can pass on one and fail on the other. Rails' own `bin/rails test` step builds both bundles via `test:prepare`.
- **Options**
  - **(a) Enhance `spec:prepare`.** In `lib/tasks/postcss.rake` (or a new task file) add `Rake::Task['spec:prepare'].enhance(['dartsass:build'])`, so `bin/rails spec` builds both bundles the way `bin/rails test` does in a Minitest app. Rails: "a one-line enhancement that makes `bin/ci` and the GitHub job see the same assets."
  - **(b) Run the GitHub job's command in `bin/ci`.** `step "Tests: RSpec", "bin/rails db:test:prepare spec"`, the same command as the GitHub job. Testing and CI: "one line, and it gives both CI entry points the same contract." Land it with F9: until F9 is fixed, this would also make `bin/ci` fail on a fresh app.
- **Recommended** — (a) / (b) — Rails filed (a), which needs no schema and so is independent of F9. Testing and CI filed (b), which runs the identical command in both CI entry points but depends on F9.
- **Concurred by** — Rails (R8)
- **Divergence** — Both reports filed this 🟢 Low, recommended Implement, with different fixes: Rails (a), Testing and CI (b). Because the two fixes change different files and (b) depends on F9's ruling, the choice is carried as a ⚖️ Decision.
- **Status** — ✅ Fixed: ruled (a) Enhance spec:prepare; `560e524` copies `lib/tasks/spec_assets.rake`, which adds `dartsass:build` to `spec:prepare`; `bin/rails spec` rebuilt a deleted `application.css`

### F11 ~~⚖️ Decision - Capybara is installed but system specs have no driver, and CI has no place for them~~ ✅ Fixed

- **File** — `home/.rails/template.rb`
- **Location** — `gem_group :test` (`gem 'capybara'`, `gem 'rubocop-capybara'`) and `setup_rspec`
- **Issue** — `-T` makes Rails omit `selenium-webdriver`, the `system-test` CI job and its screenshot upload, and write `config.generators.system_tests = nil`. The template adds `capybara` and `rubocop-capybara` back but configures no driver. In rspec-rails 8.0.4 `SystemExampleGroup` calls `driven_by(:selenium_chrome_headless)` unless a spec sets one, and `ActionDispatch::SystemTesting::Driver` then does `require "selenium/webdriver"`, so the first `type: :system` spec a developer writes fails with a `LoadError` unrelated to the code under test. Turbo and Stimulus behavior can't be browser-tested until someone works out which gem and configuration are missing, and if system specs are added later they run inside the `test` job with no screenshot upload, so CI failures leave no evidence.
- **Options**
  - **(a) Rails' own setup, adapted to RSpec:** `selenium-webdriver` in `:test`; `spec/support/capybara.rb` defaulting `type: :system` to `driven_by :rack_test` and using `driven_by :selenium_chrome_headless` for `js: true`; an `actions/upload-artifact` step in the `test` job (`if: failure()`, path `tmp/screenshots`, `if-no-files-found: ignore`). Chrome is preinstalled on `ubuntu-latest`, which Rails' own job already relies on. Cost: one gem, one support file, one CI step. Rails' report lists the unadapted form — `driven_by :selenium, using: :headless_chrome` for every system spec, plus the screenshot step — at the cost of "a browser in CI and slower specs".
  - **(b) `rack_test` only:** just the support file defaulting to `rack_test` (`config.before(:each, type: :system) { driven_by :rack_test }`). No JavaScript in tests, no new gem; JS-driven flows stay untestable. Rails: "System specs work browserless with no CI changes; JavaScript-dependent specs need a driver added later."
  - **(c) Drop `capybara` and `rubocop-capybara`:** request specs only. Smallest setup; no browser-level tests at all.
  - **(d) `cuprite`** with a `driven_by :cuprite`. Faster headless Chrome over CDP, but one more non-default gem.
- **Recommended** — (a) / (b) — Testing and CI recommends (a): it restores what `-T` removed for a Hotwire front end, matches the decision to restore Rails' CI for RSpec, and the `rack_test` default keeps non-JS specs fast. Rails recommends (b), because it makes the installed Capybara usable today with no CI cost, and leaves the browser choice to the app that first needs JavaScript specs.
- **Concurred by** — Rails (R6)
- **Divergence** — Testing and CI recommended (a), its own (a); Rails recommended (b), its own (a). Rails' (b) is folded into (a) here and its (c) is (d).
- **Status** — ✅ Fixed: ruled (e) match another project's setup: `rack_test` default, `:js` specs on Playwright with Chrome (`capybara-playwright-driver` and the `playwright` npm package), plus a CI screenshot upload step (a new option); `a29703e` adds `capybara-playwright-driver`, a `playwright` npm package pinned to `playwright-ruby-client`'s version and `spec/support/capybara.rb` (`rack_test` default, `:js` on Playwright with Chrome), plus a screenshot upload step; a `rack_test` spec and a `:js` spec both passed in a generated app

### F12 ~~⚖️ Decision - The template is verified only by hand-run probes~~ ⏸️ Deferred

- **File** — `home/.rails/template.rb` (and the repository's `.github/workflows/ci.yml`, which the branch does not change)
- **Location** — whole template
- **Issue** — The repository's CI lints YAML, Markdown, JSON and shell but never lints Ruby or runs the template. Most of the breakage risk is upstream — Rails reshaping `deploy.yml`, `ci.rb`, `ci.yml` or the layouts; rspec-rails rewording `rails_helper.rb`; Thor or dartsass changing a task — and the `!` actions catch some of it but not a silent `uncomment_lines` miss (F14), a change in which rake task the CSS build hooks onto, or a broken generated suite (F9). Each is found on the next real `rails new`, often months later and mid-way through starting an app.
- **Options**
  - **(a) A `rails-template` job in the dotfiles CI**, on `paths: home/.railsrc, home/.rails/**`, a weekly `schedule` and `workflow_dispatch`, with a PostgreSQL service: install Ruby, Node and the `rails` gem; `rails new probe --rc=home/.railsrc -m home/.rails/template.rb` (the `-m` in `.railsrc` points at `~/.rails`, so either link `home/.rails` there or confirm the command-line `-m` takes precedence); then in the app `bin/rubocop`, `bin/kamal config` and `RAILS_ENV=test bin/rails db:test:prepare spec`, plus one generated request spec that renders the HAML layout so the asset builds and layout are exercised. Cost: a several-minute job and one more workflow to maintain; the schedule is what catches upstream drift.
  - **(b) A checked-in probe script, run by hand**, doing the same against a scratch directory. No scheduled run, but the manual probe becomes repeatable rather than reconstructed each time.
  - **(c) Keep manual probes.** No new upkeep; every upstream break is found by the next real `rails new`.
- **Recommended** — (a): the likely failures arrive with upstream releases, not with edits to this repository, and only a scheduled run finds them before a real app does. F9 should land first, or the job must generate a model to get a schema.
- **Status** — ⏸️ Deferred: "Defer (a) to follow-up" — a scheduled rails-template CI job on its own branch

### F13 ~~🟡 Medium Priority - The `test` job drops the "Install packages" step Rails' own job runs~~ ✅ Fixed

- **File** — `home/.rails/files/github/ci_jobs.yml`
- **Location** — `test.steps`, before `Checkout code`
- **Issue** — railties-8.1.4's `github/ci.yml.tt` opens the `test` job with `sudo apt-get install … <%= ci_packages %>`, where `ci_packages` is `dockerfile_build_packages` minus what the runner already has — for this stack `libpq-dev`, `libvips` and `node-gyp`, matching the probe's `Dockerfile` build stage. The template's job omits that step, while `b4d0577` says the job "keeps Rails' PostgreSQL service and adds Node and Yarn", which reads as if nothing else changed. The generated `Gemfile` enables `image_processing` (ruby-vips), so on a runner without libvips any spec that analyzes or transforms an Active Storage image fails, though it passes on a Mac with Homebrew vips; `libpq-dev` matters when the `bundler-cache` is cold and `pg` compiles; `node-gyp` for any native npm package added later.
- **Suggestion** — Restore the step, generated from Rails' own list so it tracks Rails: the template's `after_bundle` block runs in the generator, so `ci_packages` is callable there. Rename the file to `github/ci_jobs.yml.tt`, read it through `ERB.new(…, trim_mode: '-').result(binding)` in `setup_ci`, and add `run: sudo apt-get update && sudo apt-get install --no-install-recommends -y <%= ci_packages.join(" ") %>`. If evaluating ERB in the template isn't wanted, hard-code the three packages with a comment that the list mirrors Rails' `ci_packages`.
- **Recommendation** — Implement: a one-step restore of Rails' own job that removes a CI-only failure local runs won't reproduce.
- **Verification** — The code quality report's premise that "the app has no `image_processing` gem" was checked and is false: the probe's `Gemfile:38` has `gem 'image_processing', '~> 1.2'` uncommented (Rails 8.1's default), which is why the libvips concern stands. Whether `ubuntu-latest` already has `libvips`: checked with `gh api repos/actions/runner-images/contents/images/ubuntu/Ubuntu2404-Readme.md --jq .content | base64 -d | grep -n -E 'libvips|libpq-dev'` — no match, and the 333-line readme's "Installed apt packages" list has neither, so libvips is not preinstalled on `ubuntu-latest` and the finding holds. Whether `libpq-dev` arrives with the runner's PostgreSQL 16.15 install: unverified — `dpkg -s libpq-dev` in a scratch workflow, a non-zero exit confirming the step is needed for it.
- **Concurred by** — Rails (R7, 🟢 Low, Implement, suggesting the hard-coded step ahead of `Checkout code`: `sudo apt-get update && sudo apt-get install --no-install-recommends -y libpq-dev libvips node-gyp`, and noting that `pg` 1.7.0 ships an `x86_64-linux` native gem, so `libpq-dev` is not needed today), code quality (R14, an ℹ️ Observation calling the omission safe today: GitHub's Ubuntu image installs libpq-dev, per runner-images `install-postgresql.sh` lines 25–26, and the app has no `image_processing` gem — the premise refuted under Verification — and noting the b4d0577 message does not mention the omission)
- **Divergence** — Testing and CI filed 🟡 Medium, Rails 🟢 Low, both recommending Implement; code quality filed it as an ℹ️ Observation with no recommendation, on the `image_processing` premise refuted above.
- **Status** — ✅ Fixed: `3fa4c45` opens the `test` job with Rails' `apt-get install … libpq-dev libvips node-gyp` step

### F14 ~~🟢 Low Priority - Uncommenting the `spec/support` loader fails silently if rspec-rails rewords the line~~ ✅ Fixed

- **File** — `home/.rails/template.rb`
- **Location** — `setup_rspec`, `uncomment_lines 'spec/rails_helper.rb', %r{Rails\.root\.glob\('spec/support}`
- **Issue** — Thor 1.5.0's `uncomment_lines` is a plain `gsub_file`, with no bang variant. If a later rspec-rails changes that commented line, the step does nothing, `rails new` still succeeds, and `spec/support/factory_bot.rb` and `shoulda_matchers.rb` are never loaded: the first `create(:widget)` raises `NoMethodError` and the shoulda-matchers integration is missing, with nothing pointing at the template. Elsewhere the template uses `gsub_file!` and `insert_into_file!` against exactly this upstream drift.
- **Suggestion** — Replace the call with `gsub_file! 'spec/rails_helper.rb', %r{^# (Rails\.root\.glob\('spec/support)}, '\1'`, so a reworded template stops generation.
- **Recommendation** — Implement: a one-line change that follows the template's own fail-loudly convention.
- **Concurred by** — code quality (R3, which adds that the line moved from `Dir[...]` to `Rails.root.glob` in an earlier major and suggests the same bang form as F1, or the shared `uncomment_lines!` helper, to be implemented with F1), Rails (R2, which covers this edit together with the F1 edits and filed the set 🟡 Medium, adding that if the line moves FactoryBot's syntax methods and shoulda's integration silently vanish)
- **Status** — ✅ Fixed: `e23deeb` uncomments the `spec/support` loader with the raising `uncomment_lines!` helper

### F15 ~~🟢 Low Priority - The repository's CI does not lint the Ruby this branch adds~~ ⏸️ Deferred

- **File** — `.github/workflows/ci.yml` (context); `home/.rails/template.rb` and `home/.rails/files/**/*.rb`
- **Location** — "Run the linters" step
- **Issue** — The super-linter step enables Bash, GitHub Actions, JSON, Markdown and YAML, not Ruby. Nothing in CI checks `template.rb`, `postcss.rake`, `dartsass.rb` or the `spec/support` files against the owner's RuboCop and line-length rules, so a later edit can drift unnoticed. (The YAML files are covered; yamllint reports only line-length warnings, on ci_jobs.yml:17, 20 and 38, all copied verbatim from Rails.)
- **Suggestion** — In a follow-up, enable `VALIDATE_RUBY` with a repository-root RuboCop config scoped to `home/.rails` (the template's `rubocop.yml` is deliberately dot-less so it doesn't apply here).
- **Recommendation** — Defer; repository tooling, not this feature branch.
- **Status** — ⏸️ Deferred: "Defer (Recommended)" — to the same follow-up branch as F12's template CI job

## Front-End Build

### F16 ~~⚖️ Decision - The esbuild config never minifies in the Kamal image, because the Dockerfile does not set `NODE_ENV`~~ ✅ Fixed

- **File** — `home/.rails/files/esbuild.config.mjs`
- **Location** — `minify: process.env.NODE_ENV === 'production'` (line 12)
- **Issue** — Rails' generated Dockerfile sets `RAILS_ENV=production` but never `NODE_ENV`, so `assets:precompile` → `javascript:build` → `yarn build` always produces an unminified bundle: Bootstrap plus Turbo ship at several times their minified size, with source maps. The production branch of the config is effectively dead. Another project gets minification by setting `ENV NODE_ENV=production` in its build stage after `yarn install`, but that only works there because it uses Yarn 4. Under the template's Yarn 1, jsbundling's `javascript:build` first runs a plain `yarn install` (its `javascript:install` prerequisite), and with `NODE_ENV=production` Yarn 1 skips `devDependencies` — and esbuild, postcss, postcss-cli and autoprefixer are all `devDependencies` in the generated `package.json`. Copying the other project's approach verbatim would break the image build.
- **Options**
  - **(a) Key minification on `RAILS_ENV` as well:** `minify: [process.env.NODE_ENV, process.env.RAILS_ENV].includes('production')`. Works with Rails' Dockerfile unchanged, which respects the decision to keep Docker defaults, and still honors `NODE_ENV` for anyone who sets it. Diverges slightly from the other project's file.
  - **(b) Have the template insert `ENV NODE_ENV=production` plus `SKIP_YARN_INSTALL=1` before `assets:precompile` in the Dockerfile.** Matches the other project's approach, but edits a kept Rails default and adds a second `gsub_file!` that a future Dockerfile reshape can break.
  - **(c) Key minification on `RAILS_ENV` alone:** `minify: process.env.RAILS_ENV === 'production'`, the variable the Rails Dockerfile already sets (Dockerfile:24). Rails: "a one-token change that makes the existing intent real"; front-end build: "a one-line change that makes the config do what it says on every Kamal deploy".
- **Recommended** — (a) / (c) — Deployment and operations recommends (a): a one-line config change, no Dockerfile surgery, safe under both Yarn 1 and Yarn 4. Rails and front-end build each filed (c) as an Implement, keying on the variable the Dockerfile sets.
- **Verification** — unverified at build time: `docker build -t probe .` in the probe app, then `docker run --rm probe sh -c 'head -c 300 /rails/public/assets/application-*.js'`; indented, unminified output confirms the dead `minify` branch. Alternatively (front-end build) `RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile` in a disposable copy, comparing the output `application.js` with the 453,765-byte development build; roughly equal sizes confirm.
- **Concurred by** — Rails (R9), front-end build (R1, which measures the probe's non-minified `app/assets/builds/application.js` at 453,765 bytes — Turbo, Stimulus and all of Bootstrap's JavaScript — and notes that neither `config/deploy.yml` nor CI sets `NODE_ENV` either)
- **Divergence** — Deployment and operations filed a ⚖️ recommending (a), its own (a). Rails and front-end build each filed 🟡 Medium, recommended Implement, with (c) as the fix. All three agree the config must key on a variable the Docker build sets and that setting `NODE_ENV` in the Dockerfile alone would break the Yarn 1 build.
- **Status** — ✅ Fixed: ruled (a) NODE_ENV or RAILS_ENV; `c6ce3fb` minifies when `NODE_ENV` or `RAILS_ENV` is production; `RAILS_ENV=production yarn build` cut `application.js` from 453,765 to 232,958 bytes

### F17 ~~⚖️ Decision - The dartsass initializer replaces the gem's default build options rather than extending them~~ ✅ Fixed

- **File** — `home/.rails/files/config/initializers/dartsass.rb`
- **Location** — lines 3–9
- **Issue** — dartsass-rails 0.5.1 defaults `build_options` to `["--style=compressed", "--no-source-map"]` (`lib/dartsass/engine.rb`). Assigning a new array drops `--no-source-map`, so the probe generates `app/assets/builds/application.css.map` and production serves a CSS source map pointing at Bootstrap's SCSS. Nothing in the file or the commit message says this is intended, and the owner's rules keep framework defaults unless a current need justifies a change.
- **Options**
  - **(a) Extend the defaults** (`build_options.push('--silence-deprecation=…', '--load-path', …)`): keeps the gem's no-source-map default and drops one line; loses CSS source maps in development. Rails offers the variant of keeping `'--no-source-map'` in the assigned array.
  - **(b) Keep the replacement and add a comment** that the CSS source map is wanted (e.g. to match esbuild's `sourcemap: true`): keeps maps; one comment line, and the deviation from gem defaults stays. Front-end build's wording: `# Replaces the defaults, dropping --no-source-map so the build emits a source map`.
- **Recommended** — (a) / (b) — Code quality recommends (a), unless the other project this setup mirrors deliberately ships CSS maps; the JavaScript side already emits maps, so (a) gives up little. Front-end build filed (b) as an Implement, "a one-line comment where a reader could otherwise make a real mistake", and reports that the other project's initializer says the source map is deliberate. Rails filed either as an Implement: "one array element or one comment line".
- **Concurred by** — Rails (R10, which measures the map at 82 KB in the probe, published under `/assets` in production), front-end build (R3)
- **Divergence** — Code quality filed a ⚖️ recommending (a). Front-end build filed 🟢 Low, Implement, with (b) as the fix. Rails filed 🟢 Low, Implement, offering (a)'s variant or (b).
- **Status** — ✅ Fixed: ruled (b) Keep, add comment; F30 is worked in the same edit; `47777e7` keeps the replacement and comments that it drops `--no-source-map` on purpose

### F18 ~~⚖️ Decision - Whether autoprefixer earns its place in a fresh app that only admits modern browsers~~ ✅ Fixed

- **File** — `home/.rails/template.rb`
- **Location** — `setup_postcss` (with `home/.rails/files/postcss.config.js` and `home/.rails/files/lib/tasks/postcss.rake`)
- **Issue** — The generated `ApplicationController` keeps Rails' `allow_browser versions: :modern`, which rejects every browser below the "modern" baseline. The template ships no `.browserslistrc`, so autoprefixer falls back to Browserslist's broad defaults and emits prefixes for browsers the app already turns away. The other project has a `.browserslistrc` tuned to its audience; the template did not carry it. Meanwhile the step costs three devDependencies, a rake task, Node and node_modules as a requirement of `dartsass:build` wherever it runs, and a development/production CSS difference (`dartsass:watch` skips the step, as the rake comment says). In return it adds a handful of declarations — the probe's built CSS has 3 `-webkit-user-select:none` alongside 9 `user-select:none`, and how many of those exist only because of the defaults is unmeasured (see Verification). The owner's settled decision covers Bootstrap via dartsass-rails, not this extra pass, so this is open.
- **Options**
  - **(a) Keep as is.** Matches the other project; prefixes for browsers `allow_browser` blocks, and dev/prod CSS keep differing.
  - **(b) Keep it, and add a `.browserslistrc` matching Rails' `:modern` baseline** (copied by the template). Autoprefixer then targets the browsers actually served, so its output is correct by construction; one more file to keep in step with Rails' definition of `:modern`.
  - **(c) Drop PostCSS.** Removes the Node dependency from `dartsass:build`, the rake enhancement and the dev/prod CSS difference; if Rails ever widens `allow_browser`, prefixes would have to come back.
- **Recommended** — (b): it keeps the decision to mirror the other project's pipeline while making autoprefixer's targets agree with the app's own browser policy.
- **Verification** — unverified: whether autoprefixer under the defaults adds prefixes that a modern baseline would not — in the probe app, `npx autoprefixer --info`, then the same with a `.browserslistrc` set to Rails' `:modern` versions; a near-empty second list supports (b)/(c).
- **Status** — ✅ Fixed: ruled (b) Rails' :modern baseline: a `.browserslistrc` of `safari >= 17.2`, `chrome >= 120`, `firefox >= 121`, `opera >= 106`; `ef9ba1c` copies a `.browserslistrc` with `:modern`'s floors for desktop and mobile Safari, Chrome and Firefox, Opera and Edge; `npx autoprefixer --info` lists exactly those browsers

### F19 ~~🟢 Low Priority - `rails_command 'dartsass:install'` never aborts on failure~~ ✅ Fixed

- **File** — `home/.rails/template.rb`
- **Location** — `setup_bootstrap` (template.rb:50)
- **Issue** — Rails' `execute_command` always passes `abort_on_failure: options[:abort_on_failure]`, so the key is present with value `nil` and Thor's `config.fetch(:abort_on_failure, exit_on_failure?)` returns `nil`. Unlike every bare `run` in the template, a failed `dartsass:install` (e.g. the dart-sass binary unsupported on a platform) is ignored, and `rails new` exits 0 without the `css: bin/rails dartsass:watch` Procfile.dev line or the `app/assets/builds` gitignore entries, while the template goes on to overwrite `application.scss` as if it had run.
- **Suggestion** — `rails_command 'dartsass:install', abort_on_failure: true`.
- **Recommendation** — Implement; one keyword argument makes this step as loud as the template's bare `run` calls.
- **Verification** — Confirmed for `rails_command`: it passes `abort_on_failure: options[:abort_on_failure]` explicitly (railties `generators/actions.rb:467`), so `fetch` returns `nil` and `rails_command 'dartsass:install'` does not abort. The Rails report's broader claim that bare `run` calls never abort was refuted: under the `rails` CLI, `AppGenerator.exit_on_failure?` is reopened to `true` (railties-8.1.4 `commands/application/application_command.rb:8-13`), and Thor's `run` falls back to it (thor-1.5.0 `actions.rb:274`, `config.fetch(:abort_on_failure, self.class.exit_on_failure?)`), so a failing bare `run` does abort `rails new`. Rails' R1 is merged here, narrowed to its surviving `rails_command` claim.
- **Concurred by** — Rails (R1, filed 🟡 Medium against every `run` and `rails_command` call in `setup_esbuild`, `setup_bootstrap`, `setup_postcss` and `setup_rubocop`, suggesting `abort_on_failure: true` on each; only its `rails_command` claim survived the check under Verification)
- **Status** — ✅ Fixed: `e23deeb` passes `abort_on_failure: true` to `rails_command 'dartsass:install'`

### F20 ~~🟢 Low Priority - `stylesheet_link_tag :app` will link every CSS build output, and its comment names the wrong directory~~ ✅ Fixed

- **File** — `home/.rails/files/app/views/layouts/application.html.haml.tt`
- **Location** — lines 21–22
- **Issue** — Propshaft 1.3.2's `:app` expands to every `app/assets/**/*.css` (`app_stylesheets_paths`). In this stack the only CSS is dartsass's output in `app/assets/builds`, so the copied Rails comment "Includes all stylesheet files in app/assets/stylesheets" is wrong for these apps (that directory holds only `.scss`). Adding a second dartsass build — as the other project does with `mailer.scss` → `mailer.css` — or esbuild emitting `application.css` (which it does as soon as any JS imports a CSS file) would put those stylesheets on every page. The other project links `'application'` explicitly.
- **Suggestion** — `= stylesheet_link_tag 'application', 'data-turbo-track': 'reload'`, and drop the comment.
- **Recommendation** — Implement: the template already diverges from Rails' layout by being HAML, and naming the single bundle avoids a page-wide stylesheet leak later.
- **Status** — ✅ Fixed: `da2f0d8` links `stylesheet_link_tag 'application'` and drops the comment

### F21 ~~🟢 Low Priority - The `--load-path` value breaks the CSS build when the app path contains a space~~ 🚫 Ignored

- **File** — `home/.rails/files/config/initializers/dartsass.rb`
- **Location** — line 8
- **Issue** — dartsass-rails builds its command with `build_options.flat_map(&:split)` (`lib/dartsass/runner.rb`), splitting every option on whitespace, so `Rails.root.join('node_modules').to_s` under a path like `~/Client Apps/foo` becomes two arguments and `dartsass:build` fails.
- **Suggestion** — None worth the churn now; a relative `--load-path=node_modules` would avoid the split only if dartsass always runs from `Rails.root`, which would need checking first.
- **Recommendation** — Skip; the owner's apps live under space-free paths and the safe fix needs more verification than the risk warrants.
- **Status** — 🚫 Ignored: "Ignore (Recommended)" — apps live under space-free paths; another project uses the same setting

### F22 🟢 Low Priority - `yarn install --immutable` likely does not enforce the lockfile under Yarn 1

- **File** — `home/.railsrc` (the generated `Dockerfile` follows from the local Yarn version)
- **Location** — generated `Dockerfile:58`; `Dockerfile.tt`'s `yarn install --immutable`
- **Issue** — Rails writes `--immutable` (a Yarn 2+ flag) regardless of Yarn version, and the probe app was generated with Yarn 1.22.22 (`yarn.lock` v1, `npm install -g yarn@1.22.22`). Yarn 1 most likely ignores the unknown flag, so a drifted `package.json`/`yarn.lock` pair would build an image with dependency versions nobody committed — and jsbundling's own unfrozen `yarn install` repeats the risk. Another project avoids this with Yarn 4 via corepack, where `--immutable` does enforce the lockfile.
- **Suggestion** — Generate new apps with Yarn 4 active (corepack), which Rails detects and writes as `corepack enable && yarn set version`; or a template `gsub_file!` to `--frozen-lockfile` for Yarn 1.
- **Recommendation** — Defer: Rails' default rather than the branch's, and it should be confirmed first (see Verification).
- **Ruling** — Implement — "Use Yarn 4" — user ruling 2026-10-24 (opened G16)
- **Verification** — Confirmed: `yarn install --immutable; echo $?` under Yarn 1.22.22 in a scratch project whose `package.json` (`is-number@^7.0.0`) disagreed with its `yarn.lock` (`is-number@^6.0.0`) exited 0 and rewrote the lockfile to 7.0.0, so Yarn 1 ignores `--immutable`.

## Maintainability and Design

### F23 ~~⚖️ Decision - Ad hoc `rails new` flags crash the template mid-run, and the header lists only part of what it assumes~~ ✅ Fixed

- **File** — `home/.rails/template.rb`
- **Location** — header comment (lines 3–4); `setup_kamal`, `setup_kamal_worker`, `setup_ci`
- **Issue** — `.railsrc` applies the template to every `rails new`, so any extra flag composes with it. With `--skip-kamal`, `YAML.load_file('config/deploy.yml')` raises `Errno::ENOENT` (not a `Thor::Error`, so a stack trace). With `--skip-ci`, `append_to_file '.github/workflows/ci.yml'` raises "does not appear to exist". With `--skip-brakeman`, the `insert_into_file!` Brakeman anchor raises. With `-d sqlite3`, generation succeeds but the CI test job carries a PostgreSQL service and `postgres://` `DATABASE_URL` and fails. Each crash lands after Rails has written the app but before `setup_rubocop`, leaving an app with no `.rubocop.yml`, binstub or todo — a failing lint. The header says the template assumes "esbuild…, no Minitest, no omakase RuboCop and no Solid Queue" but not PostgreSQL, Kamal, CI or Brakeman, which later commits made it depend on.
- **Options**
  - **(a) Guard the optional steps and complete the header**: `return if skip_kamal?` in both Kamal steps and `return if skip_ci?` in the CI step (AppBase predicates, available in the template's context), plus PostgreSQL and Brakeman in the header's list. Three guard lines; covers the likeliest ad hoc flags.
  - **(b) Only complete the header**, naming every flag the template requires, so the crash is documented. No code change; half-configured app remains.
  - **(c) Leave as is.** No cost now; each crash is diagnosed from a stack trace.
- **Recommended** — (a); the guards cost a line each, and a mid-run death before RuboCop setup leaves an app worse than one generated without the template.
- **Concurred by** — Rails (R14, a 💡 Observation whose optional action adds PostgreSQL and "no Solid Queue, Cache or Cable" to the header, noting that the template also relies on `-d postgresql` for the CI job's Postgres service, on `--skip-solid` as a whole — the `# clear:` block exists only under `skip_solid?`, and Solid Cable is skipped too — and on Kamal and GitHub CI not being skipped)
- **Status** — ✅ Fixed: ruled (a) Guard steps + header, including a `skip_brakeman?` guard on the Brakeman anchor; `6af622c` guards the Kamal, CI workflow, Dependabot and database steps with `skip_kamal?`, `skip_ci?` and `skip_active_record?`, anchors the `bin/ci` test steps on Rails' closing comment so `--skip-brakeman` no longer breaks them, and completes the header; a run with `--skip-kamal --skip-ci --skip-brakeman` exited 0 with RuboCop clean

### F24 ~~🟢 Low Priority - Nothing in the code says `setup_rubocop` must run last~~ ✅ Fixed

- **File** — `home/.rails/template.rb`
- **Location** — `after_bundle` (template.rb:124–135)
- **Issue** — The step order carries two invariants that appear nowhere in the code: `setup_rubocop` autocorrects and records in `.rubocop_todo.yml` only what exists when it runs, and the `setup_ci` anchors (`step "Setup"`, `step "Security: Brakeman`) and `uncomment_lines` patterns match Rails' double-quoted output, which `rubocop -A` rewrites to single quotes (the probe's `config/ci.rb` shows the Brakeman step single-quoted and wrapped). The natural place to add a new step is the bottom of the block, and a step added after `setup_rubocop` gives the new app a failing lint or an anchor that never matches.
- **Suggestion** — A comment above `setup_rubocop` in the block, e.g. `# Last: its autocorrect and todo must cover every earlier step, whose anchors match Rails' unformatted output`.
- **Recommendation** — Implement; exactly the kind of comment the owner's rules allow, where a reader could otherwise make a real mistake.
- **Status** — ✅ Fixed: `cab15f7` comments above `setup_rubocop` in `after_bundle` why it runs last

### F25 ~~🟢 Low Priority - Two steps have names narrower than what they do, and exceed Sandi Metz's five-line limit~~ ✅ Fixed

- **File** — `home/.rails/template.rb`
- **Location** — `setup_bootstrap` (lines 49–57); `setup_ci` (lines 103–113); `setup_kamal` / `setup_kamal_worker`
- **Issue** — `setup_bootstrap` runs six statements spanning two concerns: the dartsass toolchain (install, stub removal, `application.scss`, initializer) and Bootstrap's packages and JS import. `setup_postcss` depends on the first, not the second. `setup_ci` edits two unrelated files in seven lines. Both exceed the five-line rule the owner follows, and the names mislead: `setup_kamal` adds Redis, not "Kamal", and `setup_kamal_worker` adds a Sidekiq job role. A reader looking for where dartsass is installed would not look in `setup_bootstrap`.
- **Suggestion** — Split `setup_bootstrap` into `setup_dartsass` (install, stub, scss, initializer) and `setup_bootstrap` (yarn add, import); split `setup_ci` into `setup_ci_workflow` and `setup_bin_ci`; rename the Kamal pair `setup_kamal_redis` and `setup_kamal_job_role`.
- **Recommendation** — Implement; mechanical renames and splits, and the names become the map of where each piece of the stack is configured.
- **Status** — ✅ Fixed: `cab15f7` splits `setup_dartsass`/`setup_bootstrap` and `setup_ci_workflow`/`setup_bin_ci`, and renames the Kamal pair `setup_kamal_redis` and `setup_kamal_job_role`

### F26 ~~🟢 Low Priority - The hand-kept copies of Rails output carry no pointer to their sources~~ ✅ Fixed

- **File** — `home/.rails/template.rb`; `home/.rails/files/github/ci_jobs.yml`
- **Location** — `setup_ci` comment (line 104); `setup_haml_layouts` comment (line 94)
- **Issue** — ci_jobs.yml's `lint` job is a verbatim copy, and its `test` job an adaptation, of railties' `ci.yml.tt`; the HAML layouts mirror `application.html.erb.tt` and the mailer layouts. Only the 22f4736 commit message records that the layouts need resyncing, and nothing records it for the CI jobs. On the next Rails upgrade, Rails' own `scan_ruby` job in the same workflow picks up new action versions (e.g. `actions/checkout@v7`) while the appended jobs stay pinned, and nothing in the tree prompts a resync.
- **Suggestion** — Extend the two existing comments to name their sources, e.g. in `setup_ci`: `…these restore them, adapted from railties' ci.yml.tt and config/ci.rb.tt`; in `setup_haml_layouts`: `…the replacements are HAML copies of railties' layout templates`.
- **Recommendation** — Implement; a why-it-is-so comment, and the only in-tree signal that these files track Rails.
- **Status** — ✅ Fixed: `cab15f7` names railties' `github/ci.yml.tt`, `config/ci.rb.tt` and layout templates in the comments

## Conventions and Style

### F27 ~~🟢 Low Priority - The accessory comment's second sentence has no final period~~ ✅ Fixed

- **File** — `home/.rails/files/kamal/redis_accessory.yml`
- **Location** — lines 4–6
- **Issue** — The comment is two sentences ("…at that host instead. No port is published, which keeps it off the public interface"), and the owner's rule is that a multi-sentence comment punctuates normally. The comment is copied into every generated `deploy.yml`.
- **Suggestion** — End line 6 with a period.
- **Recommendation** — Implement; one character.
- **Concurred by** — Rails (R15, at the same severity and recommendation; its other point, that the first sentence understates the move, is carried on F3)
- **Status** — ✅ Fixed: `a78bf11` rewrote the comment with every sentence punctuated

### F28 ~~🟢 Low Priority - The `.railsrc` comment enumerates features and has already drifted~~ ✅ Fixed

- **File** — `home/.railsrc`
- **Location** — line 8
- **Issue** — `# Adds Bootstrap through dartsass-rails, RSpec, HAML, Sidekiq and RuboCop` was written in 60c0caa and omits the Valkey accessory, the Kamal job role and the restored CI jobs that later commits added. Each future step makes it staler, and the owner's rules exclude drifting comment content.
- **Suggestion** — `-m ~/.rails/template.rb # Sets up the stack these flags don't; see its setup_* steps`, or drop the trailing comment.
- **Recommendation** — Implement; a comment that does not enumerate cannot go stale.
- **Status** — ✅ Fixed: `cab15f7` replaces the enumerating comment with one pointing at the `setup_*` steps

## Documentation and Commit Messages

### F29 ~~🟢 Low Priority - The stub-removal comment has the shadowing backwards~~ ✅ Fixed

- **File** — `home/.rails/template.rb`
- **Location** — `setup_bootstrap`, line 53
- **Issue** — "The stub shares the logical path application.css with the dartsass build, which it would shadow" says the stub wins. Propshaft maps logical paths first-path-wins (`propshaft-1.3.2/lib/propshaft/load_path.rb:69-78`), and `app/assets/*` directories are added in sorted order (`railties paths.rb:238-243`, glob `"*"`), so `app/assets/builds` precedes `app/assets/stylesheets` and the build shadows the stub. Removing it is still right — edits to a second `application.css` would silently do nothing.
- **Suggestion** — "The stub shares the logical path application.css with the dartsass build, which shadows it, so edits to the stub would do nothing".
- **Recommendation** — Implement: a one-line comment fix.
- **Status** — ✅ Fixed: `cab15f7` says the dartsass build shadows the stub

### F30 ~~🟢 Low Priority - The load-path comment names `@use`, but the stylesheet uses `@import`~~ ✅ Fixed

- **File** — `home/.rails/files/config/initializers/dartsass.rb`
- **Location** — line 7
- **Issue** — "Lets @use resolve npm packages…" sits beside an `application.scss` whose only line is `@import 'bootstrap/scss/bootstrap'`. The load path serves both, but the comment points readers at the directive the app doesn't use.
- **Suggestion** — "Lets @import and @use resolve npm packages without adding node_modules to Propshaft's asset paths".
- **Recommendation** — Implement: a one-word fix.
- **Status** — ✅ Fixed: `47777e7` names `@import` and `@use` in the load-path comment

### F31 🟢 Low Priority - The 60c0caa message uses serial commas

- **File** — commit 60c0caa
- **Location** — first and second paragraphs
- **Issue** — The owner's style is no serial comma; the message has two: "…a full RuboCop configuration in place of omakase, and Bootstrap compiled with Sass" and "drops the dead flag, and passes `-m`". The first may be there to keep "omakase and Bootstrap" from reading as a pair, which the rule says to restructure instead. Merged messages can't be edited, and 60c0caa is already on `origin/railsrc-preferences` — though the remote branch has diverged from local at its second commit (`48d184f` there, `84aece5` here), so a force-push is due either way.
- **Suggestion** — Reorder the first list ("…Bootstrap compiled with Sass, HAML, Sidekiq and a full RuboCop configuration in place of omakase"), and change "drops the dead flag, and passes" to "drops the dead flag and passes".
- **Recommendation** — Implement; a reword of an unmerged commit that is being force-pushed anyway.

## Observations

### F32 ℹ️ Observation - `rails new` runs freshly resolved npm install scripts on the developer's machine

- **File** — `home/.rails/template.rb`
- **Location** — `home/.rails/template.rb:51`, `home/.rails/template.rb:60`
- **Issue** — The two `yarn add` calls (Yarn classic, lockfile v1 in the probe) resolve the latest versions of five packages and their transitive dependencies at generation time with lifecycle scripts enabled, on the machine that holds the owner's SSH keys, GitHub token and Kamal secrets — the propagation path of the 2025 npm worm compromises. None of these five packages needs an install script, so `--ignore-scripts` on these two calls would cost nothing, but it would not close the window: jsbundling's installer has already run `yarn add` for esbuild and Hotwire in the same `rails new`, every later `yarn install` runs scripts, and Yarn classic offers no minimum-release-age gate. Noted as context, not an action.

### F33 ℹ️ Observation - Where the template differs from another project's migration, the template has it right

- **File** — `home/.rails/template.rb`
- **Location** — `setup_kamal_worker`; the Rails-generated `bin/docker-entrypoint` and `Dockerfile`
- **Issue** — Several differences should not be "fixed" toward the other project. Rails' entrypoint runs `db:prepare` only when the command ends in `./bin/rails server`, so the job role (`bundle exec sidekiq`) skips it without needing an environment flag; the other project's entrypoint runs it unconditionally and makes the worker role opt out with `SKIP_DB_PREPARE=1`, which fails open (a role that forgets the flag runs migrations). The template's version is the better one to adopt. Kamal's boot barrier starts non-primary roles only after the primary web role passes its health check, so new Sidekiq code never runs before the web container has migrated. A non-proxied role's stop timeout defaults to `drain_timeout` (30 s), longer than Sidekiq's 25 s shutdown timeout, so in-flight jobs are requeued cleanly on deploy. Sidekiq's default concurrency of 5 matches the generated database pool (`RAILS_MAX_THREADS` default 5). Rails' role name `job` (vs the other project's `workers`), Kamal's default accessory restart policy `unless-stopped` (vs `restart: always`, practically equivalent) and publishing no port (vs `127.0.0.1:6379`) are all fine as they are; a loopback binding only matters for host-side `redis-cli` or backups, and `kamal accessory exec redis valkey-cli` covers both.

### F34 ℹ️ Observation - Durability and recovery limits the next operator should know

- **File** — `home/.rails/files/kamal/redis_accessory.yml`
- **Location** — `directories: - data:/data`
- **Issue** — A relative directory resolves to `$PWD/<service>-redis/data` in the SSH user's home on the root disk. Append-only persistence survives a container restart, as the comment says, but not a host rebuild, and nothing backs the files up. Another project keeps them on an attached block-storage volume. For a job queue this is a defensible trade-off — Postgres is the record — but scheduled (`wait:`) jobs and retries live only there. Separately, another project's Redis recovery runbook found that after `kamal accessory reboot redis` the production Action Cable listener does not reattach; the app must be restarted (`kamal app boot`) after any Valkey restart.

### F35 ℹ️ Observation - Moving another project from `redis:8` to `valkey/valkey:8` may not reuse its existing data directory

- **File** — `home/.rails/files/kamal/redis_accessory.yml`
- **Location** — `image: valkey/valkey:8`
- **Issue** — Valkey (Rails' default, BSD-licensed) is a sound choice for the template, and Sidekiq 8 supports it. If another project adopts it, Redis 8 writes RDB/AOF-preamble formats newer than the Redis 7.2 fork Valkey 8 descends from, so pointing `valkey:8` at the existing data directory may fail to load; the safe path is to drain the queue and start Valkey on an empty directory. Unconfirmed — see Verification.
- **Verification** — `unverified`: `docker run -d --name r8 -v "$PWD/d:/data" redis:8 redis-server --appendonly yes`, write a key, `docker rm -f r8`, then `docker run --rm -v "$PWD/d:/data" valkey/valkey:8 valkey-server --appendonly yes`; a load error in the Valkey log confirms, the key present refutes.

### F36 ℹ️ Observation - Why the test adapter line in `config/environments/test.rb` must stay

- **File** — `home/.rails/template.rb`
- **Location** — `setup_sidekiq`
- **Issue** — In activejob-8.1.4, `ActiveJob::TestHelper#before_setup` swaps in the test adapter only for job classes whose `_queue_adapter` is `nil`; the global `config.active_job.queue_adapter = :sidekiq` sets it, so without the test-environment override specs would enqueue through Sidekiq into Redis, and rspec-rails' `have_enqueued_job` reads `ActiveJob::Base.queue_adapter` directly. The line is load-bearing, not taste, and should not be "cleaned up" as redundant. A related gotcha: a class that includes `Sidekiq::Job` directly bypasses Active Job, and its specs will still need Redis or `Sidekiq::Testing`.

### F37 💡 Observation (optional action) - FactoryBot definitions are never linted

- **File** — `home/.rails/files/spec/support/factory_bot.rb`
- **Location** — whole file
- **Issue** — Optional: add a `spec/factories_spec.rb` (or a CI step) that calls `FactoryBot.lint traits: true`, so a factory that builds an invalid record fails directly rather than through whichever spec uses it first.

### F38 ℹ️ Observation - Files under `~/.rails/files` shadow Rails' own generator templates

- **File** — `home/.rails/template.rb`
- **Location** — `source_paths`
- **Issue** — Because `files` comes before `super`, and Rails' later `run_kamal` step calls `template "config/deploy.yml"` and `template "kamal-secrets.tt"` through the same paths (`app_base.rb:740-748`), a future file added at a Rails template's relative path (for example `config/deploy.yml` or `Dockerfile`) would silently replace Rails' version for Rails' own steps, not just the template's. Nothing collides today.

### F39 💡 Observation (optional action) - `.rubocop.yml` restates defaults

- **File** — `home/.rails/files/rubocop.yml`
- **Location** — `AllCops`
- **Issue** — `DisplayCopNames: true` is RuboCop 1.92's default (`config/default.yml:69`), and rubocop-rails 2.38 already excludes `bin/*` and `db/*schema.rb` in merge mode. Optional action: drop `DisplayCopNames` and the `db/schema.rb` exclude; keep `bin/**/*` only if subdirectories of `bin` matter.

### F40 💡 Observation (optional action) - The adapter lines land above `load_defaults` and Rails' explanatory comment

- **File** — `home/.rails/template.rb`
- **Location** — `setup_sidekiq`
- **Issue** — Rails' `environment` action inserts right after `class Application < Rails::Application` (`actions.rb:206-220`), so the probe has `queue_adapter = :sidekiq` above `config.load_defaults 8.1` and `:test` above "Settings specified here will take precedence…". It works, since `load_defaults` doesn't touch the adapter, but inverts Rails' "configure after load_defaults" guidance. Optional action: `inject_into_file! 'config/application.rb', …, after: /^    config\.load_defaults .*\n/`.

### F41 💡 Observation (optional action) - Derive the Kamal service name from `app_name` rather than parsing `deploy.yml`

- **File** — `home/.rails/template.rb`
- **Location** — `setup_kamal` (template.rb:74)
- **Action** — Replace `YAML.load_file('config/deploy.yml').fetch('service')` with `app_name`: Rails' `deploy.yml.tt` writes `service: <%= app_name %>`, and the layout template already uses `app_name`. Drops a cwd-relative file read and a YAML parse.

### F42 ℹ️ Observation - Both appends assume the appended key is absent or last

- **File** — `home/.rails/template.rb`
- **Location** — `setup_kamal` (line 81); `setup_ci` (line 106)
- **Note** — Neither append can fail, so neither raises on a reshaped file. The `jobs` append relies on `jobs:` staying the last top-level key in Rails' `ci.yml` (a later key such as `concurrency:` would make the appended jobs nest under it), and the `accessories:` append relies on Rails' own `accessories` block staying commented (if uncommented, the YAML gets a duplicate key and Psych keeps the last). Both hold for Rails 8.1.4; `insert_into_file! '.github/workflows/ci.yml', …, after: "jobs:\n"` is the loud equivalent for the workflow if either breaks.

### F43 💡 Observation (optional action) - The `@` alias is copied but unused in a fresh app

- **File** — `home/.rails/files/esbuild.config.mjs`
- **Location** — `esbuild.config.mjs:13`
- **Issue** — The `'@'` → `app/javascript` alias comes from the other project; the generated `app/javascript` uses relative imports (`./controllers`), so nothing references it. Optional: drop it until an app needs it, or keep it as a house convention.

### F44 ℹ️ Observation - `format: 'esm'` and `publicPath` are load-bearing, even though the other project's config lacks them

- **File** — `home/.rails/files/esbuild.config.mjs`
- **Location** — lines 7 and 10
- **Issue** — These two options reproduce jsbundling-rails' default `--format=esm --public-path=/assets`. The layout loads the bundle with `type: 'module'`, and `publicPath` sets the URLs esbuild writes for any file JS imports (fonts, images). Someone syncing this file with the other project's later would see them as drift; removing them breaks the bundle or those asset URLs.

### F45 💡 Observation (optional action) - The two `config/ci.rb` insertions use different string styles

- **File** — `home/.rails/template.rb`
- **Location** — `setup_ci` (lines 107–112)
- **Action** — The first insertion hard-codes its indent inside `%()`, the second uses `<<~RUBY.indent(2)`. Using the heredoc form for both would make them read alike and keep the indentation rule in one form.

### F46 💡 Observation (optional action) - The runtime gems land after the Gemfile's group blocks

- **File** — `home/.rails/template.rb`
- **Location** — lines 11–13
- **Action** — Rails' `gem` action appends to the Gemfile's end, so in the probe `dartsass-rails`, `haml-rails` and `sidekiq` sit directly after `group :development … end` with no blank line, apart from the other runtime gems. One `inject_into_file 'Gemfile', …, before: "group :development, :test do\n"` would group them with their peers.

## Consolidated Summary

| Finding | Type | Category | Description | File | Location | Recommendation | Group | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F1 | 🟡 Medium | Correctness | `REDIS_URL` and redis-gem edits fail silently | `home/.rails/template.rb` | `setup_kamal`; top level | Implement | G10 | ✅ |
| F2 | ⚖️ Decision | Security | Valkey accepts unauthenticated connections on the shared `kamal` network | `home/.rails/files/kamal/redis_accessory.yml` | `accessories.redis`; `setup_kamal` | Options (a) | G2 | ✅ |
| F3 | 🟡 Medium | Security | Accessory comment steers a host move toward a public, unauthenticated port | `home/.rails/files/kamal/redis_accessory.yml` | lines 4-6 | Implement | G2 | ✅ |
| F4 | 🟢 Low | Security | No Dependabot coverage for the npm packages the template adds | `home/.rails/template.rb` | `setup_ci` | Implement | G13 | ✅ |
| F5 | 🟢 Low | Security | Appended CI jobs pin actions by tag and declare no token permissions | `home/.rails/files/github/ci_jobs.yml` | whole workflow | Skip | — | 🚫 |
| F6 | 🟡 Medium | Deployment and Operations | No memory cap or explicit eviction policy for Valkey | `home/.rails/files/kamal/redis_accessory.yml` | `cmd:` (line 9) | Implement | G2 | ✅ |
| F7 | 🟢 Low | Deployment and Operations | Job-role rewrite strips `  # ` anywhere in a line | `home/.rails/template.rb` | `setup_kamal_worker` | Implement | G10 | ✅ |
| F8 | 🟢 Low | Deployment and Operations | RuboCop and its plugins ship in the production image | `home/.rails/template.rb` | `gem_group :test` | Implement | G11 | ✅ |
| F9 | ⚖️ Decision | Testing and CI | A new app's first CI test run fails without `db/schema.rb` | `home/.rails/files/github/ci_jobs.yml` | `test` job, `Run tests` | Options (a) / (e) | G1 | ✅ |
| F10 | ⚖️ Decision | Testing and CI | `bin/ci`'s RSpec step never builds the Sass bundle | `home/.rails/template.rb` | `setup_ci` | Options (a) / (b) | G1 | ✅ |
| F11 | ⚖️ Decision | Testing and CI | Capybara is installed but system specs have no driver | `home/.rails/template.rb` | `gem_group :test`; `setup_rspec` | Options (a) / (b) | G3 | ✅ |
| F12 | ⚖️ Decision | Testing and CI | The template is verified only by hand-run probes | `home/.rails/template.rb` | whole template | Options (a) | G8 | ⏸️ |
| F13 | 🟡 Medium | Testing and CI | `test` job drops Rails' Install packages step | `home/.rails/files/github/ci_jobs.yml` | `test.steps` | Implement | G9 | ✅ |
| F14 | 🟢 Low | Testing and CI | `spec/support` uncomment fails silently | `home/.rails/template.rb` | `setup_rspec` | Implement | G10 | ✅ |
| F15 | 🟢 Low | Testing and CI | Repository CI does not lint the branch's Ruby | `.github/workflows/ci.yml` | "Run the linters" step | Defer | — | ⏸️ |
| F16 | ⚖️ Decision | Front-End Build | esbuild never minifies in the Kamal image | `home/.rails/files/esbuild.config.mjs` | line 12 | Options (a) / (c) | G4 | ✅ |
| F17 | ⚖️ Decision | Front-End Build | dartsass initializer drops the gem's `--no-source-map` default | `home/.rails/files/config/initializers/dartsass.rb` | lines 3–9 | Options (a) / (b) | G5 | ✅ |
| F18 | ⚖️ Decision | Front-End Build | Whether autoprefixer earns its place under `allow_browser :modern` | `home/.rails/template.rb` | `setup_postcss` | Options (b) | G6 | ✅ |
| F19 | 🟢 Low | Front-End Build | `rails_command 'dartsass:install'` never aborts on failure | `home/.rails/template.rb` | `setup_bootstrap` | Implement | G10 | ✅ |
| F20 | 🟢 Low | Front-End Build | `stylesheet_link_tag :app` links every CSS output; comment names wrong directory | `home/.rails/files/app/views/layouts/application.html.haml.tt` | lines 21–22 | Implement | G12 | ✅ |
| F21 | 🟢 Low | Front-End Build | `--load-path` breaks the CSS build under a path with a space | `home/.rails/files/config/initializers/dartsass.rb` | line 8 | Skip | — | 🚫 |
| F22 | 🟢 Low | Front-End Build | `yarn install --immutable` likely does not enforce the lockfile under Yarn 1 | `home/.railsrc` | generated `Dockerfile:58` | Defer | G16 | ❓ |
| F23 | ⚖️ Decision | Maintainability and Design | Ad hoc `rails new` flags crash the template; header incomplete | `home/.rails/template.rb` | header; `setup_kamal`, `setup_kamal_worker`, `setup_ci` | Options (a) | G7 | ✅ |
| F24 | 🟢 Low | Maintainability and Design | Nothing says `setup_rubocop` must run last | `home/.rails/template.rb` | `after_bundle` | Implement | G14 | ✅ |
| F25 | 🟢 Low | Maintainability and Design | Step names narrower than what they do; over five lines | `home/.rails/template.rb` | `setup_bootstrap`; `setup_ci`; Kamal pair | Implement | G14 | ✅ |
| F26 | 🟢 Low | Maintainability and Design | Hand-kept copies of Rails output carry no source pointer | `home/.rails/template.rb` | `setup_ci`; `setup_haml_layouts` | Implement | G14 | ✅ |
| F27 | 🟢 Low | Conventions and Style | Accessory comment's second sentence has no final period | `home/.rails/files/kamal/redis_accessory.yml` | lines 4–6 | Implement | G2 | ✅ |
| F28 | 🟢 Low | Conventions and Style | `.railsrc` comment enumerates features and has drifted | `home/.railsrc` | line 8 | Implement | G14 | ✅ |
| F29 | 🟢 Low | Documentation and Commit Messages | Stub-removal comment has the shadowing backwards | `home/.rails/template.rb` | `setup_bootstrap`, line 53 | Implement | G14 | ✅ |
| F30 | 🟢 Low | Documentation and Commit Messages | Load-path comment names `@use`; stylesheet uses `@import` | `home/.rails/files/config/initializers/dartsass.rb` | line 7 | Implement | G5 | ✅ |
| F31 | 🟢 Low | Documentation and Commit Messages | 60c0caa message uses serial commas | commit 60c0caa | first and second paragraphs | Implement | G15 | ❓ |
| F32 | ℹ️ Observation | Security | `rails new` runs freshly resolved npm install scripts | `home/.rails/template.rb` | lines 51, 60 | — | — | — |
| F33 | ℹ️ Observation | Deployment and Operations | Where the template differs from another project, it has it right | `home/.rails/template.rb` | `setup_kamal_worker` | — | — | — |
| F34 | ℹ️ Observation | Deployment and Operations | Durability and recovery limits of the Valkey data directory | `home/.rails/files/kamal/redis_accessory.yml` | `directories` | — | — | — |
| F35 | ℹ️ Observation | Deployment and Operations | `redis:8` data may not load in `valkey/valkey:8` | `home/.rails/files/kamal/redis_accessory.yml` | `image` | — | — | — |
| F36 | ℹ️ Observation | Testing and CI | Why the test adapter line must stay | `home/.rails/template.rb` | `setup_sidekiq` | — | — | — |
| F37 | 💡 Observation | Testing and CI | FactoryBot definitions are never linted | `home/.rails/files/spec/support/factory_bot.rb` | whole file | — | — | — |
| F38 | ℹ️ Observation | Maintainability and Design | Files under `~/.rails/files` shadow Rails' generator templates | `home/.rails/template.rb` | `source_paths` | — | — | — |
| F39 | 💡 Observation | Maintainability and Design | `.rubocop.yml` restates defaults | `home/.rails/files/rubocop.yml` | `AllCops` | — | — | — |
| F40 | 💡 Observation | Maintainability and Design | Adapter lines land above `load_defaults` | `home/.rails/template.rb` | `setup_sidekiq` | — | — | — |
| F41 | 💡 Observation | Maintainability and Design | Derive the Kamal service name from `app_name` | `home/.rails/template.rb` | `setup_kamal` | — | — | — |
| F42 | ℹ️ Observation | Maintainability and Design | Both appends assume the appended key is absent or last | `home/.rails/template.rb` | `setup_kamal`; `setup_ci` | — | — | — |
| F43 | 💡 Observation | Maintainability and Design | The `@` alias is unused in a fresh app | `home/.rails/files/esbuild.config.mjs` | line 13 | — | — | — |
| F44 | ℹ️ Observation | Maintainability and Design | `format: 'esm'` and `publicPath` are load-bearing | `home/.rails/files/esbuild.config.mjs` | lines 7 and 10 | — | — | — |
| F45 | 💡 Observation | Conventions and Style | The two `config/ci.rb` insertions use different string styles | `home/.rails/template.rb` | `setup_ci` | — | — | — |
| F46 | 💡 Observation | Conventions and Style | Runtime gems land after the Gemfile's group blocks | `home/.rails/template.rb` | lines 11–13 | — | — | — |

## Pre-Merge Checklist

### G1 ✅ — Settle a fresh app's schema and the `bin/ci` Sass build

Closed: every member fixed in `560e524`, verified as each finding's Status line records.

- [x] ✅ F9 - Whether a fresh app gets a placeholder `db/schema.rb`, a why-comment or another fix (ruled: run `bin/rails db:create db:migrate` in `after_bundle`)
- [x] ✅ F10 - Whether `bin/ci` builds Sass by enhancing `spec:prepare` or by running `db:test:prepare spec` (ruled (a): enhance spec:prepare)

### G2 ✅ — Settle the Valkey accessory's authentication, then its comment and command

Closed: every member fixed in `a78bf11`, verified as each finding's Status line records.

- [x] ✅ F2 - Whether Valkey requires a password from a Kamal secret (ruled (a): password from secret)
- [x] ✅ F3 - Extend the accessory comment so a host move publishes the port on a private address only, against the password-protected accessory
- [x] ✅ F6 - Add `--maxmemory` and an explicit `noeviction` policy to the Valkey `cmd:`, against the password-protected accessory
- [x] ✅ F27 - End the accessory comment's second sentence with a period, against the password-protected accessory

### G3 ✅ — Settle the system-spec driver

Closed: every member fixed in `a29703e`, verified as each finding's Status line records.

- [x] ✅ F11 - Which driver system specs use (ruled (e): match another project's setup, `rack_test` default and `:js` specs on Playwright with Chrome, plus a CI screenshot upload step)

### G4 ✅ — Settle how esbuild decides to minify

Closed: every member fixed in `c6ce3fb`, verified as each finding's Status line records.

- [x] ✅ F16 - Which variable keys esbuild minification (ruled (a): NODE_ENV or RAILS_ENV)

### G5 ✅ — Settle the dartsass build options

Closed: every member fixed in `47777e7`, verified as each finding's Status line records.

- [x] ✅ F17 - Whether the initializer keeps the gem's `--no-source-map` default (ruled (b): keep the replacement, add a comment)
- [x] ✅ F30 - Name `@import` as well as `@use` in the load-path comment

### G6 ✅ — Settle autoprefixer's browser targets

Closed: every member fixed in `ef9ba1c`, verified as each finding's Status line records.

- [x] ✅ F18 - Whether autoprefixer stays, gains a `.browserslistrc` or goes (ruled (b): a `.browserslistrc` matching Rails' `:modern` baseline)

### G7 ✅ — Settle how the template treats ad hoc `rails new` flags

Closed: every member fixed in `6af622c`, verified as each finding's Status line records.

- [x] ✅ F23 - Whether to guard optional steps and complete the header (ruled (a): guard steps, including `skip_brakeman?` on the Brakeman anchor, and complete the header)

### G8 ✅ — Settle how the dotfiles CI verifies the template

Closed by F12's deferral: the scheduled rails-template CI job moves to its own branch after this one merges.

- [x] ⏸️ F12 - Whether the dotfiles CI generates and tests an app from the template (deferred to a follow-up branch)

### G9 ✅ — Restore Rails' Install packages step in the CI test job

Closed: every member fixed in `3fa4c45`, verified as each finding's Status line records.

- [x] ✅ F13 - Restore the Install packages step (`libpq-dev`, `libvips`, `node-gyp`) in the `test` job

### G10 ✅ — Make the template's edits and steps fail loudly

Closed: every member fixed in `e23deeb`, verified as each finding's Status line records.

- [x] ✅ F1 - Switch the `REDIS_URL` and redis-gem edits to `gsub_file!`
- [x] ✅ F14 - Switch the `spec/support` uncomment to `gsub_file!`
- [x] ✅ F19 - Pass `abort_on_failure: true` to `rails_command 'dartsass:install'`
- [x] ✅ F7 - Anchor the job-role comment-stripping regex

### G11 ✅ — Move RuboCop out of the production image

Closed: every member fixed in `ec14f79`, verified as each finding's Status line records.

- [x] ✅ F8 - Move the eight RuboCop gems into `gem_group :development`

### G12 ✅ — Link the application stylesheet by name

Closed: every member fixed in `da2f0d8`, verified as each finding's Status line records.

- [x] ✅ F20 - Replace `stylesheet_link_tag :app` with `'application'` and drop the comment

### G13 ✅ — Add npm to the generated Dependabot config

Closed: every member fixed in `bd297e8`, verified as each finding's Status line records.

- [x] ✅ F4 - Append an `npm` ecosystem entry to `.github/dependabot.yml`

### G14 ✅ — Restructure the template's steps and correct its comments

Closed: every member fixed in `cab15f7`, verified as each finding's Status line records.

- [x] ✅ F25 - Split `setup_bootstrap` and `setup_ci`, and rename the Kamal pair
- [x] ✅ F24 - Comment that `setup_rubocop` must run last
- [x] ✅ F26 - Name the Rails sources the CI jobs and HAML layouts copy
- [x] ✅ F29 - Correct the stub-removal comment's shadowing direction
- [x] ✅ F28 - Replace the enumerating `.railsrc` comment

### G15 — Reword the 60c0caa commit message

Last: a history rewrite, best done once the other edits are committed.

- [ ] ❓ F31 - Remove the serial commas from the 60c0caa message

### G16 — Generate new apps with Yarn 4

Ruled Implement; needs a machine change first (Yarn 4 as corepack's global default) and the template writing `.yarnrc.yml` with `nodeLinker: node-modules` before jsbundling installs packages.

- [ ] ❓ F22 - Enforce the lockfile under Yarn 1 (ruled Implement — "Use Yarn 4"; opened G16)

### Not recommended for this revision

- [x] 🚫 F5 - Pin CI actions to SHAs and add a `permissions:` block (ignored — matches Rails' generated workflow; no secret or write scope at stake)
- [x] ⏸️ F15 - Lint the template's Ruby in the repository CI (deferred — to the same follow-up branch as F12's template CI job)
- [x] 🚫 F21 - Make `--load-path` safe under a path with a space (ignored — apps live under space-free paths; another project uses the same setting)

## Checked and refuted

- **Rails report R16 — "The `bin/rubocop -A` comment claims an abort that cannot happen"** (`home/.rails/template.rb`, `setup_rubocop`, line 118). Check: under the `rails` CLI, `AppGenerator.exit_on_failure?` is reopened to `true` (railties-8.1.4 `commands/application/application_command.rb:8-13`), and Thor's `run` falls back to it (thor-1.5.0 `actions.rb:274`, `config.fetch(:abort_on_failure, self.class.exit_on_failure?)`). Result: without `abort_on_failure: false` that `run` would abort `rails new`, so the comment is correct; withdrawn. The code quality report reached the same conclusion in its preamble.
