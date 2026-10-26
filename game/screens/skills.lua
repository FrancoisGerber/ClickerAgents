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
local Buffs = require("sim.buffs")

local M = {}
local st, L, opts

local SKILLS = require("data.skills")

local function skillsScreen()
  local m, gap = 24, 16
  local bodyY = L.topH + 16
  drawText("SKILLS", m, bodyY, C.text, 2)
  local y = bodyY + 40
  local w = math.floor((L.W - m * 2 - gap) * 0.56)
  local names, states = {}, {}
  for i, sk in ipairs(SKILLS) do
    names[i] = sk.name
    local cd = st.skillCd[i] or 0
    local live = Buffs.left(st, i)
    if live > 0 then
      states[i] = { "ACTIVE " .. math.ceil(live) .. "S", C.gain }
    elseif cd > 0 then
      states[i] = { math.ceil(cd) .. "S", C.poor }
    elseif st.owned[i] then
      states[i] = { "OWNED", C.gold }
    else
      states[i] = { fmt(SKILLS[i].cost), C.dim }
    end
  end
  local sel = st.cursor[2]
  local h = rowsPanel(m, y, w, names, nil, sel, states, L.panelRows, L.panelH)
  local x2 = m + w + gap
  local pw = L.W - m - x2 - 24
  panel(x2, y, L.W - m - x2, h)
  local sk = SKILLS[sel]
  local wR2 = L.W - m - x2
  wire(sk.name, x2 + 12, y + 14, C.text, pw)
  wire("AGENT", x2 + 12, y + 42, C.dim, pw)
  drawTextR(sk.agent, x2 + wR2 - 12, y + 42, C.text, 2)
  local cdLeft = st.skillCd[sel] or 0
  local live = Buffs.left(st, sel)
  wire(live > 0 and "RUNNING" or "COOLDOWN", x2 + 12, y + 68, C.dim, pw)
  if live > 0 then
    drawTextR(math.ceil(live) .. "S LEFT", x2 + wR2 - 12, y + 68, C.gain, 2)
  elseif cdLeft > 0 then
    drawTextR(math.ceil(cdLeft) .. "S LEFT", x2 + wR2 - 12, y + 68, C.poor, 2)
  else
    drawTextR(sk.cd .. "S", x2 + wR2 - 12, y + 68, C.text, 2)
  end
  if not st.owned[sel] then
    wire("COST", x2 + 12, y + 94, C.dim, pw)
    drawTextR(fmt(sk.cost), x2 + wR2 - 12, y + 94, C.gold, 2)
  end
  wire("EFFECT", x2 + 12, st.owned[sel] and y + 94 or y + 120, C.dim, pw)
  wireWrap(sk.eff, x2 + 12, st.owned[sel] and y + 118 or y + 144, C.text, pw, 24)
end


function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  skillsScreen()
end

return M
