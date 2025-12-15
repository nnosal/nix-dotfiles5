-- ~/.config/nvim/init.lua
-- Configuration Neovim minimaliste mais fonctionnelle
-- Géré par GNU Stow - Éditable sans rebuild Nix

-- ============================================
-- OPTIONS DE BASE
-- ============================================
local opt = vim.opt

-- Numéros de ligne
opt.number = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- Recherche
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Interface
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Fichiers
opt.backup = false
opt.swapfile = false
opt.undofile = true
opt.undodir = vim.fn.expand("~/.local/state/nvim/undo")

-- Comportement
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.splitright = true
opt.splitbelow = true
opt.updatetime = 250
opt.timeoutlen = 300

-- ============================================
-- KEYMAPS
-- ============================================
local keymap = vim.keymap.set

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Navigation fenêtres
keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Resize fenêtres
keymap("n", "<C-Up>", ":resize +2<CR>", { silent = true })
keymap("n", "<C-Down>", ":resize -2<CR>", { silent = true })
keymap("n", "<C-Left>", ":vertical resize -2<CR>", { silent = true })
keymap("n", "<C-Right>", ":vertical resize +2<CR>", { silent = true })

-- Buffers
keymap("n", "<S-h>", ":bprevious<CR>", { silent = true, desc = "Previous buffer" })
keymap("n", "<S-l>", ":bnext<CR>", { silent = true, desc = "Next buffer" })
keymap("n", "<leader>bd", ":bdelete<CR>", { silent = true, desc = "Delete buffer" })

-- Clear search highlight
keymap("n", "<Esc>", ":nohlsearch<CR>", { silent = true })

-- Meilleure indentation
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")

-- Déplacer lignes
keymap("n", "<A-j>", ":m .+1<CR>==", { silent = true })
keymap("n", "<A-k>", ":m .-2<CR>==", { silent = true })
keymap("v", "<A-j>", ":m '>+1<CR>gv=gv", { silent = true })
keymap("v", "<A-k>", ":m '<-2<CR>gv=gv", { silent = true })

-- ============================================
-- AUTOCOMMANDS
-- ============================================
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
  group = "YankHighlight",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- Remove trailing whitespace on save
autocmd("BufWritePre", {
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- Return to last edit position
autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    local line = vim.fn.line("'\"")
    if line > 1 and line <= vim.fn.line("$") then
      vim.cmd('normal! g\"')
    end
  end,
})

-- ============================================
-- FILETYPES
-- ============================================
vim.filetype.add({
  extension = {
    nix = "nix",
    pkl = "pkl",
  },
})

-- ============================================
-- NOTE: Plugins
-- ============================================
-- Pour les plugins, utilisez lazy.nvim
-- Décommentez et configurez selon vos besoins:
--
-- local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- if not vim.loop.fs_stat(lazypath) then
--   vim.fn.system({
--     "git", "clone", "--filter=blob:none",
--     "https://github.com/folke/lazy.nvim.git",
--     "--branch=stable", lazypath,
--   })
-- end
-- vim.opt.rtp:prepend(lazypath)
--
-- require("lazy").setup({
--   -- Colorscheme
--   { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
--   -- File explorer
--   { "nvim-tree/nvim-tree.lua" },
--   -- Fuzzy finder
--   { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
--   -- LSP
--   { "neovim/nvim-lspconfig" },
--   -- Completion
--   { "hrsh7th/nvim-cmp" },
-- })

print("✨ Neovim configuré - Ultimate Dotfiles")
