-- Every number in the game, in one place, with the formula from docs/DESIGN.md.
-- Pure functions: no state, no love.*, trivially testable on the host.
local M = {}

local MILESTONE_FIRST = 25
local MILESTONE_EVERY = 25
local DAMAGE_STEP = 4          -- x4 damage at every milestone
local COST_GROWTH = 1.07

function M.vuln_hp(zone)
  if zone <= 140 then
    return math.floor(10 * (1.55 ^ (zone - 1)) + 10 * (zone - 1))
  end
  local base = math.floor(10 * (1.55 ^ 139) + 10 * 139)
  return math.floor(base * (1.145 ^ (zone - 140)))
end

function M.boss_hp(zone)
  return M.vuln_hp(zone) * 10
end

function M.credits_per_vuln(zone)
  return math.max(1, math.floor(0.05 * M.vuln_hp(zone)))
end

-- next level price for an agent whose level-1 price is `base`
function M.agent_cost(base, level)
  return math.max(1, math.floor(base * (COST_GROWTH ^ (level - 1))))
end

-- how many times an agent has crossed a damage milestone
function M.milestones(level)
  local n = 0
  local at = MILESTONE_FIRST
  while level >= at do
    n = n + 1
    at = at + MILESTONE_EVERY
  end
  return n
end

function M.agent_dps(agent)
  if agent.lv <= 0 then return 0 end
  return agent.base * agent.lv * (DAMAGE_STEP ^ M.milestones(agent.lv))
end

function M.is_boss_zone(zone)
  return zone % 5 == 0
end

-- zones walk through six layers of the target (see data/systems.lua)
function M.layer_index(zone)
  if zone >= 100 then return 6 end
  if zone >= 81 then return 5 end
  if zone >= 61 then return 4 end
  if zone >= 41 then return 3 end
  if zone >= 21 then return 2 end
  return 1
end

function M.rootkits_for_run(total_agent_levels, boss_kills)
  return math.floor(total_agent_levels / 2000) + boss_kills
end

return M
