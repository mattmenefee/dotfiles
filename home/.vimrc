" RULE #1: Don't put any lines in your vimrc that you don't understand

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
Plugin 'jgdavey/vim-turbux'
Plugin 'jgdavey/tslime.vim'
Plugin 'scrooloose/nerdcommenter'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'
Plugin 'myint/syntastic-extras'
Plugin 'jpo/vim-railscasts-theme'
Plugin 'flazz/vim-colorschemes'
Plugin 'tpope/vim-cucumber'
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
Plugin 'marijnh/tern_for_vim'
Plugin 'rking/ag.vim'
Plugin 'thoughtbot/vim-rspec'
Plugin 'mtscout6/vim-cjsx'
Plugin 'mxw/vim-jsx'
Plugin 'ap/vim-css-color'
Plugin 'rainerborene/vim-reek'
" Plugin 'w0rp/ale' " conflicts with syntastic
Plugin 'tpope/vim-repeat'

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
set incsearch     " do incremental searching
set laststatus=2  " Always display the status line
set autowrite     " Automatically :write before running commands

" Softtabs, 2 spaces
set tabstop=2
set shiftwidth=2
set shiftround
set expandtab


set autoindent
set autoread
set autowrite
set confirm
set hlsearch
set ignorecase
set pastetoggle=<F2>
set scrolloff=7
set shortmess=atI
set showmatch
set sidescroll=8
set softtabstop=2
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

" Markdown files end in .md
au BufRead,BufNewFile *.md set filetype=markdown

" Enable spellchecking for Markdown
au BufRead,BufNewFile *.md setlocal spell

" Automatically wrap at 80 characters for Markdown
au BufRead,BufNewFile *.md setlocal textwidth=80

" Auto-lint Sass files
let g:syntastic_scss_checkers = ['scss_lint']
autocmd BufRead,BufNewFile */modus/* let g:syntastic_scss_checkers=[]

" Auto-lint Haml files
let g:syntastic_haml_checkers = ['haml_lint']

" Auto-lint React files
let g:syntastic_javascript_checkers = ['eslint']

" Auto-lint language check (via syntastic-extras)
let g:syntastic_gitcommit_checkers = ['language_check']

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

autocmd User Rails Rnavcommand uploader app/uploaders -suffix=_uploader.rb -default=model()
autocmd User Rails Rnavcommand steps features/step_definitions -suffix=_steps.rb -default=web
autocmd User Rails Rnavcommand factory spec/factories -suffix=_factory.rb -default=model()
autocmd User Rails Rnavcommand feature features -suffix=.feature -default=cucumber
autocmd User Rails Rnavcommand support spec/support features/support -default=env
autocmd User Rails Rnavcommand report app/reports

map <Leader><Space> :nohlsearch<CR>
map <Leader>, :%s/\s\+$//<CR>

let g:NERDTreeHijackNetrw=1
