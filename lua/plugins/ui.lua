-- Dashboard bitmap fonts, HOW rendering, and animation share one lazy owner.
local function create_dashboard()
  local fonts = (function()
    -- Bitmap typefaces for HOW, independent of its color and animation.
    local fonts = {
      block = {
        "##   ##    #####    ##   ##",
        "##   ##   ##   ##   ##   ##",
        "##   ##   ##   ##   ##   ##",
        "#######   ##   ##   ## # ##",
        "##   ##   ##   ##   ## # ##",
        "##   ##   ##   ##   #######",
        "##   ##    #####     ## ## ",
      },
      thin = {
        "#   #    ###    #   #",
        "#   #   #   #   #   #",
        "#   #   #   #   #   #",
        "#####   #   #   # # #",
        "#   #   #   #   # # #",
        "#   #   #   #   # # #",
        "#   #    ###     # # ",
      },
      rounded = {
        "##   ##     ###     ##   ##",
        "##   ##    ## ##    ##   ##",
        "##   ##   ##   ##   ##   ##",
        "#######   ##   ##   ## # ##",
        "##   ##   ##   ##   ## # ##",
        "##   ##    ## ##     ## ## ",
        "##   ##     ###       # #  ",
      },
    }

    -- A consistent right lean, not a different animation or fill character.
    fonts.slant = {}
    for y, line in ipairs(fonts.block) do
      local offset = math.floor((#fonts.block - y) / 2)
      fonts.slant[y] = (" "):rep(offset) .. line .. (" "):rep(3 - offset)
    end

    -- Offset a light shadow down and right, then put the solid face on top.
    -- ASCII markers keep cell positions independent of UTF-8 byte lengths.
    local shadow = {}
    for y = 1, #fonts.block + 1 do
      shadow[y] = {}
      for x = 1, #fonts.block[1] + 1 do
        shadow[y][x] = " "
      end
    end
    for y, line in ipairs(fonts.block) do
      for x = 1, #line do
        if line:sub(x, x) == "#" then
          shadow[y + 1][x + 1] = "."
        end
      end
    end
    for y, line in ipairs(fonts.block) do
      for x = 1, #line do
        if line:sub(x, x) == "#" then
          shadow[y][x] = "#"
        end
      end
    end
    fonts.shadow = {}
    for y, row in ipairs(shadow) do
      fonts.shadow[y] = table.concat(row)
    end

    local sleep = { "         Z", "      Z   ", "   z      ", " z        " }
    local M = {}

    function M.names()
      return { "shadow", "block", "thin", "rounded", "slant" }
    end

    function M.get(name)
      local font = fonts[name]
      if not font then
        return nil, "Unknown HOW font: " .. tostring(name) .. ". Choose " .. table.concat(M.names(), ", ") .. "."
      end
      local rows = {}
      for y, line in ipairs(font) do
        rows[y] = line .. "  " .. (sleep[y] or (" "):rep(10))
      end
      return rows
    end

    return M
  end)()

  -- A solid, breathing HOW with selectable bitmap typefaces.
  local M = {
    config = {
      -- RGB color in #RRGGBB form; use false to follow the theme's normal text.
      color = "#FF0000",
      -- Typeface: shadow, block, thin, rounded or slant. :HowFont previews changes live.
      font = "shadow",
    },
  }
  local api, uv = vim.api, vim.uv
  local ns = api.nvim_create_namespace("dashboard_stars")
  local states = {}
  local width, height, interval = 42, 8, 80
  local function solid_char()
    return vim.fn.strdisplaywidth("█") == 1 and "█" or "#"
  end
  local function shadow_char()
    return vim.fn.strdisplaywidth("░") == 1 and "░" or "."
  end
  local highlight = "DashboardHow"

  local function highlights()
    local color = M.config.color
    api.nvim_set_hl(0, highlight, color and { fg = color } or { link = "Normal" })
  end

  local function stop(state)
    state.timer:stop()
  end

  local function close(state)
    if state.closed then
      return
    end
    state.closed = true
    stop(state)
    state.timer:close()
    states[state.buf] = nil
    if api.nvim_buf_is_valid(state.buf) then
      api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
    end
    api.nvim_del_augroup_by_id(state.group)
  end

  local function visible(state)
    -- A popup, another split or another application may own focus while this
    -- dashboard remains on screen. Only hiding/replacing its window pauses it.
    return not state.closed
      and api.nvim_win_is_valid(state.win)
      and api.nvim_win_get_buf(state.win) == state.buf
      and api.nvim_win_get_tabpage(state.win) == api.nvim_get_current_tabpage()
  end

  local function pixels(logo)
    local ret = {}
    local left = math.floor((width - #logo[1]) / 2)
    for y, line in ipairs(logo) do
      for x = 1, #line do
        local char = line:sub(x, x)
        if char ~= " " then
          ret[#ret + 1] = { x = left + x - 1, y = y - 1, char = char ~= "#" and char or nil }
        end
      end
    end
    -- In narrow windows several source cells may merge; keep solid strokes above shadows.
    table.sort(ret, function(a, b)
      return a.char == "." and b.char ~= "."
    end)
    return ret
  end

  local function breathe(state)
    local color = api.nvim_get_hl(0, { name = highlight, link = false }).fg
    if not color then
      api.nvim_set_hl(0, state.highlight, { link = highlight })
      return
    end
    -- All strokes breathe together over four seconds, never below 65% brightness.
    local brightness = 0.65 + 0.35 * (1 + math.cos(state.time * math.pi / 2)) / 2
    local function channel(shift)
      return math.floor((math.floor(color / 2 ^ shift) % 256) * brightness + 0.5)
    end
    local fg = string.format("#%02X%02X%02X", channel(16), channel(8), channel(0))
    api.nvim_set_hl(0, state.highlight, { fg = fg })
  end

  local function draw(state)
    -- Rendering and animation have separate lifetimes: an inactive dashboard
    -- still needs its header, especially after Snacks re-renders its buffer.
    if state.closed or not state.row or not api.nvim_buf_is_valid(state.buf) then
      return
    end
    local solid, shade = solid_char(), shadow_char()
    local cells = state.cells
    if
      not cells
      or state.cells_width ~= state.width
      or state.cells_font ~= state.font
      or state.cells_solid ~= solid
      or state.cells_shade ~= shade
    then
      cells = {}
      for y = 1, height do
        cells[y] = {}
        for x = 1, state.width do
          cells[y][x] = { " " }
        end
      end
      for _, pixel in ipairs(state.pixels) do
        local x = math.floor(pixel.x * state.width / width) + 1
        local char = pixel.char == "." and shade or pixel.char or solid
        cells[pixel.y + 1][x] = { char, state.highlight }
      end
      state.cells = cells
      state.cells_width, state.cells_font = state.width, state.font
      state.cells_solid, state.cells_shade = solid, shade
    end
    breathe(state)
    local lines = api.nvim_buf_line_count(state.buf)
    for y, chunks in ipairs(cells) do
      if state.row + y > lines then
        break
      end
      api.nvim_buf_set_extmark(state.buf, ns, state.row + y - 1, state.col, {
        id = y,
        virt_text = chunks,
        virt_text_pos = "overlay",
        hl_mode = "replace",
        priority = 110,
        strict = false,
      })
    end
  end

  local function resume(state)
    if visible(state) and state.font ~= M.config.font then
      state.dashboard:update()
      return
    end
    draw(state)
    if not visible(state) then
      if not state.closed then
        stop(state)
      end
      return
    end
    if state.timer:is_active() then
      return
    end
    state.last_tick = uv.hrtime()
    state.timer:start(interval, interval, function()
      -- At most one pending frame, even when Neovim's main loop is busy.
      if state.pending then
        return
      end
      state.pending = true
      vim.schedule(function()
        state.pending = false
        if state.closed then
          return
        end
        if not visible(state) then
          stop(state)
          return
        end
        local now = uv.hrtime()
        state.time = state.time + math.min((now - state.last_tick) / 1e9, 0.2)
        state.last_tick = now
        -- Glyphs stay fixed; changing their shared highlight animates every
        -- stroke without rebuilding cells or rewriting eight extmarks/frame.
        breathe(state)
      end)
    end)
  end

  local function attach(dashboard, pos, logo)
    local state = states[dashboard.buf]
    if not state then
      highlights()
      state = {
        buf = dashboard.buf,
        timer = assert(uv.new_timer()),
        group = api.nvim_create_augroup("dashboard_stars_" .. dashboard.buf, { clear = true }),
        highlight = "DashboardHowAnimation" .. dashboard.buf,
        time = 0,
      }
      states[state.buf] = state
      local function on(events, opts)
        opts.group = state.group
        api.nvim_create_autocmd(events, opts)
      end
      on("User", {
        pattern = "SnacksDashboardUpdatePost",
        callback = function()
          -- Snacks rewrites the buffer during layout: restore only our overlay.
          if not state.closed then
            api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
            resume(state)
          end
        end,
      })
      on({ "BufEnter", "BufWinEnter", "WinEnter", "TabEnter", "WinClosed" }, {
        callback = function()
          vim.schedule(function()
            resume(state)
          end)
        end,
      })
      on("ColorScheme", {
        callback = function()
          highlights()
          draw(state)
        end,
      })
      on("OptionSet", {
        pattern = { "ambiwidth", "emoji" },
        callback = function()
          if not state.closed then
            state.dashboard:update()
          end
        end,
      })
      on({ "BufWipeout", "BufDelete" }, {
        buffer = state.buf,
        callback = function()
          close(state)
        end,
      })
      on("VimLeavePre", {
        callback = function()
          close(state)
        end,
      })
    end
    state.dashboard = dashboard
    state.font = M.config.font
    state.pixels = pixels(logo)
    state.win = dashboard.win
    state.row = pos[1] - 1
    local left = math.max(0, pos[2] + 1)
    local available = math.max(1, math.min(dashboard.opts.width, api.nvim_win_get_width(state.win) - left))
    state.width = math.min(width, available)
    state.col = left + math.floor((available - state.width) / 2)
  end

  -- Keep a static HOW in the same buffer as the menu; the animation only adds
  -- a shared breathing highlight on top. Losing focus must never leave an empty header.
  -- Its render hook follows Snacks' centering and resize layout automatically.
  function M.section()
    local logo = assert(fonts.get(M.config.font))
    local lines = {}
    local char, shade = solid_char(), shadow_char()
    local left = math.floor((width - #logo[1]) / 2)
    for y = 1, height do
      local line = logo[y] or (" "):rep(#logo[1])
      lines[y] = (" "):rep(left) .. line:gsub("#", char):gsub("%.", shade) .. (" "):rep(width - left - #logo[1])
    end
    return {
      text = { { table.concat(lines, "\n"), hl = highlight } },
      align = "center",
      padding = 2,
      render = function(dashboard, pos)
        attach(dashboard, pos, logo)
      end,
    }
  end

  -- Preview only changes the current session; edit config.font to keep a choice.
  function M.set_font(name)
    local logo, err = fonts.get(name)
    if not logo then
      return false, err
    end
    M.config.font = name
    for _, state in pairs(states) do
      if
        not state.closed
        and api.nvim_buf_is_valid(state.buf)
        and api.nvim_win_is_valid(state.win)
        and api.nvim_win_get_buf(state.win) == state.buf
      then
        state.dashboard:update()
      end
    end
    return true
  end

  api.nvim_create_user_command("HowFont", function(opts)
    local function select(name)
      if name then
        local ok, err = M.set_font(name)
        if not ok then
          vim.notify(err, vim.log.levels.WARN)
        end
      end
    end
    if opts.args == "" then
      vim.ui.select(fonts.names(), { prompt = "HOW font (session preview):" }, select)
    else
      select(opts.args)
    end
  end, {
    nargs = "?",
    desc = "Preview a HOW header typeface (persist with config.font)",
    complete = function(prefix)
      return vim.tbl_filter(function(name)
        return name:sub(1, #prefix) == prefix
      end, fonts.names())
    end,
  })

  return M
end

local dashboard
local function dashboard_section()
  dashboard = dashboard or create_dashboard()
  return dashboard.section()
end

-- Statusline process totals and current tab/window indexes.
local api = vim.api
-- winlayout() excludes floats, so no per-window config calls or stale cache
-- are needed, even when an existing window changes between float and split.
local function count_layout_windows(layout)
  if layout[1] == "leaf" then
    return 1
  end
  local count = 0
  for _, child in ipairs(layout[2] or {}) do
    count = count + count_layout_windows(child)
  end
  return count
end

local function process_totals()
  local tabs = #api.nvim_list_tabpages()
  local windows = 0
  for tabnr = 1, tabs do
    windows = windows + count_layout_windows(vim.fn.winlayout(tabnr))
  end
  return ("%dt:%dw"):format(tabs, windows)
end

local function active_position()
  return ("[T%d:W%d]"):format(vim.fn.tabpagenr(), vim.fn.winnr())
end

local function add_navigation(sections, replace_clock)
  sections.lualine_z = replace_clock and {} or (sections.lualine_z or {})
  -- Use the rightmost region's own colors for contrast; bold only the badge.
  table.insert(sections.lualine_z, {
    process_totals,
    color = {},
    separator = "",
    padding = 1,
  })
  table.insert(sections.lualine_z, {
    active_position,
    color = { gui = "bold" },
    separator = "",
    padding = { left = 0, right = 1 },
  })
end

local function configure_statusline_navigation(opts)
  opts.sections = opts.sections or {}
  add_navigation(opts.sections, true)
  -- Extensions replace the main statusline. Keep the summary visible there
  -- too, without changing bufferline or adding any per-window UI.
  for i, extension in ipairs(opts.extensions or {}) do
    if type(extension) == "string" then
      extension = require("lualine.extensions." .. extension)
    end
    extension = vim.deepcopy(extension)
    extension.sections = extension.sections or {}
    add_navigation(extension.sections)
    opts.extensions[i] = extension
  end
end

return {
  {
    "tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
  {
    "snacks.nvim",
    opts = {
      dashboard = {
        sections = {
          dashboard_section,
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      },
      notifier = {
        timeout = 6000,
        width = { min = 40, max = 0.6 },
        height = { min = 1, max = 0.8 },
        style = "fancy",
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    lazy = false,
    opts = {
      options = {
        separator_style = { "", "" },
        indicator = {
          icon = "",
          style = "none",
        },
      },
      highlights = {
        background = { bg = "none" },
        fill = { bg = "none" },
        buffer_selected = { bg = "none", fg = "#ff0000" },
        buffer_visible = { bg = "none" },
        close_button = { bg = "none" },
        close_button_selected = { bg = "none" },
        close_button_visible = { bg = "none" },
        duplicate = { bg = "none" },
        duplicate_selected = { bg = "none" },
        duplicate_visible = { bg = "none" },
        error = { bg = "none" },
        error_selected = { bg = "none" },
        error_visible = { bg = "none" },
        hint = { bg = "none" },
        hint_selected = { bg = "none" },
        hint_visible = { bg = "none" },
        indicator_selected = { bg = "none" },
        indicator_visible = { bg = "none" },
        info = { bg = "none" },
        info_selected = { bg = "none" },
        info_visible = { bg = "none" },
        modified = { bg = "none" },
        modified_selected = { bg = "none" },
        modified_visible = { bg = "none" },
        numbers = { bg = "none" },
        numbers_selected = { bg = "none" },
        numbers_visible = { bg = "none" },
        offset_separator = { bg = "none" },
        pick = { bg = "none" },
        pick_selected = { bg = "none" },
        pick_visible = { bg = "none" },
        separator = { bg = "none" },
        separator_selected = { bg = "none" },
        separator_visible = { bg = "none" },
        tab = { bg = "none" },
        tab_close = { bg = "none" },
        tab_selected = { bg = "none" },
        tab_separator = { bg = "none" },
        tab_separator_selected = { bg = "none" },
        trunc_marker = { bg = "none" },
        warning = { bg = "none" },
        warning_selected = { bg = "none" },
        warning_visible = { bg = "none" },
      },
    },
    config = function(_, opts)
      vim.o.termguicolors = true
      require("bufferline").setup(opts)
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local neocodeium_symbols = {
        status = {
          [0] = "󰚩 ",
          [1] = "󱚧 ",
          [2] = "󱙻 ",
          [3] = "󱙺 ",
          [4] = "󱙺 ",
          [5] = "󱚠 ",
          [6] = "󱚠 ",
        },
        server_status = {
          [0] = "󰣺 ",
          [1] = "󰣻 ",
          [2] = "󰣽 ",
        },
      }

      local function neocodeium_status()
        local ok, neocodeium = pcall(require, "neocodeium")
        if not ok then
          return ""
        end

        local status, server_status = neocodeium.get_status()

        return (neocodeium_symbols.status[status] or "") .. (neocodeium_symbols.server_status[server_status] or "")
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = {
          "NeoCodeiumServer*",
          "NeoCodeium*Enabled",
          "NeoCodeium*Disabled",
        },
        callback = function()
          pcall(function()
            require("lualine").refresh()
          end)
        end,
      })

      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}

      table.insert(opts.sections.lualine_x, 1, {
        neocodeium_status,
        color = { fg = "yellow" },
        cond = function()
          return package.loaded["neocodeium"] ~= nil
        end,
      })
      configure_statusline_navigation(opts)
    end,
  },
  {
    "lukas-reineke/virt-column.nvim",
    opts = {},
    config = function()
      require("virt-column").setup({
        char = "│",
        virtcolumn = "120",
        highlight = "Comment",
      })

      local ft_columns = {
        cpp = "120",
        c = "120",
        python = "80",
        markdown = "100",
        lua = "100",
        go = "120",
      }
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local col = ft_columns[args.match]
          if col then
            require("virt-column").update({ virtcolumn = col })
          end
        end,
      })
    end,
  },
  {
    "stevearc/quicker.nvim",
    ft = "qf",
    ---@module "quicker"
    ---@type quicker.SetupOptions
    opts = {},
  },
}
