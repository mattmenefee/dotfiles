# Vim Configuration Commands Documentation

This document explains the purpose of every non-commented line in `home/.vimrc`.

## Basic Vim Configuration

**Line 5:** `set nocompatible`
- Disables Vi compatibility mode, enabling enhanced Vim features

**Line 6:** `filetype off`
- Temporarily disables filetype detection (required for Vundle plugin loading)

## Vundle Plugin Manager Setup

**Line 9:** `set rtp+=~/.vim/bundle/Vundle.vim`
- Adds Vundle directory to Vim's runtime path

**Line 10:** `call vundle#begin()`
- Initializes Vundle plugin manager

**Lines 13-56:** `Plugin 'PluginName'`
- Declares 44 plugins for installation/management by Vundle

**Line 59:** `call vundle#end()`
- Finalizes Vundle configuration

**Line 60:** `filetype plugin indent on`
- Re-enables filetype detection with plugin and indentation support

## Leader Key Configuration

**Line 75:** `let mapleader = " "`
- Sets spacebar as the leader key for custom key mappings

## Editor Behavior Settings

**Line 77:** `set backspace=2`
- Allows backspace to delete across line breaks, tabs, and auto-indents

**Line 78:** `set nocompatible`
- Duplicate of line 5 - uses Vim settings rather than Vi settings

**Line 79:** `set nobackup`
- Disables creation of backup files

**Line 80:** `set nowritebackup`
- Disables backup creation before overwriting files

**Line 81:** `set noswapfile`
- Disables swap file creation

**Line 82:** `set history=2000`
- Stores last 2000 commands in command history

**Line 83:** `set ruler`
- Shows cursor position (line, column) in status line

**Line 84:** `set showcmd`
- Displays incomplete commands in status line

**Line 85:** `set laststatus=2`
- Always displays status line (even with single window)

**Line 86:** `set autowrite`
- Automatically saves file before running commands

**Line 87:** `set autoindent`
- Maintains indentation level from previous line

**Line 88:** `set autoread`
- Automatically reloads files changed outside Vim

**Line 89:** `set autowrite`
- Duplicate of line 86 - auto-saves before commands

**Line 90:** `set confirm`
- Prompts for confirmation before destructive operations

**Line 91:** `set pastetoggle=<F2>`
- F2 key toggles paste mode (prevents auto-indenting when pasting)

**Line 92:** `set shortmess=atI`
- Shortens various Vim messages (abbreviate, truncate, no intro message)

**Line 93:** `set visualbell`
- Uses visual bell instead of audible beeping

**Line 97:** `set undofile`
- Persists undo history across Vim sessions

## Indentation Settings

**Line 100:** `set tabstop=2`
- Sets tab character display width to 2 spaces

**Line 101:** `set shiftwidth=2`
- Sets indentation width to 2 spaces

**Line 102:** `set shiftround`
- Rounds indentation to nearest multiple of shiftwidth

**Line 103:** `set expandtab`
- Converts tab characters to spaces

**Line 104:** `set softtabstop=2`
- Makes tab key insert 2 spaces in insert mode

## Text Formatting

**Line 107:** `set textwidth=100`
- Automatically wraps text at 100 characters

**Line 109:** `set wrapmargin=2`
- Wraps text 2 columns from right edge of window

## Search Configuration

**Line 112:** `set incsearch`
- Shows search matches as you type (incremental search)

**Line 114:** `set hlsearch`
- Highlights all search matches in the file

**Line 116:** `set ignorecase`
- Makes searches case-insensitive by default

**Line 118:** `set smartcase`
- Case-sensitive search when pattern contains uppercase letters

**Line 120:** `set scrolloff=7`
- Keeps 7 lines visible above/below cursor when scrolling

## Display Options

**Line 123:** `set showmatch`
- Highlights matching brackets/parentheses when cursor is on them

**Line 124:** `set sidescroll=8`
- Scrolls horizontally by 8 characters at a time

**Line 125:** `set switchbuf=useopen`
- Uses existing window when switching to buffer

**Line 126:** `set virtualedit=block`
- Allows cursor positioning beyond end of line in visual block mode

**Line 127:** `set number`
- Shows line numbers

**Line 128:** `set list`
- Shows invisible characters (tabs, trailing spaces)

## Syntax and Appearance

