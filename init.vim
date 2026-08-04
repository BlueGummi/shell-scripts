" ╔═══════════════════════════════════════════════════════════════════════════╗
" ║  init.vim — table of contents.  Jump with:  /SECTION: <name>               ║
" ╟───────────────────────────────────────────────────────────────────────────╢
" ║  Plugins ............ vim-plug plugin list                                 ║
" ║  Early setup ........ airline boot, filetype, mapleader                    ║
" ║  Copilot ............ copilot.lua + suggestion keymaps                     ║
" ║  ClaudeCode ......... claudecode.nvim CLI bridge + <leader>C keymaps        ║
" ║  Completion ......... nvim-cmp mappings                                    ║
" ║  Todo-comments                                                             ║
" ║  Treesitter                                                                ║
" ║  Aerial ............. symbols outline                                      ║
" ║  Colorscheme ........ cyberdream setup (transparent)                       ║
" ║  LSP ................ lsp servers + cmp/lsp glue                           ║
" ║  Which-key .......... group/label registrations                           ║
" ║  Gitsigns                                                                  ║
" ║  Telescope .......... pickers (setup in lua block)                         ║
" ║  Bufferline ......... the tab bar + drag-order persistence                 ║
" ║  Session ............ persistence.nvim (sticky per-dir restore)            ║
" ║  Editing ............ comment / flash / autopairs / indent / surround      ║
" ║  Trouble ............ diagnostics/quickfix panel                           ║
" ║  Build .............. cmake-tools (primary) + overseer (ad-hoc)            ║
" ║  Vimscript fns ...... comment-block converter, airline helpers             ║
" ║  NERDTree                                                                  ║
" ║  Telescope keymaps                                                         ║
" ║  Airline ............ statusline config                                    ║
" ║  Editor options ..... set … (tabs, undo, numbers, shada)                   ║
" ╚═══════════════════════════════════════════════════════════════════════════╝

" ═══════════════════════════ SECTION: Plugins ═══════════════════════════
call plug#begin('~/.local/share/nvim/plugged')

Plug 'nvim-telescope/telescope-frecency.nvim'
Plug 'folke/which-key.nvim'
Plug 'stevearc/stickybuf.nvim'
Plug 'zbirenbaum/copilot.lua'
Plug 'coder/claudecode.nvim'
Plug 'tpope/vim-sensible'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'vim-airline/vim-airline'
Plug 'ryanoasis/vim-devicons'
Plug 'vim-airline/vim-airline-themes'
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'preservim/nerdtree'
Plug 'scottmckendry/cyberdream.nvim'
Plug 'sbdchd/neoformat'
Plug 'wakatime/vim-wakatime'
Plug 'lewis6991/satellite.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' }
Plug 'nvim-lua/plenary.nvim'
Plug 'lewis6991/gitsigns.nvim'
Plug 'stevearc/aerial.nvim'
Plug 'mrcjkb/rustaceanvim'
Plug 'folke/todo-comments.nvim'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'akinsho/bufferline.nvim', { 'tag': '*' }
Plug 'folke/persistence.nvim'
Plug 'numToStr/Comment.nvim'
Plug 'folke/flash.nvim'
Plug 'windwp/nvim-autopairs'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'kylechui/nvim-surround', { 'tag': '*' }
Plug 'folke/trouble.nvim'
Plug 'stevearc/overseer.nvim'
Plug 'Civitasv/cmake-tools.nvim'

call plug#end()

" ═══════════════════════════ SECTION: Early setup ═══════════════════════════
autocmd VimEnter * ++once call s:EnableAirlineAfterStartup()
function! s:EnableAirlineAfterStartup()
  set laststatus=2
  AirlineRefresh
endfunction

autocmd BufNewFile,BufRead *.sh set filetype=sh

let mapleader = " "

lua << EOF
-- ═══════════════════════════ SECTION: Copilot ═══════════════════════════
local copilot = require("copilot")

copilot.setup({
  suggestion = {
    enabled = true,
    auto_trigger = true,
    debounce = 60,
    keymap = { accept = false },
  },
  panel = { enabled = false },
  server_opts_overrides = {
    settings = {
      advanced = {
        inlineSuggestCount = 1,
        listCount = 3,
      }
    }
  }
})

local suggestion = require("copilot.suggestion")

local function after_member_access()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before_cursor = line:sub(1, col)
  return before_cursor:match("[%.%-:][%w_]*$") ~= nil
end

local function should_suppress_copilot()
  local line = vim.api.nvim_get_current_line()
  local is_blank = line:match("^%s*$") ~= nil
  return is_blank or after_member_access()
end

vim.keymap.set("i", "<Tab>", function()
  local line = vim.api.nvim_get_current_line()
  local is_blank = line:match("^%s*$") ~= nil

  if suggestion.is_visible() and not is_blank then
    suggestion.accept_line()
    return ""
  elseif require("cmp").visible() then
    require("cmp").confirm({ select = true })
    return ""
  else
    return "<Tab>"
  end
end, { expr = true, silent = true, desc = "Accept copilot line / confirm completion / indent" })

vim.keymap.set("i", "<C-j>", function()
  if suggestion.is_visible() then
    suggestion.accept()
  end
end, { silent = true, desc = "Accept full copilot suggestion" })

local state_path = "/tmp/nvim_copilot_disabled"

local function load_copilot_state()
  local f = io.open(state_path, "r")
  if f then
    local val = f:read("*a"):gsub("\n", "")
    f:close()
    return val == "true"
  end
  return false
end

local function save_copilot_state(disabled)
  local f = io.open(state_path, "w")
  if f then
    f:write(tostring(disabled))
    f:close()
  end
end

local copilot_user_disabled = load_copilot_state()

vim.keymap.set("n", "<leader>d", function()
  copilot_user_disabled = not copilot_user_disabled
  save_copilot_state(copilot_user_disabled)
  if copilot_user_disabled then
    suggestion.dismiss()
    vim.b.copilot_suggestion_auto_trigger = false
  else
    vim.b.copilot_suggestion_auto_trigger = true
  end
  vim.cmd("redrawstatus")
end, { desc = "Toggle Copilot suggestions" })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if copilot_user_disabled then
      vim.b.copilot_suggestion_auto_trigger = false
    end
    vim.cmd("redrawstatus")
  end,
})

vim.api.nvim_create_autocmd({ "InsertEnter", "CursorMovedI", "TextChangedI" }, {
  callback = function()
    if copilot_user_disabled or should_suppress_copilot() then
      suggestion.dismiss()
      vim.b.copilot_suggestion_auto_trigger = false
    else
      vim.b.copilot_suggestion_auto_trigger = true
    end
  end,
})

-- ═══════════════════════════ SECTION: ClaudeCode ═══════════════════════════
-- Runs the Claude Code CLI in a split, wired over the same protocol as the
-- official editor extensions. Selection-aware: visually select, <leader>Cs, and
-- the range is sent as an @-mention so Claude sees exactly what the cursor is on.
require("claudecode").setup({})

vim.keymap.set('n', '<leader>Cc', '<cmd>ClaudeCode<CR>',          { desc = "Toggle Claude" })
vim.keymap.set('n', '<leader>Cf', '<cmd>ClaudeCodeFocus<CR>',    { desc = "Focus Claude window" })
vim.keymap.set('n', '<leader>Cr', '<cmd>ClaudeCode --resume<CR>',   { desc = "Resume a past session" })
vim.keymap.set('n', '<leader>CC', '<cmd>ClaudeCode --continue<CR>', { desc = "Continue last session" })
vim.keymap.set('n', '<leader>Cb', '<cmd>ClaudeCodeAdd %<CR>',    { desc = "Add current buffer to context" })
vim.keymap.set({ 'n', 'v' }, '<leader>Cs', '<cmd>ClaudeCodeSend<CR>', { desc = "Send selection / cursor context" })
vim.keymap.set('n', '<leader>Ca', '<cmd>ClaudeCodeDiffAccept<CR>',    { desc = "Accept proposed diff" })
vim.keymap.set('n', '<leader>Cd', '<cmd>ClaudeCodeDiffDeny<CR>',      { desc = "Reject proposed diff" })

-- ═══════════════════════════ SECTION: Todo-comments ═══════════════════════════
require("todo-comments").setup {
  signs = true,
  keywords = {
    FIX = { icon = " ", color = "error" },
    TODO = { icon = " ", color = "info" },
    HACK = { icon = " ", color = "warning" },
    WARN = { icon = " ", color = "warning" },
    PERF = { icon = " ", color = "hint" },
    NOTE = { icon = " ", color = "hint" },
    BUG =  { icon = " ", color = "error" },
  },
}

vim.api.nvim_create_autocmd({"InsertEnter", "InsertLeave"}, {
  callback = function()
    vim.cmd("redrawstatus")
  end,
})

function _G.CopilotStatus()
  local auto = vim.b.copilot_suggestion_auto_trigger
  local disabled = (auto == false) or (auto == nil and copilot_user_disabled)
  if disabled then
    return " "
  else
    return " "
  end
end

