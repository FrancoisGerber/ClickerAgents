-- Headless suite: geometry at three sizes, the M1 formulas, the tick, buying,
-- saving and the gptk contract. No window, no LÖVE.
-- Usage: lua tests/headless.lua

local SW, SH = 720, 480
local calls = { rect = 0, errors = {} }
local OX, OY = 0, 0
local STACK = {}

love = {
  graphics = {
    setColor = function() end,
    setBackgroundColor = function() end,
    setDefaultFilter = function() end,
    push = function() table.insert(STACK, { x = OX, y = OY }) end,
    pop = function() local t = table.remove(STACK); if t then OX, OY = t.x, t.y end end,
    translate = function(dx, dy) OX, OY = OX + (dx or 0), OY + (dy or 0) end,
    getDimensions = function() return SW, SH end,
    rectangle = function(mode, x, y, w, h)
      calls.rect = calls.rect + 1
      if type(x) ~= "number" or type(y) ~= "number" then
        table.insert(calls.errors, "rect with non-numeric coords")
        return
      end
      x, y = x + OX, y + OY
      if x < 0 or y < 0 or w < 0 or h < 0 then
        table.insert(calls.errors, string.format("negative rect %.1f %.1f %.1f %.1f", x, y, w, h))
      end
      if x + w > SW + 0.001 or y + h > SH + 0.001 then
        table.insert(calls.errors, string.format("outside %dx%d: %.1f %.1f %.1f %.1f", SW, SH, x, y, w, h))
      end
    end,
  },
  event = { quit = function() end },
}

package.path = "game/?.lua;" .. package.path
_G.DS_TEST = true
local Game = dofile("game/main.lua")

local F = require("sim.formulas")
local Combat = require("sim.combat")
local Economy = require("sim.economy")
local Save = require("sim.save")
local SimState = require("sim.state")

local ok, fail = 0, 0
local function check(cond, msg)
  if cond then ok = ok + 1 else fail = fail + 1; print("  FAIL " .. msg) end
end

local function st() return Game.state() end

-- ---------------------------------------------------------------- geometry
print("geometry")
for _, size in ipairs({ { 720, 480 }, { 640, 480 }, { 720, 720 } }) do
  SW, SH = size[1], size[2]
  love.load()
  local s = st()
  s.screen = "game"
  for tab = 1, 7 do
    s.tab = tab
    love.draw()
  end
  s.screen = "splash"; love.draw()
  s.screen = "game"
  local L = Game.layoutOf()
  print(string.format("  %dx%d  profile=%-7s agent=%d battle=%d rows=%d",
    SW, SH, L.profile or "?", L.heroW, L.battleW, L.rows))
