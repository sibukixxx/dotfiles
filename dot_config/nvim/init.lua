-- =========================
-- Neovim 快適セット (macOS)
-- - テーマ: tokyonight-moon（青弱め）
-- - LSP: 0.11 の新API互換シムで非推奨回避
-- - LuaSnip: 正しい require 名で読込
-- - プラグイン管理: lazy.nvim
-- =========================

-- 0) リーダーキー
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 1) macOS クリップボード
vim.opt.clipboard = "unnamedplus"

-- 2) UI/編集
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.updatetime = 200
vim.opt.timeoutlen = 400
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", extends = "›", precedes = "‹" }

-- 3) キーマップ
local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "ハイライト解除" })
map({ "i", "c" }, "jj", "<Esc>", { desc = "jjでEsc" })
map("n", "<leader>w", "<cmd>w<CR>", { desc = "保存" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "閉じる" })
map("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "ファイルツリー" })
map("n", "<leader>.", "<cmd>Oil<CR>", { desc = "ディレクトリ編集(Oil)" })

-- 4) lazy.nvim ブートストラップ
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git","clone","--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git","--branch=stable",lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

-- 5) プラグイン
require("lazy").setup({
  -- テーマ（青弱め）
  { "neanias/everforest-nvim", lazy = false, priority = 1000 },
  { "pmouraguedes/neodarcula.nvim", lazy = false, priority = 1000 },
  { "folke/tokyonight.nvim", lazy = false, priority = 1000, opts = {
      style = "moon",
      dim_inactive = true,
      styles = { comments = { italic = false } },
    },
  },

  -- UI
  { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "nvim-tree/nvim-web-devicons" },
  { "folke/which-key.nvim", event = "VeryLazy" },
  { "lewis6991/gitsigns.nvim" },

  -- ファイル操作
  { "nvim-neo-tree/neo-tree.nvim", branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim","nvim-tree/nvim-web-devicons","MunifTanjim/nui.nvim" } },
  { "stevearc/oil.nvim", opts = {} },

  -- 検索
  { "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },

  -- Treesitter
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

  -- LSP & ツール
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "neovim/nvim-lspconfig" },

  -- 補完
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },
  { "rafamadriz/friendly-snippets" },

  -- フォーマッタ
  { "stevearc/conform.nvim" },

  -- 小物
  { "numToStr/Comment.nvim", opts = {} },
  { "windwp/nvim-autopairs", opts = {} },
}, {
  ui = { border = "rounded" },
  change_detection = { notify = false },
})

-- 6) テーマ適用 + 目に優しい微調整
vim.cmd.colorscheme("everforest")
-- ★ カラー上書き（背景はテーマのまま、文字は白、ハイライト調整）
local hi = vim.api.nvim_set_hl

-- ベース：白文字（背景はテーマ継承＝NONE）
hi(0, "Normal",      { fg = "#ffffff", bg = "NONE" })
hi(0, "NormalNC",    { fg = "#e6e6e6", bg = "NONE" })
hi(0, "NormalFloat", { fg = "#ffffff", bg = "NONE" })
hi(0, "FloatBorder", { fg = "#3b3f55", bg = "NONE" })   -- フロート枠は控えめ

-- 行番号/カーソルライン（ダーク環境でうるさくない程度）
hi(0, "SignColumn",   { bg = "#1a1b26" }) -- 左のアイコン/診断領域も同色に

-- コメントは落ち着いたグレー
hi(0, "Comment",     { fg = "#8a8a8a", italic = false })

-- ポップアップメニュー（補完など）
hi(0, "Pmenu",       { fg = "#e6e6e6", bg = "#1d2131" })
hi(0, "PmenuSel",    { fg = "#ffffff", bg = "#2a2f45" })

-- ★ 選択範囲：淡い水色
hi(0, "Visual",      { fg = "NONE",    bg = "#2a3e5c" })  -- 淡い青み

-- ★ 検索ヒット：黄色ベース（通常とインクリメンタル）
hi(0, "Search",      { fg = "#1b1e2b", bg = "#d2b457" })  -- 目に刺さらないイエロー
hi(0, "IncSearch",   { fg = "#000000", bg = "#f0c86b" })  -- 少し明るめの黄色

