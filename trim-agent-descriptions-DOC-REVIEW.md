# Document Review: 7 documents on trim-agent-descriptions

| | |
| --- | --- |
| **Scope** | The changes on this branch (base `d22496a`): the seven agent files under `home/.claude/agents/` |
| **Branch** | `trim-agent-descriptions` |
| **Reviewed** | 2026-10-24 |
| **Reviewed by** | Opus 5.5 (`claude-opus-5-5`) |
| **Collated by** | Opus 5.5 (`claude-opus-5-5`) |

## Documents

| Document | Commit |
| --- | --- |
| `home/.claude/agents/code-best-practices-reviewer.md` | `89872d4` |
| `home/.claude/agents/documentation-expert.md` | `89872d4` |
| `home/.claude/agents/postgresql-expert.md` | `89872d4` |
| `home/.claude/agents/ruby-on-rails-expert.md` | `89872d4` |
| `home/.claude/agents/security-reviewer.md` | `89872d4` |
| `home/.claude/agents/test-suite-architect.md` | `89872d4` |
| `home/.claude/agents/ui-ux-design-specialist.md` | `89872d4` |

## Review History

### 2026-10-24 — Initial review by Opus 5.5 (`claude-opus-5-5`)

One reviewer per document, all on Opus 5.5 (`claude-opus-5-5`). 26 findings: 23 actionable (two ⚖️ Decisions) and 3 observations. The test-review overlap filed from both sides (code-best-practices-reviewer and test-suite-architect) is merged into F2. No check was handed back. Two optional YAML parses of the documentation-expert and ruby-on-rails-expert frontmatter, run on the user's approval, returned the expected descriptions. The session then worked every group: 21 findings fixed, 2 ignored.

## Overall Assessment

The trimmed descriptions kept the agents' frontmatter valid but dropped several trigger situations and left a few sibling boundaries misaligned, so a router could miss or misroute requests the bodies still support. Both ⚖️ Decisions were ruled (b) and edited in: F1 names a first-pass security check in code-best-practices-reviewer and tells the router to also run security-reviewer, and F8 rewords ruby-on-rails-expert's responsibility 3 while keeping Testing Excellence. All nine groups are closed in the order G1, G3, G4, G5, G2, G6, G7, G8 and G9, restoring the lost triggers (open pull requests, production administration, JSONB querying, application performance, deployment, information architecture, dependency and configuration audits) and lining up each pair of handoffs. F13 and F23 were ignored on the user's ruling, and the three 💡 observations are left as optional. Every actionable finding is now ✅ or 🚫, and the frontmatter of all seven files still parses.

## Consistency

### F1 ~~⚖️ Decision - The description no longer says this agent covers security as part of a general review, so auth-touching features now route only to security-reviewer~~ ✅ Fixed

- **Document** — `home/.claude/agents/code-best-practices-reviewer.md`
- **Location** — frontmatter `description:`, lines 4–7
- **Issue** — The old description listed "security" among the areas analyzed. Its second `<example>` sent "I finished the user authentication module" to this agent "to ensure it follows security and design best practices". The new list ("design, readability, maintainability, performance and project conventions") drops security, and it now sends "a dedicated vulnerability audit" to security-reviewer. The body still checks for security: "Security vulnerabilities and data validation" (line 41), and "security > correctness > performance" (line 64) puts it first in the priority order. Meanwhile `home/.claude/agents/security-reviewer.md` now claims "changes that touch auth, user input, queries, file access or sensitive data". So a finished feature that touches auth now best matches security-reviewer alone. The design, readability and Sandi Metz review that the old example promised for that case may not be dispatched. The two descriptions don't contradict each other, but routing for the old example has changed and neither description tells the router to run both.
- **Options**
  - **(a) Keep as is.** The two agents stay cleanly separated and the description stays short. The word "dedicated" implies a lighter security pass happens here. The cost is that an auth-heavy feature may get only a security audit and no quality review.
  - **(b) Name the security pass and say when to run both.** For example: "…performance, project conventions and a first-pass security check, including Sandi Metz's rules for Ruby. … For a dedicated vulnerability audit also run security-reviewer". This restores the body capability and the old routing for auth modules. The cost is one more clause, and some overlap that the router has to resolve by dispatching both.
  - **(c) Name the security pass without changing the boundary sentence.** This makes the description match the body. The cost is that it leaves "use security-reviewer" as an either-or, which can still route an auth-touching feature to one agent only.
- **Recommended** — (b), because the old description explicitly sent auth modules here for design review, and "also" is the smallest wording that keeps both reviews for that case.
- **Status** — ✅ Fixed: ruled (b) — "Name it + 'also'": the description now names "a first-pass security check" and says "For a dedicated vulnerability audit also run security-reviewer"

### F2 ~~🟢 Low Priority - The test boundary covers writing and fixing tests but not reviewing them, which both agents claim~~ ✅ Fixed

