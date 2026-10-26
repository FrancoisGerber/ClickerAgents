-- Persistence. A save is a small table serialised to Lua; on launch the time
-- away is replayed through the same combat rules so the player returns to a
-- decision rather than to a wall.
local Combat = require("sim.combat")
local Economy = require("sim.economy")
local Log = require("core.log")

local M = {}

M.FILE = "save.lua"
M.OFFLINE_CAP = 8 * 3600      -- beyond eight hours farming stops being interesting
M.INTERVAL = 60               -- a save every minute, no matter what
M.reason = nil                -- why the last write happened, for the tests

local function quote(s)
  return string.format("%q", tostring(s))
end

-- Only plain data goes in: numbers, booleans and flat arrays.
function M.snapshot(st)
  local agents = {}
  for i, a in ipairs(st.agents) do agents[i] = a.lv end
  local function copy(t)
    local out = {}
    for i = 1, #t do out[i] = t[i] end
    return out
  end
  return {
    version = 2,
    saved_at = os.time(),
    credits = st.credits,
    zone = st.zone,
    kills = st.kills,
    cleared = st.cleared or false,
    killsRequired = st.killsRequired or 10,
    rootkits = st.rootkits,
    bossKills = st.bossKills or 0,
    systems = st.systems,
    bestZone = st.bestZone,
    playtime = st.playtime or 0,
    totalKills = st.totalKills or 0,
    totalBosses = st.totalBosses or 0,
    agents = agents,
    owned = copy(st.owned),
    upOwned = copy(st.upOwned),
    achDone = copy(st.achDone),
    daemons = copy(st.daemons or {}),
  }
end

function M.serialise(data)
  local parts = { "return {" }
  for k, v in pairs(data) do
    if type(v) == "table" then
      local items = {}
      for i = 1, #v do items[i] = tostring(v[i]) end
      parts[#parts + 1] = string.format("  %s = { %s },", k, table.concat(items, ", "))
    elseif type(v) == "string" then
      parts[#parts + 1] = string.format("  %s = %s,", k, quote(v))
    else
      parts[#parts + 1] = string.format("  %s = %s,", k, tostring(v))
    end
  end
  parts[#parts + 1] = "}"
  return table.concat(parts, "\n")
end

function M.deserialise(text)
  local chunk = loadstring or load
  local fn = chunk(text)
  if not fn then return nil end
  local ok, data = pcall(fn)
  if not ok or type(data) ~= "table" then return nil end
  return data
end

-- copy a loaded save onto a fresh run state
function M.apply(st, data)
  if not data then return false end
  st.credits = data.credits or 0
  st.zone = data.zone or 1
  st.kills = data.kills or 0
  st.cleared = data.cleared or false
  st.killsRequired = data.killsRequired or 10
  st.rootkits = data.rootkits or 0
  st.bossKills = data.bossKills or 0
  st.systems = data.systems or 0
  st.bestZone = data.bestZone or st.zone
  st.playtime = data.playtime or 0
  st.totalKills = data.totalKills or 0
  st.totalBosses = data.totalBosses or 0
  for i, lv in ipairs(data.agents or {}) do
    if st.agents[i] then st.agents[i].lv = lv end
  end
  for i, v in ipairs(data.owned or {}) do st.owned[i] = v end
  for i, v in ipairs(data.upOwned or {}) do st.upOwned[i] = v end
  for i, v in ipairs(data.achDone or {}) do st.achDone[i] = v end
  for i, v in ipairs(data.daemons or {}) do st.daemons[i] = v end
  st.zoneSel = st.zone
  Economy.recalc(st)
  Combat.spawn(st)
  if st.cleared then st.boss, st.timer = false, 0 end
  return true
end

-- Buying something, walking into a new zone or ascending all mark the run dirty;
-- the beat below turns that into a write at the end of the frame.
function M.request(st)
  st.saveRequest = true
end

function M.sync(st, dt)
  st.saveClock = (st.saveClock or 0) + (dt or 0)
  local due = st.saveRequest or st.saveClock >= M.INTERVAL
  if not due then return false end
  M.reason = st.saveRequest and "change" or "beat"
  st.saveRequest = false
  st.saveClock = 0
  st.saves = (st.saves or 0) + 1
  M.write(st)
  return true
end

function M.write(st)
  if not (love and love.filesystem) then return false end
  local ok = love.filesystem.write(M.FILE, M.serialise(M.snapshot(st)))
  if ok then Log.dbg(string.format("[save] zone %d · %s", st.zone, M.reason or "manual")) end
  return ok
end

function M.read()
  if not (love and love.filesystem) then return nil end
  if not love.filesystem.getInfo or not love.filesystem.getInfo(M.FILE) then return nil end
  local text = love.filesystem.read(M.FILE)
  if not text then return nil end
  return M.deserialise(text)
end

-- Replay the time away. Returns the report the Welcome Back screen shows.
function M.replay_offline(st, data)
  local saved = data and data.saved_at or nil
  if not saved then return nil end
  local elapsed = math.max(0, math.floor(os.time() - saved))
  if elapsed < 30 then return nil end
  local capped = math.min(elapsed, M.OFFLINE_CAP)

  local zones0 = st.zone
  local credits0 = st.credits
  Combat.simulate(st, capped, 5)

  return {
    seconds = capped,
    zones = st.zone - zones0,
    credits = st.credits - credits0,
    stopped_at = st.zone,
    boss = st.boss,
  }
end

return M
