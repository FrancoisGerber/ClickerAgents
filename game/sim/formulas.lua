-- Every number in the game, in one place, with the formula from docs/DESIGN.md.
-- Pure functions: no state, no love.*, trivially testable on the host.
local T = require("tuning")

local M = {}

-- kept as a field for callers that ask the formula what it is using
M.PROBE_SHARE = T.probe.share

function M.vuln_hp(zone)
  local v = T.vuln
  if zone <= v.soft_cap then
    return math.floor(v.base * (v.growth ^ (zone - 1)) + v.linear * (zone - 1))
  end
  local base = math.floor(v.base * (v.growth ^ (v.soft_cap - 1)) + v.linear * (v.soft_cap - 1))
  return math.floor(base * (v.tail_growth ^ (zone - v.soft_cap)))
end

function M.boss_hp(zone)
  return M.vuln_hp(zone) * T.boss.hp_multiplier
end

function M.credits_per_vuln(zone)
  return math.max(1, math.floor(T.payout.share * M.vuln_hp(zone)))
end

-- next level price for an agent whose level-1 price is `base`
function M.agent_cost(base, level)
  return math.max(1, math.floor(base * (T.agent.cost_growth ^ (level - 1))))
end

-- how many times an agent has crossed a damage milestone
function M.milestones(level)
  local n = 0
  local at = T.agent.milestone_first
  while level >= at do
    n = n + 1
    at = at + T.agent.milestone_every
  end
  return n
end

function M.agent_dps(agent)
  if agent.lv <= 0 then return 0 end
  return agent.base * agent.lv * (T.agent.milestone_step ^ M.milestones(agent.lv))
end

function M.probe_damage(dps)
  return math.max(T.probe.min, math.floor((dps or 0) * T.probe.share))
end

function M.is_boss_zone(zone)
  return zone % T.zone.boss_every == 0
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

-- what the owned one-shot tools add up to; the only place their effects live
function M.upgrade_totals(upOwned)
  local Upgrades = require("data.upgrades")
  local t = { click_add = 0, click_mul = 1, dps_add = 0, credits_add = 0, rootkit_bonus = 0 }
  for i, u in ipairs(Upgrades.list) do
    if upOwned[i] and u[4] then
      for _, e in ipairs(u[4]) do
        if e[1] == "click_add" then t.click_add = t.click_add + e[2]
        elseif e[1] == "click_mul" then t.click_mul = t.click_mul * e[2]
        elseif e[1] == "dps_add" then t.dps_add = t.dps_add + e[2]
        elseif e[1] == "credits_add" then t.credits_add = t.credits_add + e[2]
        elseif e[1] == "rootkit_bonus" then t.rootkit_bonus = t.rootkit_bonus + e[2] end
      end
    end
  end
  return t
end

function M.rootkits_for_run(total_agent_levels, boss_kills, bonus)
  return math.floor(total_agent_levels / T.prestige.levels_per_rootkit) + boss_kills + (bonus or 0)
end

return M
