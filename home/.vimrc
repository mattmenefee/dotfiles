" RULE #1: Don't put any lines in your vimrc that you don't understand

" Ensure that legacy compatibility mode is off
" documentation: http://vimdoc.sourceforge.net/htmldoc/options.html#'compatible'
set nocompatible " be iMproved, required
filetype off " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'Align'
Plugin 'DirDiff.vim'
Plugin 'fugitive.vim'
Plugin 'jQuery'
Plugin 'matchit.zip'
Plugin 'ruby-matchit'
Plugin 'surround.vim'
Plugin 'Tabular'
Plugin 'textobj-rubyblock'
Plugin 'textobj-user'
Plugin 'DrawIt'
Plugin 'Markdown'
Plugin 'Rename'
Plugin 'ervandew/supertab'
Plugin 'pangloss/vim-javascript'
Plugin 'scrooloose/nerdcommenter'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'
Plugin 'myint/syntastic-extras'
Plugin 'flazz/vim-colorschemes'
Plugin 'tpope/vim-rails'
Plugin 'tpope/vim-eunuch'
Plugin 'vim-coffee-script'
Plugin 'tpope/vim-dispatch'
Plugin 'tpope/vim-endwise'
Plugin 'airblade/vim-gitgutter'
Plugin 'bogado/file-line'
Plugin 'tpope/vim-haml'
Plugin 'jelera/vim-javascript-syntax'
Plugin 'nathanaelkane/vim-indent-guides'
Plugin 'Raimondi/delimitMate'
Plugin 'rking/ag.vim'
Plugin 'thoughtbot/vim-rspec'
Plugin 'mtscout6/vim-cjsx'
Plugin 'mxw/vim-jsx'
Plugin 'ap/vim-css-color'
Plugin 'rainerborene/vim-reek'
Plugin 'tpope/vim-repeat'
Plugin 'carakan/new-railscasts-theme'
Plugin 'tpope/vim-abolish'
Plugin 'gabesoft/vim-ags' " For searching Vim using the_silver_searcher
Plugin 'hashivim/vim-terraform'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"                     (Note: need to close and re-open Vim after removing a plugin)
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

" Leader
let mapleader = " "

set backspace=2   " Backspace deletes like most programs in insert mode
set nocompatible  " Use Vim settings, rather then Vi settings
set nobackup
set nowritebackup
set noswapfile    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287
set history=2000
set ruler         " show the cursor position all the time
set showcmd       " display incomplete commands
set laststatus=2  " Always display the status line
set autowrite     " Automatically :write before running commands
set autoindent
set autoread
set autowrite
set confirm
set pastetoggle=<F2>
set shortmess=atI
set visualbell " stop Vim from beeping at me
" set cursorline " Highlight the current line

" Maintain the undo history even after the file is closed:
set undofile

" Softtabs, 2 spaces
set tabstop=2
set shiftwidth=2
set shiftround
set expandtab " convert tabs to spaces
set softtabstop=2

" Use 100 character lines by default
set textwidth=100
" Wrap text based on a number of columns from the right side
set wrapmargin=2

" Perform incremental searches as you type:
set incsearch
" Highlight the searched term in a file:
set hlsearch
" Search ignoring case:
set ignorecase
" Search without considering ignorecase when both ignorecase and smartcase are set and the search pattern contains uppercase:
set smartcase
" Prefer to have the cursor somewhere in the middle rather than on the first line - set the cursor position to the 7th row:
set scrolloff=7

" Identify open and close brace positions when you traverse through the file:
set showmatch
set sidescroll=8
set switchbuf=useopen
set virtualedit=block
set number
set list

syntax enable
syntax on " are both of these necessary?

filetype plugin indent on

colorscheme railscasts

map QQ :q<CR>
map WW :wall<CR>
map NN :next<CR>
map PP :previous<CR>
map + <C-A>
map - <C-X>
cmap w!! w !sudo tee %
command T tabedit README

inoremap <C-F> <C-X><C-F>
inoremap <C-L> <C-X><C-L>

" Make `jj` and `jk` throw you into normal mode
inoremap jj <esc>
inoremap jk <esc>

