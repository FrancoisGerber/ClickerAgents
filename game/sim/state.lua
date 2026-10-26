-- The run: everything that gets wiped when the framework moves to a new system.
-- Pure data plus the couple of fields the UI needs; no love.* calls live here.
local Agents = require("data.agents")
local Skills = require("data.skills")
local Upgrades = require("data.upgrades")
local Achievements = require("data.achievements")

local M = {}

-- one agent owned at the start, so the first minute is not empty
local START_AGENT = 1

function M.new_run()
  local agents = {}
  for i, a in ipairs(Agents.list) do
    agents[i] = { name = a.name, lv = (i == START_AGENT) and 1 or 0, cost = a.cost, base = a.base,
                  lock = a.lock }
  end

  local st = {
    -- economy
    credits = 0, creditsKill = 0, dps = 0, click = 1,
    -- the run
    zone = 1, kills = 0, hp = 0, hpMax = 0, boss = false, timer = 0, cleared = false, killsRequired = 10, bossFails = 0, bossKills = 0,
    -- meta, kept across ascensions
    rootkits = 0, systems = 0, bestZone = 1,
    -- ui
    agents = agents, sel = 1, amount = 1,
    owned = {}, upOwned = {}, achDone = {}, skillCd = {},
    buff = { 0, 0, 0, 0, 0, 0 },
    daemons = { false, false, false, false },
    saveClock = 0, saveRequest = false, saves = 0,
    playtime = 0, totalKills = 0, totalBosses = 0,
    screen = "splash", tab = 1, cursor = { 1, 1, 1, 1, 1, 1, 1 },
    splashT = 0, welcome = true, msg = nil, msgT = 0, flashT = 0,
    zoneSel = 1, idle = false,
  }
  for i, sk in ipairs(Skills) do st.owned[i] = sk.owned end
  for i = 1, #Upgrades.list do st.upOwned[i] = false end
  for i = 1, #Achievements do st.achDone[i] = false end
  st.zoneSel = st.zone
  return st
end

return M
