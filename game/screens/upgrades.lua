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

local Upgrades = require("data.upgrades")
local UPGRADES = Upgrades.list
local upgradeLabels = Upgrades.labels

local function upgradeLabels()
  local names = {}
  for i, u in ipairs(UPGRADES) do names[i] = u[1] end
  return names
end

local function upgradesScreen()
  local m, gap = 24, 16
  local bodyY = L.topH + 16
  drawText("UPGRADES", m, bodyY, C.text, 2)
  local y = bodyY + 40
  local w = math.floor((L.W - m * 2 - gap) * 0.56)
  local names = upgradeLabels()
  local states = {}
  for i = 1, #names do
    states[i] = st.upOwned[i] and { "OWNED", C.gold } or { fmt(UPGRADES[i][2]), C.dim }
  end
  local sel = st.cursor[3]
  local h = rowsPanel(m, y, w, names, nil, sel, states, L.rows - 3)
  local x2 = m + w + gap
  local pw = L.W - m - x2 - 24
  panel(x2, y, L.W - m - x2, h)
  local u = UPGRADES[sel]
  local wR3 = L.W - m - x2
  wire(u[1], x2 + 12, y + 14, C.text, pw)
  wire("COST", x2 + 12, y + 42, C.dim, pw)
  drawTextR(fmt(u[2]), x2 + wR3 - 12, y + 42, C.gold, 2)
  wire("EFFECT", x2 + 12, y + 68, C.dim, pw)
  wireWrap(u[3], x2 + 12, y + 94, C.text, pw, 24)
end

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  upgradesScreen()
end

return M