-- ═══════════════════════════ SECTION: Treesitter ═══════════════════════════
require('nvim-treesitter').setup {
  ensure_installed = { "rust", "c", "gleam", "cpp", "markdown", "haskell", "python", "js" },
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
  },
}

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  callback = function(args)
    -- Bind to args.buf, not the current buffer: LSP renames load the changed
    -- files as *background* buffers, so by the time this scheduled callback runs
    -- the current buffer is still the original. Without the explicit bufnr,
    -- vim.treesitter.start() would target the wrong buffer and the renamed files
    -- would open with no highlighting (BufReadPost won't fire again for them).
    vim.schedule(function()
      pcall(vim.treesitter.start, args.buf)
    end)
  end,
})

-- ═══════════════════════════ SECTION: Structural select ═══════════════════════════
-- Treesitter-driven visual selection biased toward whole structures, not tokens.
--   S     (normal)  → select the nearest enclosing STRUCTURAL node (struct/fn/block/if/loop)
--   gs    (normal)  → select the exact smallest node under the cursor (literal fallback)
--   <Tab> (visual)  → grow to the next structural ancestor
--   <S-Tab> (visual)→ shrink back down the remembered stack
-- nvim-treesitter's main branch dropped the incremental_selection module, so this is
-- hand-rolled on the core vim.treesitter API.
local ts_sel = {}

-- A node counts as a "structure" if it is a named node spanning more than one
-- line — i.e. it has a body (function, struct, block, if/loop, table, class...).
-- Language-agnostic: works for any grammar treesitter can parse, with no
-- per-language node-type list to maintain.
local function is_structural(node)
  if not node:named() then return false end
  local sr, _, er, _ = node:range()
  return er > sr
end

-- Per-window shrink stack: previous ranges to fall back to on <S-Tab>.
local ts_stacks = {}

local function clampcol(row, col)
  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
  return math.max(math.min(col, #line), 0)
end

local function node_range(node)
  local sr, sc, er, ec = node:range()
  return { sr, sc, er, ec }  -- end-exclusive, 0-based
end

-- Visually select an end-exclusive range; converts to charwise-inclusive for vim.
local function select_range(r)
  if vim.fn.mode():match("[vV\022]") then
    vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
  end
  local sr, sc, er, ec = r[1], r[2], r[3], r[4]
  if ec == 0 and er > sr then
    er = er - 1
    local line = vim.api.nvim_buf_get_lines(0, er, er + 1, false)[1] or ""
    ec = math.max(#line - 1, 0)
  else
    ec = math.max(ec - 1, 0)
  end
  vim.api.nvim_win_set_cursor(0, { sr + 1, clampcol(sr, sc) })
  vim.cmd("normal! v")
  vim.api.nvim_win_set_cursor(0, { er + 1, clampcol(er, ec) })
end

-- Current visual selection as an end-exclusive range (call while still in visual mode).
local function current_visual_range()
  local s = vim.fn.getpos("v")
  local e = vim.fn.getpos(".")
  local sr, sc = s[2] - 1, clampcol(s[2] - 1, s[3] - 1)
  local er, ec = e[2] - 1, clampcol(e[2] - 1, e[3] - 1)
  if sr > er or (sr == er and sc > ec) then sr, sc, er, ec = er, ec, sr, sc end
  return { sr, sc, er, ec + 1 }
end

local function le(ar, ac, br, bc) return ar < br or (ar == br and ac <= bc) end

-- outer strictly contains inner (both end-exclusive)
local function contains_larger(outer, inner)
  local same = outer[1] == inner[1] and outer[2] == inner[2]
    and outer[3] == inner[3] and outer[4] == inner[4]
  return not same
    and le(outer[1], outer[2], inner[1], inner[2])
    and le(inner[3], inner[4], outer[3], outer[4])
end

-- Nearest structural ancestor strictly containing `base`.
local function structural_from(base)
  local node = vim.treesitter.get_node({ pos = { base[1], base[2] } })
  while node do
    if is_structural(node) and contains_larger(node_range(node), base) then
      return node_range(node)
    end
    node = node:parent()
  end
  return nil
end

function ts_sel.smart()
  local win = vim.api.nvim_get_current_win()
  local base, fresh
  if vim.fn.mode():match("[vV\022]") then
    base, fresh = current_visual_range(), false
  else
    local cur = vim.api.nvim_win_get_cursor(0)
    base, fresh = { cur[1] - 1, cur[2], cur[1] - 1, cur[2] }, true
  end
  local nr = structural_from(base)
  if not nr then  -- no structural ancestor (odd langs): just go one node up
    local node = vim.treesitter.get_node({ pos = { base[1], base[2] } })
    if node and node:parent() then nr = node_range(node:parent())
    elseif node then nr = node_range(node) end
  end
  if not nr then return end
  if fresh then ts_stacks[win] = {} end
  ts_stacks[win] = ts_stacks[win] or {}
  table.insert(ts_stacks[win], base)
  select_range(nr)
end

function ts_sel.literal()
  local cur = vim.api.nvim_win_get_cursor(0)
  local node = vim.treesitter.get_node({ pos = { cur[1] - 1, cur[2] } })
  if not node then return end
  ts_stacks[vim.api.nvim_get_current_win()] =
    { { cur[1] - 1, cur[2], cur[1] - 1, cur[2] } }
  select_range(node_range(node))
end

function ts_sel.shrink()
  local st = ts_stacks[vim.api.nvim_get_current_win()]
  if not st or #st == 0 then return end
  local prev = table.remove(st)
  if prev[1] == prev[3] and prev[2] == prev[4] then  -- back to a bare cursor: exit visual
    vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
    vim.api.nvim_win_set_cursor(0, { prev[1] + 1, clampcol(prev[1], prev[2]) })
  else
    select_range(prev)
  end
end

vim.keymap.set("n", "S", ts_sel.smart,           { silent = true, desc = "Select structure (smart)" })
vim.keymap.set("n", "gs", ts_sel.literal,        { silent = true, desc = "Select node under cursor (literal)" })
vim.keymap.set("x", "<Tab>", ts_sel.smart,       { silent = true, desc = "Grow structural selection" })
vim.keymap.set("x", "<S-Tab>", ts_sel.shrink,    { silent = true, desc = "Shrink structural selection" })

-- ═══════════════════════════ SECTION: Aerial (symbols) ═══════════════════════════
require('aerial').setup({
  filter_kind = false,
  layout = {
    default_direction = 'right',
    min_width = 30,
  },
  show_guides = true,
  nerd_font = true,
  post_parse_symbol = nil,
  manage_folds = false,
  link_folds_to_tree = false,
  link_tree_to_cursor = true,
  arrange_symbols = function(symbols, opts)
    local grouped = { Struct = {}, Enum = {}, Function = {}, Other = {} }
    for _, sym in ipairs(symbols) do
      if grouped[sym.kind] then
        table.insert(grouped[sym.kind], sym)
      else
        table.insert(grouped.Other, sym)
      end
    end
    local result = {}
    for _, group in ipairs({ "Struct", "Enum", "Function", "Other" }) do
      for _, sym in ipairs(grouped[group]) do
        table.insert(result, sym)
      end
    end
    return result
  end,
})

vim.keymap.set('n', '<leader>aa', '<cmd>AerialToggle! right<CR>', { desc = "Toggle symbols outline" })
vim.keymap.set('n', '<leader>as', '<cmd>Telescope aerial<CR>', { desc = "Search symbols (Telescope)" })

-- ═══════════════════════════ SECTION: Colorscheme (cyberdream) ═══════════════════════════
require("cyberdream").setup({
    transparent = true,
})

-- ═══════════════════════════ SECTION: LSP (servers + completion glue) ═══════════════════════════
local cmp = require('cmp')
local cmp_lsp = require('cmp_nvim_lsp')

vim.lsp.config("clangd", {
    cmd = {
        "clangd",
        "--clang-tidy",
        "--background-index",
        "--header-insertion=iwyu",
        "--enable-config",
    },
    capabilities = cmp_lsp.default_capabilities(),
    on_attach = function(client, bufnr)
        -- require here: the `local cmp` below is declared later in this chunk, so
        -- referencing it directly would resolve to the (nil) global and error.
        require('cmp').setup.buffer {
            sources = {
                { name = 'nvim_lsp', max_item_count = 15 },
            }
        }
    end,
})
vim.lsp.enable({"clangd"})

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
})

vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
    pattern = "*",
    callback = function()
        vim.diagnostic.setloclist({open=false})
    end
})

vim.lsp.config.bashls = {
  cmd = { 'bash-language-server', 'start' },
  filetypes = { 'bash', 'sh' }
}
vim.lsp.enable 'bashls'

vim.g.rustaceanvim = {
  server = {
    on_attach = on_attach,
    settings = {
        ["rust-analyzer"] = {
            lru = { capacity = 512 },
            updates = { rateLimit = 0 },
            diagnostics = {
                enableExperimental = true,
            },
            check = {
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
  },
}

vim.lsp.config("pylsp", {})
vim.lsp.enable({"pylsp"})

-- vim.lsp.with was removed; hover/signature_help now take opts directly
local hover = vim.lsp.buf.hover
vim.lsp.buf.hover = function(opts)
    return hover(vim.tbl_extend("force", { border = "rounded" }, opts or {}))
end

local signature_help = vim.lsp.buf.signature_help
vim.lsp.buf.signature_help = function(opts)
    return signature_help(vim.tbl_extend("force", { border = "rounded" }, opts or {}))
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
            max_item_count = 20,
        },
        { name = 'buffer', max_item_count = 20 },
        { name = 'path', max_item_count = 20 },
    },

    window = {
      completion = cmp.config.window.bordered({
        border = "rounded",
        winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None",
      }),
      documentation = cmp.config.window.bordered({
        border = "rounded",
        winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
      }),
    },
})

