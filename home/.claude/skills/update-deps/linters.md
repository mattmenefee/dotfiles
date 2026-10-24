# Update Dependencies: Linter Updates

## Step 8: Handle RuboCop Updates

Check the `gem_update` output or `git diff Gemfile.lock` for changes to `rubocop` or any `rubocop-*`
gem. Which of them changed decides how much of this step to run.

If `rubocop` itself was updated, whether or not any plugin was too:

1. Run `bin/rubocop -A` to auto-fix any new violations.
2. Review the output for violations that could not be auto-fixed and manually fix them.
3. After **all** violations are resolved, regenerate `.rubocop_todo.yml` (if it exists). Blank it
   first: `.rubocop.yml` inherits from the todo, so regenerating it in place treats every offense it
   excludes as already handled and writes a todo with no rules — un-grandfathering them all, so a
   plain `bin/rubocop` fails even though `bin/rubocop -A` just reported clean:

   ```bash
   printf '# Placeholder\n' > .rubocop_todo.yml
   bin/rubocop --auto-gen-config --auto-gen-only-exclude --exclude-limit 1000
   bin/rubocop   # must still report no offenses
   ```

   The diff should be the header (version and timestamp) plus any real shrinkage. If `bin/rubocop`
   reports offenses, the regeneration lost exclusions: restore the file with
   `git restore .rubocop_todo.yml` and investigate before going on.
4. Note the RuboCop fixes for inclusion in the commit message body (see Step 10).

If only `rubocop-*` plugins were updated (for example `rubocop-rails`), run items 1, 2 and 4
but **not** item 3. The `.rubocop_todo.yml` header records only the core RuboCop version, so
regenerating it after a plugin-only bump changes nothing but the timestamp. If a regeneration
happened anyway, restore the file rather than committing the timestamp-only diff:

```bash
git restore --source=HEAD --staged --worktree .rubocop_todo.yml
```

A clean `bin/rubocop -A` run exits 0 and reports "no offenses detected" or lists only auto-corrected
offenses. Any remaining offenses must be fixed manually before proceeding.

## Step 9: Handle haml-lint Updates

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
