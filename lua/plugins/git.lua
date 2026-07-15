return {
  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 1000,
        virt_text_pos = "eol", -- 行尾显示
      },
      numhl = true,
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    opts = {
      keymaps = {
        view = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
          { "n", "<Esc>", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
          {
            "n",
            "<leader>hr",
            function()
              require("gitsigns").reset_hunk()
            end,
            { desc = "Reset hunk (回退光标处修改)" },
          },
          {
            "v",
            "<leader>hr",
            function()
              require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end,
            { desc = "Reset hunk (选区)" },
          },
          { "n", "<leader>ho", "do", { desc = "Diff obtain (还原此 hunk)" } },
          {
            "n",
            "<leader>hR",
            function()
              require("gitsigns").reset_buffer()
            end,
            { desc = "Reset buffer (回退整个文件)" },
          },
        },
        file_panel = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
          { "n", "<Esc>", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
        },
        file_history_panel = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
          { "n", "<Esc>", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
        },
      },
    },
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "sindrets/diffview.nvim",
      "ibhagwan/fzf-lua",
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Show Neogit UI" },
    },
    opts = {
      integrations = {
        diffview = true,
      },
    },
  },
}
