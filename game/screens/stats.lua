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

local function statsScreen()
  local m, gap = 24, 16
  local bodyY = L.topH + 16
  drawText("STATS", m, bodyY, C.text, 2)
  local y = bodyY + 40
  local w = math.floor((L.W - m * 2 - gap) / 2)
  local h = rowsPanel(m, y, w, {
    "THROUGHPUT", "PROBE DAMAGE", "CREDITS PER VULN", "VULNS",
    "BEST LAYER", "SYSTEMS BREACHED", "ROOTKITS", "PLAYTIME",
  })
  local x2 = m + w + gap
  local pw = L.W - m - x2 - 24
  panel(x2, y, L.W - m - x2, h, "DPS BY LAYER")
end

-- SKILLS: the actives roster. Buying is not wired; owning is what puts a slot

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  statsScreen()
end

return M
