-- The tick: probes, passive throughput, kills, zones and the boss clock.
-- Everything here mutates the run state and nothing else.
local F = require("sim.formulas")
local Economy = require("sim.economy")
local Buffs = require("sim.buffs")
local Achievements = require("sim.achievements")

local M = {}

local KILLS_PER_ZONE = 10
local BOSS_SECONDS = 30

M.KILLS_PER_ZONE = KILLS_PER_ZONE
M.BOSS_SECONDS = BOSS_SECONDS

-- HONEYPOT buys the firewall ten more seconds
function M.boss_seconds(st)
  return BOSS_SECONDS + ((st.daemons and st.daemons[4]) and 10 or 0)
end

-- put a fresh target in front of the player for the current zone
function M.spawn(st)
  st.boss = F.is_boss_zone(st.zone)
  st.killsRequired = st.boss and 1 or KILLS_PER_ZONE
  local base = st.boss and F.boss_hp(st.zone) or F.vuln_hp(st.zone)
  st.hpMax = math.floor(base * Buffs.multipliers(st).vulnHp)
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
    st.boss = false            -- a beaten firewall leaves plain vulns to farm
    st.timer = 0
  end
  st.hpMax = F.vuln_hp(st.zone)
  st.hp = st.hpMax
end

-- the player's move: only from a cleared zone, and only forwards
function M.advance_zone(st)
  if not st.cleared then return false end
  st.zone = st.zone + 1
  st.kills = 0
  st.cleared = false
  st.killsRequired = nil
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
    st.hpMax = math.floor(F.vuln_hp(st.zone) * Buffs.multipliers(st).vulnHp)
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
  -- Crawl sends its own probes; they hit as hard as a manual one
  if Buffs.active(st, Buffs.CRAWL) and st.click > 0 then
    M.damage(st, Buffs.CRAWL_PROBES * st.click * dt)
  end
  -- CRON runs one extra probe a second, forever
  if st.daemons and st.daemons[1] and st.click > 0 then
    M.damage(st, st.click * dt)
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