vim.api.nvim_set_keymap('n', '<leader>ff', ':Neoformat<CR>', { noremap = true, silent = true, desc = "Format file (Neoformat)" })

vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = "Exit terminal mode" })
vim.filetype.add({
    extension = {
        mdx = "markdown",
    },
})

local lsp_active = false

function toggle_lsp()
    vim.lsp.stop_client(vim.lsp.get_clients())
    lsp_active = false
end

-- ═══════════════════════════ SECTION: Which-key ═══════════════════════════
local wk = require('which-key')
wk.setup({ delay = 400, win = { border = "rounded" } })

vim.api.nvim_create_autocmd("User", {
  pattern = "WhichKeyClose",
  callback = function()
    vim.cmd("AirlineRefresh")
  end,
})

-- which-key group labels
local wk = require('which-key')
wk.add({
  { "<leader>a", group = "aerial/symbols" },
  { "<leader>f", group = "find/format" },
  { "<leader>h", group = "git hunks" },
  { "<leader>t", group = "toggles" },
  { "<leader>q", group = "session" },
  { "<leader>x", group = "trouble/diagnostics" },
  { "<leader>o", group = "overseer/tasks" },
  { "<leader>c", group = "cmake" },
  { "<leader>C", group = "claude" },
  { "<leader>Cs", desc = "Send selection / cursor context", mode = "v" },
  { "<leader>fs", desc = "LSP: symbol by name (project)" },
  { "<leader>fd", desc = "LSP: definitions" },
  { "<leader>fr", desc = "LSP: references (usages)" },
  { "<leader>ft", desc = "LSP: type definition" },
  { "<leader>fc", desc = "LSP: incoming calls (callers)" },
  { "<leader>fC", desc = "LSP: outgoing calls (callees)" },
  { "S", desc = "Select structure (smart)" },
  { "gs", desc = "Select node under cursor (literal)" },
  { "<Tab>", desc = "Grow structural selection", mode = "x" },
  { "<S-Tab>", desc = "Shrink structural selection", mode = "x" },
  { "<leader>b", desc = "CMake build" },
  { "<leader>?", desc = "Show all keybinds" },
  { "<leader>g", desc = "NERDTree: find current file" },
  { "<leader>G", desc = "NERDTree: toggle" },
  { "<leader>n", desc = "NERDTree: focus" },
  { "<leader>d", desc = "Toggle Copilot" },
  { "<leader>[", desc = "Previous buffer" },
  { "<leader>]", desc = "Next buffer" },
  { "<leader>1", desc = "Go to buffer 1" },
  { "<leader>2", desc = "Go to buffer 2" },
  { "<leader>3", desc = "Go to buffer 3" },
  { "<leader>4", desc = "Go to buffer 4" },
  { "<leader>5", desc = "Go to buffer 5" },
  { "<leader>6", desc = "Go to buffer 6" },
  { "<leader>7", desc = "Go to buffer 7" },
  { "<leader>8", desc = "Go to buffer 8" },
  { "<leader>9", desc = "Go to last buffer" },
  { "<leader>c", desc = "Convert // comments to /* */ (visual)", mode = "v" },
  { "]c", desc = "Next git hunk" },
  { "[c", desc = "Prev git hunk" },
  { "<F1>", desc = "Stop LSP clients" },
  { "<F5>", desc = "Strip trailing whitespace" },
})

-- ═══════════════════════════ SECTION: Gitsigns ═══════════════════════════
require('gitsigns').setup{
  on_attach = function(bufnr)
    local gitsigns = require('gitsigns')

    local function map(mode, l, r, desc)
      vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
    end

    -- Navigation
    map('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal({']c', bang = true})
      else
        gitsigns.nav_hunk('next')
      end
    end, "Next git hunk")

    map('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal({'[c', bang = true})
      else
        gitsigns.nav_hunk('prev')
      end
    end, "Prev git hunk")

    -- Actions
    map('n', '<leader>hs', gitsigns.stage_hunk, "Stage hunk")
    map('n', '<leader>hr', gitsigns.reset_hunk, "Reset hunk")

    map('v', '<leader>hs', function()
      gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, "Stage selected hunk")

    map('v', '<leader>hr', function()
      gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, "Reset selected hunk")

    map('n', '<leader>hS', gitsigns.stage_buffer, "Stage buffer")
    map('n', '<leader>hR', gitsigns.reset_buffer, "Reset buffer")
    map('n', '<leader>hp', gitsigns.preview_hunk, "Preview hunk")
    map('n', '<leader>hi', gitsigns.preview_hunk_inline, "Preview hunk inline")

    map('n', '<leader>hb', function()
      gitsigns.blame_line({ full = true })
    end, "Blame line (full)")

    map('n', '<leader>hd', gitsigns.diffthis, "Diff this")

    map('n', '<leader>hD', function()
      gitsigns.diffthis('~')
    end, "Diff against last commit")

    map('n', '<leader>hQ', function() gitsigns.setqflist('all') end, "All hunks to quickfix")
    map('n', '<leader>hq', gitsigns.setqflist, "Buffer hunks to quickfix")

    -- Toggles
    map('n', '<leader>tb', gitsigns.toggle_current_line_blame, "Toggle line blame")
    map('n', '<leader>tw', gitsigns.toggle_word_diff, "Toggle word diff")

    -- Text object
    vim.keymap.set({'o', 'x'}, 'ih', gitsigns.select_hunk, { buffer = bufnr, desc = "Select hunk (text object)" })
  end
}

-- Claim <LeftMouse> before satellite.setup() runs. Satellite maps it in n/v/o/i
-- (satellite.lua: `if maparg('<leftmouse>') == ''`) to drive click-to-scroll on
-- the scrollbar; a click in the bottom rows of that column sets topline to the
-- last buffer line, and the handler blocks in getchar() until a <LeftRelease>,
-- swallowing keystrokes meanwhile. Pre-empting the map keeps the scrollbar and
-- its gitsigns/diagnostic/aerial handlers, minus the click hijack.
vim.keymap.set({ 'n', 'v', 'o', 'i' }, '<LeftMouse>', '<LeftMouse>', { noremap = true })

require('satellite').setup({
  current_only = false,
  winblend = 50,
  handlers = {
    aerial = { enable = true },
    gitsigns = { enable = true },
    diagnostic = { enable = true },
  },
})
require("stickybuf").setup()

vim.api.nvim_set_keymap('n', '<F1>', ':lua toggle_lsp()<CR>', { noremap = true, silent = true, desc = "Stop LSP clients" })

local uv = vim.loop
local last_weather = ""
local last_update = 0
local weather_timer = nil
local cache_path = "/tmp/nvim_weather_cache"
local sun_cache_path = "/tmp/nvim_sun_cache"
local moon_cache_path = "/tmp/nvim_moon_cache"
local sunrise, sunset = nil, nil
local last_moon = ""

local moon_emoji_to_nf = {
  ["🌑"] = "",
  ["🌒"] = "",
  ["🌓"] = "",
  ["🌔"] = "",
  ["🌕"] = "",

  ["🌖"] = "",
  ["🌗"] = "",

  ["🌘"] = "",
}

local function moon_cache_stale()
  local stat = uv.fs_stat(moon_cache_path)
  if not stat then return true end
  return (os.time() - stat.mtime.sec) > (6 * 3600)
end

local function load_moon_cache()

  local f = io.open(moon_cache_path, "r")
  if f then

    local data = f:read("*a")
    f:close()
    if data and data ~= "" then
      last_moon = data:gsub("\n", ""):gsub("%s+", "")
    end
  end
end
 
local function save_moon_cache()
  local f = io.open(moon_cache_path, "w")
  if f then
    f:write(last_moon)
    f:close()
  end
end

 
local function update_moon_async()
  if not moon_cache_stale() then
    load_moon_cache()

    return
  end
 
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local data = ""
  local handle
  handle = uv.spawn("curl", {
    args = { "-s", "wttr.in?format=%m" },
    stdio = { nil, stdout, stderr },
  }, function(code)
    vim.defer_fn(function()
      stdout:close()

      stderr:close()
      handle:close()
      if code == 0 and data and data ~= "" then
        last_moon = data:gsub("\n", ""):gsub("%s+", "")
        save_moon_cache()
        vim.schedule(function() vim.cmd("redrawstatus") end)
      end
    end, 100)

  end)
  stdout:read_start(function(err, chunk)
    if chunk then data = data .. chunk end
  end)
  stderr:read_start(function() end)
end
 
local function get_moon_icon()
  if last_moon == "" then return "" end
  return moon_emoji_to_nf[last_moon] or last_moon