- **Document** — `home/.claude/agents/code-best-practices-reviewer.md`
- **Location** — frontmatter `description:`, line 7 ("to write or fix tests use test-suite-architect")
- **Issue** — `home/.claude/agents/test-suite-architect.md` now describes itself as "Writes, reviews and improves tests". This description says "Reviews recently written code" and points only writing and fixing tests elsewhere. Its body also reviews tests: "When reviewing test code: Ensure tests are meaningful, isolated and maintainable" (line 73) and "Test coverage and testability" (line 42). A request such as "review the specs I just wrote" therefore matches both agents. test-suite-architect's preference sentence mentions only ruby-on-rails-expert, so neither description settles the tie. The old description had no test boundary at all, so this is a remaining gap rather than a regression. Both agents can handle the request, so misrouting costs little.
- **Suggestion** — Widen the boundary to "to write, fix or review tests on their own use test-suite-architect". Test code inside a mixed diff stays here, which matches the body's line 73.
- **Recommendation** — Implement — it is a three-word change in a line this branch already rewrote, and it settles the one sibling overlap left in the new descriptions.
- **Concurred by** — `home/.claude/agents/test-suite-architect.md`, which files the mirror image from its side (frontmatter `description`, lines 4 and 6-7: its only boundary sentence names ruby-on-rails-expert, not code-best-practices-reviewer) and suggests widening its last sentence: "Prefer it over ruby-on-rails-expert or code-best-practices-reviewer whenever the deliverable is tests or a review of them." Rewrap it to 100 columns. Both reports recommend Implement.
- **Status** — ✅ Fixed: the boundary now reads "to write, fix or review tests on their own use test-suite-architect", and test-suite-architect's now reads "Prefer it over ruby-on-rails-expert or code-best-practices-reviewer whenever the deliverable is tests or a review of them"

### F3 ~~🟢 Low Priority - Abbreviation "technical specs" replaces a spelled-out term~~ ✅ Fixed

- **Document** — `home/.claude/agents/documentation-expert.md`
- **Location** — frontmatter `description:`, line 5 ("technical specs")
- **Issue** — The old text said "technical specifications". House style prefers spelled-out terms, and the trim shortened this one. "ADRs" is a well-known abbreviation and the body heading defines it (line 30), so it can stay. "Docs" matches the body's own usage throughout.
- **Suggestion** — Write "technical specifications".
- **Recommendation** — Implement: the lines need rewrapping for F12 and F21 anyway, so it costs nothing extra.
- **Status** — ✅ Fixed: "technical specs" is now "technical specifications"

### F4 ~~🟡 Medium Priority - JSONB scope narrowed to "trade-offs" while the Rails sibling routes all JSONB here~~ ✅ Fixed

- **Document** — `home/.claude/agents/postgresql-expert.md`
- **Location** — Frontmatter `description:`, line 5 ("JSONB vs relational trade-offs")
- **Issue** — The old description claimed "JSON/JSONB operations". The new one claims only the modeling decision, "JSONB vs relational trade-offs". That excludes JSONB work after the decision: querying nested keys, jsonpath, GIN or expression indexes on JSONB. The body covers that work under Advanced Features ("JSONB operations, indexing and query patterns") and Recent PostgreSQL Features ("Enhanced JSON/SQL path language", "JSON constructor functions and IS JSON predicate"). The sibling `home/.claude/agents/ruby-on-rails-expert.md` description (line 7) says "for query plans, indexes, schema or JSONB use postgresql-expert", so it hands off all JSONB work. This description now accepts only the trade-off question, which leaves "how do I index this JSONB key?" claimed by neither.
- **Suggestion** — Replace "JSONB vs relational trade-offs" with "JSONB modeling, querying and indexing". This can share the F14 edit.
- **Recommendation** — Implement: it restores the old scope and closes the gap with the sibling's handoff in a two-word change.
- **Status** — ✅ Fixed: "JSONB vs relational trade-offs" is now "JSONB (modeling, querying and indexing)"; the parentheses keep the comma list free of a nested "and"

### F5 ~~🟡 Medium Priority - Description routes Active Record and N+1 away, but the body claims both~~ ✅ Fixed

- **Document** — `home/.claude/agents/postgresql-expert.md`
- **Location** — Frontmatter `description:` lines 6–7 against "Rails-Specific Considerations", lines 98–106
- **Issue** — The new description says "for Rails app code, Active Record patterns or N+1 queries use ruby-on-rails-expert". That matches the sibling `home/.claude/agents/ruby-on-rails-expert.md`, which claims "Active Record usage and N+1 queries". This agent's body still lists "Understand Active Record's query generation patterns" and "Help optimize N+1 queries and eager loading strategies" among its responsibilities. The branch introduced the boundary, so it introduced the contradiction too. A maintainer reading the file can't tell which half reflects the intended split. The agent may also take on Rails-side N+1 fixes when a caller dispatches it for a slow query.
- **Suggestion** — Narrow the two body bullets to the database side of the boundary. For example: "Read the SQL Active Record generates and judge its plan" and "Diagnose N+1 and eager-loading problems from the query log and plans, leaving the Active Record fix to ruby-on-rails-expert".
- **Recommendation** — Implement: it is two body bullets, and without the change the file contradicts the boundary this branch added.
- **Status** — ✅ Fixed: the two body bullets now read "Read the SQL Active Record generates and judge its plan" and "Diagnose N+1 and eager-loading problems from the query log and plans, leaving the Active Record fix to ruby-on-rails-expert"

### F6 ~~🟡 Medium Priority - The description no longer says "performance", which can send a slow-page request to postgresql-expert~~ ✅ Fixed

