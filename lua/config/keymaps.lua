-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set
if vim.g.vscode then
else
  -- neo-tree.vim
  map({ "n", "v" }, "<C-n>", function()
    require("neo-tree.command").execute({ toggle = true })
  end, { desc = "Neo-tree toggle" })
  map({ "n", "v" }, "<leader>e", function()
    require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
  end, { desc = "Neo-tree togger (cwd)" })
  map({ "n", "v" }, "<leader>E", function()
    require("neo-tree.command").execute({ toggle = true, reveal = true })
  end, { desc = "Neo-tree reveal file" })
  map({ "n", "v" }, "<leader>fe", function()
    require("neo-tree.command").execute({ dir = vim.loop.cwd() })
  end, { desc = "Neo-tree open cwd" })
end

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
map({ "n", "v" }, "d", '"_d', { noremap = true, silent = true })
map({ "n", "v" }, "D", '"_D', { noremap = true, silent = true })
map("n", "dd", '"_dd', { noremap = true, silent = true })

map({ "n", "v" }, "x", '"_x', { noremap = true, silent = true })
map({ "n", "v" }, "X", '"_X', { noremap = true, silent = true })

map("n", "q", function() end, { desc = "disable macro recording" })
