if false then
  return {}
end

return {
  -- LazyVim中使用minimap每次minimaptoggle都会出现弹窗
  -- {
  --   "wfxr/minimap.vim",
  --   build = "cargo install --locked code-minimap",
  --   init = function()
  --     vim.g.minimap_width = 6
  --     vim.g.minimap_git_colors = 1
  --     vim.g.minimap_block_filetypes =
  --       { "", "fugitive", "nvim-tree", "tagbar", "fzf", "telescope", "NvimTree", "nvdash", "help", "dashboard" }
  --     vim.g.minimap_block_buftypes = { "nofile", "nowrite", "quickfix", "terminal", "prompt", "NvimTree", "nvdash" }
  --     vim.g.minimap_close_filetypes = { "", "startify", "netrw", "vim-plug", "NvimTree", "nvdash", "help", "dashboard" }
  --     vim.g.minimap_highlight_range = 1
  --     vim.g.minimap_highlight_search = 1
  --   end,
  -- },
  {
    "folke/snacks.nvim",
    opts = {
      image = { enabled = false },
      explorer = { enabled = false },
      picker = {
        sources = {
          explorer = { enabled = false },
        },
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      delay = 100,
    },
  },
}