- **Document** — `home/.claude/agents/ruby-on-rails-expert.md`
- **Location** — Frontmatter `description`, lines 4–7
- **Issue** — The old description said "performance" twice ("architecture, patterns, performance or implementation" and "Active Record optimization"). Its second example was the case where this matters: "My index action is slow with 1000+ records", answered with N+1, caching, pagination and database optimization. The new text keeps "N+1 queries" and "caching" but drops "performance". Meanwhile `home/.claude/agents/postgresql-expert.md` now opens with "slow queries and EXPLAIN ANALYZE". A router that gets "this page/action is slow" will probably match "slow" to postgresql-expert, even though the body here carries the matching scope: Primary Responsibility 2 ("Optimize application performance and database queries"), the Performance & Caching section (fragment and Russian doll caching, HTTP caching, memory profiling, request/response optimization) and When Debugging step 2. This is the one trigger situation the old description covered that a router can no longer find. The two descriptions' "use X instead" clauses don't settle it, because neither one names app-level slowness.
- **Suggestion** — Name application performance next to caching, e.g. rewrap lines 4–7 as: "Ruby on Rails specialist for application-level work: architecture and service objects, Active Record usage and N+1 queries, app performance (slow actions and pages) and caching, Hotwire, background jobs, API design, Rails upgrades and debugging. Use for Rails design and implementation questions; for query plans, indexes, schema or JSONB use postgresql-expert, and for test suites use test-suite-architect."
- **Recommendation** — Implement. The old description's own example shows this was a core trigger, and the sibling's new "slow queries" wording now competes for it.
- **Status** — ✅ Fixed: the description now names "application performance (slow actions and pages) and caching", spelling out "app"

### F7 ~~🟢 Low Priority - The test boundary is narrower here than the one test-suite-architect claims~~ ✅ Fixed

- **Document** — `home/.claude/agents/ruby-on-rails-expert.md`
- **Location** — Frontmatter `description`, line 7 ("for test suites use test-suite-architect")
- **Issue** — `home/.claude/agents/test-suite-architect.md` says "Prefer it over ruby-on-rails-expert whenever the deliverable is tests" and covers "unit, integration and end-to-end specs" and test strategy. This document hands over only "test suites", which reads as suite-level work (a slow or flaky suite, a suite refactor). Under that wording, "write specs for this service object" stays with ruby-on-rails-expert as a "Rails implementation question". The two descriptions agree on the direction but not on where the line falls, so a router reading only this one could keep single-spec work here.
- **Suggestion** — Match the sibling's wording: "…and whenever the deliverable is tests use test-suite-architect." (line 7 stays under 100 columns).
- **Recommendation** — Implement. It is a one-phrase edit that removes the only gap between the two boundary statements.
- **Status** — ✅ Fixed: the boundary now reads "whenever the deliverable is tests use test-suite-architect"

### F8 ~~⚖️ Decision - The body still lists testing strategy as a primary responsibility that the description now hands off~~ ✅ Fixed

- **Document** — `home/.claude/agents/ruby-on-rails-expert.md`
- **Location** — Primary Responsibilities item 3 ("Advise on testing strategies and test design", line 25) and the Testing Excellence section (lines 69–78), compared with frontmatter line 7
- **Issue** — The old description advertised "testing strategies". The new one deliberately sends tests to test-suite-architect. The body still claims testing strategy as one of five primary responsibilities and keeps a full Testing Excellence section. The router never reads the body, so nothing is misrouted. But the agent's description and its system prompt now disagree about whether test strategy is its job, and a later editor can't tell which one is intended.
- **Options**
  - **(a) Keep the body as it is.** No edit. The agent keeps its test knowledge for the Rails work it is dispatched on ("Always think about test coverage for suggested changes"), but the description and responsibility 3 still disagree.
  - **(b) Reword responsibility 3 only**, e.g. "Keep suggested changes testable and name the specs they need", and leave Testing Excellence as supporting knowledge. A one-line edit that lines the stated responsibilities up with the routing while keeping the context.
  - **(c) Trim Testing Excellence as well** and point to test-suite-architect. This aligns the body fully, but the agent loses context it uses when writing Rails code with specs.
- **Recommended** — (b), because it removes the contradiction without taking away knowledge the agent uses on dispatched Rails work.
- **Status** — ✅ Fixed: ruled (b) — "Reword resp. 3": responsibility 3 now reads "Keep suggested changes testable and name the specs they need"; Testing Excellence is unchanged

### F9 ~~🟢 Low Priority - "specs" and the Rails-only boundary drop the old "any codebase" framing~~ ✅ Fixed

- **Document** — `home/.claude/agents/test-suite-architect.md`
- **Location** — frontmatter `description`, line 4
- **Issue** — The old description opened "create, review or improve test suites for any codebase". The new one drops that phrase. It also switches to "end-to-end specs", which is RSpec vocabulary, while the rest of the description says "tests". The only sibling it names is the Rails agent. The body (lines 36-43) explicitly covers Jest, Mocha, pytest and unittest. Read alone, the description now looks Rails-centric. No other sibling claims tests, so a router would probably still pick this agent for a pytest or Jest request. The cost is a weaker signal and mixed terms, not misrouting.
- **Suggestion** — Bring back the language-neutral scope and use one term: "Writes, reviews and improves tests in any language or framework: unit, integration and end-to-end, TDD, test strategy, …"
- **Recommendation** — Implement. It recovers one phrase of scope the old text carried and makes the terms consistent at no cost.
- **Status** — ✅ Fixed: the description now opens "Writes, reviews and improves tests in any language or framework" and says "end-to-end tests"

## Accuracy

### F10 ~~🟢 Low Priority - "Multi-tenancy" is advertised but the body never covers it~~ ✅ Fixed

