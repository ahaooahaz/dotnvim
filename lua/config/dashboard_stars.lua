-- A gently flickering HOW in the dashboard's original header area.
local M = {
  config = {
    -- RGB color in #RRGGBB form; use false to follow the theme's normal text.
    color = "#FF0000",
  },
}
local api, uv = vim.api, vim.uv
local ns = api.nvim_create_namespace("dashboard_stars")
local states = {}
local width, height, interval = 42, 8, 80
-- # cells flicker; literal Z/z stay readable beside HOW. The whole group is centered.
local logo = {
  "##   ##    #####    ##   ##           Z",
  "##   ##   ##   ##   ##   ##        Z   ",
  "##   ##   ##   ##   ##   ##     z      ",
  "#######   ##   ##   ## # ##   z        ",
  "##   ##   ##   ##   ## # ##            ",
  "##   ##   ##   ##   #######            ",
  "##   ##    #####     ## ##             ",
}
-- Vary ink density rather than color; even the lightest stroke stays visible.
local glyphs = { "▒", "▓", "█" }
local ascii_glyphs = { ":", "+", "#" }
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

local function active(state)
  return not state.closed
    and state.focused
    and api.nvim_win_is_valid(state.win)
    and api.nvim_get_current_win() == state.win
    and api.nvim_get_current_buf() == state.buf
end

local function pixels(seed)
  -- Keep our random sequence separate from other plugins' math.random state.
  local function random()
    seed = (seed * 16807) % 2147483647
    return (seed - 1) / 2147483646
  end
  local ret = {}
  local function add(x, y, char)
    ret[#ret + 1] = {
      x = x,
      y = y,
      char = char ~= "#" and char or nil,
      phase = random() * math.pi * 2,
      speed = 0.7 + random() * 1.1,
    }
  end
  local left = math.floor((width - #logo[1]) / 2)

  for y, line in ipairs(logo) do
    for x = 1, #line do
      local char = line:sub(x, x)
      if char ~= " " then
        add(left + x - 1, y - 1, char)
      end
    end
  end
  return ret
end

local function draw(state)
  -- Rendering and animation have separate lifetimes: an inactive dashboard
  -- still needs its header, especially after Snacks re-renders its buffer.
  if state.closed or not state.row or not api.nvim_buf_is_valid(state.buf) then
    return
  end
  local cells = {}
  for y = 1, height do
    cells[y] = {}
    for x = 1, state.width do
      cells[y][x] = { " " }
    end
  end
  for _, pixel in ipairs(state.pixels) do
    local char = pixel.char
    if not char then
      local light = (math.sin(state.time * pixel.speed + pixel.phase) + 1) / 2
      local level = math.min(#glyphs, 1 + math.floor(light * #glyphs))
      char = glyphs[level]
      if vim.fn.strdisplaywidth(char) ~= 1 then
        char = ascii_glyphs[level]
      end
    end
    local x = math.floor(pixel.x * state.width / width) + 1
    cells[pixel.y + 1][x] = { char, highlight }
  end
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
  draw(state)
  if not active(state) then
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
      if not active(state) then
        stop(state)
        return
      end
      local now = uv.hrtime()
      state.time = state.time + math.min((now - state.last_tick) / 1e9, 0.2)
      state.last_tick = now
      draw(state)
    end)
  end)
end

local function attach(dashboard, pos)
  local state = states[dashboard.buf]
  if not state then
    highlights()
    state = {
      buf = dashboard.buf,
      timer = assert(uv.new_timer()),
      group = api.nvim_create_augroup("dashboard_stars_" .. dashboard.buf, { clear = true }),
      pixels = pixels(uv.hrtime() % 2147483646 + 1),
      focused = true,
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
    on({ "BufEnter", "WinEnter", "TabEnter" }, {
      callback = function()
        vim.schedule(function()
          resume(state)
        end)
      end,
    })
    on({ "BufLeave", "WinLeave", "TabLeave", "FocusLost" }, {
      callback = function(ev)
        if ev.event == "FocusLost" then
          state.focused = false
        end
        stop(state)
      end,
    })
    on("FocusGained", {
      callback = function()
        state.focused = true
        resume(state)
      end,
    })
    on("ColorScheme", {
      callback = function()
        highlights()
        draw(state)
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
  state.win = dashboard.win
  state.row = pos[1] - 1
  local left = math.max(0, pos[2] + 1)
  local available = math.max(1, math.min(dashboard.opts.width, api.nvim_win_get_width(state.win) - left))
  state.width = math.min(width, available)
  state.col = left + math.floor((available - state.width) / 2)
end

-- Keep a static HOW in the same buffer as the menu; the animation only adds
-- changing ink density on top. Losing focus must never leave an empty header.
-- Its render hook follows Snacks' centering and resize layout automatically.
function M.section()
  local lines = {}
  local char = vim.fn.strdisplaywidth(glyphs[2]) == 1 and glyphs[2] or ascii_glyphs[2]
  local left = math.floor((width - #logo[1]) / 2)
  for y = 1, height do
    local line = logo[y] or (" "):rep(#logo[1])
    lines[y] = (" "):rep(left) .. line:gsub("#", char) .. (" "):rep(width - left - #logo[1])
  end
  return {
    text = { { table.concat(lines, "\n"), hl = highlight } },
    align = "center",
    padding = 2,
    render = attach,
  }
end

return M