" Open Markdown files in Chrome via F5
autocmd BufEnter *.md exe 'noremap <F5> :!open -a "Google Chrome.app" %:p<CR>'

" More natural vim splits
" Ctrl+[direction keys] to move between splits
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright

" Get off my lawn
nnoremap <Left> :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up> :echoe "Use k"<CR>
nnoremap <Down> :echoe "Use j"<CR>

" Treat <li> and <p> tags like the block tags they are
let g:html_indent_tags = 'li\|p'

" Display extra whitespace
set list listchars=tab:»·,trail:·
" Remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" Axlsx files end in .axlsx
au BufRead,BufNewFile *.axlsx set filetype=ruby

" Markdown files end in .md
au BufRead,BufNewFile *.md set filetype=markdown

" Enable spellchecking for Markdown
au BufRead,BufNewFile *.md setlocal spell

" Automatically wrap at 80 characters for Markdown
au BufRead,BufNewFile *.md setlocal textwidth=80

" Encrypted Rails credentials files end in .enc
au BufRead,BufNewFile *.yml.enc* set filetype=yaml

" Python files end in .py
au BufRead,BufNewFile *.py set filetype=python

" Dockerfile files start with Dockerfile*
au BufRead,BufNewFile Dockerfile* set filetype=dockerfile

" Capistrano service templates end in .service.erb
au BufRead,BufNewFile *.service.erb set filetype=ruby.ini

" Auto-lint Sass files
let g:syntastic_scss_checkers = ['scss_lint']
autocmd BufRead,BufNewFile */modus/* let g:syntastic_scss_checkers=[]

" Auto-lint Haml files
let g:syntastic_haml_checkers = ['haml_lint']

" Auto-lint React files
let g:syntastic_javascript_checkers = ['eslint']

" Auto-lint language check (via syntastic-extras)
let g:syntastic_gitcommit_checkers = ['language_check']

" Set python version
let g:syntastic_python_python_exec = 'python3'
let g:syntastic_python_checkers = ['python']

" Auto-lint YAML (via syntastic-extras)
let g:syntastic_yaml_checkers = ['pyyaml']

" Specify coffeelint config options
let coffee_lint_options = '-f config/coffeelint.json'

" Allow JSX in normal JS files
let g:jsx_ext_required = 0

" show hidden files by default
let NERDTreeShowHidden = 1

" Git commit message spell checking and automatic wrapping at the
" recommended 72 columns
autocmd Filetype gitcommit setlocal spell textwidth=72

" RSpec.vim mappings
let g:rspec_runner = "os_x_iterm"
" let g:rspec_command = "!bin/rspec {spec}"
let g:rspec_command = "Dispatch bin/rspec {spec}"
map <Leader>t :call RunCurrentSpecFile()<CR>
map <Leader>s :call RunNearestSpec()<CR>
map <Leader>l :call RunLastSpec()<CR>
map <Leader>a :call RunAllSpecs()<CR>

" Allow copy/paste to work with OS X clipboard
set clipboard=unnamed

" open a NERDTree automatically when vim starts up if no files were specified
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Open help in vertical pane by default
cabbrev h vertical help

" Stuff from Paul below:

" The following gives you a quick 'git blame' on the hightlighted code
vmap gl :<C-U>!git blame <C-R>=expand("%:p") <CR> \| sed -n <C-R>=line("'<") <CR>,<C-R>=line("'>") <CR>p <CR>

map <Leader><Space> :nohlsearch<CR>
map <Leader>, :%s/\s\+$//<CR>

let g:NERDTreeHijackNetrw=1

" Ags / The Silver Searcher configuration:
" Search for the word under cursor
nnoremap <Leader>s :Ags<Space><C-R>=expand('<cword>')<CR><CR>
" Search for the visually selected text
vnoremap <Leader>s y:Ags<Space><C-R>='"' . escape(@", '"*?()[]{}.') . '"'<CR><CR>
" Run Ags
nnoremap <Leader>a :Ags<Space>
" Quit Ags
nnoremap <Leader><Leader>a :AgsQuit<CR>
