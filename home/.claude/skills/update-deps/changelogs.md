# Update Dependencies

## Known Changelog Quirks

### sass-embedded

The `sass-embedded` Ruby gem wraps the Dart Sass compiler but does not maintain its own changelog or
GitHub releases. Its version number tracks the compiler, so use the Dart Sass changelog at
[sass/dart-sass](https://github.com/sass/dart-sass/blob/main/CHANGELOG.md) and anchor to the
matching version heading (e.g. `#11030` for 1.103.0).

Do **not** treat the sister host
[sass/embedded-host-node](https://github.com/sass/embedded-host-node/blob/main/CHANGELOG.md) as a
lockstep source. It is a separate release train whose changelog can lag the compiler by one or more
versions, so the entry for the version being shipped may simply not exist there yet. Reach for it
only for host-specific notes that the Dart Sass changelog does not cover.

### Bundler

Since 4.0.0, Bundler and RubyGems share version numbers and release tags. Link the joint release
page, `https://github.com/ruby/rubygems/releases/tag/v<version>`. The notes are also in the root
`CHANGELOG.md` of `ruby/rubygems`, under each version's `### Bundler` subsection.
`CHANGELOG-bundler.md` no longer exists on `master`; pre-4.0 history is in
`doc/CHANGELOG-bundler-2.x.md`.

### google-protobuf

The gem's `4.<x>.<y>` maps to the protobuf release tag `v<x>.<y>`: 4.35.0 is
`https://github.com/protocolbuffers/protobuf/releases/tag/v35.0`.

### Gems with no changelog

`playwright-ruby-client` and `capybara-playwright-driver` publish no changelog and no GitHub
releases, so link [Diffend](https://my.diffend.io) as Step 10 describes.
`active_storage_validations` is not one of them: it keeps `CHANGES.md` and publishes releases.

### Changelogs without usable anchors

- **`msgpack`** keeps a plain-text `ChangeLog` with no headings to anchor, so link the file itself
- **`ssrf_filter`** puts the release date in each heading, so its slugs carry the date as well as
  the version — 1.6.0 slugs to the form `#160-982026`. Read the slug from the rendered page rather
  than deriving it

### Changelogs on another branch or repository

- **`appsignal`** 4.10.x patch releases are documented only on the `4.x-stable` branch, not `main`
- **`cancancan`** has moved to `coorasse/cancancan`. The old URLs redirect, but link the new home

### Tool and image pins

- **`jq`** tags its releases `jq-1.8.2`, so a `^v?[0-9]` tag filter returns nothing. Match the `jq-`
  prefix
- **Elasticsearch**'s GitHub release page is only a pointer. Link the real notes on `elastic.co`