- **Document** — `home/.claude/agents/postgresql-expert.md`
- **Location** — Frontmatter `description:`, line 5 ("schema design and multi-tenancy")
- **Issue** — Multi-tenancy is now a headline capability. In the old description it appeared only inside an `<example>`, whose commentary pointed to "partitioning, row-level security and schema design". `grep -niE 'tenan|row-level|rls|security'` over the file finds no match in the body, only line 5. Row-level security, the main PostgreSQL-specific multi-tenancy tool, appears nowhere in the body. The description promises something the system prompt does not prepare the agent for. The gap existed before, but the old text buried it in an example and the new text states it outright.
- **Suggestion** — Add a bullet to the body's "Schema Design" list: "Multi-tenancy patterns: tenant-keyed shared tables, schema-per-tenant and row-level security policies".
- **Recommendation** — Implement: one body bullet makes the advertised capability real. Dropping "multi-tenancy" from the description would instead lose the routing the old example carried.
- **Status** — ✅ Fixed: Schema Design now carries "Multi-tenancy patterns: tenant-keyed shared tables, schema-per-tenant and row-level security policies"

## Clarity and Structure

### F11 ~~🟡 Medium Priority - Two trigger situations from the old description are gone: reviewing an open pull request, and improving existing code on request~~ ✅ Fixed

- **Document** — `home/.claude/agents/code-best-practices-reviewer.md`
- **Location** — frontmatter `description:`, lines 5–6 ("Use after finishing a class, module or feature, before committing or opening a PR")
- **Issue** — The old description named three situations: "post-implementation reviews, pull request feedback or when you want to improve code quality". The new one keeps only the first, and its timing ("before committing or opening a PR") actively excludes the second. A request to review an already-open pull request for code quality no longer matches this agent's trigger. The body supports both dropped cases. It reviews "the most recently written or modified code unless explicitly asked otherwise" (line 63), which covers a pull request's diff and, on request, older code. The router reads only the description, so in those cases it may dispatch nothing or the wrong agent.
- **Suggestion** — Replace lines 5–6's trigger sentence with: "Use after finishing a class, module or feature, before committing, on an open pull request's diff or when asked to improve existing code." Reflow to 100 columns.
- **Recommendation** — Implement — the branch's stated goal is to trim without losing routing, and these are routing triggers the old text carried that the body still supports.
- **Status** — ✅ Fixed: the trigger now reads "before committing, on an open pull request's diff or when asked to improve existing code"

### F12 ~~🟢 Low Priority - "inline code documentation" narrowed to "code comments"~~ ✅ Fixed

- **Document** — `home/.claude/agents/documentation-expert.md`
- **Location** — frontmatter `description:`, line 5 ("code comments")
- **Issue** — The old description said "inline code documentation". The body's **In-Code Documentation** bullet (line 39) covers "Meaningful comments, method documentation, module-level overviews", and Constraints (lines 224–225) names YARD and JSDoc. "Code comments" drops method and module documentation from what the router sees. A request like "write YARD docs for this service class" now matches less clearly, and the closest sibling claim, code-best-practices-reviewer's "readability", could pick it up instead.
- **Suggestion** — Replace "code comments" with "inline code documentation" (or "code comments and docstrings") and rewrap lines 4–7 to stay within 100 columns.
- **Recommendation** — Implement: it puts back a capability the old text listed and the body supports, for a few words.
- **Status** — ✅ Fixed: "code comments" is now "inline code documentation", the alternative the user chose over "code comments and docstrings"

### F13 ~~🟢 Low Priority - Dropped trigger: making documentation consistent~~ 🚫 Ignored

- **Document** — `home/.claude/agents/documentation-expert.md`
- **Location** — frontmatter `description:`, lines 5–7 (the "Use when" clause)
- **Issue** — The old description listed "ensuring consistency across documentation" as a use case. The new "Use when" clause names three situations: a feature needs docs, existing docs are outdated or hard to follow, and a concept needs explaining. None of them covers a request to align terminology or structure across a set of documents that are neither outdated nor hard to follow. The opening "reviews and improves documentation" still covers the request, and the body supports it ("consistent terminology", line 102; "Cross-reference validation", line 206), so the routing risk is small.
- **Suggestion** — Add "or inconsistent with each other" after "outdated or hard to follow".
- **Recommendation** — Skip: "reviews and improves documentation" already routes these requests here, and no sibling competes for them.
- **Status** — 🚫 Ignored: "reviews and improves documentation" already routes it

### F14 ~~🟡 Medium Priority - Production administration dropped from the routing summary~~ ✅ Fixed

- **Document** — `home/.claude/agents/postgresql-expert.md`
- **Location** — Frontmatter `description:`, lines 4–7
- **Issue** — The old description advertised "performance tuning", "troubleshooting" and "production database management" (`git show d22496a:home/.claude/agents/postgresql-expert.md`, line 4). The new list keeps query, index, schema, JSONB, full-text, partitioning, locking and migration work, but no administration trigger survives. The body still makes this a primary responsibility: item 5 "Help with production database administration and monitoring" and the whole "Performance & Administration" section. That section covers connection pooling (PgBouncer, Odyssey), vacuum, autovacuum and bloat, WAL and replication, backups, `pg_stat_*` monitoring and memory configuration. A router given "autovacuum isn't keeping up", "set up PgBouncer", "replication lag" or "how much `work_mem`?" has only the catch-all "the question is about the database itself" to go on. No listed trigger matches. The body's item 4 "upgrades" (major-version PostgreSQL upgrades) appeared in neither description.
- **Suggestion** — Add an administration clause to the trigger list and rewrap to 100 columns: "…partitioning, locking, safe migrations and upgrades, and production administration such as vacuum and bloat, replication, backups, connection pooling and configuration tuning." Restructure the sentence if that pushes in a serial comma, e.g. end the list at "safe migrations and upgrades" and open a new sentence: "Also covers production administration: vacuum and bloat, replication, backups, connection pooling and configuration tuning."
- **Recommendation** — Implement: this is a whole body section the router can no longer see, and the edit is one line in the same frontmatter the branch already changes.
- **Status** — ✅ Fixed: took the suggestion's second form: "safe migrations and upgrades" ends the list and a new sentence reads "Also covers production administration: vacuum and bloat, replication, backups, connection pooling and configuration tuning."

