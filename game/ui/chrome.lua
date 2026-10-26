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

-- The bar is built from what each field actually needs: its label, a gap, and a value
-- box wide enough for the longest figure it will ever show (six characters for credits
-- and throughput, four for rootkits and zone). Whatever width is left over becomes the
-- space *between* the fields, so the bar reads across the whole screen instead of
-- bunching on the left, and a growing number eats its own gap rather than its neighbour.
M.VALUE_W = { 72, 72, 48, 48 }     -- px at scale 2
M.LABEL_GAP = 12                   -- between a label and its own value
M.EDGE = 16                        -- screen margin

function M.slotWidths(W)
  local labels = { "CREDITS", "DPS", "ROOTKITS", "ZONE" }
  local out, total = {}, 0
  for i = 1, 4 do
    local w = #labels[i] * 12 + M.LABEL_GAP + M.VALUE_W[i]
    out[i] = w
    total = total + w
  end
  return out, total
end

function M.gap(W)
  local _, total = M.slotWidths(W)
  local spare = W - M.EDGE * 2 - total
  return math.max(8, math.floor(spare / 3))
end

local function topBar()
  px(0, 0, L.W, L.topH, C.panel)
  local W = L.W
  local slots = {
    { label = "CREDITS",  value = fmt(st.credits),       colour = C.gold },
    { label = "DPS",      value = fmt(st.dps),           colour = C.gain },
    { label = "ROOTKITS", value = tostring(st.rootkits), colour = C.gold },
    { label = "ZONE",     value = tostring(st.zone),     colour = C.text },
  }
  local widths = M.slotWidths(W)
  local gap = M.gap(W)
  local x = M.EDGE
  for i, slot in ipairs(slots) do
    drawText(slot.label, x, 8, C.dim, 2)
    local vx = x + #slot.label * 12 + M.LABEL_GAP
    drawTextR(fit(slot.value, M.VALUE_W[i]), vx + M.VALUE_W[i], 8, slot.colour, 2)
    x = x + widths[i] + gap
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
