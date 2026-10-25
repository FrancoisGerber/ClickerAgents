-- Transient one-line messages ("NEED 20K CREDITS"). Screen-local: it draws over
-- whatever is behind it and clears itself.
local Draw = require("ui.draw")
local Config = require("config")

local text, textW = Draw.text, Draw.textW
local px, frame = Draw.px, Draw.frame
local C = Config.C

local M = {}

function M.say(st, msg, seconds)
  st.msg, st.msgT = msg, seconds or 1.6
end

function M.draw(ctx)
  local st, L = ctx.state, ctx.layout
  if not st.msg or (st.msgT or 0) <= 0 then return end

  -- The toast lives inside the battle column: full width would cover the buy
  -- footer, and the arena's last band is empty once the bar is drawn.
  local avail = L.battleW - 24
  local label = Draw.fit(st.msg, avail - 24, 2)
  local w = math.min(avail, textW(label, 2) + 24)
  local x = L.battleX + math.floor((L.battleW - w) / 2)
  local y = L.H - L.hintH - 40
  px(x, y, w, 24, C.panel)
  frame(x, y, w, 24, 2, C.gold)
  text(label, x + 12, y + 6, C.text, 2)
end

return M
