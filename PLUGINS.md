# Vim Plugins Documentation

This document lists all the Vim plugins defined in `home/.vimrc` and their purposes.

## Plugin Manager
- **VundleVim/Vundle.vim** - Plugin manager for Vim, manages installation and updating of other plugins

## Text Manipulation & Formatting
- **Align** - Aligns text based on patterns (e.g., aligning = signs in variable assignments)
- **surround.vim** - Provides mappings to easily delete, change and add surroundings (parentheses, brackets, quotes, etc.)
- **Tabular** - Text filtering and alignment plugin
- **textobj-rubyblock** - Text objects for Ruby blocks (def/end, class/end, etc.)
- **textobj-user** - Create your own text objects easily
- **DrawIt** - ASCII drawing plugin for creating diagrams and charts
- **Rename** - Rename files from within Vim
- **tpope/vim-endwise** - Automatically adds 'end' statements for Ruby, Vim script, etc.
- **Raimondi/delimitMate** - Automatically closes quotes, parenthesis, brackets, etc.
- **tpope/vim-repeat** - Enables repeating supported plugin maps with "."
- **tpope/vim-abolish** - Search and replace with case-sensitive variants

## File & Directory Management
- **DirDiff.vim** - Directory diff tool for comparing directories
- **scrooloose/nerdtree** - Tree explorer plugin for navigating the filesystem
- **bogado/file-line** - Opens files at specific line numbers (e.g., `vim file.txt:42`)

## Git Integration
- **fugitive.vim** - Git wrapper for Vim, provides Git commands from within Vim
- **airblade/vim-gitgutter** - Shows git diff markers in the sign column

## Language Support & Syntax
- **jQuery** - jQuery syntax highlighting and snippets
- **pangloss/vim-javascript** - JavaScript syntax highlighting and indentation
- **jelera/vim-javascript-syntax** - Enhanced JavaScript syntax highlighting
- **vim-coffee-script** - CoffeeScript support for Vim
- **tpope/vim-haml** - Haml, Sass, and SCSS syntax highlighting
- **mtscout6/vim-cjsx** - CJSX (CoffeeScript JSX) syntax highlighting
- **mxw/vim-jsx** - JSX syntax highlighting and indenting
- **hashivim/vim-terraform** - Terraform syntax highlighting and formatting

## Ruby & Rails Support
- **matchit.zip** - Extended % matching for HTML, LaTeX, and other languages
- **ruby-matchit** - Ruby-specific % matching
- **tpope/vim-rails** - Ruby on Rails power tools for Vim
- **thoughtbot/vim-rspec** - RSpec runner for Vim
- **rainerborene/vim-reek** - Reek (Ruby code smell detector) integration

## Code Quality & Linting
- **scrooloose/syntastic** - Syntax checking plugin that runs files through external syntax checkers
- **myint/syntastic-extras** - Additional checkers for Syntastic

## Productivity & Navigation
- **ervandew/supertab** - Perform all your vim insert mode completions with Tab
- **scrooloose/nerdcommenter** - Commenting plugin with support for multiple languages
- **nathanaelkane/vim-indent-guides** - Visually displays indent levels
- **rking/ag.vim** - The Silver Searcher integration for fast text searching
- **gabesoft/vim-ags** - Silver Searcher plugin with interactive interface
- **tpope/vim-dispatch** - Asynchronous build and test dispatcher

## Visual & Themes
- **Markdown** - Markdown syntax highlighting
- **flazz/vim-colorschemes** - Collection of color schemes
- **carakan/new-railscasts-theme** - Railscasts color theme
- **ap/vim-css-color** - Highlights CSS colors with their actual colors

## System Integration
- **tpope/vim-eunuch** - Helpers for UNIX shell commands (e.g., :Remove, :Move, :Chmod)

## Notes
- Many plugins are from Tim Pope (tpope), a well-known Vim plugin author
- The configuration is heavily Ruby/Rails focused with RSpec testing support
- Includes modern JavaScript/React development tools (JSX, CoffeeScript)
- Emphasizes code quality with linting and syntax checking
- Provides comprehensive Git integration and file management tools