local api = vim.api
local winbar_group

local function update_winbar(args)
  if api.nvim_get_current_buf() ~= args.buf then
    return
  end
  local state = require("neo-tree.sources.manager").get_state_for_window()
  if not (state and state.bufnr == args.buf and state.tree) then
    return
  end
  local ok, node = pcall(state.tree.get_node, state.tree, api.nvim_win_get_cursor(0)[1])
  if ok and node then
    local name = vim.fn.fnamemodify(node:get_id(), ":t")
    local title = "%#Comment# " .. name:gsub("%%", "%%%%")
    if vim.wo.winbar ~= title then
      vim.wo.winbar = title
    end
  end
end

local function attach_winbar(args)
  local buf = args.bufnr or api.nvim_get_current_buf()
  winbar_group = winbar_group or api.nvim_create_augroup("NeoTreeWinbarPath", { clear = true })
  -- Re-entering a tree must not add another cursor callback to the same buffer.
  if #api.nvim_get_autocmds({ group = winbar_group, event = "CursorMoved", buffer = buf }) == 0 then
    api.nvim_create_autocmd("CursorMoved", {
      group = winbar_group,
      buffer = buf,
      callback = update_winbar,
      desc = "Show the current Neo-tree node in its window title",
    })
  end
  update_winbar({ buf = buf })
end

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons", -- optional, but recommended
    },
    lazy = true,
    cmd = "Neotree",
    init = function()
      -- Preserve both `nvim directory` and `:edit directory` before the first
      -- tree command. File editing alone should not load the explorer.
      api.nvim_create_autocmd("BufEnter", {
        group = api.nvim_create_augroup("DotnvimNeoTreeDirectory", { clear = true }),
        callback = function(args)
          if package.loaded["neo-tree"] then
            return true
          end
          local stat = args.file ~= "" and vim.uv.fs_stat(args.file)
          if stat and stat.type == "directory" then
            require("neo-tree")
            -- Its BufEnter handlers were installed during this event, so
            -- explicitly hand over this first directory as well.
            require("neo-tree.setup.netrw").hijack()
            return true
          end
        end,
      })
    end,
    opts = {
      close_if_last_window = true,
      window = {
        width = 25,
        position = "left",
        mappings = {
          -- Keep Space exclusively as the leader prefix; Enter opens/toggles nodes.
          ["<space>"] = "none",
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
        window = {
          mappings = {
            ["<leader>sg"] = {
              function(state)
                local node = state.tree and state.tree:get_node()
                if not node or (node.type ~= "directory" and node.type ~= "file") then
                  return
                end
                local path = node:get_id()
                local dir = node.type == "directory" and path or vim.fn.fnamemodify(path, ":h")
                require("fzf-lua").live_grep({ cwd = dir })
              end,
              desc = "Grep in selected directory",
            },
          },
        },
        use_libuv_file_watcher = true,
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true,
        },
      },
      event_handlers = {
        {
          event = "neo_tree_buffer_enter",
          handler = attach_winbar,
        },
      },
    },
  },
}
