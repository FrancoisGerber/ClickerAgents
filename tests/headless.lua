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
local Chrome = require("ui.chrome")
local Combat = require("sim.combat")
local Economy = require("sim.economy")
local Upgrades = require("data.upgrades")
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
check(s.zone == 1 and s.cleared, "clearing ten vulns stops the run in that zone")
check(s.credits > 0, "kills pay credits")

-- the gate holds, but the farm does not stop: DPS keeps paying in the same zone
local gateZone, gateKills = s.zone, s.kills
local creditsBeforeFarm = s.credits
for _ = 1, 20 do Combat.tick(s, 0.5) end
check(s.zone == gateZone, "a cleared zone holds the player in place")
check(s.kills == gateKills, "the kill counter stops at the gate")
check(s.credits > creditsBeforeFarm, "but DPS keeps farming credits in that zone")
check(s.hpMax > 0 and s.hp > 0, "and a fresh vuln keeps the bar moving")
check(Combat.advance_zone(s) and s.zone == 2 and not s.cleared, "X walks through into the next zone")
check(s.hpMax > 0, "the next zone spawns a fresh target")

-- offline replay is the exception: it walks through cleared zones by itself
local off = SimState.new_run()
Combat.new_run_spawn(off)
off.dps = 100000
Combat.simulate(off, 120, 1)
check(off.zone > 1, "offline time advances zones without the player")

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

