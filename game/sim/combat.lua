-- The tick: probes, passive throughput, kills, zones and the boss clock.
-- Everything here mutates the run state and nothing else.
local F = require("sim.formulas")
local Economy = require("sim.economy")

local M = {}

local KILLS_PER_ZONE = 10
local BOSS_SECONDS = 30

M.KILLS_PER_ZONE = KILLS_PER_ZONE
M.BOSS_SECONDS = BOSS_SECONDS

-- put a fresh target in front of the player for the current zone
function M.spawn(st)
  st.boss = F.is_boss_zone(st.zone)
  st.hpMax = st.boss and F.boss_hp(st.zone) or F.vuln_hp(st.zone)
  st.hp = st.hpMax
  st.timer = st.boss and BOSS_SECONDS or 0
  Economy.recalc(st)
end

function M.new_run_spawn(st)
  st.kills = 0
  M.spawn(st)
end

-- Cleared is a state, not a step: the zone stops when its last vuln dies and the
-- player has to walk through. Nothing moves them on while they are playing.
local function advance(st)
  st.kills = st.kills + 1
  local target = st.boss and 1 or KILLS_PER_ZONE
  if st.kills >= target then
    st.kills = target
    st.cleared = true
    st.hp = 0
    st.hpMax = 0
    st.timer = 0
  else
    st.hpMax = st.boss and F.boss_hp(st.zone) or F.vuln_hp(st.zone)
    st.hp = st.hpMax
  end
end

-- the player's move: only from a cleared zone, and only forwards
function M.advance_zone(st)
  if not st.cleared then return false end
  st.zone = st.zone + 1
  st.kills = 0
  st.cleared = false
  if st.zone > st.bestZone then st.bestZone = st.zone end
  st.zoneSel = st.zone
  M.spawn(st)
  return true
end

-- a kill pays, then the next vuln takes its place
local function kill(st)
  st.credits = st.credits + st.creditsKill
  advance(st)
end

function M.damage(st, amount)
  if amount <= 0 or st.cleared then return end
  st.hp = st.hp - amount
  while st.hp <= 0 and not st.cleared do
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
  if st.cleared then return end          -- waiting on the player, not on the clock
  if st.hp <= 0 then M.spawn(st) end
  if st.dps > 0 then M.damage(st, st.dps * dt) end

  if st.boss and st.timer > 0 then
    st.timer = st.timer - dt
    if st.timer <= 0 then
      -- the perimeter closed: lose the attempt, keep the credits
      st.timer = 0
      st.kills = 0
      st.boss = false
      M.spawn(st)
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
