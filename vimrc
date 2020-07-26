" for 4 spaces indenting and auto-indent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab

" for makefiles, use tabs instead of spaces:
if has ("autocmd")
  filetype on
  autocmd FileType make setlocal noexpandtab
endif

" mouse functionality
set mouse=a

" visual bell instead of sound
set visualbell

" display line numbers
set number

" set syntax highlighting
syntax on

" Use case insensitive search, except when using capital letters
set ignorecase
set smartcase