**Line 130:** `syntax enable`
- Enables syntax highlighting engine

**Line 131:** `syntax on`
- Turns on syntax highlighting

**Line 133:** `filetype plugin indent on`
- Enables filetype-specific plugins and indentation

**Line 135:** `colorscheme railscasts`
- Sets the Railscasts color scheme

## Key Mappings

**Line 137:** `map QQ :q<CR>`
- QQ in normal mode quits Vim

**Line 138:** `map WW :wall<CR>`
- WW in normal mode saves all modified files

**Line 139:** `map NN :next<CR>`
- NN in normal mode goes to next file in argument list

**Line 140:** `map PP :previous<CR>`
- PP in normal mode goes to previous file in argument list

**Line 141:** `map + <C-A>`
- + key increments number under cursor

**Line 142:** `map - <C-X>`
- - key decrements number under cursor

**Line 143:** `cmap w!! w !sudo tee %`
- w!! command saves file with sudo privileges

**Line 144:** `command T tabedit README`
- T command opens README file in new tab

## Insert Mode Mappings

**Line 146:** `inoremap <C-F> <C-X><C-F>`
- Ctrl+F triggers filename completion in insert mode

**Line 147:** `inoremap <C-L> <C-X><C-L>`
- Ctrl+L triggers whole line completion in insert mode

**Line 150:** `inoremap jj <esc>`
- jj in insert mode switches to normal mode

**Line 151:** `inoremap jk <esc>`
- jk in insert mode switches to normal mode

## Auto Commands

**Line 154:** `autocmd BufEnter *.md exe 'noremap <F5> :!open -a "Google Chrome.app" %:p<CR>'`
- F5 opens Markdown files in Google Chrome when editing .md files

## Split Window Navigation

**Line 158:** `nnoremap <C-J> <C-W><C-J>`
- Ctrl+J moves to split window below

**Line 159:** `nnoremap <C-K> <C-W><C-K>`
- Ctrl+K moves to split window above

**Line 160:** `nnoremap <C-L> <C-W><C-L>`
- Ctrl+L moves to split window right

**Line 161:** `nnoremap <C-H> <C-W><C-H>`
- Ctrl+H moves to split window left

## Split Window Behavior

**Line 164:** `set splitbelow`
- Opens new horizontal splits below current window

**Line 165:** `set splitright`
- Opens new vertical splits to the right of current window

## Arrow Key Discipline

**Line 168:** `nnoremap <Left> :echoe "Use h"<CR>`
- Left arrow key shows reminder to use h instead

**Line 169:** `nnoremap <Right> :echoe "Use l"<CR>`
- Right arrow key shows reminder to use l instead

**Line 170:** `nnoremap <Up> :echoe "Use k"<CR>`
- Up arrow key shows reminder to use k instead

**Line 171:** `nnoremap <Down> :echoe "Use j"<CR>`
- Down arrow key shows reminder to use j instead

## HTML/Web Development

**Line 174:** `let g:html_indent_tags = 'li\|p'`
- Treats `<li>` and `<p>` tags as block elements for indentation

## Whitespace Management

**Line 177:** `set list listchars=tab:»·,trail:·`
- Shows tabs as »· and trailing spaces as ·

**Line 179:** `autocmd BufWritePre * :%s/\s\+$//e`
- Automatically removes trailing whitespace when saving files

## File Type Associations

**Line 182:** `au BufRead,BufNewFile *.axlsx set filetype=ruby`
- Treats .axlsx files as Ruby files

**Line 185:** `au BufRead,BufNewFile *.md set filetype=markdown`
- Treats .md files as Markdown

**Line 188:** `au BufRead,BufNewFile *.md setlocal spell`
- Enables spell checking for Markdown files

**Line 191:** `au BufRead,BufNewFile *.md setlocal textwidth=80`
- Sets text width to 80 characters for Markdown files

**Line 194:** `au BufRead,BufNewFile *.yml.enc* set filetype=yaml`
- Treats encrypted Rails credential files as YAML

**Line 197:** `au BufRead,BufNewFile *.py set filetype=python`
- Treats .py files as Python

**Line 200:** `au BufRead,BufNewFile Dockerfile* set filetype=dockerfile`
- Treats files starting with "Dockerfile" as Dockerfile format

