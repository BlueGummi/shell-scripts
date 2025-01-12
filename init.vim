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
Plug 'akinsho/toggleterm.nvim', {'tag' : '*'}
Plug 'brymer-meneses/grammar-guard.nvim'
Plug 'williamboman/nvim-lsp-installer'
call plug#end()
lua require("toggleterm").setup()
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
local lspconfig = require('lspconfig')
lspconfig.rust_analyzer.setup({
    settings = {
        ["rust-analyzer"] = {
            cargo = {
                loadOutDirsFromCheck = true,
            },
            procMacro = {
                enable = true,
            },
        },
    },
})
require("grammar-guard").init()
local cmp = require'cmp'
require("lspconfig").grammar_guard.setup({
	settings = {
		ltex = {
			enabled = { "latex", "tex", "bib", "markdown" },
			language = "en",
			diagnosticSeverity = "information",
			setenceCacheSize = 2000,
			additionalRules = {
				enablePickyRules = true,
				motherTongue = "en",
			},
			trace = { server = "verbose" },
			dictionary = {},
			disabledRules = {},
			hiddenFalsePositives = {},
		},
	},
})
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
lspconfig.clangd.setup {}
require('lspconfig').gleam.setup({})
vim.api.nvim_set_keymap('n', '<leader>gd', '<cmd>lua vim.lsp.buf.definition()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>', { noremap = true, silent = true })

EOF

let g:webdevicons_enable_airline_tabline = 1
let g:webdevicons_enable_airline_statusline = 1
syntax enable
if !isdirectory(expand("~/.local/share/nvim/undo"))
  call mkdir(expand("~/.local/share/nvim/undo"), "p")
endif

set undofile
set undodir=~/.local/share/nvim/undo
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme = 'base16_gruvbox_dark_medium'
colorscheme everforest
set laststatus=2
set termguicolors
let g:powerline_pycmd = 'python3'
set statusline=%#PmenuSel#%{powerline#statusline()}%#Normal#
set number
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-h> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>
autocmd TermEnter term://*toggleterm#*
      \ tnoremap <silent><c-t> <Cmd>exe v:count1 . "ToggleTerm"<CR>

nnoremap <silent><c-t> <Cmd>exe v:count1 . "ToggleTerm"<CR>
inoremap <silent><c-t> <Esc><Cmd>exe v:count1 . "ToggleTerm"<CR>
