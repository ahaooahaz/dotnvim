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
    -- 处理 `file:line[:col]` 形式的路径（:e 和命令行参数都支持），并提供 gF。
    -- 必须启动即加载：它靠 plugin/fetch.vim:37 的 `autocmd VimEnter` 把运行期
    -- 的 BufNewFile 处理器换上去，懒加载会让 plugin 文件在 VimEnter 之后才被
    -- source，那条 autocmd 就永远不触发。gF 由插件自己定义，无需 keys。
    --
    -- 取代了 bogado/file-line —— 后者 plugin/file_line.vim:92 只在“source 时
    -- 当前 buffer 不是可读文件”才注册处理器，于是 `nvim somefile.cpp` 之后
    -- 整个会话的 :e file:line 都失效。vim-fetch 是它的官方替代品。
    "wsdjeg/vim-fetch",
    lazy = false,
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
  { "wakatime/vim-wakatime", lazy = false },
}
