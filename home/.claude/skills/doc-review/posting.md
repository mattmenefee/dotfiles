# Document Review: Posting the Review

## PR Comment Format

<!-- Keep in sync with a project's /ship-it, where one exists: Step 8 of .claude/commands/ship-it.md
     in some projects, and in the dotfiles repository Step 6 of .claude/skills/ship-it/SKILL.md with
     the patterns in scripts/scrub.sh beside it, whose header lists the differences from this
     section that are intended; update that list whenever this section changes, and re-derive it
     before syncing in either direction. Each restates the stats-line rule and carries its own
     copies of the scrub pattern set (with the placeholder exemption built into `paths`), the
     cleared-lines rule and the Sensitive Information withholding. This skill's own copy of the
     pattern set is scripts/scrub-lib.sh -->

<!-- Keep in sync with Step 8 of another project's .claude/commands/ship-it.md, where the amended
     `keys`, `schemes` and `secrets` set in scripts/scrub-lib.sh was tested against credential
     samples and harmless negatives -->

When posting review findings as a PR comment (e.g. during `/ship-it` or when explicitly asked), post
them with `scripts/post.sh` from the skill directory, which wraps the review in a collapsible
`<details><summary>` block and posts it with `--body-file`. Every command below runs from the
repository root on the pull request's branch; `<skill dir>` is the skill directory SKILL.md names.

A review comment records how the review ended, not a snapshot of one in progress. `post.sh` opens
with the same two checks `/ship-it` runs for findings still open, a ❓ summary row or a `- [ ]`
checklist item, and refuses to post while either finds one. When it refuses, name the open findings
to the user: one with a **Ruling** line or an Implement recommendation needs its group worked, and
any other needs the user's ruling. Never mark a finding yourself to get past the check. A review
that quotes a summary row or an unchecked item at the start of a line can never pass it; tell the
user that is why, rather than loosening it.

Before posting, also name to the user every ⏸️ Deferred 🔴 Critical finding, whatever its category,
and every ⏸️ Deferred 🟠 High finding under Sensitive Information, each with the follow-up
its **Status** or **Recommendation** line names, or say that it names none. Each is off the
pre-merge path but still describes a weakness the comment would publish. A Sensitive Information
finding is then withheld or cleared under Ask before withholding, below.

Scrub the review document before building the comment. This artifact is written by an agent reading
a developer machine, and a finding that traces where a global command or a user-level agent resolves
from will cite an absolute path under the home directory. Check here rather than trusting the review
stage, because this is the step that publishes. Run the scrub:

```bash
'<skill dir>/scripts/scrub.sh'
```

It prints the files it scanned, then every hit. Exit 0 is clean, 1 means it printed hits and 2 means
the scan itself failed or found no artifact to scan: treat 2 as a block, never as clean.

The scripts check that each file they are given can be read and make one that cannot fatal. An unset
or unreadable path is not otherwise an error: `grep` warns on stderr, prints no match lines and —
under a trailing `|| true` — exits 0, so the scrub would certify a document it never opened.

The `/dev/null` argument keeps `grep` printing the filename. Branch on the exit code rather than
swallowing it: `grep` exits 1 when it matches nothing, which is the benign case the scrub is written
around, but 2 when it cannot read the file. `|| true` collapses both to success, rewriting a read
failure into a clean bill of health — the exact fail-open this section exists to prevent, and a
warning on stderr is easy for an agent scanning for `file:line:` output to disregard.

**Empty output means nothing matched only if `grep` actually ran.** At least four paths produce no
output: nothing matched, which is the intended one; the file could not be read; `find` matched zero
files; and the wrong directory was scanned. Only the first is clean. Treat the others as a failed
scrub and do not post — which is what the readability checks, the exit-code branches and the echoed
file list in the scripts are each there to make visible.

The scan covers the set of artifacts rather than one named file. `scripts/scrub-lib.sh`, which
`scrub.sh` and `post.sh` share so the two scans cannot drift apart, matches them with `find` rather
than a shell glob, and matches `*local-review*.md` rather than the exact name, since a review
carried onto a stacked branch is named `<source-branch>-carried-local-review.md`.

