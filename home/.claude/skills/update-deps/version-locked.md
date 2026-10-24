# Update Dependencies

## Version-Locked Packages

Some packages must be updated in tandem because their versions must match across ecosystems. After
updating, verify these constraints and revert any that break them. Each `yarn up` here takes one of
the two prefixes from [Step 4](javascript.md#step-4-update-javascript-dependencies): the restore
prefix when the target is the version the repository already commits, and the gated prefix
otherwise. Make these changes before Step 4's re-resolution — inside Step 4's single restore call
when the prefix is the restore prefix — so `yarn up -R '*'` and the `yarn why` check see them.

### Playwright

The `playwright` npm package and the `playwright-ruby-client` gem must match **exactly**, patch
included. The gem supports one driver version, which it names in
`Playwright::COMPATIBLE_PLAYWRIGHT_VERSION`, and the npm package must equal it. The gem is often not
in the `Gemfile` at all — it can arrive through `capybara-playwright-driver` — so read the version
from the installed gem rather than from a manifest. The npm package usually releases first, and a
newer npm **patch** is as much a mismatch as a newer minor.

After [Step 3](SKILL.md#step-3-update-ruby-dependencies) and `yarn up '*'` have moved both sides,
compare them as installed:

```bash
bundle exec ruby -e 'require "playwright"; puts Playwright::COMPATIBLE_PLAYWRIGHT_VERSION'
npx playwright --version   # prints "Version <x.y.z>"
```

1. If they differ, the gem's value wins. Move the npm side to it, which writes an exact pin:

   ```bash
   YARN_ENABLE_SCRIPTS=false YARN_NPM_MINIMAL_AGE_GATE=3d yarn up playwright@<compatible-version>
   ```

   That is the gated prefix, for a version the repository does not yet commit. When the gem did not
   move and `<compatible-version>` is the version already committed, use the restore prefix instead,
   in Step 4's restore call.

   Do **not** hold back the Ruby gem to match an older npm package — only the npm side moves.

2. If the `Gemfile` declares the gem (`grep -n playwright-ruby-client Gemfile`), update its `~>`
   constraint to the new version. If it does not, there is nothing to edit there.

3. Run the repository's own check, if it has one:

   ```bash
   grep -rl COMPATIBLE_PLAYWRIGHT_VERSION spec
   bin/rspec <each file it lists>
   ```

   With no such spec, rerun the comparison above; it is the check.

4. Before running any system spec locally, install the browser build the new version expects, with
   the repository's own script if it has one (for example `yarn playwright:install`). Nothing
   installs it when the npm version changes, and install scripts are off during this command. A CI
   image that bundles its own browsers is unaffected.

### Cocooned

The `@notus.sh/cocooned` npm package and the `cocooned` gem must have **matching versions**. The
maintainer typically releases both sides simultaneously — mismatches are rare.

When a new version is available:

1. Both should update together. If for some reason only one side updated, revert it to match the
   other:

   ```bash
   # If the npm package got ahead (writes an exact pin). The gated prefix, unless <gem-version> is
   # the version already committed — then the restore prefix, in Step 4's restore call:
   YARN_ENABLE_SCRIPTS=false YARN_NPM_MINIMAL_AGE_GATE=3d yarn up @notus.sh/cocooned@<gem-version>

   # If the gem got ahead, first set the cocooned constraint in Gemfile to <npm-version> exactly:
   # bundle update never moves a gem below what the Gemfile already allows
   bundle update cocooned --conservative
   ```

2. Update the version constraints in both manifest files:
   - `Gemfile`: while the sides differ, keep the exact version from item 1; once they match, use a
     `~>` constraint for `cocooned`
   - `package.json`: while the sides differ, keep the exact pin from item 1; once they match,
     restore the project's usual operator (`^` or `~`) for `@notus.sh/cocooned`. A range must not
     stand in for a hold: Step 4's re-resolution sends it to the newest release it admits, which is
     the version the hold blocks

### Rails JavaScript Packages

The `@rails/*` npm packages the app uses (`@rails/actioncable`, `@rails/actiontext`,
`@rails/activestorage` and the like) track the `rails` gem. Rails encodes the gem's version on npm
with the patch multiplied by 100 and any fourth segment added to it: gem 8.1.4 is npm `8.1.400`, and
the security release 8.1.2.1 is npm `8.1.201`. A prerelease gem does not follow that rule: gem
`8.1.0.beta1` is npm `8.1.0-beta1`, so for one, read the matching npm version from
`npm view @rails/actioncable versions --json` rather than deriving it. Their `latest` dist-tag is
sometimes left behind on an older release line, and `yarn up '*'` follows it down — walking an app
on Rails 8.1 back to `^7.2.302` with no warning. After Step 4's restore, check each against the gem:

```bash
bundle exec rails --version
grep -n '"@rails/' package.json
```

Restore any whose range no longer starts at the gem's npm version with
`yarn up '@rails/<name>@^<npm-version>'`, using the matching prefix: the restore prefix when that
version is already committed, and the gated prefix when it is not — after a Rails bump in Step 3,
for one. When a Rails upgrade ships in the same PR
([Step 2](SKILL.md#step-2-create-the-feature-branch)), these bumps belong in the upgrade commit, not
the dependency commit. If the upgrade commit does not already carry them, stop and ask the user
whether to amend it; never rewrite it on your own.
