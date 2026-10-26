-- Active skill effects. A buff is a countdown in seconds; the multipliers are read
-- by sim/economy on every recalculation, so casting a skill changes the numbers and
-- the numbers change back when it expires. What each skill does lives in
-- data/skills.lua, so adding a skill is a data edit, not a change here.
-- Pure data, no love.* calls.
local T = require("tuning")
local Skills = require("data.skills")

local M = {}

M.DURATION = T.buff.duration
M.CRIT_MUL = T.buff.crit_multiplier   -- Phish makes every probe crit

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
  for i = 1, #Skills do
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

-- what the live buffs do to the derived stats. Every kind used in data/skills.lua
-- lands in exactly one field here.
function M.multipliers(st)
  local m = { dps = 1, credits = 1, click = 1, vulnHp = 1, probes = 0 }
  for i, sk in ipairs(Skills) do
    if M.active(st, i) and sk.effects then
      for _, e in ipairs(sk.effects) do
        local kind, value = e[1], e[2]
        if kind == "dps_mul" then m.dps = m.dps * value
        elseif kind == "credits_mul" then m.credits = m.credits * value
        elseif kind == "click_mul" then m.click = m.click * value
        elseif kind == "vulnhp_mul" then m.vulnHp = m.vulnHp * value
        elseif kind == "probes" then m.probes = m.probes + value
        elseif kind == "crit" then m.click = m.click * M.CRIT_MUL
        end
      end
    end
  end
  return m
end

return M
