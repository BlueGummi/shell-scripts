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
Plug 'Mofiqul/vscode.nvim'
Plug 'lewis6991/satellite.nvim'

call plug#end()

set laststatus=0

autocmd VimEnter * ++once call s:EnableAirlineAfterStartup()
function! s:EnableAirlineAfterStartup()
  set laststatus=2
  AirlineRefresh
endfunction


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
local cmp = require('cmp')
local cmp_lsp = require('cmp_nvim_lsp')

lspconfig.clangd.setup{
    capabilities = cmp_lsp.default_capabilities(),
    on_attach = function(client, bufnr)
        cmp.setup.buffer {
            sources = {
                { name = 'nvim_lsp', max_item_count = 10 },
            }
        }
    end,
}

local nvim_lsp = require('lspconfig')

nvim_lsp.svls.setup {
  cmd = {"svls"},
  filetypes = {"verilog", "systemverilog", "sv"},
  root_dir = nvim_lsp.util.root_pattern('.git', '.'),
  settings = {},
  on_attach = function(client, bufnr)
  end,
}

vim.diagnostic.config({
  virtual_text = true,
  signs = true,       
  underline = true,
  update_in_insert = false,
})


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

require'lspconfig'.pylsp.setup{}

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
        {
            name = 'nvim_lsp',
            entry_filter = function(entry)
                return true
            end,
            max_item_count = 10,
        },
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

local lsp_active = false

function toggle_lsp()
    vim.lsp.stop_client(vim.lsp.get_active_clients())
    lsp_active = false
end

vim.api.nvim_set_keymap('n', '<F1>', ':lua toggle_lsp()<CR>', { noremap = true, silent = true })
local uv = vim.loop
local last_weather = ""
local last_update = 0
local weather_timer = nil
local cache_path = "/tmp/nvim_weather_cache"
local sun_cache_path = "/tmp/nvim_sun_cache"
local sunrise, sunset = nil, nil

local function load_weather_cache()
  local f = io.open(cache_path, "r")
  if f then
    local data = f:read("*a")
    f:close()
    if data and data ~= "" then
      last_weather = data:gsub("\n", "")
    end
  end
end

local function save_weather_cache()
  local ok, f = pcall(io.open, cache_path, "w")
  if ok and f then
    f:write(last_weather)
    f:close()
  end
end

local function parse_sun_times(data)
  -- wttr.in?format=%S+%s gives sunrise/sunset in HH:MM format (local time)
  local sr, ss = data:match("(%d+:%d+)%s+(%d+:%d+)")
  if sr and ss then
    sunrise, sunset = sr, ss
    return true
  end
  return false
end

local function save_sun_cache()
  if not sunrise or not sunset then return end
  local f = io.open(sun_cache_path, "w")
  if f then
    f:write(string.format("%s %s\n", sunrise, sunset))
    f:close()
  end
end

local function load_sun_cache()
  local f = io.open(sun_cache_path, "r")
  if f then
    local data = f:read("*a")
    f:close()
    parse_sun_times(data)
  end
end

local function sun_cache_stale()
  local stat = uv.fs_stat(sun_cache_path)
  if not stat then return true end
  -- refresh if older than 6 hours (sunrise/sunset don’t shift much)
  return (os.time() - stat.mtime.sec) > (6 * 3600)
end

local function update_sun_times()
  if not sun_cache_stale() then
    load_sun_cache()
    return
  end

  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local data = ""
  local handle
  handle = uv.spawn("curl", {
    args = { "-s", "--max-time", "3", "wttr.in?format=%S+%s" },
    stdio = { nil, stdout, stderr },
  }, function(code)
    vim.defer_fn(function()
      stdout:close()
      stderr:close()
      handle:close()
      if code == 0 and data and data ~= "" and parse_sun_times(data) then
        save_sun_cache()
      end
    end, 100)
  end)
  stdout:read_start(function(err, chunk)
    if chunk then data = data .. chunk end
  end)
  stderr:read_start(function() end)
end

