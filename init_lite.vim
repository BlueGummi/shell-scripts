" =============================================================================
"  Neovim Lite Config — portable, fast, low-resource
"  Strips: weather, copilot, wakatime, satellite, aerial, heavy LSPs
"  Keeps:  treesitter, basic LSP, telescope, gitsigns, airline, keymaps
" =============================================================================

call plug#begin('~/.local/share/nvim/plugged')

" Core
Plug 'tpope/vim-sensible'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" UI
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'ryanoasis/vim-devicons'
Plug 'morhetz/gruvbox'
Plug 'folke/tokyonight.nvim'

" LSP + completion (lightweight set)
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'

" Navigation
Plug 'preservim/nerdtree'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-lua/plenary.nvim'

" Git
Plug 'lewis6991/gitsigns.nvim'

" Misc
Plug 'akinsho/toggleterm.nvim', {'tag': '*'}
Plug 'sbdchd/neoformat'
Plug 'folke/todo-comments.nvim'

call plug#end()

" ── Startup ──────────────────────────────────────────────────────────────────
autocmd VimEnter * ++once call s:EnableAirlineAfterStartup()
function! s:EnableAirlineAfterStartup()
  set laststatus=2
  AirlineRefresh
endfunction

autocmd BufNewFile,BufRead *.sh set filetype=sh

let mapleader = " "

" ── Airline ───────────────────────────────────────────────────────────────────
let g:airline_powerline_fonts         = 1
let g:webdevicons_enable_airline_tabline    = 1
let g:webdevicons_enable_airline_statusline = 1
let g:airline#extensions#tabline#enabled   = 1
let g:airline#extensions#tabline#formatter = 'default'
let g:airline#extensions#tabline#fnamemod  = ':t'
let g:airline_theme                   = 'base16_material_darker'
let g:airline_skip_empty_sections     = 1
let g:airline_section_b               = ''
let g:airline_section_c               = ''

" Clock in section_x, line/col in section_z
function! StatusClock()
  return os.date("%I:%M %p  %m/%d")
endfunction

function! AirlineClock()
  return strftime("  %I:%M %p  %m/%d  ")
endfunction

autocmd User AirlineAfterInit call s:SetupAirlineSections()
function! s:SetupAirlineSections()
  call airline#parts#define_function('airline_clock', 'AirlineClock')
  let g:airline_section_x = airline#section#create_right(['airline_clock'])
  let g:airline_section_z = airline#section#create([' %p%%', 'linenr', 'maxlinenr', 'colnr'])
endfunction

" ── Visuals ───────────────────────────────────────────────────────────────────
syntax enable
set termguicolors
colorscheme tokyonight

set number
set relativenumber
set signcolumn=yes
set cursorline
set laststatus=2

highlight CursorLineNr ctermfg=Yellow guifg=Yellow
highlight CursorLine   ctermbg=NONE   guibg=NONE

" ── Editor behaviour ──────────────────────────────────────────────────────────
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent

set undofile
if !isdirectory(expand("~/.local/share/nvim/undo"))
  call mkdir(expand("~/.local/share/nvim/undo"), "p")
endif
set undodir^=~/.local/share/nvim/undo//

" Restore cursor position on open
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

" Strip trailing whitespace
nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" ── Commands ──────────────────────────────────────────────────────────────────
command! Wq wq
command! WQ wq
command! W  w
command! Q  q

" ── Keymaps ───────────────────────────────────────────────────────────────────
nnoremap <leader>n  :NERDTreeFocus<CR>
nnoremap <C-h>      :NERDTreeToggle<CR>
nnoremap <C-f>      :NERDTreeFind<CR>
nnoremap <silent><c-t> <Cmd>exe v:count1 . "ToggleTerm"<CR>
nnoremap <leader>ff :Neoformat<CR>
nnoremap <F1>       :lua toggle_lsp()<CR>