### F15 ~~🟢 Low Priority - "Production deployment" was dropped and no sibling picks it up~~ ✅ Fixed

- **Document** — `home/.claude/agents/ruby-on-rails-expert.md`
- **Location** — Frontmatter `description`, lines 4–6
- **Issue** — The old description listed "production deployment" among its specializations. The new one has no deployment or production wording; "debugging" is the closest term. No sibling description covers app deployment: postgresql-expert claims "safe migrations" only, and documentation-expert covers deployment *docs*. The body does back it: Modern Rails Features has "Deployment with Kamal" (line 67) and Primary Responsibility 5 is "Troubleshoot complex bugs and production issues". Without the wording, a Kamal or production-incident question has no description to match and is left to the router's guess.
- **Suggestion** — Change "Rails upgrades and debugging" to "Rails upgrades, Kamal deployment and production debugging", rewrapping lines 5–6 as needed.
- **Recommendation** — Implement. It costs a few words, and nothing else in the agent set claims this scope.
- **Status** — ✅ Fixed: the description now reads "Rails upgrades, Kamal deployment and production debugging"

### F16 ~~🟢 Low Priority - The enumerated trigger list leaves out change types the body audits~~ ✅ Fixed

- **Document** — `home/.claude/agents/security-reviewer.md`
- **Location** — Frontmatter `description:`, lines 4–7
- **Issue** — The old description gave a general trigger ("Perfect for pre-merge security audits, vulnerability assessments"). The new one lists specific triggers: "changes that touch auth, user input, queries, file access or sensitive data". A list like that reads as complete, so a router can take anything missing from it as out of scope. The body audits several kinds of change that the list doesn't name, and the capability list doesn't name them either: **Dependency changes** (the Dependency Security section checks `Gemfile.lock` for vulnerable or outdated gems); **Outbound requests built from user-supplied URLs** (the Server-Side Request Forgery section covers webhooks, link previews and image proxies); **Security configuration** (the Security Misconfiguration section and the CSRF bullets cover CORS, security headers and `skip_forgery_protection`). A gem bump or a CORS change matches none of the listed triggers, although the old "pre-merge security audits" plausibly covered both. The capability list also narrows "injection" to "SQL injection and XSS". The body covers more than that: command injection, path traversal and template injection. This is a small step backward in coverage, not a lost capability. The old text never named these areas either.
- **Suggestion** — Widen both lists while keeping the four-line shape and the 100-column wrap:

  ```yaml
  description: |-
    Security audit of code changes for vulnerabilities and attack vectors: OWASP Top 10,
    authentication and authorization, injection and XSS, SSRF, sensitive data, dependencies and
    Rails-specific risks. Use before merging changes that touch auth, user input, queries, file
    access, outbound requests, security configuration, dependencies or sensitive data, or when asked
    for a security review. For general code quality use code-best-practices-reviewer.
  ```

- **Recommendation** — Implement: it adds about a dozen words, and without it a gem bump or a config change before merge may not reach the security reviewer.
- **Status** — ✅ Fixed: both lists widened as suggested: "injection and XSS, SSRF, sensitive data, dependencies" and "outbound requests, security configuration, dependencies"

### F17 ~~🟢 Low Priority - "Information architecture" is no longer a routing trigger~~ ✅ Fixed

- **Document** — `home/.claude/agents/ui-ux-design-specialist.md`
- **Location** — Frontmatter `description`, lines 4-5
- **Issue** — The old dashboard example ("There's too much going on") sent the agent in for "the information architecture and visual hierarchy of your dashboard". The new description keeps "visual hierarchy" and "layout" but drops "information architecture". The body lists it as a core skill under Core Expertise > User Experience ("Content organization, navigation patterns, user flows"). Some requests are about structure, not looks, e.g. "how should I group these settings pages" or "what goes in the main menu". "Navigation" in the new text names a kind of UI, not the work of organizing content, so a router has less to match those requests to this agent.
- **Suggestion** — Add the term to the capability list. Rewrap if needed, keeping the line under 100 columns: `UI and UX design guidance: usability, information architecture, visual hierarchy, layout, color, typography, interaction patterns, user flows, design systems and WCAG accessibility.`
- **Recommendation** — Implement — two words restore a trigger the old example carried and the body supports.
- **Status** — ✅ Fixed: "information architecture" added to the capability list

### F18 ~~🟢 Low Priority - "Building" shifts the trigger from designing UI toward implementing it~~ ✅ Fixed

- **Document** — `home/.claude/agents/ui-ux-design-specialist.md`
- **Location** — Frontmatter `description`, lines 5-6 ("Use when building or reviewing forms, dashboards, navigation or other UI")
- **Issue** — The old text said "creating new component designs". The new one says "building ... UI", which a router could read as "this agent builds the UI". The body is advisory, not an implementer. It reviews, recommends and adds code snippets "when implementation guidance helps". The opening words "design guidance" partly offset this.
- **Suggestion** — Replace "Use when building or reviewing forms" with "Use when designing or reviewing forms".
- **Recommendation** — Skip — the "design guidance" opening already frames the agent as an advisor, so a misroute is unlikely and the change is marginal.
- **Status** — ✅ Fixed: ruled Implement — "one-word swap": "Use when building" is now "Use when designing"

## Spelling and Grammar

