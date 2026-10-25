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

local ACHIEVEMENTS = require("data.achievements")

local function achievementsScreen()
  local m, gap = 24, 16
  local bodyY = L.topH + 16
  drawText("ACHIEVEMENTS", m, bodyY, C.text, 2)
  local y = bodyY + 40
  local w = math.floor((L.W - m * 2 - gap) * 0.56)
  local names, states = {}, {}
  for i, a in ipairs(ACHIEVEMENTS) do
    names[i] = a[1]
    states[i] = st.achDone[i] and { "UNLOCKED", C.gold } or { "LOCKED", C.rule }
  end
  local sel = st.cursor[5]
  local h = rowsPanel(m, y, w, names, nil, sel, states)
  local x2 = m + w + gap
  local pw = L.W - m - x2 - 24
  panel(x2, y, L.W - m - x2, h)
  local a = ACHIEVEMENTS[sel]
  wire(a[1], x2 + 12, y + 14, C.text, pw)
  wire("REQUIREMENT", x2 + 12, y + 42, C.dim, pw)
  wireWrap(a[2], x2 + 12, y + 68, C.text, pw, 24)
end

-- UPGRADES: the ten one-shot globals from docs/CONTENT.md, with their real

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  achievementsScreen()
end

return M
