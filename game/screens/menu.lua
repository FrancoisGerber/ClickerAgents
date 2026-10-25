local Draw = require("ui.draw")
local W = require("ui.widgets")
local Config = require("config")
local Numbers = require("core/numbers")

local px, rrect, frame = Draw.px, Draw.rrect, Draw.frame
local text, textR, textC, textW = Draw.text, Draw.textR, Draw.textC, Draw.textW
local fit, wire, wireWrap = Draw.fit, Draw.wire, Draw.wireWrap
local drawText, drawTextR, drawTextC = Draw.text, Draw.textR, Draw.textC
local panel, rowSel, rowsPanel = W.panel, W.rowSel, W.rowsPanel
local C = Config.C
local fmt = Numbers.fmt

local M = {}
local st, L, opts

local function menuScreen()
  local m, gap = 24, 16
  local bodyY = L.topH + 16
  drawText("MENU", m, bodyY, C.text, 2)
  local y = bodyY + 40
  local w = math.floor((L.W - m * 2 - gap) / 2)
  local c = st.cursor[7]
  local items = { "RESUME", "SAVE", "QUIT" }
  for i, it in ipairs(items) do
    local ry = y + (i - 1) * 56
    local on = (i == c)
    if on then rowSel(m + 4, ry - 6, w - 8, 60) end
    frame(m, ry, w, 48, 2, on and C.gold or C.rule)
    drawText(it, m + 12, ry + 12, on and C.text or C.dim, 2)
  end
  local x2 = m + w + gap
  local pw = L.W - m - x2 - 24
  panel(x2, y, L.W - m - x2, 104, "ABOUT")
  wire("CLICKER AGENTS 0.1", x2 + 12, y + 40, C.text, pw)
  wire("GPL-3.0-OR-LATER", x2 + 12, y + 64, nil, pw)
  wire("LOVE 11.5 · PORTMASTER", x2 + 12, y + 88, nil, pw)
end

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  menuScreen()
end

return M
