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
      terminal = {
        auto_insert = true,
        start_insert = true,
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      delay = 100,
    },
  },
  {
    "wsdjeg/vim-fetch",
    keys = {
      { "gF", mode = { "n", "x" } },
    },
  },
  {
    "bogado/file-line",
    event = { "BufReadPre", "BufNewFile" },
  },
  {
    "regomne/nvim-step-search.lua",
    cmd = { "StepSearch", "StepSearchList", "StepSearchReset" },
    opts = {},
  },
  {
    "s1n7ax/nvim-window-picker",
    name = "window-picker",
    event = "VeryLazy",
    version = "2.*",
    opts = {
      hint = "floating-big-letter",
    },
    config = function(_, opts)
      require("window-picker").setup(opts)
    end,
  },
}
