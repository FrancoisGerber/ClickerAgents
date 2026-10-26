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
  local levels = 0
  for _, a in ipairs(st.agents or {}) do levels = levels + (a.lv or 0) end
  local T = require("tuning")
  local per = T.prestige.levels_per_rootkit
  local nextAt = per * (math.floor(levels / per) + 1)
  local rows = { "ON OFFER", "HELD", "BONUS EACH", "AGENT LEVELS", "BOSSES BROKEN", "NEXT ROOTKIT AT" }
  local states = {
    { tostring(offer), C.gold },
    { tostring(st.rootkits or 0), C.gold },
    { "+10%", C.dim },
    { tostring(levels), C.text },
    { tostring(st.totalBosses or 0), C.text },
    { tostring(nextAt), C.dim },
  }
  local ph = L.panelH
  rowsPanel(m, y, w, rows, "ROOTKITS", nil, states, nil, ph)

  -- the ascend button is the panel's footer: same panel height as every other tab
  local ay = y + ph - 64
  local c = st.cursor[4]
  local ready = Prestige.can_ascend(st)
  local confirm = st.confirmAscend == true
  local ascRow = #DAEMONS + 1
  px(m + 12, ay - 14, w - 24, 2, C.rowsplit)
  if c == ascRow then rowSel(m + 8, ay - 6, w - 16, 60) end
  frame(m + 8, ay, w - 16, 48, 2, c == ascRow and C.gold or C.rule)
  drawText(confirm and "CONFIRM" or "ASCEND", m + 20, ay + 14,
           confirm and C.warn or (ready and C.text or C.dim), 2)
  if confirm then
    drawTextR("PRESS A AGAIN", m + w - 20, ay + 14, C.warn, 2)
  elseif ready then
    drawTextR("ZONE " .. st.zone, m + w - 20, ay + 14, C.gold, 2)
  else
    drawTextR("LOCKED · ZONE " .. Prestige.unlock_zone(st), m + w - 20, ay + 14, C.poor, 2)
  end

  local x2 = m + w + gap
  local wR = L.W - m - x2
  local names, costs = {}, {}
  for i, d in ipairs(DAEMONS) do
    names[i] = d.name
    costs[i] = (st.daemons and st.daemons[i]) and { "ONLINE", C.gold } or { fmt(d.cost), C.dim }
  end
  rowsPanel(x2, y, wR, names, "DAEMONS", (c <= #DAEMONS) and c or nil, costs, L.panelRows, ph)
end

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  prestigeScreen()
end

return M