### F19 ~~🟢 Low Priority - "PR" is abbreviated where house style spells out "pull request"~~ ✅ Fixed

- **Document** — `home/.claude/agents/code-best-practices-reviewer.md`
- **Location** — frontmatter `description:`, line 6 ("before committing or opening a PR")
- **Issue** — The house style says to prefer spelling terms out, and the global CLAUDE.md writes "pull request" throughout. The old description wrote "pull request feedback". The new line abbreviates it.
- **Suggestion** — Write "pull request" and reflow lines 6–7 within 100 columns. If F11 is implemented, its wording already spells it out.
- **Recommendation** — Implement — it costs nothing as part of the same edit as F11.
- **Status** — ✅ Fixed: "opening a PR" is gone; F11's wording spells out "pull request"

### F20 ~~🟢 Low Priority - "e.g.," is followed by a comma in the body~~ ✅ Fixed

- **Document** — `home/.claude/agents/code-best-practices-reviewer.md`
- **Location** — Consider Project Context, lines 48–49 ("(e.g., RuboCop for Ruby)", "(e.g., Rails conventions)")
- **Issue** — The house style writes `e.g.` with no following comma. Both instances are older than this branch, which changed only the frontmatter. A grep over `home/.claude/agents/*.md` finds them in this file only.
- **Suggestion** — Change both to "(e.g. RuboCop for Ruby)" and "(e.g. Rails conventions)".
- **Recommendation** — Defer — this branch only touches the frontmatter, and this two-character fix fits a style follow-up better than a description trim. Fold it in if the file is edited anyway for F1, F2, F11 and F19.
- **Status** — ✅ Fixed: ruled Implement — "fold into G1": both now read "(e.g. RuboCop for Ruby)" and "(e.g. Rails conventions)"

### F21 ~~🟢 Low Priority - Serial comma in the "Use when" list~~ ✅ Fixed

- **Document** — `home/.claude/agents/documentation-expert.md`
- **Location** — frontmatter `description:`, lines 5–6 ("when existing docs are outdated or hard to follow, or when a decision…")
- **Issue** — The clause is a three-item list ("when a feature needs docs, when existing docs are outdated or hard to follow, or when a decision…") with a comma before the final "or". House style drops the serial comma. Removing it here makes the clause harder to read, because the second item already contains "or" ("outdated or hard to follow"). The house rule says to restructure in that case.
- **Suggestion** — Restructure, e.g. "Use when a feature needs docs, when a decision or technical concept needs explaining for a specific audience or when existing docs are outdated or hard to follow." This moves the item that contains "or" to the end.
- **Recommendation** — Implement: the house rule calls for it and the fix is a reorder.
- **Status** — ✅ Fixed: the "Use when" list is reordered to end "…for a specific audience or when existing docs are outdated or hard to follow", with no serial comma

### F22 ~~🟢 Low Priority - Serial comma in the "Use when" list~~ ✅ Fixed

- **Document** — `home/.claude/agents/test-suite-architect.md`
- **Location** — frontmatter `description`, lines 5-6
- **Issue** — "Use when new code needs tests, when deciding how to test a feature or integration, or when a suite needs refactoring" puts a serial comma before the third item. House style omits it. Just dropping it leaves "a feature or integration or when a suite…", which reads ambiguously. The house rule says to restructure the sentence in that case.
- **Suggestion** — Restructure so the "or" inside item two no longer collides with the list's "or", e.g. "Use when new code needs tests, when a suite needs refactoring and when deciding how to test a feature or an integration."
- **Recommendation** — Implement. It is house style on a line this branch introduced, and the edit costs nothing.
- **Status** — ✅ Fixed: the "Use when" list now reads "when a suite needs refactoring and when deciding how to test a feature or an integration", with no serial comma

### F23 ~~🟢 Low Priority - "TDD" abbreviated where the old text and the body spell it out~~ 🚫 Ignored

- **Document** — `home/.claude/agents/test-suite-architect.md`
- **Location** — frontmatter `description`, line 4
- **Issue** — The old description said "test-driven development practices", and the body (line 18) spells it out too. The new description uses "TDD", while house style generally prefers spelled-out terms.
- **Suggestion** — Write "test-driven development" if the line still fits after F9's edit.
- **Recommendation** — Skip. "TDD" is universally understood by both the router and readers, a summary written for routing benefits from brevity, and the house rule allows context to decide.
- **Status** — 🚫 Ignored: "TDD" is universally understood; routing favors brevity

## Observations

### F24 💡 Observation (optional action) - Body capabilities the description has never advertised

- **Document** — `home/.claude/agents/documentation-expert.md`
- **Location** — frontmatter `description:` compared with the body's **Documentation Types** (lines 24–39)
- **Issue** — The body also covers system design documents and Mermaid component diagrams, release notes, migration guides and upgrade paths, and incident response playbooks and deployment procedures. Neither the old nor the new description names them, so the trim introduced no new gap. A request for a migration guide or an architecture diagram may still be routed elsewhere or handled inline.
- **Action** — Optionally replace "ADRs" with "architecture docs and ADRs" and "changelogs" with "changelogs and release notes", keeping the summary short.

### F25 💡 Observation (optional action) - Most Modern Rails features are covered only by the catch-all

- **Document** — `home/.claude/agents/ruby-on-rails-expert.md`
- **Location** — Frontmatter `description` compared with Modern Rails Features (lines 52–67)
- **Issue** — The old description advertised "modern Rails features" as a group. The new one names only Hotwire. Active Storage, Action Cable, encrypted credentials, the authentication generator, and multi-database support and horizontal sharding now rely on the "Rails design and implementation questions" catch-all. That is enough in most cases, since no sibling competes for them. The exception is sharding: postgresql-expert's "partitioning" and "multi-tenancy" could pull a "shard my Rails app" request. Optional action: append "multi-database" to the list if that case comes up.

