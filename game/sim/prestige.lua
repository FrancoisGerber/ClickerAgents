-- Ascension: the one reset in the game. A run is consumed, the framework keeps
-- what it learned. Pure logic, no love.* calls.
local State = require("sim.state")
local Combat = require("sim.combat")
local Economy = require("sim.economy")
local Formulas = require("sim.formulas")
local Skills = require("data.skills")
local Agents = require("data.agents")

local T = require("tuning")
local M = {}

M.UNLOCK_ZONE = T.prestige.unlock_zone

function M.can_ascend(st)
  return st.zone >= M.UNLOCK_ZONE
end

-- every agent level you paid for, plus every firewall you broke, is worth keeping
function M.rootkits_on_offer(st)
  local levels = 0
  for _, a in ipairs(st.agents) do levels = levels + a.lv end
  return Formulas.rootkits_for_run(levels, st.bossKills or 0)
end

function M.bonus_from_held(st)
  return 1 + T.prestige.hold_bonus * (st.rootkits or 0)
end

-- ROOTKIT SPEND: a daemon is permanent and costs rootkits you could have held.
function M.daemon_owned(st, i) return (st.daemons or {})[i] == true end

function M.buy_daemon(st, i)
  local d = require("data.systems").daemons[i]
  if not d then return false end
  st.daemons = st.daemons or {}
  if st.daemons[i] then return false end
  if (st.rootkits or 0) < d[2] then return false end
  st.rootkits = st.rootkits - d[2]
  st.daemons[i] = true
  Economy.recalc(st)
  return true
end

-- wipes the run, keeps the meta. Returns the rootkits this ascension paid.
function M.ascend(st)
  if not M.can_ascend(st) then return 0 end
  local earned = M.rootkits_on_offer(st)

  st.rootkits = (st.rootkits or 0) + earned
  st.systems = (st.systems or 0) + 1

  -- the run goes back to a clean slate
  st.credits = 0
  st.zone = 1
  st.kills = 0
  st.cleared = false
  st.killsRequired = 10
  st.bossFails = 0
  st.bossKills = 0
  st.boss = false
  st.timer = 0

  for i, a in ipairs(st.agents) do
    a.lv = (i == 1) and 1 or 0
    a.cost = Agents.list[i].cost
  end

  for i = 1, #st.upOwned do st.upOwned[i] = false end
  for i, sk in ipairs(Skills) do
    st.owned[i] = sk.owned and true or false
    st.skillCd[i] = 0
  end
  for i = 1, #(st.buff or {}) do st.buff[i] = 0 end

  st.zoneSel = 1
  st.saveRequest = true   -- the save beat picks this up
  Economy.recalc(st)
  Combat.new_run_spawn(st)
  return earned
end

return M
