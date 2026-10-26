-- The pause menu. An overlay rather than a tab: START opens it from any screen,
-- the clock stops and a save lands on disk before it is drawn.
local Draw = require("ui.draw")
local W = require("ui.widgets")
local Config = require("config")

local px, frame, rrect = Draw.px, Draw.frame, Draw.rrect
local text, textR, textC, textW = Draw.text, Draw.textR, Draw.textC, Draw.textW
local panel, rowSel = W.panel, W.rowSel
local C = Config.C

local M = {}
local st, L

local ITEMS = { "RESUME", "SAVE", "QUIT" }

local function menuScreen()
  px(0, 0, L.W, L.H, C.ground)

  local w = math.min(360, L.W - 80)
  local rowH = 44
  local pad = 20
  local h = pad + 56 + #ITEMS * (rowH + 8) + 44
  local x = math.floor((L.W - w) / 2)
  local y = math.floor((L.H - h) / 2)

  panel(x, y, w, h)
  text("PAUSED", x + pad, y + 16, C.gold, 3)
  textR("CLOCK STOPPED", x + w - pad, y + 22, C.dim, 2)
  local saved = st.savedOnPause and "SAVED" or "SAVE FAILED"
  text(saved, x + pad, y + 46, st.savedOnPause and C.gain or C.poor, 2)

  local c = st.cursor.menu or 1
  local ry = y + 76
  for i, label in ipairs(ITEMS) do
    local on = (i == c)
    if on then rowSel(x + pad - 8, ry - 6, w - pad * 2 + 16, rowH + 12) end
    frame(x + pad, ry, w - pad * 2, rowH, 2, on and C.gold or C.rule)
    text(label, x + pad + 12, ry + 12, on and C.text or C.dim, 2)
    if i == 2 and st.savedOnPause then
      textR("AUTOSAVED", x + w - pad - 12, ry + 12, C.dim, 2)
    end
    if i == 3 then textR("NO SAVE LOST", x + w - pad - 12, ry + 12, C.dim, 2) end
    ry = ry + rowH + 8
  end

  -- hint on the left, version on the right: centred text cannot share a line with a
  -- right-aligned stamp without colliding at narrow widths
  text("START OR B TO RESUME", x + pad, y + h - 26, C.dim, 2)
  textR(Config.VERSION, x + w - pad, y + h - 26, C.rule, 2)
end

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  menuScreen()
end

return M