end

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
  -- wttr.in?format=%S+%s gives sunrise/sunset in HH:MM:SS format (local time)
  local sr, ss = data:match("(%d+:%d+:%d*):?%s+(%d+:%d+:%d*):?")
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
  -- refresh if older than 6 hours (sunrise/sunset don't shift much)
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
    args = { "-s", "wttr.in?format=%S+%s" },
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

  local icon
  if cond:match("thunder") or cond:match("storm") or cond:match("lightning") then
    icon = ""
  elseif cond:match("rain") or cond:match("drizzle") then
    if cond:match("light") then
      icon = ""
    elseif cond:match("heavy") then
      icon = ""
    else
      icon = ""
    end
  elseif cond:match("snow") or cond:match("sleet") or cond:match("flurr") then
    if cond:match("light") then
      icon = ""
    elseif cond:match("heavy") then
      icon = ""
    else
      icon = ""
    end
  elseif cond:match("hail") then
    icon = ""
  elseif cond:match("fog") or cond:match("mist") or cond:match("haze") or cond:match("smoke") then
    icon = ""
  elseif cond:match("overcast") then
    icon = ""
  elseif cond:match("partly") or cond:match("cloud") then
    icon = day and "" or ""
  elseif cond:match("clear") or cond:match("sun") then
    icon = day and "" or ""
  elseif cond:match("wind") or cond:match("breeze") or cond:match("gust") then
    icon = ""
  elseif cond:match("tornado") or cond:match("cyclone") or cond:match("funnel") then
    icon = ""
  elseif cond:match("dust") or cond:match("sand") then
    icon = ""
  elseif cond:match("ice") or cond:match("freez") then
    icon = ""
  else
    icon = ""
  end

  if not day and icon ~= "" then
    icon = " " .. icon
  end

  return icon
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
      args = { "-s", "wttr.in?format=%t+%C" },
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
  weather_timer:start(60000, 60000, fetch_weather)
end

function _G.StatusWeather()
  local temp, cond = last_weather:match("([%+%-]?%d+°[CF])%s*(.*)")
  local icon = get_weather_icon(temp or "", cond or "")
  local moon = get_moon_icon()
  local moon_str = moon ~= "" and (moon .. "  ") or ""
  if temp and cond then
    return string.format(" %s %s  %s  %s │ %s  ", moon_str, icon, cond, temp, os.date("%I:%M %p  %m/%d"))
  else
    return os.date("   %m/%d  %I:%M %p  ")
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
    load_moon_cache()
    update_weather_async()
    update_sun_times()
    update_moon_async()
    schedule_time_updates()
  end,
})

vim.opt.statuscolumn = "%s%=%l%#LineNr#│"
vim.api.nvim_create_autocmd("ModeChanged", {

  callback = function()
    vim.cmd("redrawstatus!")

    vim.cmd("redraw!")
  end,
})

-- Telescope: load fzf-native so filename matching uses smart-case. Without this
-- the built-in fzy sorter is always case-insensitive, so "CMake" and "cmake" both
-- match CMakeLists.txt. With smart_case, a lowercase query stays case-insensitive
-- but any uppercase letter makes the match case-sensitive.
local ok_telescope, telescope_mod = pcall(require, "telescope")
if ok_telescope then
  telescope_mod.setup({
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },
    },
  })
  pcall(telescope_mod.load_extension, "fzf")
end

local M = {}

local has_telescope, telescope = pcall(require, "telescope.builtin")
if not has_telescope then
  return M
end

local function get_project_root()
  local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if root == "" then
    root = vim.loop.cwd()
  end
  return root
end

local function get_search_text()
  local mode = vim.fn.mode()
  local text = ""

  if mode == "v" or mode == "V" then
    vim.cmd('normal! "vy')
    text = vim.fn.getreg('v')
  else
    text = vim.fn.expand("<cword>")
  end

  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  return text
end

function M.live_grep_project()
  local root = get_project_root()
  local default_text = get_search_text()

  telescope.live_grep({
    cwd = root,
    default_text = default_text,
  })
end

vim.keymap.set('n', 'fr', function()
  local root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  if not root or root == '' then
    root = vim.fn.getcwd()
  end
  require('telescope').extensions.frecency.frecency({
    cwd = root,
    workspace = 'CWD',
  })
end, { noremap = true, silent = true })

vim.keymap.set('v', '<leader>fg', M.live_grep_project, { noremap = true, silent = true, desc = "Live grep (visual selection)" })
vim.keymap.set('n', '<leader>fg', M.live_grep_project, { noremap = true, silent = true, desc = "Live grep project" })

-- LSP semantic search (clangd's project index, not raw text) — one picker per intent.
-- <leader>fs is the "grep, but symbols only" analog to <leader>fg: type a name, get
-- every matching symbol project-wide, tagged by kind, never a comment.
vim.keymap.set('n', '<leader>fs', telescope.lsp_dynamic_workspace_symbols, { desc = "LSP: symbol by name (project)" })
vim.keymap.set('n', '<leader>fd', telescope.lsp_definitions,               { desc = "LSP: definitions" })
vim.keymap.set('n', '<leader>fr', telescope.lsp_references,                { desc = "LSP: references (usages)" })
vim.keymap.set('n', '<leader>ft', telescope.lsp_type_definitions,          { desc = "LSP: type definition" })
vim.keymap.set('n', '<leader>fc', telescope.lsp_incoming_calls,            { desc = "LSP: incoming calls (callers)" })
vim.keymap.set('n', '<leader>fC', telescope.lsp_outgoing_calls,            { desc = "LSP: outgoing calls (callees)" })

vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = "Move to left window" })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = "Move to right window" })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = "Move to window below" })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = "Move to window above" })
vim.keymap.set('n', '<C-Left>',  '<C-w><', { desc = "Shrink window width" })
vim.keymap.set('n', '<C-Right>', '<C-w>>', { desc = "Grow window width" })
vim.keymap.set('n', '<C-Up>',    '<C-w>+', { desc = "Grow window height" })
vim.keymap.set('n', '<C-Down>',  '<C-w>-', { desc = "Shrink window height" })
vim.keymap.set('n', '<C-x>', ':bdelete<CR>', { noremap = true, silent = true, desc = 'Close buffer' })

-- Reopen the most recently closed file, browser-style ("undo close tab").
-- Neovim keeps no closed-buffer history, so track it ourselves: push every
-- real file's path onto a stack when its buffer is deleted, and pop on demand.
-- NB: Ctrl+Shift+X is only distinguishable from Ctrl+X in terminals that speak
-- the kitty keyboard protocol (kitty/WezTerm/Ghostty/foot) or in a GUI; a plain
-- terminal folds it into <C-x> (close). <leader>X is provided as a fallback.
local closed_files = {}
vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(args)
    local name = vim.api.nvim_buf_get_name(args.buf)
    if name ~= "" and vim.bo[args.buf].buftype == "" and vim.fn.filereadable(name) == 1 then
      -- de-dup: if it's already the top of the stack, don't stack it twice
      if closed_files[#closed_files] ~= name then closed_files[#closed_files + 1] = name end
    end
  end,
})
local function reopen_closed()
  local name = table.remove(closed_files)
  if name then
    vim.cmd.edit(vim.fn.fnameescape(name))
  else
    vim.notify("No recently closed file to reopen", vim.log.levels.INFO)
  end
end
vim.keymap.set('n', '<C-S-x>',   reopen_closed, { silent = true, desc = "Reopen most recently closed file" })
vim.keymap.set('n', '<leader>X', reopen_closed, { silent = true, desc = "Reopen most recently closed file" })

-- Cycle by the bufferline's *visual* order (respects drag-reorder + persisted
-- order), not buffer-number order like :bprev/:bnext would.
vim.keymap.set('n', '<leader>[', ':BufferLineCyclePrev<CR>', { silent = true, desc = "Previous buffer" })
vim.keymap.set('n', '<leader>]', ':BufferLineCycleNext<CR>', { silent = true, desc = "Next buffer" })

-- Jump straight to a buffer by its absolute position in the tabline (respects
-- drag-reorder + persisted order). <leader>9 goes to the last buffer.
-- Two gotchas, both fixed here:
--  1) Pass a *numeric* arg. The :BufferLineGoToBuffer command forwards its
--     argument as a string and go_to does list[num] with no coercion, so
--     list["1"] misses and it silently falls back to the LAST buffer.
--  2) Pass absolute=true. Without it go_to indexes state.visible_components --
--     the *scrolled/truncated* slice the tabline currently renders -- so when
--     the bar overflows and the left tabs scroll off, <leader>1 lands on the
--     leftmost *visible* tab (e.g. the 3rd real one), not the true 1st.
--     absolute=true indexes state.components, the full left-to-right order.
for i = 1, 8 do
  vim.keymap.set('n', '<leader>' .. i, function() require('bufferline').go_to(i, true) end,
    { silent = true, desc = "Go to buffer " .. i })
end
vim.keymap.set('n', '<leader>9', function() require('bufferline').go_to(-1, true) end,
  { silent = true, desc = "Go to last buffer" })

