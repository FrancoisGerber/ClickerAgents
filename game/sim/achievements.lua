-- The eight achievements, checked against the run. Cheap enough to evaluate on
-- every tick, and the only place st.achDone is written. Pure logic.
local M = {}

local ACHIEVEMENTS = require("data.achievements")

-- the rule behind each row of data/achievements.lua, in the same order
local RULES = {
  function(st) return st.zone >= 2 end,                                  -- FIRST BREACH
  function(st) return (st.totalBosses or 0) >= 10 end,                    -- FIREWALL DOWN
  function(st) return (st.rootkits or 0) >= 10 end,                       -- TEN ROOTKITS
  function(st) return (st.systems or 0) >= 1 end,                         -- NEW TARGET
  function(st) return st.zone >= 100 end,                                 -- CORE ACCESS
  function(st) return (function()
      for _, a in ipairs(st.agents) do if a.lv <= 0 then return false end end
      return true
    end)() end,                                                          -- FULL ROSTER
  function(st) return (st.totalKills or 0) >= 100 end,                    -- SILENT RUN
  function(st) return (st.bestZone or 1) >= 250 end,                      -- ROOT
}

M.rules = RULES

-- returns how many new ones were unlocked this call
function M.check(st)
  st.achDone = st.achDone or {}
  local unlocked = 0
  for i, rule in ipairs(RULES) do
    if not st.achDone[i] and rule(st) then
      st.achDone[i] = true
      unlocked = unlocked + 1
      if unlocked == 1 then
        local name = ACHIEVEMENTS[i][1]
        st.msg, st.msgT = "ACHIEVEMENT · " .. name, 2.5
      end
    end
  end
  return unlocked
end

function M.earned(st)
  local n = 0
  for i = 1, #RULES do if (st.achDone or {})[i] then n = n + 1 end end
  return n
end

return M