-- 診断（青を弱めて全体トーンに合わせる）
hi(0, "DiagnosticInfo",  { fg = "#a6adc8", bg = "NONE" })
hi(0, "DiagnosticHint",  { fg = "#9aa5ce", bg = "NONE" })
hi(0, "DiagnosticWarn",  { fg = "#d7ba7d", bg = "NONE" })
hi(0, "DiagnosticError", { fg = "#e46876", bg = "NONE" })

-- Telescope まわり（背景トーン統一）
hi(0, "TelescopeBorder",   { fg = "#3b3f55", bg = "NONE" })
hi(0, "TelescopeNormal",   { fg = "#e6e6e6", bg = "NONE" })
hi(0, "TelescopeSelection",{ fg = "#ffffff", bg = "#2a2f45" })

-- 7) lualine / which-key / gitsigns
require("lualine").setup({ options = { theme = "auto", globalstatus = true } })
require("which-key").setup({})
require("gitsigns").setup({})

-- 8) Telescope キーバインド
local tb = require("telescope.builtin")
map("n", "<leader>ff", tb.find_files, { desc = "ファイル検索" })
map("n", "<leader>fg", tb.live_grep,  { desc = "ripgrep 検索" })
map("n", "<leader>fb", tb.buffers,    { desc = "バッファ一覧" })
map("n", "<leader>fh", tb.help_tags,  { desc = "ヘルプ検索" })

-- 9) Treesitter
require("nvim-treesitter.configs").setup({
  ensure_installed = { "lua","vim","vimdoc","javascript","typescript","tsx","python","json","yaml","markdown" },
  highlight = { enable = true },
  indent = { enable = true },
})

-- 10) Mason
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "tsserver", "pyright" },
  automatic_installation = true,
})

-- 11) LSP（0.11互換シム：vim.lsp.config/旧lspconfig両対応）
local has_new = (vim.lsp and vim.lsp.config) and true or false
local ok_old, lspconfig = pcall(require, "lspconfig")
local function lsp_setup(server, opts)
  if has_new and vim.lsp.config[server] and vim.lsp.config[server].setup then
    vim.lsp.config[server].setup(opts)
  else
    vim.schedule(function()
      vim.notify(("LSP server '%s' not found"):format(server), vim.log.levels.WARN)
    end)
  end
end

local capabilities = require("cmp_nvim_lsp").default_capabilities()
local on_attach = function(_, bufnr)
  local b = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end
  b("n", "gd", vim.lsp.buf.definition, "定義へ")
  b("n", "gr", vim.lsp.buf.references, "参照")
  b("n", "K",  vim.lsp.buf.hover, "ホバー")
  b("n", "<leader>rn", vim.lsp.buf.rename, "リネーム")
  b("n", "<leader>ca", vim.lsp.buf.code_action, "コードアクション")
  b("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, "整形")
end

lsp_setup("lua_ls", {
  capabilities = capabilities, on_attach = on_attach,
  settings = { Lua = { diagnostics = { globals = { "vim" } }, workspace = { checkThirdParty = false } } }
})
lsp_setup("tsserver", { capabilities = capabilities, on_attach = on_attach })
lsp_setup("pyright",  { capabilities = capabilities, on_attach = on_attach })

-- 12) 補完（nvim-cmp + LuaSnip）
local cmp = require("cmp")
local luasnip = require("luasnip")  -- 大文字ではなく小文字！
require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
  snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
      else fallback() end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then luasnip.jump(-1)
      else fallback() end
    end, { "i", "s" }),
  }),
  sources = {
    { name = "nvim_lsp" }, { name = "path" }, { name = "buffer" }, { name = "luasnip" },
  },
  experimental = { ghost_text = true },
})

-- 13) Conform（フォーマッタ）
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "prettierd", "prettier" },
    typescript = { "prettierd", "prettier" },
    json = { "prettierd", "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    python = { "ruff_format", "black" },
  },
})
map("n", "<leader>p", function() require("conform").format({ async = true, lsp_fallback = true }) end, { desc = "Format" })

-- 14) 便利
map("n", "<leader>s", "<cmd>write<CR>", { desc = "保存" })
map("n", "<leader>x", "<cmd>bdelete<CR>", { desc = "バッファ閉じる" })
map("n", "<leader>tt", "<cmd>tabnew<CR>", { desc = "新規タブ" })

-- 起動メッセージ抑制
vim.schedule(function() vim.notify = function() end end)