**Line 203:** `au BufRead,BufNewFile *.service.erb set filetype=ruby.ini`
- Treats Capistrano service templates as Ruby/INI hybrid

## Syntastic Linting Configuration

**Line 206:** `let g:syntastic_scss_checkers = ['scss_lint']`
- Uses scss_lint for SCSS syntax checking

**Line 207:** `autocmd BufRead,BufNewFile */modus/* let g:syntastic_scss_checkers=[]`
- Disables SCSS linting for files in modus directory

**Line 210:** `let g:syntastic_haml_checkers = ['haml_lint']`
- Uses haml_lint for HAML syntax checking

**Line 213:** `let g:syntastic_javascript_checkers = ['eslint']`
- Uses ESLint for JavaScript syntax checking

**Line 216:** `let g:syntastic_gitcommit_checkers = ['language_check']`
- Uses language_check for git commit message linting

**Line 219:** `let g:syntastic_python_python_exec = 'python3'`
- Uses Python 3 for Python syntax checking

**Line 220:** `let g:syntastic_python_checkers = ['python']`
- Uses built-in Python checker for syntax checking

**Line 223:** `let g:syntastic_yaml_checkers = ['pyyaml']`
- Uses PyYAML for YAML syntax checking

## Language-Specific Settings

**Line 226:** `let coffee_lint_options = '-f config/coffeelint.json'`
- Sets CoffeeLint to use config/coffeelint.json configuration file

**Line 229:** `let g:jsx_ext_required = 0`
- Allows JSX syntax in .js files (not just .jsx)

**Line 232:** `let NERDTreeShowHidden = 1`
- Shows hidden files in NERDTree file explorer

**Line 236:** `autocmd Filetype gitcommit setlocal spell textwidth=72`
- Enables spell check and 72-character limit for git commit messages

## RSpec Testing Integration

**Line 239:** `let g:rspec_runner = "os_x_iterm"`
- Sets RSpec to run in macOS iTerm

**Line 241:** `let g:rspec_command = "Dispatch bin/rspec {spec}"`
- Uses vim-dispatch to run RSpec tests

**Line 242:** `map <Leader>t :call RunCurrentSpecFile()<CR>`
- Leader+t runs RSpec tests for current file

**Line 243:** `map <Leader>s :call RunNearestSpec()<CR>`
- Leader+s runs RSpec test nearest to cursor

**Line 244:** `map <Leader>l :call RunLastSpec()<CR>`
- Leader+l re-runs last RSpec test

**Line 245:** `map <Leader>a :call RunAllSpecs()<CR>`
- Leader+a runs all RSpec tests

## System Integration

**Line 248:** `set clipboard=unnamed`
- Uses system clipboard for yank/paste operations

**Line 251:** `autocmd StdinReadPre * let s:std_in=1`
- Detects when Vim is opened with stdin input

**Line 252:** `autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif`
- Opens NERDTree automatically when Vim starts with no files

**Line 255:** `cabbrev h vertical help`
- Opens help in vertical split instead of horizontal

## Custom Utility Mappings

**Line 260:** `vmap gl :<C-U>!git blame <C-R>=expand("%:p") <CR> \| sed -n <C-R>=line("'<") <CR>,<C-R>=line("'>") <CR>p <CR>`
- gl in visual mode shows git blame for selected lines

**Line 262:** `map <Leader><Space> :nohlsearch<CR>`
- Leader+Space clears search highlighting

**Line 263:** `map <Leader>, :%s/\s\+$//<CR>`
- Leader+comma removes trailing whitespace from entire file

**Line 265:** `let g:NERDTreeHijackNetrw=1`
- Makes NERDTree replace Vim's default file browser (netrw)

## Silver Searcher Integration

**Line 269:** `nnoremap <Leader>s :Ags<Space><C-R>=expand('<cword>')<CR><CR>`
- Leader+s searches for word under cursor using Silver Searcher

**Line 271:** `vnoremap <Leader>s y:Ags<Space><C-R>='"' . escape(@", '"*?()[]{}.') . '"'<CR><CR>`
- Leader+s in visual mode searches for selected text using Silver Searcher

**Line 273:** `nnoremap <Leader>a :Ags<Space>`
- Leader+a opens Silver Searcher prompt

**Line 275:** `nnoremap <Leader><Leader>a :AgsQuit<CR>`
- Leader+Leader+a quits Silver Searcher results window