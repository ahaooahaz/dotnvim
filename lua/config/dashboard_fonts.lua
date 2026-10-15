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
