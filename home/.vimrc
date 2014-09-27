" To update run :BundleInstall or vim +BundleInstall +qall

" Leader
let mapleader = " "
"let mapleader = ',' 'from Paul

set nocompatible  " Use Vim settings, rather then Vi settings
set nobackup
set nowritebackup
set noswapfile    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287
set history=2000
set ruler         " show the cursor position all the time
set showcmd       " display incomplete commands
set incsearch     " do incremental searching
set laststatus=2  " Always display the status line

" Declare bundles are handled via Vundle
filetype off " must be off for Bundle declarations
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" Let Vundle manage Vundle
Bundle 'gmarik/vundle'

" Define bundles via ?
Bundle 'Align'
Bundle 'DirDiff.vim'
Bundle 'fugitive.vim'
Bundle 'jQuery'
Bundle 'matchit.zip'
Bundle 'ruby-matchit'
Bundle 'surround.vim'
Bundle 'Tabular'
Bundle 'textobj-rubyblock'
Bundle 'textobj-user'
Bundle 'DrawIt'
Bundle 'Markdown'
Bundle 'Rename'

" Define bundles via Github repos
Bundle 'ervandew/supertab'
Bundle 'pangloss/vim-javascript'
Bundle 'jgdavey/vim-turbux'
Bundle 'jgdavey/tslime.vim'
Bundle 'scrooloose/nerdcommenter'
Bundle 'scrooloose/nerdtree'
Bundle 'scrooloose/syntastic'
Bundle 'jpo/vim-railscasts-theme'
Bundle 'flazz/vim-colorschemes'
Bundle 'tpope/vim-rails.git'
Bundle 'tpope/vim-eunuch.git'
Bundle 'vim-coffee-script'
Bundle 'tpope/vim-dispatch'
Bundle 'tpope/vim-endwise'
Bundle 'airblade/vim-gitgutter'
Bundle 'nono/vim-handlebars'
Bundle 'bogado/file-line'
Bundle 'tpope/vim-haml'
Bundle 'jelera/vim-javascript-syntax'
Bundle 'nathanaelkane/vim-indent-guides'
Bundle 'Raimondi/delimitMate'
Bundle 'marijnh/tern_for_vim'
Bundle 'rking/ag.vim'

" NOTE: check docs for additional installation steps for YouCompleteMe

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

set autoindent
set autoread
set autowrite
set backspace=indent,eol,start
set confirm
set expandtab
set hlsearch
set ignorecase
set pastetoggle=<F2>
set scrolloff=7
set shiftwidth=2
set shortmess=atI
set showmatch
set sidescroll=8
set softtabstop=2
set switchbuf=useopen
set virtualedit=block
set number
set list

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

" Stuff from Paul below:


cabbrev h vertical help

" The following gives you a quick "git blame" on the hightlighted code
vmap gl :<C-U>!git blame <C-R>=expand("%:p") <CR> \| sed -n <C-R>=line("'<") <CR>,<C-R>=line("'>") <CR>p <CR>

" `. - Goto last edit.

autocmd User Rails Rnavcommand uploader app/uploaders -suffix=_uploader.rb -default=model()
autocmd User Rails Rnavcommand steps features/step_definitions -suffix=_steps.rb -default=web
autocmd User Rails Rnavcommand blueprint spec/blueprints -suffix=_blueprint.rb -default=model()
autocmd User Rails Rnavcommand factory spec/factories -suffix=_factory.rb -default=model()
autocmd User Rails Rnavcommand fabricator spec/fabricators -suffix=_fabricator.rb -default=model()
autocmd User Rails Rnavcommand feature features -suffix=.feature -default=cucumber
autocmd User Rails Rnavcommand acceptance acceptance -suffix=_spec.rb -default=model()
autocmd User Rails Rnavcommand support spec/support features/support -default=env
autocmd User Rails Rnavcommand report app/reports
autocmd User Rails Rnavcommand import app/importers
autocmd User Rails Rnavcommand export app/exporters

map <Leader><Space> :nohlsearch<CR>
map <Leader>, :%s/\s\+$//<CR>

let g:turbux_command_prefix = 'bundle exec'

" hide hidden files by default
let NERDTreeShowHidden=0

let @r="require 'ruby-debug';debugger"
" re-indent xml
map <F3> :%s/>\s*</>\r</g<CR>:set ft=xml<CR>gg=G
" re-indent json
map <F4> :%s/{/{\r/g<CR>:%s/}/\r}/g<CR>:%s/,/,\r/g<CR>:set ft=javascript<CR>gg=G
