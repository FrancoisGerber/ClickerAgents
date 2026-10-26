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

local Prestige = require("sim.prestige")

local function prestigeScreen()
  local m, gap = 24, 16
  local bodyY = L.topH + 16
  drawText("PRESTIGE", m, bodyY, C.text, 2)

  local y = bodyY + 40
  local w = math.floor((L.W - m * 2 - gap) / 2)

  local offer = Prestige.rootkits_on_offer(st)
  local rows = { "ON OFFER", "HELD", "BONUS EACH" }
  local states = {
    { tostring(offer), C.gold },
    { tostring(st.rootkits or 0), C.gold },
    { "+10%", C.dim },
  }
  local h = rowsPanel(m, y, w, rows, "ROOTKITS", nil, states)

  local ay = y + h + 16
  local c = st.cursor[4]
  local ready = Prestige.can_ascend(st)
  local confirm = st.confirmAscend == true
  if c == 5 then rowSel(m + 4, ay - 6, w - 8, 60) end
  frame(m, ay, w, 48, 2, c == 5 and C.gold or C.rule)
  drawText(confirm and "CONFIRM" or "ASCEND", m + 12, ay + 12,
           confirm and C.warn or (ready and C.text or C.dim), 2)
  if confirm then
    drawTextR("PRESS A AGAIN", m + w - 12, ay + 12, C.warn, 2)
  elseif ready then
    drawTextR("ZONE " .. st.zone, m + w - 12, ay + 12, C.gold, 2)
  else
    drawTextR("LOCKED · ZONE " .. Prestige.UNLOCK_ZONE, m + w - 12, ay + 12, C.poor, 2)
  end

  local x2 = m + w + gap
  local wR = L.W - m - x2
  local names, costs = {}, {}
  for i, d in ipairs(DAEMONS) do
    names[i] = d[1]
    costs[i] = (st.daemons and st.daemons[i]) and { "ONLINE", C.gold } or { fmt(d[2]), C.dim }
  end
  rowsPanel(x2, y, wR, names, "DAEMONS · ROOTKIT SPEND", (c <= 4) and c or nil, costs)
end

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  prestigeScreen()
end

return M
