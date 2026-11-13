-- Diffview navigation reuses normal editors without losing their jump history.
local api = vim.api
local editor_wins = {}

local function is_editor_win(win)
  if not win or not api.nvim_win_is_valid(win) then
    return false
  end
  if vim.fn.win_gettype(win) ~= "" then
    return false
  end

  local buf = api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" or vim.wo[win].diff then
    return false
  end
  if api.nvim_buf_get_name(buf):match("^diffview://") then
    return false
  end

  local lib = package.loaded["diffview.lib"]
  return not (lib and lib.tabpage_to_view(api.nvim_win_get_tabpage(win)))
end

local function setup_diffview_editor_tracking()
  local function remember_editor()
    local win = api.nvim_get_current_win()
    if is_editor_win(win) then
      -- These three events often arrive together for the same window.
      if editor_wins[1] == win then
        return
      end
      for i = #editor_wins, 1, -1 do
        if editor_wins[i] == win or not api.nvim_win_is_valid(editor_wins[i]) then
          table.remove(editor_wins, i)
        end
      end
      table.insert(editor_wins, 1, win)
    end
  end

  remember_editor()
  api.nvim_create_autocmd({ "BufEnter", "WinEnter", "TabEnter" }, {
    group = api.nvim_create_augroup("DotnvimDiffviewEditor", { clear = true }),
    callback = remember_editor,
    desc = "Remember the editing window, not Neogit or Diffview windows",
  })
end

local function find_editor_win(lib)
  -- Tab/split creation briefly shows the source file in a new plugin window.
  -- Keep an MRU list so those transient windows cannot erase the real editor.
  for _, win in ipairs(editor_wins) do
    if is_editor_win(win) then
      return win
    end
  end

  local tabs = api.nvim_list_tabpages()
  local previous = lib.get_prev_non_view_tabpage()
  if previous then
    table.insert(tabs, 1, previous)
  end
  for _, tab in ipairs(tabs) do
    if not lib.tabpage_to_view(tab) then
      local current = api.nvim_tabpage_get_win(tab)
      if is_editor_win(current) then
        return current
      end
      for _, win in ipairs(api.nvim_tabpage_list_wins(tab)) do
        if is_editor_win(win) then
          return win
        end
      end
    end
  end
end

local function edit_diff_file()
  local lib = require("diffview.lib")
  local view = lib.get_current_view()
  local file = view and view:infer_cur_file()
  if not file then
    return
  end
  if vim.fn.filereadable(file.absolute_path) ~= 1 then
    vim.notify("File does not exist on disk: " .. file.absolute_path, vim.log.levels.ERROR)
    return
  end

  -- Match Diffview's default: use the main (normally right-hand) diff window.
  local cursor = { 1, 0 }
  if file == view.cur_entry then
    local main = view.cur_layout:get_main_win()
    if main:is_valid() then
      cursor = api.nvim_win_get_cursor(main.id)
    end
  end

  local win = find_editor_win(lib)
  if win then
    api.nvim_set_current_win(win)
  else
    -- Never replace a Neogit, terminal, or another Diffview window.
    vim.cmd("tabnew")
    -- A new tab inherits its source window's jumplist. Drop only this new
    -- window's list, which otherwise contains Neogit / diffview:// entries.
    vim.cmd("clearjumps")
  end

  -- Record the source in this editor's jumplist, not the diff window's list.
  -- This also makes Ctrl-O work when jumping to another line of the same file.
  vim.cmd("normal! m'")
  local buf = require("diffview.utils").find_file_buffer(file.absolute_path)
  if buf then
    if buf ~= api.nvim_get_current_buf() then
      vim.cmd("buffer " .. buf)
    end
  else
    vim.cmd("edit " .. vim.fn.fnameescape(file.absolute_path))
  end
  require("diffview.utils").set_cursor(0, cursor[1], cursor[2])
  -- Keep the view and its window options intact so gt/gT can return to it.
end

-- Neogit's fzf-lua finder only returns selected entries. Keep this override
-- local to Diff -> range so other Neogit pickers retain their usual behavior.
local function pick_ref(refs, prompt, callback)
  local completed = false
  local function complete(ref)
    if completed then
      return
    end
    completed = true
    ref = ref and vim.trim(ref)
    callback(ref ~= "" and ref or nil)
  end

  local function cancel()
    complete(nil)
  end

  require("fzf-lua").fzf_exec(refs, {
    prompt = prompt .. "> ",
    previewer = false,
    fzf_opts = {
      ["--no-multi"] = true,
      ["--layout"] = "reverse",
      ["--header"] = "Enter: select / input if no match | Ctrl-Y: use input | Esc: cancel",
    },
    winopts = {
      height = 0.4,
      on_close = function()
        -- fzf-lua closes the window before dispatching the accepted action.
        -- Defer cancellation so it cannot win the race against that action.
        vim.schedule(cancel)
      end,
    },
    actions = {
      ["enter"] = function(selected, opts)
        complete(selected[1] or opts.last_query)
      end,
      ["ctrl-y"] = function(_, opts)
        complete(opts.last_query)
      end,
      ["esc"] = cancel,
      ["ctrl-c"] = cancel,
      ["ctrl-q"] = cancel,
    },
  })
end

local function neogit_range(popup)
  local git = require("neogit.lib.git")
  local input = require("neogit.lib.input")
  local select_ref = require("neogit.lib.async").wrap(pick_ref, 3)
  local item = popup:get_env("item")
  local section = popup:get_env("section")
  local commit
  if section and (section.name == "log" or section.name == "recent") then
    commit = item and item.name
  end

  -- Stable, linear-time deduplication matters in repos with many refs/tags.
  local refs, seen = {}, {}
  local function add_refs(list)
    for _, ref in ipairs(list) do
      if ref and not seen[ref] then
        seen[ref] = true
        refs[#refs + 1] = ref
      end
    end
  end
  add_refs({ git.branch.current() or "HEAD" })
  add_refs(git.branch.get_all_branches(false))
  add_refs(git.tag.list())
  add_refs(git.refs.heads())
  if commit and not seen[commit] then
    table.insert(refs, 1, commit)
  end

  local from = select_ref(refs, "Diff for range from")
  if not from then
    return
  end

  local to = select_ref(refs, "Diff from " .. from .. " to")
  if not to then
    return
  end

  local choice = input.get_choice("Select type", {
    values = { "&1. Range (a..b)", "&2. Symmetric Difference (a...b)", "&3. Cancel" },
    default = 3,
  })
  popup:close()

  local separator = ({ ["1"] = "..", ["2"] = "..." })[choice]
  if separator then
    local viewer = require("neogit.config").get_diff_viewer()
    require("neogit.integrations." .. viewer).open("range", from .. separator .. to)
  end
end

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
          { "n", "gf", edit_diff_file, { desc = "Edit working file in the original editor" } },
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
          { "n", "gf", edit_diff_file, { desc = "Edit working file in the original editor" } },
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
          { "n", "<Esc>", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
        },
        file_history_panel = {
          { "n", "gf", edit_diff_file, { desc = "Edit working file in the original editor" } },
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
          { "n", "<Esc>", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
        },
      },
    },
    config = function(_, opts)
      setup_diffview_editor_tracking()
      require("diffview").setup(opts)
    end,
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
      -- 去掉 commit 视图中 l 键的 LogPopup 映射，让 l 恢复为正常方向键
      mappings = {
        popup = {
          ["l"] = false,
        },
      },
    },
    config = function(_, opts)
      require("neogit").setup(opts)
      require("neogit.popups.diff.actions").range = neogit_range
    end,
  },
}
