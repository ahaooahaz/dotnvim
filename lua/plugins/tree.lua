return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons", -- optional, but recommended
    },
    lazy = false,
    opts = {
      close_if_last_window = true,
      window = {
        width = 25,
        position = "left",
        mappings = {
          ["Y"] = {
            function(state)
              local node = state.tree:get_node()
              local path = node:get_id()
              vim.fn.setreg("+", path)
              vim.fn.setreg('"', path)
              vim.notify("Copied: " .. path)
            end,
            desc = "copy_absolute_path",
          },
        },
      },
      filesystem = {
        use_libuv_file_watcher = true,
      },
      event_handlers = {
        {
          event = "neo_tree_buffer_enter",
          handler = function(args)
            local group = vim.api.nvim_create_augroup("NeoTreeWinbarPath", { clear = false })
            vim.api.nvim_create_autocmd("CursorMoved", {
              group = group,
              buffer = args.bufnr or 0,
              callback = function()
                local ok, mgr = pcall(require, "neo-tree.sources.manager")
                if not ok then
                  return
                end
                local state = mgr.get_state("filesystem")
                if not (state and state.tree) then
                  return
                end
                local linenr = vim.api.nvim_win_get_cursor(0)[1]
                local got, node = pcall(state.tree.get_node, state.tree, linenr)
                if got and node then
                  local name = vim.fn.fnamemodify(node:get_id(), ":t")
                  vim.wo.winbar = "%#Comment# " .. name:gsub("%%", "%%%%")
                end
              end,
            })
          end,
        },
      },
    },
  },
}
