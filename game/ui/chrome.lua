-- The persistent furniture: the top bar of live numbers and the hint strip with
-- the tab dots.
local Draw = require("ui.draw")
local Config = require("config")
local Numbers = require("core/numbers")

local px, frame, rrect = Draw.px, Draw.frame, Draw.rrect
local fit = Draw.fit
local text, textR, textW = Draw.text, Draw.textR, Draw.textW
local drawText, drawTextR, drawTextC = Draw.text, Draw.textR, Draw.textC
local C = Config.C
local fmt = Numbers.fmt

local M = {}
local st, L, opts

-- The bar is divided by need, not by even columns: credits and throughput carry the
-- long figures, rootkits and zone stay small. Each slot has a minimum that its label
-- plus its widest value needs, and whatever width is left over is handed out with
-- credits and throughput first, so the bar spreads out on a wide screen instead of
-- bunching to the left.
M.MINS = { 180, 140, 156, 108 }        -- credits, dps, rootkits, zone at scale 2
M.WEIGHTS = { 0.42, 0.36, 0.12, 0.10 }

function M.slotWidths(W)
  local usable = W - 32
  local base = 0
  for i = 1, 4 do base = base + M.MINS[i] end
  local spare = math.max(0, usable - base)
  local out = {}
  for i = 1, 4 do out[i] = M.MINS[i] + spare * M.WEIGHTS[i] end
  return out
end

local function topBar()
  px(0, 0, L.W, L.topH, C.panel)
  local W = L.W
  local INSET = 12
  local slots = {
    { label = "CREDITS",  value = fmt(st.credits),       colour = C.gold },
    { label = "DPS",      value = fmt(st.dps),           colour = C.gain },
    { label = "ROOTKITS", value = tostring(st.rootkits), colour = C.gold },
    { label = "ZONE",     value = tostring(st.zone),     colour = C.text },
  }
  local widths = M.slotWidths(W)
  local x = 16
  for i, slot in ipairs(slots) do
    local w = math.floor(widths[i])
    drawText(slot.label, x, 8, C.dim, 2)
    local room = w - INSET - textW(slot.label, 2) - INSET
    drawTextR(fit(slot.value, math.max(24, room)), x + w - INSET, 8, slot.colour, 2)
    x = x + w
  end
  -- no clock up here: the firewall's own bar on the arena carries the time
  px(0, L.topH - 2, W, 2, C.rule)
end

local TABS = { "BATTLE", "SKILLS", "UPGRADES", "PRESTIGE", "ACHIEVEMENTS", "STATS" }
local NTABS = #TABS

local K = {
  LR = { k = "L/R",    t = "TAB" },
  ST = { k = "START",  t = "MENU" },
  SE = { k = "SELECT", t = "AMOUNT" },
  ZN = { k = "L2/R2",  t = "ZONE" },
}

local function hintBar()
  local aChip = { k = "A", t = "BUY" }
  local bChip = { k = "B", t = "CLICK" }
  local selChip = { k = "A", t = "SELECT" }

  local buyChip = { k = "A", t = "BUY" }
  local useChip = { k = "X", t = "USE" }
  local backChip = { k = "B", t = "BACK" }
  local chips
  if st.tab == 1 then
    local sel = st.zoneSel or st.zone
    local zoneChip
    if sel ~= st.zone then zoneChip = { k = "X", t = "GO" }
    elseif st.cleared then zoneChip = { k = "X", t = "ADVANCE" }
    else zoneChip = K.ZN end
    chips = { aChip, bChip, zoneChip, K.SE, K.ST }
  elseif st.tab == 2 then
    chips = { buyChip, useChip, backChip, K.LR }
  elseif st.tab == 3 then
    chips = { buyChip, backChip, K.LR }
  elseif st.tab == 6 then
    chips = { backChip, K.LR, K.ST }
  else
    chips = { selChip, backChip, K.LR }
  end
  local h = chips
  px(0, L.H - L.hintH, L.W, L.hintH, C.panel)
  px(0, L.H - L.hintH, L.W, 2, C.rule)

  local dotsW = NTABS * 16 + 16
  local limit = L.W - dotsW
  local x = 16
  for _, b in ipairs(h) do
    local cw = 6 * #b.k + 8
    local wNeed = cw + 6 + textW(b.t, 2) + 18
    if x + wNeed > limit then break end
    local lit = (b.t == "CLICK" and st.flashT > 0)
    rrect(x, L.H - L.hintH + 8, cw, 16, 2, lit and C.gold or C.rule)
    drawText(b.k, x + math.floor((cw - 6 * #b.k) / 2), L.H - L.hintH + 13,
             lit and C.ground or C.text, 1)
    x = x + cw + 6
    drawText(b.t, x, L.H - L.hintH + 8, lit and C.gold or C.dim, 2)
    x = x + textW(b.t, 2) + 18
  end
  for i = 0, NTABS - 1 do
    px(L.W - dotsW + 8 + i * 16, L.H - L.hintH + 12, 8, 8,
       i == st.tab - 1 and C.gold or C.rule)
  end
end

M.TABS, M.NTABS, M.K = TABS, NTABS, K

function M.topBar(ctx)
  st, L, opts = ctx.state, ctx.layout, ctx.opts or {}
  topBar()
end

function M.hintBar(ctx)
  st, L = ctx.state, ctx.layout
  hintBar()
end

return M