nnoremap <leader>fd <cmd>lua require('telescope.builtin').find_files({
            \ cwd = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
            \ })<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>

" Convert // comments to /* */ blocks (visual selection)
function! ConvertAllCommentsToBlocks() range
  let l:start = a:firstline
  let l:end   = a:lastline
  let l:lines = getline(l:start, l:end)
  let l:result = [] | let l:block_buffer = [] | let l:in_block = 0
  for l:line in l:lines
    if l:line =~ '^\s*//'
      call add(l:block_buffer, substitute(l:line, '^\s*//\s*', '', ''))
      let l:in_block = 1 | continue
    endif
    if l:line =~ '//'
      if l:in_block && !empty(l:block_buffer)
        call add(l:result, '/* ' . join(l:block_buffer, ' ') . ' */')
        let l:block_buffer = [] | let l:in_block = 0
      endif
      let l:mp = match(l:line, '//')
      call add(l:result, strpart(l:line,0,l:mp) . '/* ' .
            \ substitute(strpart(l:line,l:mp), '^//\s*','','') . ' */')
      continue
    endif
    if l:in_block
      if !empty(l:block_buffer)
        call add(l:result, '/* ' . join(l:block_buffer, ' ') . ' */')
        let l:block_buffer = []
      endif
      let l:in_block = 0
    endif
    call add(l:result, l:line)
  endfor
  if !empty(l:block_buffer)
    call add(l:result, '/* ' . join(l:block_buffer, ' ') . ' */')
  endif
  call setline(l:start, l:result)
  if len(l:result) < (l:end - l:start + 1)
    call deletebufline('%', l:start + len(l:result), l:end)
  endif
endfunction
vnoremap <leader>c :<C-u>call ConvertAllCommentsToBlocks()<CR>

" ── Lua config ────────────────────────────────────────────────────────────────
lua << EOF

-- ── Treesitter ────────────────────────────────────────────────────────────────
require('nvim-treesitter.configs').setup {
  ensure_installed = { "rust", "c", "cpp", "lua", "bash", "python", "markdown" },
  highlight = { enable = true },
  indent    = { enable = true },
}

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    vim.schedule(function() pcall(vim.treesitter.start) end)
  end,
})

-- ── LSP ───────────────────────────────────────────────────────────────────────
local cmp     = require('cmp')
local cmp_lsp = require('cmp_nvim_lsp')
local caps    = cmp_lsp.default_capabilities()

-- clangd (C/C++)
vim.lsp.config("clangd", {
  capabilities = caps,
  init_options = { fallbackFlags = { "--background-index" } },
})
vim.lsp.enable("clangd")

-- bash
vim.lsp.config.bashls = {
  cmd      = { 'bash-language-server', 'start' },
  filetypes = { 'bash', 'sh' },
  capabilities = caps,
}
vim.lsp.enable('bashls')

-- python
vim.lsp.config("pylsp", { capabilities = caps })
vim.lsp.enable("pylsp")

-- rust (via rustaceanvim if available, else plain lsp)
local ok_rust = pcall(function()
  vim.g.rustaceanvim = {
    server = {
      capabilities = caps,
      settings = {
        ["rust-analyzer"] = {
          check   = { command = "clippy" },
          cargo   = { allFeatures = true },
          procMacro = { enable = true },
        },
      },
    },
  }
end)

vim.diagnostic.config({
  virtual_text    = true,
  signs           = true,
  underline       = true,
  update_in_insert = false,
})

vim.lsp.handlers["textDocument/hover"] =
  vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
vim.lsp.handlers['textDocument/signatureHelp'] =
  vim.lsp.with(vim.lsp.handlers.signature_help, { border = 'rounded' })

function toggle_lsp()
  vim.lsp.stop_client(vim.lsp.get_clients())
end

-- ── nvim-cmp ──────────────────────────────────────────────────────────────────
local lsp_hover = function()
  if vim.fn.pumvisible() == 1 then
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-e>", true, true, true), "n")
  end
  vim.lsp.buf.hover()
