-- Active skill effects. A buff is a countdown in seconds; the multipliers are read
-- by sim/economy on every recalculation, so casting a skill changes the numbers and
-- the numbers change back when it expires. Pure data, no love.* calls.
local T = require("tuning")
local M = {}

M.DURATION = T.buff.duration

-- roster order matches data/skills.lua
M.CRAWL, M.SPRAY, M.PHISH, M.SIPHON, M.FLOOD, M.BLACKOUT = 1, 2, 3, 4, 5, 6

M.CRIT_MUL = T.buff.crit_multiplier   -- Phish makes every probe crit
M.CRAWL_PROBES = T.buff.crawl_probes  -- extra probes per second
M.BLACKOUT_CUT = T.buff.blackout_cut  -- share of the vuln HP removed

function M.start(st, i)
  st.buff = st.buff or {}
  st.buff[i] = M.DURATION
end

function M.left(st, i)
  return (st.buff and st.buff[i]) or 0
end

function M.active(st, i)
  return M.left(st, i) > 0
end

-- ticks every buff down; returns true when one of them expired this frame
function M.tick(st, dt)
  st.buff = st.buff or {}
  local expired = false
  for i = 1, #st.buff do
    local left = st.buff[i] or 0
    if left > 0 then
      left = left - dt
      if left <= 0 then
        st.buff[i] = 0
        expired = true
      else
        st.buff[i] = left
      end
    end
  end
  return expired
end

-- what the live buffs do to the derived stats
function M.multipliers(st)
  local m = { dps = 1, credits = 1, click = 1, vulnHp = 1 }
  if M.active(st, M.SPRAY) then m.dps = m.dps * 2 end
  if M.active(st, M.SIPHON) then m.credits = m.credits * 3 end
  if M.active(st, M.FLOOD) then m.click = m.click * 2 end
  if M.active(st, M.PHISH) then m.click = m.click * M.CRIT_MUL end
  if M.active(st, M.BLACKOUT) then m.vulnHp = m.vulnHp * (1 - M.BLACKOUT_CUT) end
  return m
end

return M