end
check(#calls.errors == 0, "geometry: " .. tostring(calls.errors[1]))
print("  rects drawn: " .. calls.rect)

-- ---------------------------------------------------------------- formulas
print("formulas")
check(F.vuln_hp(1) >= 10, "vuln hp at zone 1")
check(F.vuln_hp(2) > F.vuln_hp(1), "vuln hp grows with zone")
check(F.vuln_hp(141) > F.vuln_hp(140), "vuln hp grows past the linear stretch")
check(F.boss_hp(5) == F.vuln_hp(5) * 10, "boss is ten vulns in one bar")
check(F.credits_per_vuln(10) >= 3, "credits per vuln")
check(F.agent_cost(5, 1) == 5, "first level costs the base price")
check(F.agent_cost(100, 10) > F.agent_cost(100, 9), "cost grows with level")
check(F.milestones(24) == 0 and F.milestones(25) == 1, "first damage milestone at 25")
check(F.milestones(50) == 2, "milestone every 25 levels")
print(string.format("  hp(1)=%.0f hp(50)=%.4g hp(140)=%.4g cost(100,lvl10)=%.0f",
  F.vuln_hp(1), F.vuln_hp(50), F.vuln_hp(140), F.agent_cost(100, 10)))

-- ---------------------------------------------------------------- the tick
print("combat")
local s = SimState.new_run()
Combat.new_run_spawn(s)
check(s.zone == 1 and s.kills == 0, "a run starts on zone 1 with no kills")
check(s.hp == F.vuln_hp(1), "the first vuln has its formula HP")

local hp0 = s.hp
s.click = 1
Combat.probe(s)
check(s.hp == hp0 - 1 or s.kills == 1, "a probe takes 1 HP off")

s.click = 100000
for _ = 1, 40 do Combat.probe(s) end
check(s.zone > 1, "clearing ten vulns advances the zone")
check(s.credits > 0, "kills pay credits")

local boss = SimState.new_run()
boss.zone = 5
Combat.new_run_spawn(boss)
check(boss.boss == true, "zone 5 is a boss firewall")
check(boss.timer == Combat.BOSS_SECONDS, "the boss has a 30 second clock")
check(boss.hpMax == F.boss_hp(5), "the boss bar is ten vulns deep")

local before = boss.zone
boss.dps = 0
boss.timer = 0.5
Combat.tick(boss, 1)
check(boss.zone == before, "failing the clock keeps the zone")
check(boss.timer == Combat.BOSS_SECONDS, "failing the clock gives the boss a fresh timer")
check(boss.hp == boss.hpMax, "failing the clock re-arms the firewall")

-- ---------------------------------------------------------------- buying
print("economy")
local b = SimState.new_run()
Combat.new_run_spawn(b)
b.credits = 100000
local lvl = b.agents[1].lv
local cost = Economy.next_cost(b, 1)
check(Economy.buy(b, 1), "buying succeeds with credits")
check(b.agents[1].lv == lvl + 1, "the level went up")
check(b.credits == 100000 - cost, "exactly the price was spent")
local poor = SimState.new_run()
poor.credits = 0
check(not Economy.buy(poor, 1), "buying without credits fails")
check(poor.agents[1].lv == 1, "a failed buy changes nothing")
print(string.format("  agent 1 lvl %.0f -> %.0f, credits 100000 -> %.0f, dps %.0f",
  lvl, b.agents[1].lv, b.credits, b.dps))

-- ---------------------------------------------------------------- save
print("save")
local src = SimState.new_run()
Combat.new_run_spawn(src)
src.credits = 4242
src.zone = 12
src.kills = 3
src.rootkits = 7
src.agents[2].lv = 5
src.bestZone = 12
local text = Save.serialise(Save.snapshot(src))
local data = Save.deserialise(text)
check(data ~= nil, "the save parses back")
local dst = SimState.new_run()
Save.apply(dst, data)
check(dst.credits == 4242, "credits survive a save")
check(dst.zone == 12 and dst.kills == 3, "zone and kills survive a save")
check(dst.rootkits == 7, "rootkits survive a save")
check(dst.agents[2].lv == 5, "agent levels survive a save")
print("  round trip: " .. #text .. " bytes, zone " .. dst.zone .. ", credits " .. dst.credits)

-- ---------------------------------------------------------------- offline
print("offline")
local off = SimState.new_run()
Combat.new_run_spawn(off)
off.agents[2].lv = 40
Economy.recalc(off)
local credits0, zone0 = off.credits, off.zone
local ran = Combat.simulate(off, 3600, 5)
check(ran > 0, "the offline replay runs")
check(off.zone >= zone0, "offline progress never goes backwards")
check(off.credits > credits0, "offline credits accrue")
print(string.format("  %.0fs replayed: zone %.0f -> %.0f, credits +%.0f",
  ran, zone0, off.zone, off.credits - credits0))

-- ---------------------------------------------------------------- binds
print("binds")
local B = Game.bindsOf()
check(B.buy and B.click and B.fire and B.prevSkill and B.nextSkill, "every bind resolves")
local f = io.open("port/clickeragents/clickeragents.gptk", "r")
check(f ~= nil, "the gptk is readable")
if f then
  local gptk = {}
  for line in f:lines() do
    local k, v = line:match("^%s*(%w+)%s*=%s*(%w+)")
    if k then gptk[k] = v end
  end
  f:close()
  check(B.buy == gptk.b, "printed A matches the gptk")
  check(B.click == gptk.a, "printed B matches the gptk")
  print(string.format("  gptk: A=%s (buy) B=%s (probe)", gptk.b, gptk.a))
end

-- ---------------------------------------------------------------- screens
print("screens")
SW, SH = 720, 480
love.load()
local g = st()
g.screen = "game"

g.tab = 1
local lv0 = g.agents[1].lv
g.credits = 100000
love.keypressed(B.buy)
check(g.agents[1].lv == lv0 + 1, "A buys the selected agent")
check(g.credits < 100000, "A spends credits")

local hp0b = g.hp
love.keypressed(B.click)
check(g.hp < hp0b or g.kills > 0, "B probes the vuln")

g.tab = 2
g.cursor[2] = 1
g.skillCd[1] = 0
love.keypressed(B.fire)
check((g.skillCd[1] or 0) > 0, "X casts on the skills tab")
love.keypressed(B.fire)
love.draw()

g.tab = 1
g.zone = 12
g.zoneSel = 12
love.keypressed(B.prevSkill)
check(g.zoneSel == 11, "L2 steps a zone back")
love.keypressed(B.fire)
check(g.zoneSel == 12, "X snaps back to the live zone")

local visited = {}
for _ = 1, 7 do
  love.keypressed("e")
  visited[#visited + 1] = g.tab
end
check(visited[7] == 1, "R cycles all seven screens back to battle")

g.tab = 4
g.cursor[4] = 1
love.keypressed(B.buy)
check(g.msg ~= nil, "a daemon press reports its rootkit price")
love.keypressed("e")
love.keypressed("e")
love.keypressed("e")
love.draw()
print("  input, tabs and daemons exercised")

print(string.format("\nchecks: %d ok, %d failed", ok, fail))
if fail > 0 then os.exit(1) end
print("OK: three screen sizes, formulas, tick, save, binds, input")