Run `grep` as `command grep` wherever the shell invokes it. An interactive shell can wrap `grep` in
a function or alias — ugrep with `--ignore-files`, for one — and review artifacts are routinely
gitignored, so a wrapper that honors ignore files would skip exactly the files the scrub exists to
read, and the two scrub forms would silently run different tools. `command` bypasses functions and
aliases; `find -exec grep` already runs the binary directly and needs no prefix. Never give the
scrub a flag or tool that honors ignore files. Run every scrub `grep` under `LC_ALL=C` as well: in a
UTF-8 locale macOS `grep` matches nothing on a line holding an invalid byte, so a credential after
one reads as clean.

`find` does the matching so the shell never expands the glob. An unmatched `*-DOC-REVIEW.md` inside
a single `grep` command aborts that command outright under zsh, and `2>/dev/null` does not suppress
it, because the shell reports the failed expansion before the redirection applies — the scrub then
silently does not run at all. A branch-suffixed review document is a deliberate convention, so
matching the exact name would leave the artifact unopened, printing nothing and reading as clean.

Anchor the scan to `git rev-parse --show-toplevel`, not to `.`. The artifact is written to the
project root while `find .` scans wherever the agent happens to be, and `-maxdepth 1` makes that
miss total rather than partial — one `cd`, a subdirectory or a review agent running in an isolated
worktree is enough to scan an empty set. Capture the file list and fail loudly when it is empty,
then echo what was scanned: `find … -exec … +` never invokes `grep` when it matches nothing, so it
prints nothing and exits 0, byte-identical to a genuinely clean scan. The `find` form was adopted to
stop the scrub silently not running, and without these two lines it reintroduces the same silence
through a different door. Listing the files scanned is what makes the verdict checkable rather than
merely quiet.

Rewrite each hit **in the review document** before building the comment — `~`-prefixed when the path
genuinely lies outside the repository, repo-relative when it does not. Fixing the comment afterwards
does not undo the disclosure: GitHub keeps the pre-edit revision in the comment's edit history,
readable by anyone with repo access, and the only complete remedy is to delete the comment and
repost it under a new URL.

Replace **every occurrence of the username**, not just the leading path prefix, with `<user>`. A
prefix rewrite is not sufficient: usernames also appear dash-encoded inside paths — Claude Code's
own per-project directories take the form `-Users-<name>--some-repo` — and a line carrying one is
caught by the scan, then passes clean after a `~`-prefix rewrite while still naming the user twice.
A remediation its own verifier certifies as safe is worse than none, because it ends the reviewer's
attention. The `-users-` term catches the dash-encoded form for exactly this reason.

Match the account name only where it names the machine: as a path segment, `/<name>/`, or as the
local part of an address, `<name>@host`. Those are the forms that identify a home directory or a
mailbox, and the path and address terms catch most of them already; the account-name term covers a
path or host the other terms miss. Never match it as a word in prose. There it is the author's name,
which the pull request already shows, and ruling attributions use it constantly
(`confirmed by <name>`), so a word match stops nearly every walked review and its rewrite to
`<user>` erases who ruled. A gate that routinely cries wolf teaches the reader to override it. The
name is escaped before it enters the pattern, since an account name can contain `.` or other
characters `grep -E` would otherwise read as syntax.

Every other term is bounded the same way, so that it fires on the machine rather than on the
repository text a review quotes. A path term must start a path, so `app/views/users/` passes while
`/Users/…` does not. A bare `/tmp/…` path names no machine, so only the per-user temp roots macOS
prints, `/private/tmp/`, `/var/folders/` and its resolved form under `/private/var/`, are matched. A
`file://` URL's home path is matched too, though the `/` before it would fail the bound. An address
must be a full dotted quad, so `10.years` passes. A host suffix must end its name, and `.local` must
carry a port or path, so `.env.test.local`, `settings.local.json` and `Time.zone.local(` pass, at
the cost of a bare `host.local` in prose.

**Re-run `scrub.sh` after rewriting, and treat any remaining output as blocking.** The rewrite step
is performed by the same agent that is judging whether it worked, so without a second pass its
belief that the document is clean is never tested against the document as it now stands. A
detect-and-fix step with no re-detect is a fix nobody checked.

