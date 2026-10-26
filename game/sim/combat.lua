-- The tick: probes, passive throughput, kills, zones and the boss clock.
-- Everything here mutates the run state and nothing else.
local F = require("sim.formulas")
local Economy = require("sim.economy")
local Buffs = require("sim.buffs")
local Achievements = require("sim.achievements")

local M = {}

local T = require("tuning")
local Systems = require("data.systems")

local KILLS_PER_ZONE = T.zone.kills_per_zone
local BOSS_SECONDS = T.boss.seconds

M.KILLS_PER_ZONE = KILLS_PER_ZONE
M.BOSS_SECONDS = BOSS_SECONDS

-- HONEYPOT and friends buy the firewall extra seconds
function M.boss_seconds(st)
  return BOSS_SECONDS + Systems.daemon_mults(st).boss_seconds
end

-- The HP the current target should have. A beaten firewall keeps its stats on the
-- vuln that replaces it, so clearing a boss zone never pays less than the boss did.
function M.target_hp(st)
  local base = (st.boss or st.bossFarm) and F.boss_hp(st.zone) or F.vuln_hp(st.zone)
  return math.max(1, math.floor(base * Buffs.multipliers(st).vulnHp))
end

-- put a fresh target in front of the player for the current zone
function M.spawn(st)
  st.boss = F.is_boss_zone(st.zone) and not st.bossFarm
  st.killsRequired = (st.boss or st.bossFarm) and 1 or KILLS_PER_ZONE
  st.hpMax = M.target_hp(st)
  st.hp = st.hpMax
  st.timer = st.boss and M.boss_seconds(st) or 0
  Economy.recalc(st)
end

function M.new_run_spawn(st)
  st.kills = 0
  M.spawn(st)
end

-- Cleared means the next zone is unlocked, not that the work stops. The player
-- keeps farming the zone they are standing in for credits; only the gate to the
-- next zone waits for them.
local function advance(st)
  st.kills = st.kills + 1
  local target = st.killsRequired or KILLS_PER_ZONE
  if st.kills >= target then
    st.kills = target
    st.cleared = true
    if st.boss then
      st.bossKills = (st.bossKills or 0) + 1
      st.totalBosses = (st.totalBosses or 0) + 1
    end
    st.boss = false            -- the gate is open, but the firewall's stats stay
    st.bossFarm = F.is_boss_zone(st.zone)
    st.timer = 0
  end
  st.hpMax = M.target_hp(st)
  st.hp = st.hpMax
end

-- Walk to any zone up to the furthest one reached. Everything behind the frontier
-- is already open, so arriving there leaves you farming with the gate open.
function M.travel_to(st, z)
  local top = st.bestZone or st.zone
  z = math.max(1, math.min(z, top))
  st.zone = z
  st.zoneSel = z
  st.kills = 0
  st.bossFails = st.bossFails or 0
  -- walking into a zone behind the frontier means its firewall is already beaten:
  -- you arrive with the gate open and the boss stats still on the target
  st.bossFarm = (z < top) and F.is_boss_zone(z) or nil
  M.spawn(st)
  st.cleared = z < top
  if st.cleared then
    st.kills = st.killsRequired
    st.boss, st.timer = false, 0
    st.hpMax = M.target_hp(st)
    st.hp = st.hpMax
  end
  st.saveRequest = true
  return true
end

-- the player's move: only from a cleared zone, and only forwards
function M.advance_zone(st)
  if not st.cleared then return false end
  st.zone = st.zone + 1
  st.kills = 0
  st.cleared = false
  st.killsRequired = nil
  st.bossFarm = nil
  if st.zone > st.bestZone then st.bestZone = st.zone end
  st.zoneSel = st.zone
  M.spawn(st)
  st.saveRequest = true   -- the save beat picks this up
  return true
end

-- a kill pays, then the next vuln takes its place; past the gate it just pays
local function kill(st)
  st.credits = st.credits + st.creditsKill
  st.totalKills = (st.totalKills or 0) + 1
  if st.cleared then
    st.hpMax = M.target_hp(st)
    st.hp = st.hpMax
    return
  end
  advance(st)
end

function M.damage(st, amount)
  if amount <= 0 then return end
  st.hp = st.hp - amount
  while st.hp <= 0 do
    local over = -st.hp
    kill(st)
    if st.cleared then break end
    if st.hp > over then
      st.hp = st.hp - over
    end
  end
end

function M.probe(st)
  st.flashT = 0.25
  M.damage(st, st.click)
end

-- passive damage plus the boss clock; dt is seconds
function M.tick(st, dt)
  st.playtime = (st.playtime or 0) + dt
  if Buffs.tick(st, dt) then Economy.recalc(st) end    -- a buff ended: stats revert
  if st.hp <= 0 then M.spawn(st) end
  if st.dps > 0 then M.damage(st, st.dps * dt) end
  -- skills and daemons both push extra probes; each hits as hard as a manual one
  if (st.probes or 0) > 0 and st.click > 0 then
    M.damage(st, st.probes * st.click * dt)
  end
  Achievements.check(st)

  if st.boss and st.timer > 0 then
    st.timer = st.timer - dt
    if st.timer <= 0 then
      -- the perimeter closed: you lose the attempt and get pushed back a zone to
      -- farm the dps you are missing. Credits stay, and the gate forward stays open
      -- so walking back in is one press.
      st.timer = 0
      st.bossFails = (st.bossFails or 0) + 1
      st.zone = math.max(1, st.zone - 1)
      M.spawn(st)
      st.cleared = true
      st.kills = st.killsRequired
      st.msg, st.msgT = "PERIMETER CLOSED · BACK ONE ZONE", 2.5
    end
  end
end

-- the offline report: run the same rules without a frame loop
-- Offline time is the exception: the framework keeps going without the player,
-- so a cleared zone is walked through automatically. Never used while playing.
function M.simulate(st, seconds, step)
  step = step or 1
  local done = 0
  while done < seconds do
    if st.cleared then
      if not M.advance_zone(st) then break end
    end
    M.tick(st, step)
    done = done + step
    if st.boss and st.timer <= 0 then break end
    if st.dps <= 0 then break end
  end
  return done
end

return M
