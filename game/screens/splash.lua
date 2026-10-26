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

local Sprites = require("ui.sprites")
local drawMark = Sprites.drawMark

local function splashScreen()
  px(0, 0, L.W, L.H, C.ground)
  local cx = math.floor(L.W / 2)
  -- the badge is the real mark, drawn from the same grid as tools/gen_logo.py
  local cell = math.max(4, math.floor(math.min(L.W / 720, L.H / 480) * 8))
  local markSize = 20 * cell
  local my = math.floor(L.H * 0.12)
  drawMark(cx - math.floor(markSize / 2), my, cell)
  local scale = 4
  local ty = my + markSize + math.floor(L.H * 0.04)
  drawTextC("CLICKER AGENTS", cx, ty, C.gold, scale)
  drawTextC("AN UNLICENSED FRAMEWORK", cx, ty + 7 * scale + 12, C.text, 2)
  drawTextC("PRESS ANY BUTTON", cx, L.H - 72, C.dim, 2)
  px(0, L.H - 96, L.W, 2, C.rule)
  drawText(Config.VERSION, 16, L.H - 28, C.rule, 2)
  drawTextR("GPL-3.0-OR-LATER", L.W - 16, L.H - 28, C.rule, 2)
end

-- WELCOME BACK: the offline report from docs/DESIGN.md §7. Wireframe until the
-- save and the offline simulation exist; it appears once after the title so the

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  splashScreen()
end

return M
