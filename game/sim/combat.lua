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

local function advance(st)
  st.kills = st.kills + 1
  if st.kills >= (st.boss and 1 or KILLS_PER_ZONE) then
    st.zone = st.zone + 1
    st.kills = 0
    if st.zone > st.bestZone then st.bestZone = st.zone end
    M.spawn(st)
  else
    st.hpMax = st.boss and F.boss_hp(st.zone) or F.vuln_hp(st.zone)
    st.hp = st.hpMax
  end
end

-- a kill pays, then the next vuln takes its place
local function kill(st)
  st.credits = st.credits + st.creditsKill
  advance(st)
end

function M.damage(st, amount)
  if amount <= 0 then return end
  st.hp = st.hp - amount
  while st.hp <= 0 do
    local over = -st.hp
    kill(st)
    if st.hp > over then
      st.hp = st.hp - over
    end
    if st.hp > 0 then break end
  end
end

function M.probe(st)
  st.flashT = 0.25
  M.damage(st, st.click)
end

-- passive damage plus the boss clock; dt is seconds
function M.tick(st, dt)
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
function M.simulate(st, seconds, step)
  step = step or 1
  local done = 0
  while done < seconds do
    M.tick(st, step)
    done = done + step
    if st.boss and st.timer <= 0 then break end
    if st.dps <= 0 then break end
  end
  return done
end

return M
