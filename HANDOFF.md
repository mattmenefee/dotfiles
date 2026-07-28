# Neovim Migration — Session Handoff

Snapshot of where the Neovim migration sits at the end of this working
session, plus everything we tried on the open colorscheme issue. Read
`PLAN.md` for the broader phased migration roadmap.

## Branch / PR state

- Branch: `neovim`
- Draft PR: [#74](https://github.com/mattmenefee/dotfiles/pull/74)
- Latest commit: `9b63f25` ("Cut over from MacVim to Neovim (Phase 1)")
- All 7 phase issues filed: [#67](https://github.com/mattmenefee/dotfiles/issues/67)–[#73](https://github.com/mattmenefee/dotfiles/issues/73) with blocked-by relationships
- Closes [#64](https://github.com/mattmenefee/dotfiles/issues/64) (undodir workaround) via Phase 1

## What's done in Phase 1

- Moved `home/.vimrc` → `home/.config/nvim/init.vim` with runtimepath shim so Vundle still finds `~/.vim/bundle/`
- Dropped the `undodir` block (Neovim's default is XDG-compliant)
- Dropped `set pastetoggle=<F2>` (removed in Neovim 0.10)
- Dropped `ervandew/supertab` plugin (broken in Neovim 0.12 — `E129`/`E475`)
- Dropped `flazz/vim-colorschemes` plugin (abandoned 6 years; no Neovim support)
- Switched `colorscheme railscasts` → `colorscheme new-railscasts` (from already-installed `carakan/new-railscasts-theme`)
- Enabled `set termguicolors` (required for new-railscasts; gui-defined scheme)
- Updated `vim` alias → `nvim`, bootstrap script, README, Brewfile

## Manual cleanup not yet done on local machine

- [ ] `rm -rf ~/.vim/undo` — directory from old workaround
- [ ] `brew uninstall macvim` — confirm `vim` alias works first
- [ ] `nvim +PluginClean! +qall` — removes `~/.vim/bundle/vim-colorschemes` from disk
- [ ] `homesick link dotfiles` — verify no `.un~` symlinks appear (validates [#64](https://github.com/mattmenefee/dotfiles/issues/64))

## Open issue: colorscheme still not quite right

The colorscheme situation has been the main friction point and isn't
fully resolved. User has not confirmed `new-railscasts` is acceptable as
of session end.

### Timeline of what we tried

1. **Starting state:** `colorscheme railscasts` loading
   `flazz/vim-colorschemes/colors/railscasts.vim`. User reported "color
   theme is not loading."

2. **Fix attempt 1: Added `set termguicolors`.** Diagnosed that the
   colorscheme *was* loading but rendering with cterm (256-color)
   fallback. Enabled truecolor. User said colors still looked wrong vs
   MacVim.

3. **Reverted `termguicolors`.** Reasoned MacVim was also using cterm
   (no `termguicolors` was ever set there), so matching its appearance
   means matching its rendering path. Restart of nvim showed identical
   appearance to step 2 — meaning `termguicolors` was not the operative
   variable for what user was seeing.

4. **Compared `README.md` side-by-side.** Key visual differences:
   - **Markdown list markers** (`*`, `1.`): orange in MacVim, green in Neovim
   - **Markdown link text** (`[Development]`): orange in MacVim, red in Neovim
   - **Spellcheck**: only `CIRM` flagged in MacVim; many words
     (`Sidekiq`, `Redis`, `AppSignal`, `Autoprefixer`, `stylesheets`)
     flagged in Neovim

5. **Root cause identified.** Neovim loads *two* markdown syntax files
   (verified via `scriptnames`):
   - `~/.vim/bundle/Markdown/syntax/markdown.vim` (the vim-scripts
     `Plugin 'Markdown'`) — uses `mkd*` group names
   - `/opt/homebrew/.../share/nvim/runtime/syntax/markdown.vim`
     (Neovim's built-in) — uses `markdown*` group names, loads
     **after** and overrides
   MacVim's built-in markdown.vim is older and doesn't override the
   plugin, so MacVim sees the `mkd*` groups; Neovim sees the
   `markdown*` groups. Same colorscheme + different group names =
   different colors.

   The vim-scripts plugin's links (from
   `~/.vim/bundle/Markdown/syntax/markdown.vim`):

   ```
   mkdListItem  → Identifier   (orange in railscasts)
   mkdLink      → htmlLink
   mkdCode      → String       (green)
   mkdDelimiter → Delimiter
   ```

   Verified in MacVim: `:hi markdownListMarker` returned
   `E411: Highlight group not found` — confirming MacVim never sees
   that group, only the legacy `mkd*` ones.

6. **Discovered `flazz/vim-colorschemes` is abandoned** and has no
   dedicated markdown styling (zero `markdown`/`mkd` references in its
   148-line `railscasts.vim`). `carakan/new-railscasts-theme`
   (already installed, but never used because the user's config said
   `colorscheme railscasts` and that plugin ships
   `new-railscasts.vim`) has 293 lines of definitions including
   `markdownError → SpellLocal`, `mkdHeading`, `mkdLink`.

7. **Current attempt (in PR):** switched to
   `colorscheme new-railscasts` + re-enabled `set termguicolors`
   (carakan's scheme is gui-only: 215 `gui*` definitions, only 11
   `cterm*`). Result not yet visually confirmed by user.

### If new-railscasts is still wrong

Options to try next, in rough order of effort:

1. **Override specific markdown highlight groups** in `init.vim`:
   ```vim
   hi link markdownListMarker        Identifier
   hi link markdownOrderedListMarker Identifier
   hi link markdownLinkText          htmlLink
   hi link markdownUrl               htmlString
   hi link markdownLinkDelimiter     Delimiter
   hi link markdownLinkTextDelimiter Delimiter
   ```
   This would mimic the legacy `mkd*` → parent group mappings.

2. **Disable the vim-scripts `Plugin 'Markdown'`.** It's not actually
   doing anything in Neovim (the built-in overrides it). Removing it
   reduces noise but won't change appearance.

3. **Force the vim-scripts plugin to win** by adding
   `~/.vim/after/syntax/markdown.vim` that re-applies its highlight
   links after Neovim's built-in runs. Hacky but works.

4. **Disable `@Spell` in markdown list items** to stop flagging
   `Sidekiq`/etc.:
   ```vim
   syntax cluster markdownNoSpell contains=markdownListItem
   ```

5. **Try a different colorscheme entirely** (gruvbox, tokyonight,
   kanagawa, catppuccin — all maintained, all gui-first with good
   cterm fallbacks).

6. **Defer to Phase 6 / [#72](https://github.com/mattmenefee/dotfiles/issues/72)** (treesitter). Treesitter parses content
   rather than relying on regex tokens, and uses a standardized set of
   highlight groups across all filetypes — this whole class of "old
   plugin vs built-in syntax file disagrees on which group to apply"
   problem disappears.

### Diagnostic commands cheatsheet

In **either** editor:

```vim
:colorscheme                                      " current scheme name
:hi <GroupName>                                   " show colors for a highlight group
:scriptnames                                      " every loaded vim/lua file in order
:echo synIDattr(synID(line('.'), col('.'), 0), 'name')  " highlight group at cursor
```

In Neovim specifically:

```vim
:Inspect                                          " show all highlights/captures at cursor (nvim 0.9+)
:checkhealth                                      " comprehensive health check
```

## Files of interest

- `/Users/matt/.homesick/repos/dotfiles/home/.config/nvim/init.vim` — main config
- `/Users/matt/.homesick/repos/dotfiles/PLAN.md` — phased migration plan
- `/Users/matt/.vim/bundle/Markdown/syntax/markdown.vim` — legacy plugin we identified as conflicting (line 89–105 has the `hi link` definitions)
- `/Users/matt/.vim/bundle/new-railscasts-theme/colors/new-railscasts.vim` — currently active colorscheme
- `/opt/homebrew/Cellar/neovim/0.12.2/share/nvim/runtime/syntax/markdown.vim` — Neovim's built-in markdown syntax (the override)

## Resuming

When picking this back up, easiest first move is to restart `nvim`,
open `README.md`, and assess the current state with `new-railscasts`
active. If the visual is acceptable: mark [#67](https://github.com/mattmenefee/dotfiles/issues/67) done, un-draft
[PR #74](https://github.com/mattmenefee/dotfiles/pull/74), do the manual cleanup checklist above. If not: pick one
of the six fallback options in the section above.