local function is_daytime()
  if not (sunrise and sunset) then
    load_sun_cache()
    if not (sunrise and sunset) then
      update_sun_times()
      return true  -- default to day if unknown
    end
  end

  local function to_minutes(t)
    local h, m = t:match("(%d+):(%d+)")
    return tonumber(h) * 60 + tonumber(m)
  end

  local now = os.date("*t")
  local now_m = now.hour * 60 + now.min
  local sr_m = to_minutes(sunrise)
  local ss_m = to_minutes(sunset)

  return now_m >= sr_m and now_m < ss_m
end

local function get_weather_icon(temp, cond)
  if not cond or cond == "" then return "🌡️" end
  cond = cond:lower()
  local day = is_daytime()

  if cond:match("thunder") or cond:match("storm") or cond:match("lightning") then
    return "⛈️"
  elseif cond:match("rain") or cond:match("drizzle") then
    if cond:match("light") then
      return "🌦️"
    elseif cond:match("heavy") then
      return "🌧️"
    else
      return "🌦️"
    end
  elseif cond:match("snow") or cond:match("sleet") or cond:match("flurr") then
    if cond:match("light") then
      return "🌨️"
    elseif cond:match("heavy") then
      return "❄️"
    else
      return "🌨️"
    end
  elseif cond:match("hail") then
    return "🧊"
  elseif cond:match("fog") or cond:match("mist") or cond:match("haze") or cond:match("smoke") then
    return "🌫️"
  elseif cond:match("overcast") then
    return "☁️"
  elseif cond:match("partly") or cond:match("cloud") then
    return day and "🌤️" or "☁️"
  elseif cond:match("clear") or cond:match("sun") then
    return day and "☀️" or "🌙"
  elseif cond:match("wind") or cond:match("breeze") or cond:match("gust") then
    return "💨"
  elseif cond:match("tornado") or cond:match("cyclone") or cond:match("funnel") then
    return "🌪️"
  elseif cond:match("dust") or cond:match("sand") then
    return "🏜️"
  elseif cond:match("ice") or cond:match("freez") then
    return "🧊"
  else
    return "🌡️"
  end
end

local function update_weather_async()
  if weather_timer then weather_timer:stop() end
  weather_timer = uv.new_timer()

  local function fetch_weather()
    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)
    local data = ""
    local handle
    handle = uv.spawn("curl", {
      args = { "-s", "--max-time", "2", "wttr.in?format=%t+%C" },
      stdio = { nil, stdout, stderr },
    }, function(code)
      vim.defer_fn(function()
        stdout:close()
        stderr:close()
        handle:close()
        if code == 0 and data ~= "" and not data:match("Unknown location") then
          last_weather = data:gsub("\n", "")
          last_update = os.time()
          save_weather_cache()
          vim.schedule(function() vim.cmd("redrawstatus") end)
        end
      end, 100)
    end)
    stdout:read_start(function(err, chunk)
      if chunk then data = data .. chunk end
    end)
    stderr:read_start(function() end)
  end

  fetch_weather()
  weather_timer:start(600000, 600000, fetch_weather)
end

function _G.StatusWeather()
  local temp, cond = last_weather:match("([%+%-]?%d+°[CF])%s*(.*)")
  local icon = get_weather_icon(temp or "", cond or "")
  if temp and cond then
    return string.format("%s %s %s %s", icon, cond, temp, os.date("%m/%d %I:%M %p"))
  else
    return os.date("%m/%d %I:%M %p")
  end
end

local function schedule_time_updates()
  vim.defer_fn(function()
    vim.cmd("redrawstatus")
    schedule_time_updates()
  end, 60000)
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    load_weather_cache()
    update_weather_async()
    update_sun_times()
    schedule_time_updates()
  end,
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
let g:airline_theme = 'molokai'
let g:powerline_pycmd = 'python3'
let g:airline#extensions#tabline#formatter = 'default'
let g:airline_powerline_fonts = 1
let g:webdevicons_enable_airline_tabline = 1
let g:webdevicons_enable_airline_statusline = 1
colorscheme cyberdream 

function! AirlineWeather()
  return luaeval('StatusWeather()')
endfunction

let g:airline_section_z = '%{AirlineWeather()}'

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

let g:neoformat_verilog_verible = {
      \ 'exe': 'verible-verilog-format',
      \ 'args': ['--indentation_spaces=4 -'],
      \ 'stdin': 1,
      \ }
let g:neoformat_enabled_verilog = ['verible']