### F26 💡 Observation (optional action) - No boundary sentence toward code-best-practices-reviewer

- **Document** — `home/.claude/agents/ui-ux-design-specialist.md`
- **Location** — Frontmatter `description`, line 6 ("use proactively after UI or styling changes")
- **Issue** — `home/.claude/agents/code-best-practices-reviewer.md` says "Use after finishing a class, module or feature, before committing". So after a UI change, both agents' proactive triggers match. On this branch every sibling with a close neighbor got a "use X instead" clause. This description has none, and neither did the old one, so nothing was lost. The two reviews complement each other: design and usability here, code quality there. Both running is fine, and a hard "use X instead" would wrongly stop one of them.
- **Suggestion** — Optional. If you want the pattern to match the siblings, add a complementary clause, not an exclusive one: "For the code quality of the implementation, also use code-best-practices-reviewer."

## Consolidated Summary

| Finding | Type | Category | Description | Document | Location | Recommendation | Group | Status |
| --------- | ---------- | ---------- | ------------- | ---------- | ---------- | ---------------- | ------- | -------- |
| F1 | ⚖️ Decision | Consistency | Security dropped from the description, so auth-touching features route only to security-reviewer | `home/.claude/agents/code-best-practices-reviewer.md` | frontmatter `description:`, lines 4–7 | Options (b) | G1 | ✅ |
| F2 | 🟢 Low | Consistency | Test boundary covers writing and fixing tests but not reviewing them | `home/.claude/agents/code-best-practices-reviewer.md` | frontmatter `description:`, line 7 | Implement | G1 | ✅ |
| F3 | 🟢 Low | Consistency | "technical specs" abbreviates a spelled-out term | `home/.claude/agents/documentation-expert.md` | frontmatter `description:`, line 5 | Implement | G9 | ✅ |
| F4 | 🟡 Medium | Consistency | JSONB scope narrowed to "trade-offs" while the Rails sibling routes all JSONB here | `home/.claude/agents/postgresql-expert.md` | frontmatter `description:`, line 5 | Implement | G3 | ✅ |
| F5 | 🟡 Medium | Consistency | Description routes Active Record and N+1 away, but the body claims both | `home/.claude/agents/postgresql-expert.md` | Rails-Specific Considerations, lines 98–106 | Implement | G4 | ✅ |
| F6 | 🟡 Medium | Consistency | "Performance" dropped, so slow-page requests may go to postgresql-expert | `home/.claude/agents/ruby-on-rails-expert.md` | frontmatter `description`, lines 4–7 | Implement | G5 | ✅ |
| F7 | 🟢 Low | Consistency | Test boundary narrower than the one test-suite-architect claims | `home/.claude/agents/ruby-on-rails-expert.md` | frontmatter `description`, line 7 | Implement | G5 | ✅ |
| F8 | ⚖️ Decision | Consistency | Body still lists testing strategy as a primary responsibility the description hands off | `home/.claude/agents/ruby-on-rails-expert.md` | Primary Responsibilities item 3; Testing Excellence | Options (b) | G2 | ✅ |
| F9 | 🟢 Low | Consistency | "specs" and the Rails-only boundary drop the "any codebase" framing | `home/.claude/agents/test-suite-architect.md` | frontmatter `description`, line 4 | Implement | G8 | ✅ |
| F10 | 🟢 Low | Accuracy | "Multi-tenancy" advertised but the body never covers it | `home/.claude/agents/postgresql-expert.md` | frontmatter `description:`, line 5; Schema Design | Implement | G4 | ✅ |
| F11 | 🟡 Medium | Clarity and Structure | Open pull request and improve-existing-code triggers are gone | `home/.claude/agents/code-best-practices-reviewer.md` | frontmatter `description:`, lines 5–6 | Implement | G1 | ✅ |
| F12 | 🟢 Low | Clarity and Structure | "inline code documentation" narrowed to "code comments" | `home/.claude/agents/documentation-expert.md` | frontmatter `description:`, line 5 | Implement | G9 | ✅ |
| F13 | 🟢 Low | Clarity and Structure | Dropped trigger: making documentation consistent | `home/.claude/agents/documentation-expert.md` | frontmatter `description:`, lines 5–7 | Skip | — | 🚫 |
| F14 | 🟡 Medium | Clarity and Structure | Production administration dropped from the routing summary | `home/.claude/agents/postgresql-expert.md` | frontmatter `description:`, lines 4–7 | Implement | G3 | ✅ |
| F15 | 🟢 Low | Clarity and Structure | "Production deployment" dropped and no sibling picks it up | `home/.claude/agents/ruby-on-rails-expert.md` | frontmatter `description`, lines 4–6 | Implement | G5 | ✅ |
| F16 | 🟢 Low | Clarity and Structure | Trigger list leaves out change types the body audits | `home/.claude/agents/security-reviewer.md` | frontmatter `description:`, lines 4–7 | Implement | G7 | ✅ |
| F17 | 🟢 Low | Clarity and Structure | "Information architecture" no longer a routing trigger | `home/.claude/agents/ui-ux-design-specialist.md` | frontmatter `description`, lines 4-5 | Implement | G6 | ✅ |
| F18 | 🟢 Low | Clarity and Structure | "Building" shifts the trigger from designing UI toward implementing it | `home/.claude/agents/ui-ux-design-specialist.md` | frontmatter `description`, lines 5-6 | Skip | G6 | ✅ |
| F19 | 🟢 Low | Spelling and Grammar | "PR" abbreviated where house style spells out "pull request" | `home/.claude/agents/code-best-practices-reviewer.md` | frontmatter `description:`, line 6 | Implement | G1 | ✅ |
| F20 | 🟢 Low | Spelling and Grammar | "e.g.," followed by a comma in the body | `home/.claude/agents/code-best-practices-reviewer.md` | Consider Project Context, lines 48–49 | Defer | G1 | ✅ |
| F21 | 🟢 Low | Spelling and Grammar | Serial comma in the "Use when" list | `home/.claude/agents/documentation-expert.md` | frontmatter `description:`, lines 5–6 | Implement | G9 | ✅ |
| F22 | 🟢 Low | Spelling and Grammar | Serial comma in the "Use when" list | `home/.claude/agents/test-suite-architect.md` | frontmatter `description`, lines 5-6 | Implement | G8 | ✅ |
| F23 | 🟢 Low | Spelling and Grammar | "TDD" abbreviated where the old text and the body spell it out | `home/.claude/agents/test-suite-architect.md` | frontmatter `description`, line 4 | Skip | — | 🚫 |
| F24 | 💡 Observation | — | Body capabilities the description has never advertised | `home/.claude/agents/documentation-expert.md` | frontmatter `description:`; Documentation Types | — | — | — |
| F25 | 💡 Observation | — | Most Modern Rails features covered only by the catch-all | `home/.claude/agents/ruby-on-rails-expert.md` | frontmatter `description`; Modern Rails Features | — | — | — |
| F26 | 💡 Observation | Consistency | No boundary sentence toward code-best-practices-reviewer | `home/.claude/agents/ui-ux-design-specialist.md` | frontmatter `description`, line 6 | — | — | — |

