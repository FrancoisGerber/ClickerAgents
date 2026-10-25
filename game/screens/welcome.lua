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

local function hm(sec)
  local h = math.floor(sec / 3600)
  local m = math.floor((sec % 3600) / 60)
  if h > 0 then return h .. "H " .. m .. "M" end
  return m .. "M"
end

local function welcomeScreen(report)
  local m, gap = 24, 16
  local r = report or { seconds = 0, zones = 0, credits = 0, stopped_at = st.zone,
                        boss = false }
  px(0, 0, L.W, L.H, C.ground)
  drawText("WELCOME BACK", m, L.topH + 16, C.gold, 2)
  drawTextR(hm(r.seconds) .. " AWAY", L.W - m, L.topH + 16, C.dim, 2)

  local y = L.topH + 56
  local w = math.floor((L.W - m * 2 - gap) / 2)
  local h = rowsPanel(m, y, w, { "LAYERS GAINED", "CREDITS EARNED", "STOPPED AT" }, nil, nil,
    { { fmt(r.zones), C.text }, { fmt(r.credits), C.gold }, { "ZONE " .. fmt(r.stopped_at), C.text } })

  local x2 = m + w + gap
  local wR = L.W - m - x2
  rowsPanel(x2, y, wR, { "THROUGHPUT", "TIME SIMULATED", "AT A BOSS" },
            "OFFLINE SUMMARY", nil,
    { { fmt(st.dps), C.gain }, { hm(r.seconds), C.text }, { r.boss and "YES" or "NO", C.text } })

  px(m, y + h + 24, w, 48, C.rule)
  frame(m, y + h + 24, w, 48, 2, C.gold)
  drawText("CONTINUE", m + 12, y + h + 36, C.gold, 2)
  drawTextR("A", m + w - 12, y + h + 36, C.dim, 2)
end

function M.draw(ctx, report)
  st, L = ctx.state, ctx.layout
  welcomeScreen(report)
end

return M
