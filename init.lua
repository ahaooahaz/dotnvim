if vim.g.vscode then
  -- Skip LazyVim in vscode neovim plugins.
  require("config.keymaps")
  require("config.options")
else
  require("config.lazy")
end
