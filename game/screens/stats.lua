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
local Formulas = require("sim.formulas")

local M = {}
local st, L, opts

local function statsScreen()
  local m, gap = 24, 16
  local bodyY = L.topH + 16
  drawText("STATS", m, bodyY, C.text, 2)
  local y = bodyY + 40
  local w = math.floor((L.W - m * 2 - gap) / 2)
  local hours = math.floor((st.playtime or 0) / 3600)
  local mins = math.floor(((st.playtime or 0) % 3600) / 60)
  local h = rowsPanel(m, y, w, {
    "THROUGHPUT", "PROBE DAMAGE", "CREDITS PER VULN", "VULNS KILLED",
    "BEST LAYER", "SYSTEMS BREACHED", "ROOTKITS HELD", "PLAYTIME",
  }, nil, nil, {
    { fmt(st.dps), C.gain },
    { fmt(st.click), C.gold },
    { fmt(st.creditsKill), C.gold },
    { fmt(st.totalKills or 0), C.text },
    { "ZONE " .. tostring(st.bestZone or 1), C.text },
    { tostring(st.systems or 0), C.text },
    { tostring(st.rootkits or 0), C.gold },
    { string.format("%dH %02dM", hours, mins), C.dim },
  })

  local x2 = m + w + gap
  local wR = L.W - m - x2
  -- only the agents actually deployed, and only as many rows as the panel holds
  local deployed = {}
  for _, a in ipairs(st.agents) do
    if a.lv > 0 then deployed[#deployed + 1] = a end
  end
  local names, values = {}, {}
  local room = math.max(1, math.floor((L.H - L.hintH - y - 32) / L.rowH) - 1)
  for i = 1, math.min(#deployed, room) do
    local a = deployed[i]
    names[i] = a.name
    values[i] = { fmt(Formulas.agent_dps(a)), C.gain }
  end
  if #deployed > room then
    names[room] = string.format("+%d MORE", #deployed - room + 1)
    values[room] = { "", C.rule }
  end
  rowsPanel(x2, y, wR, names, "AGENT THROUGHPUT · DPS", nil, values)
end

-- SKILLS: the actives roster. Buying is not wired; owning is what puts a slot

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  statsScreen()
end

return M
