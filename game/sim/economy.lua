-- Buying things and recomputing the derived numbers. The only place that writes
-- credits, levels or tool ownership.
local F = require("sim.formulas")
local Upgrades = require("data.upgrades")
local Skills = require("data.skills")
local Buffs = require("sim.buffs")

local M = {}

-- total throughput, probe damage and the per-vuln payout, from the current state
function M.recalc(st)
  local dps = 0
  for _, a in ipairs(st.agents) do dps = dps + F.agent_dps(a) end
  local t = F.upgrade_totals(st.upOwned)
  local b = Buffs.multipliers(st)
  local dm = st.daemons or {}
  local beacon = dm[3] and 1.10 or 1
  local watchdog = dm[2] and 1.15 or 1
  st.dps = math.floor(dps * (1 + t.dps_add) * b.dps * beacon * (1 + 0.10 * (st.rootkits or 0)))
  local payout = F.credits_per_vuln(st.zone) * (st.boss and 3 or 1)
  st.creditsKill = math.max(1, math.floor(payout * (1 + t.credits_add) * b.credits * watchdog))
  st.click = math.max(1, math.floor(F.probe_damage(st.dps) * t.click_mul * (1 + t.click_add) * b.click))
end

function M.next_cost(st, i)
  local a = st.agents[i]
  return F.agent_cost(a.cost, a.lv + 1)
end

function M.unlocked(st, i)
  local a = st.agents[i]
  return a.lock == nil or st.zone >= a.lock
end

function M.buy(st, i)
  local a = st.agents[i]
  if not a or not M.unlocked(st, i) then return false end
  local cost = M.next_cost(st, i)
  if st.credits < cost then return false end
  st.credits = st.credits - cost
  a.lv = a.lv + 1
  M.recalc(st)
  st.saveRequest = true   -- the save beat picks this up
  return true
end

function M.buy_max(st, i)
  local bought = 0
  while M.buy(st, i) do bought = bought + 1 end
  return bought
end

-- amount 0 means MAX, matching the START button's cycle
function M.buy_amount(st, i, amount)
  if amount == 0 then return M.buy_max(st, i) end
  local bought = 0
  for _ = 1, amount do
    if not M.buy(st, i) then break end
    bought = bought + 1
  end
  return bought
end

-- one-shot global tools
function M.tool_cost(i) return Upgrades.list[i][2] end
function M.tool_owned(st, i) return st.upOwned[i] == true end

function M.buy_tool(st, i)
  local cost = M.tool_cost(i)
  if not cost or M.tool_owned(st, i) then return false end
  if st.credits < cost then return false end
  st.credits = st.credits - cost
  st.upOwned[i] = true
  M.recalc(st)
  st.saveRequest = true   -- the save beat picks this up
  return true
end

-- skills are bought once, then cast from the SKILLS tab
function M.skill_cost(i) return Skills[i] and Skills[i].cost end
function M.skill_owned(st, i) return st.owned[i] == true end

function M.buy_skill(st, i)
  local cost = M.skill_cost(i)
  if not cost or M.skill_owned(st, i) then return false end
  if st.credits < cost then return false end
  st.credits = st.credits - cost
  st.owned[i] = true
  st.saveRequest = true   -- the save beat picks this up
  return true
end

function M.select(st, i)
  st.sel = math.max(1, math.min(#st.agents, i))
end

return M
