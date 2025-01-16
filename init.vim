call plug#begin('~/.local/share/nvim/plugged')
Plug 'tpope/vim-sensible'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'vim-airline/vim-airline'
Plug 'powerline/powerline'
Plug 'ryanoasis/vim-devicons'
Plug 'vim-airline/vim-airline-themes'
Plug 'morhetz/gruvbox'     
Plug 'joshdick/onedark.vim' 
Plug 'dracula/vim'          
Plug 'sainnhe/everforest'    
Plug 'folke/tokyonight.nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-cmp'    
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'   
Plug 'hrsh7th/cmp-path'     
Plug 'hrsh7th/cmp-cmdline'
Plug 'preservim/nerdtree'
Plug 'caenrique/buffer-term.nvim'
Plug 'williamboman/nvim-lsp-installer'
Plug 'tribela/transparent.nvim'
Plug 'navarasu/onedark.nvim'
call plug#end()
colorscheme onedark
lua << EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = "rust", "c", "gleam", "cpp", "markdown", "haskell", "python", "js",
  highlight = {
    enable = true,              
  },
  indent = {
    enable = true,
  }
}
vim.filetype.add({
  extension = {
    mdx = "markdown",
  },
})
EOF
lua << EOF
require('buffer-term').setup({
  terminal_options = {
      start_insert = true,
      buf_listed = false,
      no_numbers = true,
  }
})
local buffer_term = require('buffer-term')

buffer_term.setup() -- default config
local cmp = require'cmp'
cmp.setup({
  snippet = {
    expand = function(args)
    end,
  },
  mapping = {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
    ['<C-e>'] = cmp.mapping.close(),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
  },
})
vim.api.nvim_set_keymap('n', '<leader>gd', '<cmd>lua vim.lsp.buf.definition()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>', { noremap = true, silent = true })
EOF

let g:webdevicons_enable_airline_tabline = 1
let g:webdevicons_enable_airline_statusline = 1
syntax enable
if !isdirectory(expand("~/.local/share/nvim/undo"))
  call mkdir(expand("~/.local/share/nvim/undo"), "p")
endif

lua << EOF
require('transparent').setup({})
EOF
set undofile
set undodir=~/.local/share/nvim/undo
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme = 'base16_gruvbox_dark_medium'
set laststatus=2
set termguicolors
let g:powerline_pycmd = 'python3'
set statusline=%#PmenuSel#%{powerline#statusline()}%#Normal#
set number
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-h> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

let g:airline#extensions#tabline#formatter = 'default'
let g:airline_powerline_fonts = 1

lua << EOF
local buffer_term = require('buffer-term')

buffer_term.setup() 

vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')
vim.keymap.set({ 'n', 't' }, ';a', function() buffer_term.toggle('a') end)
vim.keymap.set({ 'n', 't' }, ';s', function() buffer_term.toggle('s') end)
vim.keymap.set({ 'n', 't' }, ';d', function() buffer_term.toggle('d') end)
vim.keymap.set({ 'n', 't' }, ';f', function() buffer_term.toggle('f') end)
vim.keymap.set({ 'n', 't' }, '<c-;>', buffer_term.toggle_last)
EOF
