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
Plug 'sbdchd/neoformat'
Plug 'wakatime/vim-wakatime'
call plug#end()

let mapleader = " "

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
local lspconfig = require('lspconfig')
lspconfig.clangd.setup{
    on_attach = function(client, bufnr)
        require('cmp').setup.buffer { 
            sources = {
                { name = 'nvim_lsp' },
            }
        }
    end,
    capabilities = {
        textDocument = {
            hover = {
                dynamicRegistration = false,
            },
        },
    },
}


require'toggleterm'.setup()
local lspconfig = require'lspconfig'

local on_attach = function(client)
    require'completion'.on_attach(client)
end
lspconfig.bashls.setup{}
require("lspconfig").rust_analyzer.setup({
    settings = {
        ["rust-analyzer"] = {
            diagnostics = {
                enableExperimental = true,
            },
            checkOnSave = {
                command = "clippy",
            },
            cargo = {
                allFeatures = true,
                buildScripts = {
                    enable = true,
                },
            },
            procMacro = {
                enable = true,
            },
            analysis = {
                enable = true,
                ignoreInactiveCode = false,
            },
            imports = {
                granularity = {
                    group = "module",
                },
                prefix = "self",
            },
        },
    },
    root_dir = function(fname)
        return require("lspconfig.util").root_pattern("Cargo.toml", "rust-project.json", ".git")(fname)
            or vim.fn.getcwd() 
    end,
    single_file_support = true,
})

lspconfig.rust_analyzer.setup({
    on_attach = function(client, bufnr)
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end
})


vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = "rounded",
})

local original_hover = vim.lsp.handlers["textDocument/hover"]

vim.lsp.handlers["textDocument/hover"] = function(_, result, ctx, config)
    local cmp = require'cmp'
    if cmp.visible() then
        cmp.close()
    end
  
    if original_hover then
        original_hover(_, result, ctx, config)
    end
end

local lsp_buf_hover = function()
    if vim.fn.pumvisible() == 1 then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-e>", true, true, true), "n")
    end
    vim.lsp.buf.hover()
end

local cmp = require'cmp'
cmp.setup({
    snippet = {
        expand = function(args)
        end,
    },
    
    completion = {
        completeopt = 'menu,menuone,noselect',
        max_items = 10,
        min_length = 1,
        timeout = 100, 
    },
    mapping = {
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
        ['<C-l>'] = cmp.mapping(lsp_buf_hover, { 'i', 's' }),
        ['<C-Space>'] = cmp.mapping.complete(),
    },

    sources = {
        { name = 'nvim_lsp',  max_item_count = 10 },
        { name = 'buffer', max_item_count = 10 },
        { name = 'path', max_item_count = 10 },
    },
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },

})

vim.api.nvim_set_keymap('n', '<leader>f', ':Neoformat<CR>', { noremap = true, silent = true })

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