-- ---------------------------------------------------------------- selection
print("selection")
local BattleScreen = require("screens.battle")
local pick = SimState.new_run()
pick.sel = 1
check(BattleScreen.row_is_selected(pick, 0), "the first agent is the highlighted row")
check(not BattleScreen.row_is_selected(pick, 1), "the second row is not highlighted")
pick.sel = 2
check(BattleScreen.row_is_selected(pick, 1), "moving down highlights the second row")
check(not BattleScreen.row_is_selected(pick, 0), "and clears the first")
Economy.select(pick, 0)
check(pick.sel == 1, "selection clamps at the first agent")
Economy.select(pick, 99)
check(pick.sel == #pick.agents, "selection clamps at the last agent")
print("  row 0 <-> agent 1, clamped at both ends")

-- ---------------------------------------------------------------- upgrades
print("upgrades")
local function fresh_with_level(lv)
  local u = SimState.new_run()
  u.agents[1].lv = lv
  u.zone = 3
  Economy.recalc(u)
  return u
end

local base = fresh_with_level(10)
local bDps, bClick, bCredits = base.dps, base.click, base.creditsKill

local w = fresh_with_level(10); w.upOwned[2] = true; Economy.recalc(w)      -- WORDLIST +10% throughput
check(w.dps == math.floor(bDps * 1.10), "+10% throughput tools lift DPS")

local s2 = fresh_with_level(10); s2.upOwned[1] = true; Economy.recalc(s2)    -- SCANNER +25% probe
check(s2.click == math.floor((1 + 0.005 * s2.dps) * 1.25), "+25% probe tools lift click damage")

local e = fresh_with_level(10); e.upOwned[4] = true; Economy.recalc(e)       -- EXPLOIT KIT x2 probe
check(e.click == math.floor((1 + 0.005 * e.dps) * 2), "x2 probe tools double click damage")

local m = fresh_with_level(10); m.upOwned[9] = true; Economy.recalc(m)       -- MIXER +100% credits
check(m.creditsKill == bCredits * 2, "+100% credit tools double the payout")

local p = fresh_with_level(10); p.upOwned[10] = true; Economy.recalc(p)      -- PERSISTENCE
check(p.dps == math.floor(bDps * 1.25), "PERSISTENCE lifts throughput")
local totals = F.upgrade_totals(p.upOwned)
check(totals.rootkit_bonus == 1, "PERSISTENCE adds a rootkit per ascension")
check(F.rootkits_for_run(0, 0, totals.rootkit_bonus) == 1, "and the ascension payout sees it")

-- ---------------------------------------------------------------- purchases
print("purchases")
local shop = SimState.new_run()
shop.zone = 3
shop.agents[1].lv = 5
Economy.recalc(shop)
shop.credits = 0
check(not Economy.buy_tool(shop, 1), "a tool cannot be bought without credits")
check(not Economy.tool_owned(shop, 1), "and it stays unowned")

shop.credits = 1e4
local dpsBeforeTool = shop.dps
check(Economy.buy_tool(shop, 2), "WORDLIST can be bought once affordable")     -- +10% throughput, 5K
check(Economy.tool_owned(shop, 2), "the purchase marks it owned")
check(shop.credits == 1e4 - 5e3, "the price is deducted")
check(shop.dps == math.floor(dpsBeforeTool * 1.10), "and the effect lands immediately")
check(not Economy.buy_tool(shop, 2), "a tool cannot be bought twice")

check(not Economy.buy_skill(shop, 3), "a skill cannot be bought without credits")
shop.credits = 3e5
check(Economy.buy_skill(shop, 3), "PHISH can be bought for 250K")              -- cost 250e3
check(Economy.skill_owned(shop, 3), "the skill is owned after buying")
check(shop.credits == 3e5 - 250e3, "the skill price is deducted")
check(not Economy.buy_skill(shop, 3), "a skill cannot be bought twice")

-- ---------------------------------------------------------------- balance
print("balance (M1 acceptance)")
local run = SimState.new_run()
Combat.new_run_spawn(run)
local t, dt, zone10 = 0, 0.1, nil
while t < 240 do
  if run.cleared then Combat.advance_zone(run) end   -- a present player walks through
  Combat.tick(run, dt)
  t = t + dt
  local best, bestCost = nil, math.huge
  for i = 1, #run.agents do
    if Economy.unlocked(run, i) then
      local c = Economy.next_cost(run, i)
      if c <= run.credits and c < bestCost then best, bestCost = i, c end
    end
  end
  if best then Economy.buy(run, best) end
  if not zone10 and run.zone >= 10 then zone10 = t end
end
check(zone10 ~= nil, "a greedy player reaches zone 10 inside four minutes")
check(run.zone >= 17, "and zone 17 inside the same four minutes")
print(string.format("  zone 10 at %s, zone %d after 240s, dps %d",
  zone10 and string.format("%.0fs", zone10) or "never", run.zone, run.dps))

-- ---------------------------------------------------------------- M2 acceptance
print("balance (M2 acceptance)")
local run2 = SimState.new_run()
Combat.new_run_spawn(run2)
local dt2, t2, zone100 = 0.1, 0, nil
while t2 < 1500 do
  if run2.cleared then Combat.advance_zone(run2) end
  Combat.tick(run2, dt2)
  t2 = t2 + dt2
  -- greedy buyer: cheapest agent level first, then the next tool in order
  local best, bestCost = nil, math.huge
  for i = 1, #run2.agents do
    if Economy.unlocked(run2, i) then
      local c = Economy.next_cost(run2, i)
      if c <= run2.credits and c < bestCost then best, bestCost = i, c end
    end
  end
  if best then
    Economy.buy(run2, best)
  else
    for i = 1, #Upgrades.list do
      if not Economy.tool_owned(run2, i) and Economy.buy_tool(run2, i) then break end
    end
  end
  if not zone100 and run2.zone >= 100 then zone100 = t2 end
end
check(zone100 ~= nil, "a greedy player reaches zone 100 at all")
check(zone100 and zone100 >= 900, "but not before 15 minutes")
check(zone100 and zone100 <= 1500, "and inside 25 minutes")
print(string.format("  zone 100 at %s, final zone %d", zone100 and string.format("%.0fs", zone100) or "never", run2.zone))

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
g.sel = 1
love.keypressed("down")
check(g.sel == 2, "D-pad down moves the selection to agent 2")
love.keypressed("up")
check(g.sel == 1, "D-pad up returns to agent 1")
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
for _ = 1, 6 do
  love.keypressed("e")
  visited[#visited + 1] = g.tab
end
check(visited[6] == 1, "R cycles all six tabs back to battle")
check(Chrome.NTABS == 6, "the menu is not a tab any more")

-- START opens the pause menu from any screen, freezes the clock and saves
g.tab = 3
love.keypressed("return")
check(g.screen == "menu", "START opens the menu from a list screen")
check(g.paused == true, "opening the menu sets the paused flag")
check(g.cursor.menu == 1, "the menu cursor starts on RESUME")
local creditsBefore = g.credits
local hpBefore = g.hp
love.update(1.0)
check(g.credits == creditsBefore and g.hp == hpBefore, "the ticker is frozen while paused")
love.keypressed("b-placeholder")                  -- no-op key while paused
love.keypressed(B.click)
check(g.screen == "game" and g.paused == false, "B resumes the game")

-- SELECT cycles the buy amount, START no longer does
g.amount = 1
love.keypressed("tab")
check(g.amount == 10, "SELECT cycles the amount to x10")
love.keypressed("tab"); love.keypressed("tab")
check(g.amount == 0, "SELECT reaches MAX")
love.keypressed("tab")
check(g.amount == 1, "and wraps back to x1")

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