The placeholder exemption is **syntactic, not a judgment call**: an occurrence is exempt only when
the segment after `/Users/`, `/home/` or `-Users-` opens with an angle bracket, as `/Users/<name>/…`
and `-Users-<name>-…` quoted from the rule itself do. Any other value is treated as real, however
generic it looks, and the bracketed word must not be the account name itself: `<$me>` is its own
term, so `/Users/<login>/` still fires when the login is real. The `([^<]|$)` after each of those
terms in `paths` implements it, so the exemption is applied by the pattern rather than decided by
the agent running it — and applied to the occurrence, not the line. A filter that drops every line
holding a placeholder also drops whatever else that line carries, so a real home path or a
credential sharing a line with `/Users/<name>/` would pass both gates. Gate 2 also runs `secrets`
and `ident` as separate passes, each passed to `grep` with `-e` because `secrets` begins with
`-----` and would otherwise be read as an option, and branches on each `grep`'s own exit status,
since a status piped through a later filter is the filter's and an unreadable comment would read as
clean. `scan` runs the same two passes over the artifacts: only the `secrets` pass goes through
`uncleared`, so a cleared line still shows its path hits, and `grep_artifacts` turns a failed read,
never a clean file, into a failed `find`.

The reason it is mechanical is that the failure is asymmetric. `/Users/<name>/…` and
`/Users/dev/work/thing` produce identical adjacent hit lines, and nothing tells an agent whether
`dev`, `admin`, `ubuntu`, `runner` or `user` is a placeholder or a real account. A wrong "that's a
placeholder" publishes a real home path; the reverse merely garbles a quoted rule. Any review of
these command files carries such a quotation, which makes the exemption routine — and routine is
where habituation sets in.

`scan` matches secret-shaped content as well as paths, and those hits are **reported to the user and
block the post — never rewritten.** Rewriting a credential in the artifact hides the evidence
without rotating the secret, which leaves the reader believing a disclosure was handled when only
its trace was removed. Secret shapes are a credential-named key followed by `:` or `=` or filling a
table cell, alone or inside a longer name such as `DATABASE_PASSWORD`, a URL carrying a password
(including the empty-user form a hosted Redis prints), a private-key header, an `Authorization`
header or bearer credential, a JWT and a token by its prefix: GitHub, AWS, Slack, Stripe, Heroku,
OpenAI or Anthropic, Google, GitLab, npm, SendGrid, CircleCI, DigitalOcean and Linear. The generic
URL term forbids `/` in the password, so `registry.npmjs.org:443/@scope/pkg` is not read as
`user:password@`, and the database and queue schemes get a second term that allows it. A table key
cell may wrap its name in backticks or bold, so `` `SECRET_KEY_BASE` `` and `**Password**` are read
as the key; a header row naming a key, such as `| Token | Status |`, blocks too and is cleared like
any other line. A key cell of several words, such as `Rollbar access token`, is not matched, since
matching several words would also catch a summary row whose description mentions a credential; that
form is left to the reading pass.

A blocked hit is not always a credential: code quotes `api_key:` and `password:` keys that hold
none. Show the user each hit and ask which lines are not credentials. Only the user clears a line,
and only one they were shown. Write each cleared line verbatim, trailing spaces included, exactly as
`grep` printed it after its `<file>:<line>:` prefix, one per line, to a file of its own
(`cleared=$(mktemp -t scrub-cleared)`), then run `scrub.sh` again with that path as its argument,
and pass the same path to `post.sh` as `--cleared`. A hit is cleared only when its content, with the
`<file>:<line>:` prefix stripped, matches a cleared line exactly, so any edit to the line, including
an appended value, puts it back in front of the user, and both gates still run every other check. A
substring match would not do: a cleared key with nothing after it would also clear a later line
holding the same key and a real value. The scripts refuse a cleared file with a blank line, since no
hit is blank and such a line means the file was written wrong. Clear only secret-shaped hits; a
path, host, address or username hit is rewritten. If the user does not clear a hit, nothing is
posted.

The earlier claim that a credential reaches this step only by sharing a line with a path was wrong,
and load-bearing while it stood: it was the justification for matching paths only. A bare
token-shaped line matches no path pattern at all. Worse, it created a mutual-assumption gap — the
authoring rule calls this scrub "the backstop at publishing time" while this step assumed
credentials always arrive escorted by a path, so a secret the authoring agent failed to redact had
no second check and both stages had a documented reason not to look.

This section is the **normative definition** of the scrub, and every other command that publishes
these artifacts carries its own copy of it — notably a project's `/ship-it`, which posts
`local-review.md`, `*-DOC-REVIEW.md` and `*-PLAN.md` together and then deletes them, so it publishes
two artifacts this command never writes. Duplicate the check into each publisher; do not
cross-reference this section. A cross-reference between command files reaches nobody — the same
reason the status rule is restated in the prompts Composing the Prompts in SKILL.md lists — and the
agent running `/ship-it` never reads this one. Duplication costs a few lines; a missing scrub costs
a disclosure that cannot be undone once posted.