end

cmp.setup({
  snippet = { expand = function() end },
  completion = {
    completeopt = 'menu,menuone,noselect',
    max_items   = 10,
    timeout     = 100,
  },
  mapping = {
    ['<C-n>']     = cmp.mapping.select_next_item(),
    ['<C-p>']     = cmp.mapping.select_prev_item(),
    ['<C-e>']     = cmp.mapping.close(),
    ['<C-y>']     = cmp.mapping.confirm({ select = true }),
    ['<C-l>']     = cmp.mapping(lsp_hover, { 'i', 's' }),
    ['<C-Space>'] = cmp.mapping.complete(),
  },
  sources = {
    { name = 'nvim_lsp', max_item_count = 20 },
    { name = 'buffer',   max_item_count = 10 },
    { name = 'path',     max_item_count = 10 },
  },
  window = {
    completion    = cmp.config.window.bordered({ border = "rounded" }),
    documentation = cmp.config.window.bordered({ border = "rounded" }),
  },
})

-- ── Telescope ─────────────────────────────────────────────────────────────────
local has_telescope, telescope = pcall(require, "telescope.builtin")

if has_telescope then
  local function project_root()
    local r = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    return (r and r ~= "") and r or vim.loop.cwd()
  end

  local function grep_word()
    local mode = vim.fn.mode()
    local text = (mode == "v" or mode == "V")
      and (function() vim.cmd('normal! "vy') return vim.fn.getreg('v') end)()
      or vim.fn.expand("<cword>")
    telescope.live_grep({ cwd = project_root(), default_text = text:match("^%s*(.-)%s*$") })
  end

  vim.keymap.set('n', '<leader>fg', grep_word, { noremap = true, silent = true })
  vim.keymap.set('v', '<leader>fg', grep_word, { noremap = true, silent = true })
end

-- ── Gitsigns ──────────────────────────────────────────────────────────────────
require('gitsigns').setup {
  on_attach = function(bufnr)
    local gs = require('gitsigns')
    local function map(mode, l, r, opts)
      (opts or {}).buffer = bufnr
      vim.keymap.set(mode, l, r, opts or {})
    end
    map('n', ']c', function() if vim.wo.diff then vim.cmd.normal({']c',bang=true}) else gs.nav_hunk('next') end end)
    map('n', '[c', function() if vim.wo.diff then vim.cmd.normal({'[c',bang=true}) else gs.nav_hunk('prev') end end)
    map('n', '<leader>hs', gs.stage_hunk)
    map('n', '<leader>hr', gs.reset_hunk)
    map('n', '<leader>hb', function() gs.blame_line({ full = true }) end)
    map('n', '<leader>hd', gs.diffthis)
    map('n', '<leader>tb', gs.toggle_current_line_blame)
    map({'o','x'}, 'ih', gs.select_hunk)
  end
}

-- ── Todo comments ─────────────────────────────────────────────────────────────
require("todo-comments").setup {
  signs = true,
  keywords = {
    FIX  = { icon = " ", color = "error"   },
    TODO = { icon = " ", color = "info"    },
    HACK = { icon = " ", color = "warning" },
    WARN = { icon = " ", color = "warning" },
    NOTE = { icon = " ", color = "hint"    },
    BUG  = { icon = " ", color = "error"   },
  },
}

-- ── Toggleterm ────────────────────────────────────────────────────────────────
require('toggleterm').setup()
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')

-- ── Diagnostics list ─────────────────────────────────────────────────────────
vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
  pattern  = "*",
  callback = function() vim.diagnostic.setloclist({ open = false }) end,
})

-- ── Misc ──────────────────────────────────────────────────────────────────────
vim.opt.statuscolumn = "%s%=%l%#LineNr#│"

vim.filetype.add({ extension = { mdx = "markdown" } })

EOF