-- ═══════════════════════════ SECTION: Bufferline (tabs) ═══════════════════════════
-- Bufferline: a reorderable tabline (airline's tabline is disabled below).
-- ---- tab order: one path-keyed list, per directory, live and persisted ----
-- Tab order is identified by *path*, never by buffer number. That's the whole
-- design, and it's load-bearing: bufferline's own drag state (state.custom_sort)
-- is a list of bufnrs, and a bufnr dies with its buffer. Closing a tab dropped
-- it from that list, the next drag rewrote the list without it, and reopening
-- the file -- now an id bufferline has never ranked -- landed it at the far
-- right (buffers.lua get_updated_buffers sinks unranked ids to the end), so
-- every tab past its old slot shifted left for good. Worse, custom_sort makes
-- sorters.sort() bail early, so the first drag of a session silently switched
-- off the persisted order below and put a bufnr list in charge instead.
--
-- So: bl_order is the curated order and the only authority. A drag is folded
-- back into it (bl_sync_from_view) and custom_sort is cleared immediately, so
-- sort_by -- which reads paths -- stays in charge for the whole session. A
-- path survives close/reopen, so a tab's place does too.
local bl_order_file = vim.fn.stdpath("state") .. "/bufferline_order.json"
local bl_key = vim.fn.getcwd()  -- dir the loaded order belongs to; also the save key
local bl_order = {}             -- curated order: absolute paths, open or not
local bl_index = {}             -- path -> position in bl_order

local function bl_read_all()
  local f = io.open(bl_order_file, "r"); if not f then return {} end
  local d = f:read("*a"); f:close()
  local ok, t = pcall(vim.json.decode, d); return (ok and t) or {}
end
local function bl_write_all(t)
  local f = io.open(bl_order_file, "w"); if not f then return end
  f:write(vim.json.encode(t)); f:close()
end
local function bl_reindex()
  bl_index = {}
  for i, p in ipairs(bl_order) do bl_index[p] = i end
end
-- Persist under the key the order was *loaded* from, not getcwd() at the moment
-- of writing: the CMake source-root cd (SECTION: Build) moves cwd after this
-- section has already run, and saving under the moved cwd would write an order
-- the next launch never reads back.
local function bl_save()
  local all = bl_read_all()
  all[bl_key] = bl_order
  bl_write_all(all)
end
-- Give a path a place the first time it's seen, so it has a stable slot for the
-- rest of the session instead of floating on its buffer number.
local function bl_track(path)
  if not path or path == "" or bl_index[path] then return end
  bl_order[#bl_order + 1] = path
  bl_index[path] = #bl_order
end
local function bl_refresh_saved()
  bl_key = vim.fn.getcwd()
  bl_order = {}
  -- Drop paths that no longer exist: the list outlives the buffers in it (that's
  -- what keeps a closed tab's slot warm), so without a prune it only ever grows.
  for _, p in ipairs(bl_read_all()[bl_key] or {}) do
    if vim.fn.filereadable(p) == 1 then bl_order[#bl_order + 1] = p end
  end
  bl_reindex()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted and vim.bo[b].buftype == "" then
      bl_track(vim.api.nvim_buf_get_name(b))
    end
  end
end
bl_refresh_saved()

vim.api.nvim_create_autocmd({ "BufAdd", "BufReadPost" }, {
  group = vim.api.nvim_create_augroup("bufferline_order", { clear = true }),
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "" then return end
    bl_track(vim.api.nvim_buf_get_name(ev.buf))
  end,
})

-- Two colors drive the tab styling (defined once, reused below):
local bl_dim_bg = "#0c0e13"  -- dimmed tab-bar chrome / inactive tab background
local bl_dim_fg = "#6b7280"  -- dimmed inactive tab text

-- Populated by "Sticky buffers" in SECTION: Session. init.vim is one Lua chunk
-- and that code lives further down, so the tabline reaches it via this table.
local sticky = {}            -- .is_glance(path) -> bool ; .keep(bufnr)
local bl_glance_mark = " ·"  -- marks tabs the session won't restore; "" to hide

require('bufferline').setup {
  options = {
    mode = "buffers",
    separator_style = "thin",        -- default single divider between tabs
    indicator = { style = "icon", icon = "▎" },  -- colored bar marks the active tab
    show_buffer_close_icons = true,  -- the little × per buffer
    show_close_icon = false,         -- no global close button on the far right
    show_buffer_icons = true,        -- filetype icons via nvim-web-devicons
    modified_icon = "●",
    diagnostics = false,
    always_show_bufferline = true,
    -- Mark "glance" buffers -- files opened but never worked on, which the
    -- session deliberately won't bring back. See SECTION: Session.
    name_formatter = function(buf)
      if bl_glance_mark ~= "" and sticky.is_glance and sticky.is_glance(buf.bufnr) then
        return buf.name .. bl_glance_mark
      end
      return buf.name
    end,
    -- Order follows bl_order (paths) for every real file; anything without a
    -- path in the list -- a terminal, [No Name] -- trails by id. Drags feed
    -- back into bl_order, so this stays authoritative all session.
    sort_by = function(a, b)
      local ia, ib = bl_index[a.path], bl_index[b.path]
      if ia and ib then return ia < ib end
      if ia then return true end
      if ib then return false end
      return a.id < b.id
    end,
  },
  -- Active tab = transparent (blends into the buffer background, no box).
  -- Everything else = a dim strip (bl_dim_bg) with dim text (bl_dim_fg), so the
  -- active tab reads as a lit "hole" through an otherwise dimmed bar.
  highlights = {
    -- dimmed chrome + inactive tabs
    fill                 = { bg = bl_dim_bg },
    background           = { fg = bl_dim_fg, bg = bl_dim_bg },
    buffer_visible       = { fg = bl_dim_fg, bg = bl_dim_bg },
    separator            = { fg = bl_dim_bg, bg = bl_dim_bg },
    separator_visible    = { fg = bl_dim_bg, bg = bl_dim_bg },
    modified             = { fg = bl_dim_fg, bg = bl_dim_bg },
    modified_visible     = { fg = bl_dim_fg, bg = bl_dim_bg },
    close_button         = { fg = bl_dim_fg, bg = bl_dim_bg },
    close_button_visible = { fg = bl_dim_fg, bg = bl_dim_bg },
    duplicate            = { fg = bl_dim_fg, bg = bl_dim_bg },
    duplicate_visible    = { fg = bl_dim_fg, bg = bl_dim_bg },
    -- active tab: fully transparent, default (bright) foreground
    buffer_selected       = { bg = "NONE" },
    separator_selected    = { bg = "NONE" },
    modified_selected     = { bg = "NONE" },
    close_button_selected = { bg = "NONE" },
    duplicate_selected    = { bg = "NONE" },
    indicator_selected    = { bg = "NONE" },
  },
}

-- Fold the order bufferline is *showing* back into bl_order, then hand sorting
-- back to sort_by. Only the slots held by currently-open files are rewritten --
-- entries for closed files keep their position, which is exactly what lets a
-- reopened tab come back where it was instead of at the far right.
local function bl_sync_from_view()
  local ok, bl = pcall(require, "bufferline"); if not ok then return end
  local els = bl.get_elements(); els = (els and els.elements) or {}
  local seq = {}   -- open file paths, in the order now on screen
  for _, e in ipairs(els) do
    if e.path and e.path ~= "" then seq[#seq + 1] = e.path; bl_track(e.path) end
  end
  local open = {}
  for _, p in ipairs(seq) do open[p] = true end
  local i = 1
  for n, p in ipairs(bl_order) do
    if open[p] then bl_order[n] = seq[i]; i = i + 1 end
  end
  bl_reindex()
  -- custom_sort is the bufnr list that caused the drift; drop it every time so
  -- it never becomes the authority.
  pcall(function() require("bufferline.state").custom_sort = nil end)
  vim.cmd("redrawtabline")
  bl_save()
end

-- A drag is durable the moment you make it. The session file is re-saved on
-- every :bd (SECTION: Session), so an order saved only at VimLeavePre would be
-- the one half of the state an unclean exit throws away.
vim.api.nvim_create_autocmd("VimLeavePre", { callback = bl_save })

-- Safety net for every *other* route into a bufnr order: :BufferLineMoveNext
-- typed by hand, :BufferLineSortByDirectory, a future keymap. A non-nil
-- custom_sort is the one unambiguous "something reordered by buffer number"
-- signal, so catch it wherever it appears and convert it to paths. The check is
-- a nil test on a hot event; the fold only runs when there's something to fold.
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold" }, {
  group = "bufferline_order",
  callback = function()
    local ok, st = pcall(require, "bufferline.state")
    if ok and st.custom_sort then bl_sync_from_view() end
  end,
})

-- Reorder the current buffer left/right within the bufferline. Deliberately
-- placing a tab is curation, so it also makes the buffer stick (SECTION: Session).
local function bl_move(cmd)
  return function()
    vim.cmd(cmd)
    bl_sync_from_view()
    if sticky.keep then sticky.keep(vim.api.nvim_get_current_buf()) end
  end
end
vim.keymap.set('n', '<leader><Left>',  bl_move("BufferLineMovePrev"), { silent = true, desc = "Move buffer left in tabline" })
vim.keymap.set('n', '<leader><Right>', bl_move("BufferLineMoveNext"), { silent = true, desc = "Move buffer right in tabline" })

-- ═══════════════════════════ SECTION: Session ═══════════════════════════
-- Session persistence (per directory): remember open buffers/tabs/window layout.
-- What gets saved in a session — buffers, cwd, tabpages, window sizes, etc.
vim.o.sessionoptions = "buffers,curdir,folds,globals,help,tabpages,terminal,winsize,winpos"
require('persistence').setup()

-- ---- Sticky buffers: only files you *worked on* come back ----
-- Opening a file just to read it used to bake it into the session forever, so
-- every glance left a tab behind. Now a buffer has to earn its place: it's
-- "kept" once you act on it, and a "glance" buffer otherwise -- visible now,
-- gone next launch.
--
-- The signal is any *edit*, not "left normal mode": dd/p/x and :s never leave
-- normal mode but are plainly work, and InsertEnter alone would lose them.
-- Buffers restored from a session are kept too -- they earned their place last
-- time, and without that rule a session would decay to empty across launches.
local KEEP_ON_VISUAL = true   -- visual/select mode counts as working on a file;
                              -- false if select-to-yank makes too much stick
local kept = {}               -- absolute path -> true, once earned, for this run
local dropped = {}            -- absolute path -> true, forced back to glance by <leader>qk

-- Only listed, named, real file buffers are candidates (no terminals, no help,
-- no scratch) -- those are the only ones mksession writes as `badd` anyway.
local function buf_file(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return nil end
  if vim.bo[buf].buftype ~= "" or not vim.bo[buf].buflisted then return nil end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then return nil end
  return vim.fn.fnamemodify(name, ":p")
end

-- Whether a buffer has earned its place. The authority is its undo history:
-- reading a file in creates no undo entry, so seq_last > 0 means it was edited
-- -- and it stays > 0 after an undo, so a change you thought better of still
-- counts as work. That beats both the TextChanged autocmd (:h TextChanged says
-- it doesn't fire while there's typeahead; it was measured missing `dd` and
-- `:%s`) and 'modified' (which a :w clears). The autocmds below only latch
-- early, so the tabline mark clears the instant you touch a file.
local function is_kept(buf, path)
  if dropped[path] then return false end
  if kept[path] then return true end
  local ok, undo = pcall(vim.fn.undotree, buf)
  if ok and (undo.seq_last or 0) > 0 then
    kept[path] = true
    return true
  end
  return false
end

-- The keep-list rides *inside* the session file: 'sessionoptions' has "globals"
-- and mksession persists global strings named CamelCase, so g:KeepBufs is
-- written by the very same mks! that writes the buffer list. It can't drift
-- from the session, and <leader>qD deletes both at once -- no sidecar file.
local function publish_kept()
  local paths = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    local p = buf_file(b)
    if p and is_kept(b, p) then paths[#paths + 1] = p end
  end
  vim.g.KeepBufs = vim.json.encode(paths)
end

local function keep_buf(buf)
  local p = buf_file(buf)
  if not p then return end
  if kept[p] and not dropped[p] then return end
  kept[p] = true
  dropped[p] = nil   -- working on it again overrides an earlier <leader>qk drop
  publish_kept()
  vim.cmd("redrawtabline")   -- clear the glance mark on its tab
end

-- Hand both to the tabline (forward-declared in SECTION: Bufferline).
sticky.keep = keep_buf
sticky.is_glance = function(bufnr)
  local p = buf_file(bufnr)
  return p ~= nil and not is_kept(bufnr, p)
end

local keep_group = vim.api.nvim_create_augroup("session_keep", { clear = true })
-- InsertEnter is here on purpose: opening insert and typing nothing leaves no
-- undo entry, but it's still intent to work on the file.
vim.api.nvim_create_autocmd({ "InsertEnter", "TextChanged", "TextChangedI", "BufWritePost" }, {
  group = keep_group,
  callback = function(ev) keep_buf(ev.buf) end,
})
-- Refresh the keep-list immediately before persistence's exit save, so it can
-- never be stale by the time mks! snapshots g:KeepBufs.
vim.api.nvim_create_autocmd("User", {
  group = keep_group,
  pattern = "PersistenceSavePre",
  callback = function() publish_kept() end,
})
if KEEP_ON_VISUAL then
  -- ModeChanged matches its pattern against "oldmode:newmode"; the class is
  -- v/V/CTRL-V (visual) and s/S/CTRL-S (select).
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = keep_group,
    pattern = "*:[vVsS" .. string.char(22, 19) .. "]*",
    callback = function(ev) keep_buf(ev.buf) end,
  })
end

-- Drop the glance buffers a restored session brought back with it.
--
-- This runs *after* the session is sourced rather than filtering at save time,
-- for two reasons found the hard way: mksession writes a window's file even
-- when that buffer is unlisted (and a glance usually ends with the glance file
-- still in the window, so save-time filtering would miss the common case), and
-- flipping 'buflisted' fires BufDelete, which would recurse into the
-- persistence_sync save below. Filtering on load also means it works no matter
-- how the session got written -- clean :wqa or the BufDelete sync after a kill.
local function drop_glance_buffers()
  local allow
  if type(vim.g.KeepBufs) == "string" then
    local ok, list = pcall(vim.json.decode, vim.g.KeepBufs)
    if ok and type(list) == "table" then
      allow = {}
      for _, p in ipairs(list) do allow[p] = true end
    end
  end

  local doomed, survivors = {}, {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    local p = buf_file(b)
    -- No keep-list at all means a session written before this existed (or by a
    -- plain :mksession): keep it whole rather than nuking someone's layout.
    if p and allow and not allow[p] then
      doomed[#doomed + 1] = b
    elseif p then
      survivors[#survivors + 1] = b
      kept[p] = true   -- restored buffers keep the place they earned
    end
  end

  -- Move any window off a doomed buffer first, so wiping it doesn't punch a
  -- [No Name] hole in the layout the session just restored.
  if survivors[1] then
    local dead = {}
    for _, b in ipairs(doomed) do dead[b] = true end
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if dead[vim.api.nvim_win_get_buf(win)] then
        vim.api.nvim_win_set_buf(win, survivors[1])
      end
    end
  end
  for _, b in ipairs(doomed) do
    pcall(vim.api.nvim_buf_delete, b, {})
  end
  publish_kept()
end

-- Restore this directory's session, minus the glance buffers, and pick up the
-- tab order saved for the cwd it restored.
local function session_load(opts)
  require('persistence').load(opts)
  drop_glance_buffers()
  bl_refresh_saved()
end

-- Auto-restore the session for this directory when launching bare `nvim`
-- (no file arguments and nothing piped in), so `nvim` in a project drops you
-- right back where you left off after `:wqa`.
-- git launches nvim to edit an ephemeral file (commit/merge/tag message,
-- interactive-rebase todo). Those live in .git/ and must never be restored
-- into — or baked into — a project session, or a stale COMMIT_EDITMSG buffer
-- reappears on the next bare `nvim` in the repo. persistence's own gitcommit
-- awareness only gates the `need` threshold; mks! still writes the buffer.
local git_edit_files = {
  ["COMMIT_EDITMSG"] = true, ["MERGE_MSG"] = true, ["SQUASH_MSG"] = true,
  ["TAG_EDITMSG"] = true, ["NOTES_EDITMSG"] = true, ["git-rebase-todo"] = true,
}
local function launched_for_git_edit()
  for _, a in ipairs(vim.fn.argv()) do
    if git_edit_files[vim.fn.fnamemodify(a, ":t")] then return true end
  end
  return false
end

vim.api.nvim_create_autocmd("VimEnter", {
  nested = true,
  callback = function()
    local not_piped_in = not vim.g.started_with_stdin
    if not not_piped_in then return end

    local persistence = require('persistence')

    -- Editing a git message: don't load a session over it, don't save it back.
    if launched_for_git_edit() then
      persistence.stop()
      return
    end

    if vim.fn.argc() == 0 then
      -- Bare `nvim`: drop right back where you left off.
      session_load()
      return
    end

    -- `nvim <file>` with a saved session for this dir: don't let persistence
    -- overwrite the session with just this file on exit. Restore the existing
    -- session first, then append the launched file(s) to it and surface them.
    local session_file = persistence.current()
    if not (session_file and vim.fn.filereadable(session_file) == 1) then
      return   -- no session yet: leave the fresh file(s) to seed a new one
    end

    -- Absolute paths captured before load() resets the arglist/cwd.
    local files = {}
    for _, a in ipairs(vim.fn.argv()) do
      files[#files + 1] = vim.fn.fnamemodify(a, ":p")
    end

    session_load()

    for _, f in ipairs(files) do
      vim.cmd("badd " .. vim.fn.fnameescape(f))   -- join the session's buffer list
    end
    vim.cmd("edit " .. vim.fn.fnameescape(files[1]))   -- show what you opened nvim for
  end,
})
vim.api.nvim_create_autocmd("StdinReadPre", {
  callback = function() vim.g.started_with_stdin = true end,
})

-- Keep the on-disk session in sync the moment you close a buffer.
-- persistence only re-saves on a *clean* VimLeavePre, so a `:bd` is otherwise
-- lost if nvim exits uncleanly (terminal tab closed, shell exited, process
-- killed) and the deleted buffer reappears on next launch. Re-saving on
-- BufDelete makes a close durable right away — no need to nuke the session.
local save_pending = false
vim.api.nvim_create_autocmd("BufDelete", {
  group = vim.api.nvim_create_augroup("persistence_sync", { clear = true }),
  callback = function()
    -- Don't save while a session is being sourced (restore wipes a scratch
    -- buffer, which fires BufDelete) or when persistence isn't active.
    if vim.g.SessionLoad == 1 then return end
    local persistence = require('persistence')
    if not persistence.active() then return end
    -- Coalesce bursts into one write -- the glance sweep at startup can delete
    -- several buffers at once, and each would otherwise queue its own mks!.
    if save_pending then return end
    save_pending = true
    -- Defer so the buffer is fully off the list before mksession snapshots it.
    vim.schedule(function()
      save_pending = false
      publish_kept()   -- this path bypasses persistence's own SavePre hook
      persistence.save()
    end)
  end,
})

-- Manual session controls if you ever want them.
vim.keymap.set('n', '<leader>qs', function() session_load() end, { desc = "Restore session (this dir)" })
vim.keymap.set('n', '<leader>ql', function() session_load({ last = true }) end, { desc = "Restore last session" })
vim.keymap.set('n', '<leader>qd', function() require('persistence').stop() end, { desc = "Stop saving session" })

-- Override the sticky-buffer rule for the current file: pin one you only ever
-- read (a reference you want back tomorrow), or drop one you touched by
-- accident. Tabs the session won't restore are marked in the tabline.
vim.keymap.set('n', '<leader>qk', function()
  local buf = vim.api.nvim_get_current_buf()
  local p = buf_file(buf)
  if not p then
    vim.notify("Not a file buffer -- nothing to keep.", vim.log.levels.WARN)
    return
  end
  -- `dropped` has to be an explicit override: without it, the undo history that
  -- made the file stick in the first place would just re-latch it.
  local now_kept = not is_kept(buf, p)
  kept[p]    = now_kept or nil
  dropped[p] = (not now_kept) or nil
  publish_kept()
  vim.cmd("redrawtabline")
  vim.notify((now_kept and "Keeping " or "Dropping ") .. vim.fn.fnamemodify(p, ":~:."),
    vim.log.levels.INFO)
end, { desc = "Toggle: keep this file in the session" })

-- Nuke this directory's saved session and stop saving for the rest of this run.
-- Use when a stray buffer got baked into the session and keeps re-opening:
-- .stop() is essential — otherwise persistence would just re-save on exit.
vim.keymap.set('n', '<leader>qD', function()
  local persistence = require('persistence')
  persistence.stop()
  local removed = {}
  for _, f in ipairs({ persistence.current(), persistence.current({ branch = false }) }) do
    if vim.fn.filereadable(f) == 1 and vim.fn.delete(f) == 0 then
      table.insert(removed, f)
    end
  end
  if #removed > 0 then
    vim.notify("Deleted session (saving stopped for this run):\n" .. table.concat(removed, "\n"), vim.log.levels.INFO)
  else
    vim.notify("No session file found for this directory.", vim.log.levels.WARN)
  end
end, { desc = "Delete session (this dir) + stop saving" })

-- ═══════════════════════════ SECTION: Editing (comment/flash/pairs/indent/surround) ═══════════════════════════
-- Comment.nvim: treesitter-aware comment toggling (gcc line, gc motion/visual).
require('Comment').setup()

-- flash.nvim: jump anywhere with labels; also enhances f/t/F/T.
require('flash').setup()
vim.keymap.set({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash jump" })
-- S is repurposed for structural select (see SECTION: Structural select). flash.treesitter
-- is still available if you want it back on another key: require("flash").treesitter().

-- nvim-autopairs: auto-close brackets/quotes, integrated with nvim-cmp.
require('nvim-autopairs').setup {}
do
  local ok_cmp, cmp = pcall(require, 'cmp')
  local ok_ap, cmp_ap = pcall(require, 'nvim-autopairs.completion.cmp')
  if ok_cmp and ok_ap then
    cmp.event:on('confirm_done', cmp_ap.on_confirm_done())
  end
end

-- indent-blankline (ibl): vertical box-drawing indent guides + current scope.
require('ibl').setup {
  indent = { char = "│" },
  scope = { enabled = true },
}

-- nvim-surround: add/change/delete surrounds (ys/cs/ds, visual S).
require('nvim-surround').setup {}

-- ═══════════════════════════ SECTION: Trouble ═══════════════════════════
-- trouble.nvim: aggregated diagnostics/quickfix panel (complements inline LSP).
require('trouble').setup {}
vim.keymap.set('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>',              { desc = "Diagnostics (Trouble)" })
vim.keymap.set('n', '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = "Buffer diagnostics (Trouble)" })
vim.keymap.set('n', '<leader>xq', '<cmd>Trouble qflist toggle<cr>',                    { desc = "Quickfix list (Trouble)" })

-- cmake-tools.nvim: CMake-aware build/run for this project. Knows the out-of-source
-- build dir natively (no Makefile-detection hacks), and sends build output to the
-- quickfix list (browse with <leader>xq / Trouble). <leader>c = CMake commands.
-- ═══════════════════════════ SECTION: Build (cmake-tools + overseer) ═══════════════════════════
-- cmake-tools takes its CMake source root from nvim's cwd, and re-derives it on
-- every DirChanged — so cd-ing away (e.g. back into build/) resets it and breaks
-- generate. The stable fix: make the cwd BE the source root and leave it there.
-- Walk UP for CMakeLists.txt and cd there once, BEFORE setup (so cmake-tools' own
-- DirChanged handler, registered during setup, never sees a conflicting change).
-- Only acts inside a CMake tree; elsewhere cwd is untouched. No hardcoded paths.
local cmake_found = vim.fs.find("CMakeLists.txt", { upward = true, type = "file", path = vim.loop.cwd() })[1]
if cmake_found then vim.cmd.cd(vim.fs.dirname(cmake_found)) end
require('cmake-tools').setup {
  cmake_build_directory = "build",              -- joined onto the source-root cwd
  cmake_executor = {                            -- build errors → quickfix (async)
    name = "quickfix",
    -- only_on_error: don't flash the quickfix open/closed on a clean rebuild;
    -- it appears only when there's actually something to show.
    opts = { show = "only_on_error", position = "belowright", size = 12 },
  },
  cmake_runner = { name = "terminal" },         -- run built targets in a terminal
}
-- <leader>b BUILDS the already-configured tree; it must never *reconfigure*.
-- Configuration is owned solely by scripts/build.sh (which sets CMAKE_BUILD_TYPE,
-- toolchain, generator). cmake-tools.build() used to re-run cmake before every
-- build using its hardcoded "Debug" default, silently clobbering a RelWithDebInfo
-- cache down to -O0. Invoking the generator directly (cmake --build) can't touch
-- the build type — it just compiles what build.sh configured. Success echoes a
-- quiet line; failures populate + open the quickfix (mirrors the old only_on_error).
local function project_build_dir()
  local cml = vim.fs.find("CMakeLists.txt", { upward = true, type = "file", path = vim.loop.cwd() })[1]
  local root = cml and vim.fs.dirname(cml) or vim.loop.cwd()
  return root .. "/build"
end

local function cmake_build()
  local bdir = project_build_dir()
  if vim.fn.filereadable(bdir .. "/CMakeCache.txt") == 0 then
    vim.api.nvim_echo({ { "no configured build/ — run scripts/build.sh first", "WarningMsg" } }, true, {})
    return
  end
  local out = {}
  local function sink(_, data) if data then vim.list_extend(out, data) end end
  vim.fn.jobstart({ "cmake", "--build", bdir }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = sink,
    on_stderr = sink,
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          vim.api.nvim_echo({ { "✓ Build succeeded", "DiagnosticOk" } }, false, {})
        else
          vim.fn.setqflist({}, " ", {
            title = "cmake --build",
            lines = out,
            efm = "%f:%l:%c: %t%*[^:]: %m,%f:%l:%c: %m,%f:%l: %m",
          })
          vim.cmd("botright copen 12")
          vim.api.nvim_echo({ { "✗ Build failed", "DiagnosticError" } }, false, {})
        end
      end)
    end,
  })
end
vim.keymap.set('n', '<leader>b',  cmake_build,                        { desc = "CMake build" })
vim.keymap.set('n', '<leader>cg', '<cmd>CMakeGenerate<cr>',          { desc = "CMake generate/configure" })
vim.keymap.set('n', '<leader>cb', cmake_build,                        { desc = "CMake build" })
vim.keymap.set('n', '<leader>cr', '<cmd>CMakeRun<cr>',              { desc = "CMake run" })
vim.keymap.set('n', '<leader>cc', '<cmd>CMakeClean<cr>',            { desc = "CMake clean" })
vim.keymap.set('n', '<leader>ct', '<cmd>CMakeSelectBuildTarget<cr>',{ desc = "CMake select build target" })
vim.keymap.set('n', '<leader>cl', '<cmd>CMakeSelectLaunchTarget<cr>',{ desc = "CMake select launch target" })
vim.keymap.set('n', '<leader>cv', '<cmd>CMakeSelectBuildType<cr>',  { desc = "CMake select build type" })

vim.o.scroll = math.floor(vim.o.window / 2)
vim.api.nvim_set_keymap('n', '<C-e>', '10<C-e>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-y>', '10<C-y>', { noremap = true, silent = true })
-- overseer.nvim: kept as a bare-bones ad-hoc task runner for non-CMake odd jobs.
require('overseer').setup {}
vim.keymap.set('n', '<leader>or', '<cmd>OverseerRun<cr>',    { desc = "Run a task (Overseer)" })
vim.keymap.set('n', '<leader>oo', '<cmd>OverseerToggle<cr>', { desc = "Toggle task list (Overseer)" })

-- Summon the full which-key hint list for the current mode (all first keys,
-- not just <leader>). Pressing <leader> alone already shows the leader menu.
vim.keymap.set('n', '<leader>?', function() require('which-key').show({ global = true }) end, { desc = "Show all keybinds (which-key)" })

vim.api.nvim_create_autocmd({"InsertEnter", "InsertLeave", "BufEnter"}, {
  callback = function()
    vim.cmd("redrawstatus")
  end,
})

return M

EOF

" ═══════════════════════════ SECTION: Vimscript fns ═══════════════════════════
function! ConvertAllCommentsToBlocks() range
  let l:start = a:firstline
  let l:end = a:lastline
  let l:lines = getline(l:start, l:end)

  let l:result = []
  let l:block_buffer = []
  let l:in_block = 0

  for l:line in l:lines
    " CASE 1: full-line comment
    if l:line =~ '^\s*//'
      let l:comment_text = substitute(l:line, '^\s*//\s*', '', '')
      call add(l:block_buffer, l:comment_text)
      let l:in_block = 1
      continue
    endif

    " CASE 2: line of code with inline comment
    if l:line =~ '//'
      " flush existing block if any
      if l:in_block && !empty(l:block_buffer)
        call add(l:result, '/* ' . join(l:block_buffer, ' ') . ' */')
        let l:block_buffer = []
        let l:in_block = 0
      endif
      let l:match_pos = match(l:line, '//')
      let l:prefix = strpart(l:line, 0, l:match_pos)
      let l:comment_part = substitute(strpart(l:line, l:match_pos), '^//\s*', '', '')
      call add(l:result, l:prefix . '/* ' . l:comment_part . ' */')
      continue
    endif

    " CASE 3: blank line or normal code line
    if l:in_block
      " flush block buffer when leaving comment run
      if !empty(l:block_buffer)
        call add(l:result, '/* ' . join(l:block_buffer, ' ') . ' */')
        let l:block_buffer = []
      endif
      let l:in_block = 0
    endif

    call add(l:result, l:line)
  endfor

  " Flush final block at end of range
  if !empty(l:block_buffer)
    call add(l:result, '/* ' . join(l:block_buffer, ' ') . ' */')
  endif

  " Replace lines in buffer
  call setline(l:start, l:result)
  if len(l:result) < (l:end - l:start + 1)
    call deletebufline('%', l:start + len(l:result), l:end)
  endif
endfunction

vnoremap <leader>c :<C-u>call ConvertAllCommentsToBlocks()<CR>

syntax enable
if !isdirectory(expand("~/.local/share/nvim/undo"))
  call mkdir(expand("~/.local/share/nvim/undo"), "p")
endif

" ═══════════════════════════ SECTION: NERDTree ═══════════════════════════
let g:NERDTreeWinPos = 'right'
let g:NERDTreeWinSize = 40
let g:NERDTreeChDirMode = 2
nnoremap <leader>g :NERDTreeFind<CR>
nnoremap <leader>G :NERDTreeToggle<CR>
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" ═══════════════════════════ SECTION: Telescope keymaps ═══════════════════════════
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers({
            \ cwd = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
            \ })<cr>

nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags({
            \ cwd = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
            \ })<cr>

" NOTE: <leader>1..9 are mapped in the Lua block above via bufferline's
" go_to(i, true), which honours the tabline's *visual*/persisted order. The old
" vimscript loop that lived here jumped by getbufinfo() (buffer-NUMBER) order --
" bufferline-incompatible -- and, being defined after the Lua maps, silently
" shadowed them so <leader>1 landed on the lowest-bufnr buffer (often visual
" tab 3), not the leftmost tab. Removed.

autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

" ═══════════════════════════ SECTION: Airline ═══════════════════════════
function! AirlineWeather()
  return luaeval('StatusWeather()')
endfunction

function! AirlineCopilot()
  return luaeval('CopilotStatus()')
endfunction


let g:airline_powerline_fonts = 1
let g:webdevicons_enable_airline_tabline = 1
let g:webdevicons_enable_airline_statusline = 1
" Tabline is handled by bufferline.nvim (see setup below), so disable airline's.
let g:airline#extensions#tabline#enabled = 0
let g:airline#extensions#tabline#formatter = 'default'
let g:airline_theme = 'base16_material_darker'
let g:airline_skip_empty_sections = 1
let g:airline_section_c = ''

call airline#parts#define_function('airline_weather', 'AirlineWeather')
let g:airline_section_x = airline#section#create_right(['airline_weather'])


autocmd User AirlineAfterInit call s:SetupCopilotSection()
function! s:SetupCopilotSection()
  call airline#parts#define_function('airline_copilot', 'AirlineCopilot')
  let g:airline_section_z = airline#section#create(['airline_copilot', ' %p%%', 'linenr', 'maxlinenr', 'colnr'])
endfunction

colorscheme cyberdream

" ═══════════════════════════ SECTION: Editor options ═══════════════════════════
set undofile
set undodir^=~/.local/share/nvim/undo//
set laststatus=2
set termguicolors
set number
set relativenumber
set ignorecase   " case-insensitive search / telescope-frecency matching...
set smartcase    " ...unless the query has uppercase (fixes CMake not matching CMakeLists.txt)
set signcolumn=yes
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set cursorline

" Spellcheck (native, treesitter-scoped). 'spell' is window-local, and whenever a
" treesitter highlighter is attached to a buffer it forces 'spelloptions' to
" include `noplainbuffer` (see :h spelloptions), which restricts spell to @spell
" captures — i.e. comments & strings — so code identifiers are NOT flagged. With
" NO highlighter (no parser for the filetype), `noplainbuffer` is absent and the
" WHOLE buffer is checked, which flags every identifier. That's the bug this
" scoping fixes: we enable spell only where it can be constrained.
"   - prose filetypes (markdown/text/…) → spell the whole buffer (it's all prose)
"   - any other filetype WITH a parser  → spell, scoped by TS to comments/strings
"   - a filetype WITHOUT a parser        → leave spell OFF (can't scope it safely)
"   - UI/utility/terminal buffers        → OFF (pure noise)
" Driven per-window off BufWinEnter/FileType/TermOpen so it's correct on splits
" and :setf too. Correct a word with z=.
set spelllang=en_us
set nospell
" Only flag genuine misspellings (SpellBad). Drop the pedantic categories:
" capitalisation-at-sentence-start (killed at the source via empty
" spellcapcheck), rare-but-real words (SpellRare), and regional-variant
" spellings valid in another English locale (SpellLocal).
set spellcapcheck=
highlight! link SpellCap NONE
highlight! link SpellRare NONE
highlight! link SpellLocal NONE

lua << EOF
-- Filetypes that are prose end to end: spellcheck the whole buffer.
local spell_prose = {
  markdown = true, text = true, gitcommit = true, gitrebase = true,
  rst = true, tex = true, plaintex = true, mail = true, asciidoc = true, org = true,
}
-- UI / utility buffers where spell is pure noise.
local spell_never = {
  nerdtree = true, TelescopePrompt = true, aerial = true, trouble = true,
  qf = true, help = true, checkhealth = true,
}
local function scoped_spell()
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  local enable
  if vim.bo[buf].buftype ~= '' or spell_never[ft] then
    enable = false                       -- terminals, prompts, special buffers
  elseif spell_prose[ft] then
    enable = true                        -- prose: whole buffer
  else
    -- Code (or unknown): only spell if a parser is available, so that the TS
    -- highlighter's `noplainbuffer` will confine spell to @spell (comments &
    -- strings). No parser → can't scope → leave it off entirely.
    local lang = vim.treesitter.language.get_lang(ft)
    local ok, avail = pcall(vim.treesitter.language.add, lang)
    enable = ok and avail == true
  end
  vim.wo.spell = enable
end
vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType", "TermOpen" }, {
  callback = scoped_spell,
})
EOF

highlight CursorLineNr ctermfg=Yellow guifg=Yellow
highlight CursorLine ctermbg=NONE guibg=NONE

command! Wq wq
command! WQ wq
command! W w
command! Q q

set shada=!,'100,<1000,s100,h

"
"let g:neoformat_verilog_verible = {
"      \ 'exe': 'verible-verilog-format',
"      \ 'args': ['--indentation_spaces=4 -'],
"      \ 'stdin': 1,
"      \ }
"let g:neoformat_enabled_verilog = ['verible']