**Ask before withholding.** Reviewers file two kinds of finding under `## Sensitive Information`:
ones that point at a value, and ones about what gets published that name no value, such as a comment
heading that publishes a file name. Before assembling the comment, list each Sensitive Information
finding to the user with its number, title and Location, and say whether its text quotes a value,
locates one, describes one without locating it or names none, where a value is anything Redacting
Sensitive Evidence lists. A finding that quotes, locates or describes a value is withheld without a
question. That holds for a ✅ Fixed finding or an ℹ️ Observation too: a fixed finding still says
where the value was. A Sensitive Information finding filed elsewhere is classified and withheld the
same way. `post.sh`'s number check finds one by its summary row's Category cell, so an observation
under `## Observations`, whose row names no category, must be moved under `## Sensitive Information`
in the review file first, with the user's agreement. Ask about each finding that names no value with
`AskUserQuestion`:

- **Withhold it** (the default)
- **Post it in full**: its text names no value and points at none

Only the user's answer to this question clears a finding, never the reviewer's category or wording.

**Then withhold every trace of each Sensitive Information finding the user has not cleared**, not
only its section entry. The redaction rule keeps the *value* out of the artifact but it does not
remove the *pointer*, and the pointer is enough: a published finding reading "the connection string
at line 42 of `deploy.md` is live" is a targeting instruction for anyone with repository access, and
it survives in the comment's edit history even if the comment is deleted. Each finding appears in
more places than its section — its Consolidated Summary row names its category, description and
location, its Pre-Merge Checklist item names it again, and the Overall Assessment may describe it —
and any one of them is the pointer. Report the withheld findings to the user in conversation. Then
copy the review file to a path of its own and print it:

```bash
review_file="$(git rev-parse --show-toplevel)/<name>-DOC-REVIEW.md" \
  && post_file=$(mktemp -t doc-review-post) && cp -- "$review_file" "$post_file" \
  && echo "$post_file"
```

Then, in the copy only, delete each withheld finding's section entry, summary row, checklist item,
any assessment sentence describing it and any other mention of its number — a Review History entry,
a cross-reference in another finding or a group's reason line — and any group heading or reason line
that describes it in words: the whole group when it was the only member, otherwise a reworded
heading and reason that no longer describe it. Put a neutral count where the withheld findings
stood:

```text
1 Sensitive Information finding — withheld from this comment; see the local artifact
```

A cleared finding is posted like any other, with its section entry, summary row and checklist item.
When some are cleared and some are not, the section heading stays for the cleared ones and the count
line sits beneath it; when all are cleared, no count line is needed.

Write the numbers the user cleared, one per line, to a file of their own
(`cleared_findings=$(mktemp -t doc-review-cleared-findings)`), and pass it to `post.sh` as
`--cleared-findings`, so it knows which numbers may stay in the comment.

The local artifact keeps every finding, as the count line says; only the copy is posted. Withhold
before the body is assembled, not after — `post.sh` reads the copy whole, so a rule applied to the
finished comment has already published what it meant to withhold — and it refuses the post while any
withheld finding's number is left in a part. A category check alone would miss the checklist item,
which carries the number but no category, and a number check alone misses a group heading or reason
line that describes the finding without it, so reread those against each withheld finding's location
and subject before posting. Pass the printed path to `post.sh` as `--post`, or leave it out when
nothing is withheld, and the cleared-findings file as `--cleared-findings`, or leave it out when the
user cleared none. Each command runs in a fresh shell, so pass every path explicitly rather than
relying on a variable set in an earlier command. After any later rewrite of the review file, remake
the copy and withhold again before posting, since `post.sh` reads the copy, not the review file.
Once every part is posted, it deletes the copy and both list files. This is the one finding category
where succeeding at the job is what creates the exposure: the command is most dangerous exactly when
it works.

Then post the comment. **The gates live inside `post.sh`, not before it.** When the gate and the
post were separate fenced blocks, an agent that scrolled to the executable block, the normal way a
skill file gets used, could publish without ever running the scrub, and nothing signaled that a step
had been skipped. A control an agent can skip by copying the obvious block is not a control, so the
re-verification and the post share one script and one exit path, and there is no post step to run
without them:

```bash
'<skill dir>/scripts/post.sh' --review "$(git rev-parse --show-toplevel)/<name>-DOC-REVIEW.md" \
  --repo <OWNER/NAME> --status '<status summary>' --stats '<stats line>' \
  --post <withheld copy> --cleared <cleared lines> --cleared-findings <cleared numbers>
```

