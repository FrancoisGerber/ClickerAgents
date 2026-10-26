-- The target, drawn as a machine: a service node that cracks as its HP drains,
-- and the logo badge the title screen shows.
local Draw = require("ui.draw")
local Config = require("config")

local px, rrect, frame = Draw.px, Draw.rrect, Draw.frame
local C, ART = Config.C, Config.ART

local M = {}

-- A vuln is a vulnerable service: a chassis with pins into the host, an aperture
-- where the flaw sits, and cracks that spread as its HP drains. No creature —
-- the thing you are breaking is a socket, not a beast.

local function seg(x1, y1, x2, y2, c, t)
  local dx, dy = x2 - x1, y2 - y1
  local n = math.max(math.abs(dx), math.abs(dy), 1)
  local step = t or 2
  local i = 0
  while i <= n do
    local k = i / n
    px(math.floor(x1 + dx * k), math.floor(y1 + dy * k), step, step, c)
    i = i + step
  end
end

-- damage -> how far the cracks have spread; each entry appears at a threshold
local CRACKS = {
  { 0.12, { { 0, 0 }, { 10, 12 }, { 5, 26 }, { 14, 36 } } },
  { 0.32, { { 96, 2 }, { 86, 16 }, { 92, 30 }, { 82, 42 } } },
  { 0.52, { { 8, 44 }, { 20, 50 }, { 26, 64 }, { 16, 74 } } },
  { 0.72, { { 88, 46 }, { 76, 56 }, { 82, 70 }, { 70, 80 } } },
  { 0.88, { { 40, 8 }, { 52, 20 }, { 46, 34 } } },
}

local function ledColour(frac)
  if frac > 0.6 then return C.gain end
  if frac > 0.3 then return C.gold end
  return C.warn
end

local function drawVuln(x, y, frac, flash, k)
  frac = frac or 1
  k = k or 1
  local damage = 1 - math.max(0, math.min(1, frac))
  local body = flash and C.text or C.panel
  local edge = flash and C.text or C.rule
  local dark = ART.monsterDk
  local hot  = flash and C.flashLt or C.gold
  local function R(ox, oy, w, h, c) px(x + ox * k, y + oy * k, w * k, h * k, c) end
  local function F(ox, oy, w, h, t, c) frame(x + ox * k, y + oy * k, w * k, h * k, t * k, c) end
  local function RR(ox, oy, w, h, r, c) rrect(x + ox * k, y + oy * k, w * k, h * k, r * k, c) end

  R(28, 106, 96, 8, ART.shadow)                     -- contact shadow
  R(16, 46, 8, 6, edge); R(16, 74, 8, 6, edge)      -- pins into the host
  R(128, 46, 8, 6, edge); R(128, 74, 8, 6, edge)

  RR(24, 34, 104, 64, 6, body)                      -- chassis
  F(24, 34, 104, 64, 2, edge)

  for i = 0, 2 do                                   -- vent slats
    R(34, 48 + i * 12, 14, 4, dark)
    R(104, 48 + i * 12, 14, 4, dark)
  end

  RR(56, 44, 40, 44, 4, ART.floor)                  -- aperture: the flaw itself
  F(56, 44, 40, 44, 2, edge)
  local glow = (damage > 0.5) and C.hp or hot
  R(64, 56, 24, 20, glow)
  R(68, 60, 16, 12, C.flashLt)

  for _, c in ipairs(CRACKS) do                     -- cracks spread with damage
    if damage >= c[1] then
      local pts = c[2]
      for i = 1, #pts - 1 do
        seg(x + (24 + pts[i][1]) * k, y + (34 + pts[i][2]) * k,
            x + (24 + pts[i + 1][1]) * k, y + (34 + pts[i + 1][2]) * k,
            C.warn, math.max(2, math.floor(2 * k)))
      end
    end
  end

  R(70, 22, 12, 6, edge)                            -- status LED
  R(72, 24, 8, 3, ledColour(frac))
  if flash then F(22, 32, 108, 68, 2, C.text) end
end

local function drawBossVuln(x, y, frac, k)
  frac = frac or 1
  k = k or 1
  local damage = 1 - math.max(0, math.min(1, frac))
  local edge = C.rule
  local function R(ox, oy, w, h, c) px(x + ox * k, y + oy * k, w * k, h * k, c) end
  local function F(ox, oy, w, h, t, c) frame(x + ox * k, y + oy * k, w * k, h * k, t * k, c) end
  local function RR(ox, oy, w, h, r, c) rrect(x + ox * k, y + oy * k, w * k, h * k, r * k, c) end

  R(24, 118, 112, 8, ART.shadow)
  RR(12, 30, 136, 82, 8, ART.floor)
  F(12, 30, 136, 82, 2, C.warn)
  F(16, 34, 128, 74, 2, edge)

  for i = 0, 2 do
    R(4, 44 + i * 24, 8, 8, edge)
    R(148, 44 + i * 24, 8, 8, edge)
  end

  for i = 0, 2 do
    local ax = 28 + i * 38
    RR(ax, 48, 30, 40, 4, ART.sky)
    F(ax, 48, 30, 40, 2, edge)
    local lit = (damage < 0.35 + i * 0.3)
    R(ax + 6, 56, 18, 24, lit and C.warn or ART.monsterDk)
  end

  R(28, 36, 104, 6, C.warn)

  for _, c in ipairs(CRACKS) do
    if damage >= c[1] then
      local pts = c[2]
      for i = 1, #pts - 1 do
        seg(x + (12 + pts[i][1] * 1.3) * k, y + (30 + pts[i][2]) * k,
            x + (12 + pts[i + 1][1] * 1.3) * k, y + (30 + pts[i + 1][2]) * k,
            C.warn, math.max(2, math.floor(2 * k)))
      end
    end
  end
end

-- The same 16x16 grid tools/gen_logo.py draws the badge from, so the title
-- screen shows the real mark rather than a picture of it.
local MARK = {
  "................", ".gg.............", ".gggg...........", ".gggggg.........",
  ".gggggggg.......", ".gggggggggg.....", ".gggggggggggg...", ".ggggggggggg....",
  ".gggggggggg.....", ".gggg.gggg......", ".ggg....ggg.....", ".gg......gg.....",
  ".g........g.....", "................", "....mmmmmmmm....", "................",
}

local function drawMark(x, y, cell)
  local size = 20 * cell
  px(x, y, size, size, C.gold)
  local inner = size - 4 * cell
  px(x + 2 * cell, y + 2 * cell, inner, inner, C.ground)
  for gy, row in ipairs(MARK) do
    for gx = 1, #row do
      local ch = row:sub(gx, gx)
      if ch ~= "." then
        px(x + (gx + 1) * cell, y + (gy + 1) * cell, cell, cell,
           ch == "m" and C.rule or C.gold)
      end
    end
  end
end

-- visual centre of each sprite, in sprite units, so the arena can centre them
-- instead of guessing an offset that only fits one of them
M.CENTRE = { vuln = 76, boss = 80 }
M.drawVuln, M.drawBossVuln, M.drawMark = drawVuln, drawBossVuln, drawMark
return M
