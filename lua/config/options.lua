-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- share vim clipboard with ssh host device system clipboard
if vim.env.SSH_CONNECTION then
  vim.opt.clipboard = "unnamedplus"
  vim.g.clipboard = {
    name = "osc52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
else
  vim.opt.clipboard = "unnamedplus"
end
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8
vim.o.timeoutlen = 200
vim.o.ttimeoutlen = 10
vim.o.cursorcolumn = true
vim.filetype.add({
  extension = {
    json = "jsonc",
  },
})