## Pre-Merge Checklist

### G1 ✅ — Settle code-best-practices-reviewer's security scope and rewrite its description

Closed: F1 ruled (b) and edited in, with F2, F11, F19 and F20 fixed in the same file and F2's matching sentence in test-suite-architect.

- [x] ✅ F1 - Whether the description names a first-pass security check and says when to run both reviewers (changed to (b) — first-pass security check named; "also run security-reviewer")
- [x] ✅ F2 - Widen the test boundary to cover reviewing tests, in both this description and test-suite-architect's
- [x] ✅ F11 - Restore the open-pull-request and improve-existing-code triggers
- [x] ✅ F19 - Spell out "pull request"
- [x] ✅ F20 - Drop the comma after "e.g." in code-best-practices-reviewer's body

### G3 ✅ — Restore postgresql-expert's administration and JSONB scope

Closed: F4 and F14 fixed in one edit to postgresql-expert's description.

- [x] ✅ F4 - Widen "JSONB vs relational trade-offs" to JSONB modeling, querying and indexing
- [x] ✅ F14 - Add production administration (vacuum, replication, backups, pooling, tuning) and upgrades to the description

### G4 ✅ — Align postgresql-expert's body with its description

Closed: F5 and F10 fixed in postgresql-expert's body.

- [x] ✅ F5 - Narrow the Active Record and N+1 body bullets to the database side of the boundary
- [x] ✅ F10 - Add a multi-tenancy bullet to Schema Design

### G5 ✅ — Restore ruby-on-rails-expert's performance and deployment triggers and align its test boundary

Closed: F6, F7 and F15 fixed in one edit to ruby-on-rails-expert's description.

- [x] ✅ F6 - Name application performance next to caching
- [x] ✅ F7 - Match test-suite-architect's "whenever the deliverable is tests" boundary
- [x] ✅ F15 - Add Kamal deployment and production debugging

### G2 ✅ — Settle whether ruby-on-rails-expert's body keeps testing strategy as a responsibility

Closed: F8 ruled (b) and responsibility 3 reworded.

- [x] ✅ F8 - Whether responsibility 3 and Testing Excellence stay, are reworded or are trimmed (changed to (b) — responsibility 3 reworded; Testing Excellence kept)

### G6 ✅ — Restore "information architecture" in ui-ux-design-specialist

Closed: F17 and F18 fixed in one edit to ui-ux-design-specialist's description.

- [x] ✅ F17 - Add "information architecture" to the capability list
- [x] ✅ F18 - Change "building" to "designing" in ui-ux-design-specialist

### G7 ✅ — Widen security-reviewer's trigger and capability lists

Closed: F16 fixed by widening security-reviewer's description.

- [x] ✅ F16 - Add outbound requests, security configuration, dependencies, SSRF and wider injection to the lists

### G8 ✅ — Tidy test-suite-architect's description

Closed: F9 and F22 fixed, reflowed with G1's F2 sentence.

- [x] ✅ F9 - Restore the language-neutral scope and use "tests" throughout
- [x] ✅ F22 - Restructure the "Use when" list to drop the serial comma

### G9 ✅ — Tidy documentation-expert's description

Closed: F3, F12 and F21 fixed in one edit to documentation-expert's description.

- [x] ✅ F3 - Write "technical specifications"
- [x] ✅ F12 - Restore "inline code documentation"
- [x] ✅ F21 - Restructure the "Use when" list to drop the serial comma

### Not recommended for this revision

- [x] 🚫 F13 - Add "or inconsistent with each other" to documentation-expert's triggers (ignored — "reviews and improves documentation" already routes it)
- [x] 🚫 F23 - Spell out "test-driven development" (ignored — "TDD" is universally understood; routing favors brevity)
