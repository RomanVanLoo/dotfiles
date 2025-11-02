set encoding=utf-8

" Leader
let mapleader = " "

set backspace=2   " Backspace deletes like most programs in insert mode
set nobackup
set nowritebackup
set noswapfile    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287
set history=50
set ruler         " show the cursor position all the time
set showcmd       " display incomplete commands
set incsearch     " do incremental searching
set laststatus=2  " Always display the status line
set autowrite     " Automatically :write before running commands
set modelines=0   " Disable modelines as a security precaution
set nomodeline
set cursorcolumn
set cursorline
set ignorecase
set ttyfast
set lazyredraw

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if (&t_Co > 2 || has("gui_running")) && !exists("syntax_on")
  syntax on
endif

if filereadable(expand("~/.vimrc.bundles"))
  source ~/.vimrc.bundles
endif

" Load matchit.vim, but only if the user hasn't installed a newer version.
if !exists('g:loaded_matchit') && findfile('plugin/matchit.vim', &rtp) ==# ''
  runtime! macros/matchit.vim
endif

filetype plugin indent on

augroup vimrcEx
  autocmd!

  " When editing a file, always jump to the last known cursor position.
  " Don't do it for commit messages, when the position is invalid, or when
  " inside an event handler (happens when dropping a file on gvim).
  autocmd BufReadPost *
    \ if &ft != 'gitcommit' && line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

  " Set syntax highlighting for specific file types
  autocmd BufRead,BufNewFile *.md set filetype=markdown
  autocmd BufRead,BufNewFile .{jscs,jshint,eslint}rc set filetype=json
  autocmd BufRead,BufNewFile aliases.local,zshrc.local,*/zsh/configs/* set filetype=sh
  autocmd BufRead,BufNewFile gitconfig.local set filetype=gitconfig
  autocmd BufRead,BufNewFile tmux.conf.local set filetype=tmux
  autocmd BufRead,BufNewFile vimrc.local set filetype=vim
augroup END

" When the type of shell script is /bin/sh, assume a POSIX-compatible
" shell for syntax highlighting purposes.
let g:is_posix = 1

" Softtabs, 2 spaces
set tabstop=2
set shiftwidth=2
set shiftround
set expandtab

" Display extra whitespace
set list listchars=tab:»·,trail:·,nbsp:·

" Use one space, not two, after punctuation.
set nojoinspaces

" Numbers
set number
set numberwidth=5

" Tab completion
" will insert tab at beginning of line,
" will use completion if not at beginning
set wildmode=list:longest,list:full
function! InsertTabWrapper()
    let col = col('.') - 1
    if !col || getline('.')[col - 1] !~ '\k'
        return "\<Tab>"
    else
        return "\<C-p>"
    endif
endfunction
inoremap <Tab> <C-r>=InsertTabWrapper()<CR>
inoremap <S-Tab> <C-n>

" Switch between the last two files
nnoremap <Leader><Leader> <C-^>

" Get off my lawn
nnoremap <Left> :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up> :echoe "Use k"<CR>
nnoremap <Down> :echoe "Use j"<CR>

" vim-test mappings
nnoremap <silent> <Leader>t :TestFile<CR>
nnoremap <silent> <Leader>s :TestNearest<CR>
nnoremap <silent> <Leader>l :TestLast<CR>
nnoremap <silent> <Leader>a :TestSuite<CR>
nnoremap <silent> <Leader>gt :TestVisit<CR>

" Run commands that require an interactive shell
nnoremap <Leader>r :RunInInteractiveShell<Space>

" Reset current file to match main branch
command! ResetFileToMain execute '!git checkout main -- ' . shellescape(expand('%')) | edit

" Treat <li> and <p> tags like the block tags they are
let g:html_indent_tags = 'li\|p'

" Set tags for vim-fugitive
set tags^=.git/tags

" Open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright

" Quicker window movement
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" Map Ctrl + p to open fuzzy find (FZF)
" Enhanced FZF that accepts absolute paths
let $FZF_DEFAULT_COMMAND = 'find . -type f -not -path "*/\.git/*" 2>/dev/null | sed "s|^\./||"'
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split', 
  \ 'ctrl-v': 'vsplit' }

" Custom sink function that handles absolute paths and queries with actions
function! SmartFileOpen(lines)
  if len(a:lines) < 1
    return
  endif
  
  let query = a:lines[0]
  let action = len(a:lines) > 1 ? a:lines[1] : ''
  let file = len(a:lines) > 2 ? a:lines[2] : ''
  
  " If no file selected but query is an absolute path, use the query
  if empty(file) && query =~ '^/' && filereadable(query)
    let file = query
  elseif empty(file) && !empty(action)
    " When action is selected but no file, the action IS the file
    let file = action
    let action = ''
  endif
  
  if empty(file)
    return
  endif
  
  " Determine the vim command based on action
  let cmd = 'edit'
  if action == 'ctrl-t'
    let cmd = 'tabedit'
  elseif action == 'ctrl-x'
    let cmd = 'split'
  elseif action == 'ctrl-v'
    let cmd = 'vsplit'
  endif
  
  " If it starts with / and exists, open it as absolute path
  if file =~ '^/' && filereadable(file)
    execute cmd . ' ' . fnameescape(file)
  " If it starts with / but doesn't exist, extract filename and search for it
  elseif file =~ '^/'
    let basename = fnamemodify(file, ':t')
    " Try to find file with same name in current project
    let found = systemlist('find . -name "' . basename . '" -type f 2>/dev/null | head -1')
    if len(found) > 0
      execute cmd . ' ' . fnameescape(found[0])
    else
      echo "File not found: " . file
    endif
  else
    " Normal relative path
    execute cmd . ' ' . fnameescape(file)
  endif
endfunction

" Use --print-query and --expect to capture both query and actions
nnoremap <silent> <c-p> :call fzf#run(fzf#wrap({
  \ 'sink*': function('SmartFileOpen'), 
  \ 'options': '--print-query --expect=ctrl-t,ctrl-x,ctrl-v'
  \ }))<cr>

" Search in files (Telescope)
nnoremap <silent> <Leader>f :Telescope live_grep<CR>
nnoremap <silent> <Leader>q :copen<CR>

set grepprg=rg\ --vimgrep\ --smart-case\ --follow

" Set spellfile to location that is guaranteed to exist, can be symlinked to
" Dropbox or kept in Git and managed outside of thoughtbot/dotfiles using rcm.
set spellfile=$HOME/.vim-spell-en.utf-8.add

" Autocomplete with dictionary words when spell check is on
set complete+=kspell

" Always use vertical diffs
if &diff
  set diffopt-=internal
  set diffopt+=vertical
endif

" Local config
if filereadable($HOME . "/.vimrc.local")
  source ~/.vimrc.local
endif

call plug#begin()
  Plug 'christoomey/vim-tmux-navigator'
  Plug 'tpope/vim-commentary'
  Plug 'itchyny/lightline.vim'
  Plug 'airblade/vim-gitgutter'
  Plug 'tpope/vim-fireplace'
  Plug 'dense-analysis/ale'
  Plug 'rking/ag.vim'
  Plug 'junegunn/fzf.vim'
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/vim-easy-align'
  Plug 'godlygeek/tabular'
  Plug 'tpope/vim-fugitive'
  Plug 'gabrielelana/vim-markdown'
  Plug 'skanehira/preview-markdown.vim'
  Plug 'preservim/nerdtree'
  Plug 'thoughtbot/vim-rspec'
  Plug 'nvim-telescope/telescope.nvim', { 'do': ':UpdateRemotePlugins' }
  Plug 'nvim-lua/plenary.nvim'
  if has("nvim")
    Plug 'nvim-treesitter/nvim-treesitter', { 'commit': '7958ff9', 'do': ':TSUpdate' }
    Plug 'tanvirtin/monokai.nvim'
    Plug 'polirritmico/monokai-nightasty.nvim'
    Plug 'f-person/git-blame.nvim'
    Plug 'ribru17/bamboo.nvim'
    Plug 'github/copilot.vim'
    Plug 'ryanoasis/vim-devicons'
    Plug 'morhetz/gruvbox'

  endif
call plug#end()

" TMUX
let g:tmux_navigator_no_mappings = 1
nnoremap <silent> <c-k> :TmuxNavigateUp<cr>
nnoremap <silent> <c-j> :TmuxNavigateDown<cr>
nnoremap <silent> <c-h> :TmuxNavigateLeft<cr>
nnoremap <silent> <c-l> :TmuxNavigateRight<cr>

" Disable tmux navigator when zooming the Vim pane
let g:tmux_navigator_disable_when_zoomed = 1

" Set monokai theme
syntax enable
colorscheme gruvbox
set background=light

" Vim-Commentary
noremap \ :Commentary<CR>
autocmd FileType ruby setlocal commentstring=#\ %s

" Always use the standard clipboard instead of the register
set clipboard=unnamedplus

" Map leader + c => to copy current filepath
:nnoremap <Leader>c :let @+=expand('%:p')<CR>

" Map leader + l => turn cursorline off / Makes scrolling in big files way
" faster
:nnoremap <Leader>l :set cursorline!<CR>

" NERDTree
:nnoremap <Leader>n :NERDTreeFind<CR>

" Mappings for vim-rspec
map <Leader>t :call RunCurrentSpecFile()<CR>
map <Leader>y :call RunNearestSpec()<CR>

let g:rspec_command = "!docker compose run --rm --name web-rspec web bundle exec rspec {spec}"

" Set bar width for NERDTree
let g:NERDTreeWinSize=100
let g:NERDTreeQuitOnOpen = 1
let g:NERDTreeAutoDeleteBuffer = 1
let g:NERDTreeMinimalUI = 1

" Fold
set foldlevel=20
set foldclose=all

" easy-align
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

" Dont turn off git blame by default
let g:gitblame_enabled = 1

" ALE - Auto linting/fixing
let g:ale_fixers = {'ruby': ['standardrb'], 'typescript': ['eslint'], 'javascript': ['eslint']}
let g:ale_linters = {'ruby': ['standardrb']}
let g:ale_fix_on_save = 1

" Telescope configuration
lua << EOF
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local builtin = require('telescope.builtin')
local themes = require('telescope.themes')

-- Function to handle both relative and absolute paths
local function smart_find_files()
  local cwd = vim.fn.getcwd()
  
  builtin.find_files({
    attach_mappings = function(prompt_bufnr, map)
      -- Override the default selection action
      local function smart_select()
        local selection = action_state.get_selected_entry()
        local filename = selection.filename or selection.value
        
        -- If it's an absolute path, use it directly
        -- If it's relative, it will work normally
        actions.select_default(prompt_bufnr)
      end
      
      map('i', '<CR>', smart_select)
      map('n', '<CR>', smart_select)
      return true
    end,
    -- This allows telescope to find files using absolute paths
    find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--absolute-path" },
    -- Show both relative and absolute paths in results
    path_display = function(opts, path)
      local cwd = vim.fn.getcwd()
      -- If path starts with cwd, show relative version
      if string.find(path, cwd, 1, true) == 1 then
        return string.sub(path, string.len(cwd) + 2)
      end
      return path
    end,
  })
end

require('telescope').setup{
  defaults = {
    vimgrep_arguments = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case'
    },
    mappings = {
      i = {
        ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
        ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
      },
      n = {
        ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
        ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
      },
    },
    prompt_position = "bottom",
    prompt_prefix = "> ",
    selection_caret = "> ",
    entry_prefix = "  ",
    initial_mode = "insert",
    selection_strategy = "reset",
    sorting_strategy = "descending",
    layout_strategy = "horizontal",
    layout_config = {
      horizontal = {
        mirror = false,
        preview_width = 0.5,
      },
      vertical = {
        mirror = false,
        preview_cutoff = 0,
        preview_height = 1,
      },
    },
    file_sorter = require'telescope.sorters'.get_fuzzy_file,
    file_ignore_patterns = {},
    generic_sorter = require'telescope.sorters'.get_generic_fuzzy_sorter,
    path_display = {"smart"},
    winblend = 0,
    border = {},
    borderchars = {'|', '|', '|', '|', '+', '+', '+', '+'},
    color_devicons = true,
    use_less = true,
    set_env = { ['COLORTERM'] = 'truecolor' },
    file_previewer = require'telescope.previewers'.vim_buffer_cat.new,
    grep_previewer = require'telescope.previewers'.vim_buffer_vimgrep.new,
    qflist_previewer = require'telescope.previewers'.vim_buffer_qflist.new,
    buffer_previewer_maker = require'telescope.previewers'.buffer_previewer_maker,
  }
}

-- Custom key mappings with smart file finding
vim.api.nvim_set_keymap('n', '<leader>p', ":lua smart_find_files()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>f', ":lua require('telescope.builtin').live_grep(require('telescope.themes').get_dropdown({}))<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>q', ':copen<CR>', { noremap = true, silent = true })

-- Function to sync background with system theme using macOS defaults
local function sync_background_with_system()
  local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()

    if result and result:match("Dark") then
      vim.o.background = "dark"
    else
      vim.o.background = "dark"
    end
  end
end

-- Sync background on startup
sync_background_with_system()

-- Sync when Neovim gains focus (when you switch back to it)
vim.api.nvim_create_autocmd({"FocusGained", "VimEnter"}, {
  group = vim.api.nvim_create_augroup("SystemThemeSync", { clear = true }),
  callback = sync_background_with_system,
  desc = "Sync background with system theme"
})

-- Create a manual command to sync theme
vim.api.nvim_create_user_command('SyncTheme', sync_background_with_system, {
  desc = "Manually sync background with system theme"
})
EOF

