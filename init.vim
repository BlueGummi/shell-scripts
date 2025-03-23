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
Plug 'williamboman/nvim-lsp-installer'
Plug 'tribela/transparent.nvim'
Plug 'navarasu/onedark.nvim'
Plug 'scottmckendry/cyberdream.nvim'

call plug#end()

lua << EOF
require("cyberdream").setup({
    transparent = true,
})

require'nvim-treesitter.configs'.setup {
    ensure_installed = "rust", "c", "gleam", "cpp", "markdown", "haskell", "python", "js",
    highlight = {
        enable = true,              
    },
    indent = {
        enable = true,
    }
}

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

require'toggleterm'.setup()

vim.api.nvim_set_keymap('n', '<leader>gd', '<cmd>lua vim.lsp.buf.definition()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>', { noremap = true, silent = true })

vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')
vim.filetype.add({
    extension = {
        mdx = "markdown",
    },
})

EOF

syntax enable
if !isdirectory(expand("~/.local/share/nvim/undo"))
  call mkdir(expand("~/.local/share/nvim/undo"), "p")
endif

nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-h> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>
nnoremap <silent><c-t> <Cmd>exe v:count1 . "ToggleTerm"<CR>


autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

let g:airline#extensions#tabline#enabled = 1
let g:airline_theme = 'base16_gruvbox_dark_medium'
let g:powerline_pycmd = 'python3'
let g:airline#extensions#tabline#formatter = 'default'
let g:airline_powerline_fonts = 1
let g:webdevicons_enable_airline_tabline = 1
let g:webdevicons_enable_airline_statusline = 1
colorscheme cyberdream 


set undofile
set undodir=~/.local/share/nvim/undo
set statusline=%#PmenuSel#%{powerline#statusline()}%#Normal#
set laststatus=2
set termguicolors
set number
set tabstop=4 
set shiftwidth=4
set expandtab 
set autoindent
set smartindent
command! Wq wq
command! WQ wq
command! W w
set relativenumber
