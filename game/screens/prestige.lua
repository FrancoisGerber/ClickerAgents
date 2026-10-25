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

local Systems = require("data.systems")
local DAEMONS = Systems.daemons

local function prestigeScreen()
  local m, gap = 24, 16
  local bodyY = L.topH + 16
  drawText("PRESTIGE", m, bodyY, C.text, 2)
  local y = bodyY + 40
  local w = math.floor((L.W - m * 2 - gap) / 2)
  local h = rowsPanel(m, y, w, { "ROOTKITS ON OFFER", "ROOTKITS HELD", "BONUS PER ROOTKIT" })
  local ay = y + h + 16
  local c = st.cursor[4]
  if c == 5 then rowSel(m + 4, ay - 6, w - 8, 60) end
  frame(m, ay, w, 48, 2, c == 5 and C.gold or C.rule)
  drawText("ASCEND", m + 12, ay + 12, c == 5 and C.text or C.dim, 2)
  drawTextR("LOCKED · ZONE 100", m + w - 12, ay + 12, C.poor, 2)
  local x2 = m + w + gap
  local wR = L.W - m - x2
  -- Rootkits reinforce a system you have already consumed; the four earliest
  -- targets stand in until the campaign hands us the real list.
  local names, costs = {}, {}
  for i, d in ipairs(DAEMONS) do
    names[i], costs[i] = d[1], d[2]
  end
  rowsPanel(x2, y, wR, names, "DAEMONS · ROOTKIT SPEND", (c <= 4) and c or nil, costs)
end

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  prestigeScreen()
end

return M
