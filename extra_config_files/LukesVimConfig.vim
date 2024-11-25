set nu                  " Enable line numbers
set ai                  " Enable auto indentation
set expandtab           " Use spaces instead of tabs
set tabstop=4           " Number of spaces per tab
set shiftwidth=4        " Number of spaces for autoindent
set autoindent          " Maintain indent level of previous line
set hlsearch            " Highlight search results
set incsearch           " Incremental search
set ls=2                " Set status line
set wildmenu            " Enable tab completion menu for commands
set showcmd             " Show partial command in last line of the screen
set clipboard=unnamed   " Use system clipboard

set statusline=File:\ %t\ \ \ Buffer:\ [%{bufname('%')}]\ \ \ %l:%c

" Syntax and Appearance
syntax on               " Enable syntax highlighting
set background=dark     " Better visibility for dark themes

" File Navigation
set hidden              " Allow unsaved buffers to stay open
set switchbuf=useopen   " Switch to existing buffers if possible

" Tabs and Buffers
set tabpagemax=15       " Maximum number of tab pages
set showtabline=2       " Always show tab line
set autoread            " Auto-reload files if changed outside Vim

" Custom Key Bindings for Easier File Management
nnoremap <C-s> :w<CR>                                       " Ctrl-s: Save file
nnoremap <C-w> :q<CR>                                       " Ctrl-w: Close file
nnoremap <C-n> :enew<CR>                                    " Ctrl-n: Open a new empty buffer
nnoremap <C-t> :tabnew<CR>:NERDTreeExplore<CR>              " Ctrl-t: Open a new tab
nnoremap <C-h> :tabprevious<CR>      " Ctrl-h: Move to previous tab
nnoremap <C-l> :tabnext<CR>         " Ctrl-l: Move to next tab

nnoremap <C-b> :ls<CR>:b<Space>         " Ctrl-b: List buffers and switch between them

" Buffer and Window Navigation
nnoremap <leader>bn :bnext<CR>   " Next buffer
nnoremap <leader>bp :bprev<CR>   " Previous buffer
nnoremap <leader>wv :vsplit<CR>  " Vertical split window
nnoremap <leader>ws :split<CR>   " Horizontal split window
nnoremap <leader>wd :q<CR>       " Close current window
nnoremap <leader>ww :w<CR>       " Save current window

" Resize Splits Easily
nnoremap <leader>+ :resize +2<CR>               " Increase split height
nnoremap <leader>- :resize -2<CR>               " Decrease split height
nnoremap <leader>< :vertical resize -2<CR>      " Decrease split width
nnoremap <leader>> :vertical resize +2<CR>      " Increase split width

" Quality of Life Improvements
set undodir=~/.vim/undodir      " Directory to store undo files
set undofile                    " Save undo history to an undo file
set backspace=indent,eol,start  " More intuitive backspace behavior
set mouse=a                     " Enable mouse support in all modes
" set relativenumber              " Show relative line numbers
" set wrap                        " Wrap long lines
set scrolloff=8                 " Keep 8 lines visible above/below cursor
set sidescrolloff=8             " Keep 8 lines visible to the left/right of cursor

" Initialize vim-plug
call plug#begin('~/.vim/plugged')

" List your plugins here
Plug 'preservim/nerdtree'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

call plug#end()

" Key mapping to toggle NERDTree
nnoremap <leader>e :NERDTreeToggle<CR>
nnoremap <leader>f :FzfAg<CR>

" Enable fzf to work with ripgrep (if installed)
let g:fzf_command_prefix = 'Fzf'
let g:fzf_layout = { 'down': '40%' }  " Adjust layout height

" Open a new empty tab with <leader>n
nnoremap <leader>n :tabnew<CR>

" Close the current tab with <leader>c
nnoremap <leader>c :tabclose<CR>

" Open the current file in Sublime Text with <leader>s
nnoremap <leader>s :!"/mnt/c/Program Files/Sublime Text/sublime_text.exe" % &<CR>

" Function to yank selected text or the current line to Windows clipboard using clip.exe
function! YankToClipboard()
    " Get the current selection or the line if no selection is made
    let l:content = getreg('"')

    " Write to clipboard using clip.exe
    call system('clip.exe', l:content)
endfunction

nnoremap <silent> yy :let @"=getline('.')<CR>:call YankToClipboard()<CR>
vnoremap <silent> y :call YankToClipboard()<CR>