Leave out each of the last three that does not apply. `--repo` names the repository the pull request
is in. `--status` fills the heading's status slot and `--stats` the bold stats line beneath it, both
as the stats-line rule at the end of this section describes; the script refuses either while it
still holds a bracketed placeholder. Each gate refuses with a message that says what to fix and
`do not post`: report it to the user and post nothing by another route.

The comment is scrubbed twice, and the second pass is the one that matters, run over every part
before any is posted. The first covers the artifacts; the posted body is those *plus* everything
added at assembly — and the heading interpolates the review file's title, which names a document
that for one outside the repository arrived as an absolute path. Document Header (`review-file.md`)
requires a name there, never a path, but that line is the **first visible line of the public
comment**, so re-scan the assembled file rather than trusting the rule was followed: the section's
own principle is to check at the step that publishes, and checking only the source is one step short
of it. Taking the title from the file rather than from the scope also keeps a multi-document
review's heading to one line, `N documents on <branch>`, instead of a list of paths. The heading
names the review file's base name in backticks, in the slot `` (`<base name>`) — ``, which is how
`/ship-it` finds an earlier comment for the same file and updates it instead of posting a second
one.

`post.sh` reads the body into a variable and asserts it before wrapping it. Inside a group, a
failing `cat` sends its error to stderr and the group's exit status is the trailing `echo`'s, so an
unreadable `$post_file` still produces a well-formed comment with a complete `<details>` scaffold,
an empty body and a heading confidently claiming N findings — posted with no failure signal in
stdout or exit status. Checking the finished file with `[ -s ]` does not help, because the scaffold
is non-empty; the body itself is what has to be non-empty.

It works in `mktemp -d`, not a fixed path. `> /tmp/pr-comment.md` follows a pre-existing symlink and
clobbers its target, so a stale or hostile link redirects the write and `--body-file` posts whatever
the target holds. Under the usual umask the file is created world-readable, nothing removes it and
two concurrent reviews race on one name — so if the scrub failed, the unredacted body persists under
a guessable name after the artifact it came from was deleted, which is the one copy the threat model
assumes is gone. `mktemp -d` creates a private 0700 directory at an unpredictable path; the `trap`
removes it and every part inside it on exit.

**Split a long review into several comments rather than truncating it.** GitHub rejects a comment
body over 65,536 characters, and a thorough review of a long document can pass that. `post.sh` cuts
the body at `##` and `###` headings, filling each comment up to 60,000 bytes — under the character
limit whatever the text, with room for the wrapper — so a finding is never split across two comments
and a fenced block inside one is never cut open. Each part gets its own `<details>` wrapper labeled
"part 2 of 3"; only the first carries the heading and the stats line. Every part passes Gate 2
before the first is posted, so a hit in part three cannot leave parts one and two published with
nothing to show for it. A single section longer than the limit stops the post: cut it by hand at a
paragraph boundary outside any fence, rather than letting the script split it mid-fence. If `gh`
fails partway through, the message names the part it stopped at, since the parts before it are
already public.

**Resolve the destination before posting.** `gh pr comment` with no argument infers its pull request
from the branch's upstream, and in a fork-and-upstream layout that can be the public upstream rather
than the private fork — a different audience from the same command. `post.sh` names the repository
with `--repo`, which `gh pr view` accepts only with the branch named, resolves the pull request's
URL once, prints it and passes it to every `gh pr comment`, so the target is visible before anything
is sent and cannot change between parts.

The stats line, `--stats`, should include the total finding count and a breakdown that names every
bucket separately (e.g. "24 findings — 12 fixed, 2 deferred, 2 ignored, 8 observations"), omitting
any bucket that is empty. The buckets are fixed, refuted, deferred, ignored and observations. The
open-findings check means a posted review has no ❓ finding, so there is no open bucket. A finding a
handed-back check refuted is struck ✅ Refuted and counted as refuted, never as fixed: no edit was
made, the reviewer was wrong. Deferred and ignored findings are off the pre-merge path but they are
not resolved, so they never fold into the fixed count. Reserve "all clear" for a review in which
every actionable finding is ✅, fixed or refuted: "24 findings — 14 fixed, 2 refuted, 8 observations
— all clear". That holds for every severity and for decisions alike: a 🟢 Low ⏸️ Deferred or 🚫
Ignored bars "all clear" as surely as a 🔴 Critical does.
