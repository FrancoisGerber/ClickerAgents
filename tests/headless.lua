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
local Buffs = require("sim.buffs")
local Prestige = require("sim.prestige")
local Achievements = require("sim.achievements")
local Skills = require("data.skills")
local Systems = require("data.systems")
local Actions = require("app.actions")
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
-- the bottom of every list, where a window that does not scroll would spill
for _, size in ipairs({ { 720, 480 }, { 640, 480 } }) do
  SW, SH = size[1], size[2]
  love.load()
  local s2 = st()
  s2.screen = "game"
  local last = { 2, #require("data.skills"), #require("data.upgrades").list,
                 #require("data.systems").daemons + 1, #require("data.achievements"),
                 1, 1 }
  for tab = 2, 7 do
    s2.tab = tab
    s2.cursor[tab] = last[tab]
    love.draw()
  end
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
s.agents[1].lv = 1                       -- the player bought their first Spider
Economy.recalc(s)
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

boss.dps = 0
boss.credits = 4242
boss.timer = 0.5
Combat.tick(boss, 1)
check(boss.bossFails == 1, "failing the clock counts the attempt")
check(boss.zone == 4, "a closed perimeter pushes you back a zone to farm")
check(boss.credits == 4242, "the attempt costs the clock, not your credits")
check(boss.cleared and boss.kills == boss.killsRequired, "the gate forward stays open")
check(not boss.boss and boss.timer == 0, "the zone you land in is a normal farm zone")

check(Combat.advance_zone(boss), "one press walks back into the firewall")
check(boss.zone == 5 and boss.boss, "and the firewall is waiting")
check(boss.timer == Combat.BOSS_SECONDS, "with a fresh 30 second clock")
check(boss.hp == boss.hpMax, "and a full bar")

-- a firewall pays triple the vuln rate
local pay = SimState.new_run()
pay.zone = 5
Combat.new_run_spawn(pay)
check(pay.creditsKill == F.credits_per_vuln(5) * 3, "a firewall pays three times a vuln")

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
check(poor.agents[1].lv == 0, "a failed buy changes nothing")
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

-- ---------------------------------------------------------------- fresh run
print("fresh run")
local Z = SimState.new_run()
Combat.new_run_spawn(Z)
check(Z.credits == 0, "credits start at zero")
check(Z.dps == 0, "and no agent is deployed for free")
check(Z.agents[1].lv == 0, "not even the first Spider")
check(Economy.next_cost(Z, 1) == 12, "which costs 12 credits when you buy it")

-- probing is the only income before that
Z.click = 1
for _ = 1, 10 do Combat.probe(Z) end
check(Z.credits == 1, "ten probes into a zone-1 vuln pays one credit")
check(Z.dps == 0, "and no throughput has appeared on its own")

-- ---------------------------------------------------------------- skills
local SI = {}
for i, sk in ipairs(Skills) do SI[sk.name] = i end
local function effOf(name, kind)
  for _, e in ipairs(Skills[SI[name]].effects or {}) do
    if e[1] == kind then return e[2] end
  end
end

-- ---------------------------------------------------------------- fresh save
print("fresh save")
local N = SimState.new_run()
local ownedCount = 0
for i = 1, #N.owned do if N.owned[i] then ownedCount = ownedCount + 1 end end
check(ownedCount == 0, "a new save owns no skills at all")
check(not Economy.skill_owned(N, SI.CRAWL), "not even CRAWL")
N.credits = 1e4
check(Economy.buy_skill(N, SI.CRAWL), "CRAWL can be bought for 2K")
check(Economy.skill_owned(N, SI.CRAWL), "and then it is yours")
local kept = SimState.new_run()
Prestige.ascend(kept)   -- locked below 100, so nothing happens: just proving it is a no-op
check(not Economy.skill_owned(kept, SI.CRAWL), "ascending does not hand skills back")

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
check(s2.click == math.floor(F.probe_damage(s2.dps) * 1.25), "+25% probe tools lift click damage")

local e = fresh_with_level(10); e.upOwned[4] = true; Economy.recalc(e)       -- EXPLOIT KIT x2 probe
check(e.click == math.floor(F.probe_damage(e.dps) * 2), "x2 probe tools double click damage")

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

-- ---------------------------------------------------------------- skills
print("skills")
local K = SimState.new_run()
K.agents[1].lv = 10
K.zone = 3
Economy.recalc(K)
K.credits = 1e12
for i = 1, #Skills do
  if Economy.skill_owned(K, i) then
    check(true, Skills[i].name .. " starts owned")
  else
    check(Economy.buy_skill(K, i), "skill " .. Skills[i].name .. " can be bought")
  end
end
local d0, c0, g0 = K.dps, K.click, K.creditsKill

Actions.cast_skill(K, SI.SPRAY)
check(Buffs.active(K, SI.SPRAY), "a cast starts a 30 second buff")
check(K.dps == d0 * 2, "SPRAY doubles throughput")
check(K.skillCd[SI.SPRAY] == Skills[SI.SPRAY].cd, "and starts its own cooldown")
Buffs.tick(K, 31)
Economy.recalc(K)
check(not Buffs.active(K, SI.SPRAY) and K.dps == d0, "when it expires throughput returns")

Actions.cast_skill(K, SI.SIPHON)
check(K.creditsKill == g0 * 3, "SIPHON triples the payout")
Buffs.tick(K, 31); Economy.recalc(K)
check(K.creditsKill == g0, "and the payout comes back")

Actions.cast_skill(K, SI.FLOOD)
check(K.dps > d0, "FLOOD raises throughput")
Buffs.tick(K, 31); Economy.recalc(K)
check(K.dps == d0, "and it drops back when the buff ends")

-- SPLICE is the probe skill now
Actions.cast_skill(K, SI.SPLICE)
check(K.click == math.floor(F.probe_damage(K.dps) * effOf("SPLICE", "click_mul")),
      "SPLICE multiplies probe damage")
Buffs.tick(K, 31); Economy.recalc(K)

Actions.cast_skill(K, SI.PHISH)
check(K.click == math.floor(F.probe_damage(K.dps) * Buffs.CRIT_MUL), "PHISH makes every probe crit for x10")
Buffs.tick(K, 31); Economy.recalc(K)
check(K.click == c0, "probe damage returns to normal")

Actions.cast_skill(K, SI.BLACKOUT)
local cut = 1 - effOf("BLACKOUT", "vulnhp_mul")
local beforeMax = K.hpMax
local expectedMax = math.max(1, beforeMax - math.floor(beforeMax * cut))
check(K.hpMax == expectedMax, "BLACKOUT cuts the vuln in front of you")
local spawnMax = F.vuln_hp(K.zone) * (1 - cut)
K.cleared = false
Combat.spawn(K)
check(K.hpMax == math.floor(spawnMax), "and the next vuln spawns weakened too")
Buffs.tick(K, 31); Economy.recalc(K)
Combat.spawn(K)
check(K.hpMax == F.vuln_hp(K.zone), "full HP is back when the buff ends")

-- CRAWL adds ten probes a second on top of the agents
local C = SimState.new_run()
C.agents[1].lv = 10
C.zone = 3
Economy.recalc(C)
C.credits = 1e12
if not Economy.skill_owned(C, SI.CRAWL) then Economy.buy_skill(C, SI.CRAWL) end
C.dps = 0
C.hp, C.hpMax = 1e6, 1e6
Actions.cast_skill(C, SI.CRAWL)
C.dps = 0                       -- isolate the probes from the agents' throughput
local hpBefore = C.hp
Combat.tick(C, 1.0)
local crawlDmg = hpBefore - C.hp
check(math.abs(crawlDmg - effOf("CRAWL", "probes") * C.click) < 1e-6,
      string.format("CRAWL lands ten probes a second (%.0f damage, click %.0f)", crawlDmg, C.click))

-- ---------------------------------------------------------------- click beats idle
print("click vs idle")
local n = 0
for _, lv in ipairs({ 1, 25, 100, 400 }) do
  for _, zone in ipairs({ 1, 50, 140, 300 }) do
    local C1 = SimState.new_run()
    C1.agents[1].lv = lv
    C1.zone = zone
    Economy.recalc(C1)
    if C1.dps > 0 and C1.click > C1.dps then n = n + 1 end
  end
end
check(n == 16, "one probe is worth more than one second of idling at every level and zone")

local D = SimState.new_run()
D.agents[1].lv = 60
D.agents[2].lv = 30
D.zone = 80
Economy.recalc(D)
local dpsNow, clickNow = D.dps, D.click
-- killing a full-health vuln: idle needs this long, one probe per second is this much better
local hp = F.vuln_hp(80)
local idleSeconds = hp / dpsNow
local tapSeconds = hp / (clickNow + dpsNow)
check(tapSeconds < idleSeconds, "tapping kills the same vuln faster than waiting")
check(D.creditsKill > 0, "and both still pay")

-- with no agents at all the press still works, at the floor of 1
local F0 = SimState.new_run()
Economy.recalc(F0)
check(F0.dps == 0 and F0.click == 1, "a fresh save probes for 1 with no agents deployed")

-- ---------------------------------------------------------------- balance
print("balance (M1 acceptance)")
local run = SimState.new_run()
run.agents[1].lv = 1                     -- the first Spider is the first thing a run buys
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
run2.agents[1].lv = 1
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

-- ---------------------------------------------------------------- M3 acceptance
print("balance (M3 acceptance)")
local run3 = SimState.new_run()
run3.agents[1].lv = 1
Combat.new_run_spawn(run3)
local dt3, t3, lastBest, monotone = 0.1, 0, 1, true
local function shop3()
  local best, bestCost = nil, math.huge
  for i = 1, #run3.agents do
    if Economy.unlocked(run3, i) then
      local c = Economy.next_cost(run3, i)
      if c <= run3.credits and c < bestCost then best, bestCost = i, c end
    end
  end
  if best then Economy.buy(run3, best) return end
  for i = 1, #Upgrades.list do
    if not Economy.tool_owned(run3, i) and Economy.buy_tool(run3, i) then return end
  end
end
while t3 < 8 * 3600 and run3.zone < 300 do
  if run3.cleared then
    -- a player who will not walk into a firewall they cannot break inside 30 s
    local nxt = run3.zone + 1
    local need = F.is_boss_zone(nxt) and (F.boss_hp(nxt) / Combat.BOSS_SECONDS) * 1.05 or 0
    if run3.dps >= need then Combat.advance_zone(run3) end
  end
  Combat.tick(run3, dt3)
  t3 = t3 + dt3
  shop3()
  if run3.bestZone < lastBest then monotone = false end
  lastBest = run3.bestZone
end
check(run3.bossFails == 0, "eight hours in, no firewall was walked into underprepared")
check(run3.zone >= 150, "eight hours of play clears zone 150")
check(monotone, "the run never goes backwards")
check(math.floor(run3.zone / 5) >= 30, "thirty firewalls broken on the way")
print(string.format("  zone %d after 8h, %d firewalls broken, %d failed, dps %.2e",
  run3.zone, math.floor(run3.zone / 5), run3.bossFails or 0, run3.dps))

-- ---------------------------------------------------------------- prestige
print("prestige")
local P = SimState.new_run()
P.zone = 99
check(not Prestige.can_ascend(P), "ascension is locked below zone 100")
P.zone = 100
check(Prestige.can_ascend(P), "and opens at zone 100")

local Q = SimState.new_run()
Q.zone = 140
Q.agents[1].lv = 4000
Q.bossKills = 27
check(Prestige.rootkits_on_offer(Q) == 2 + 27, "an ascension offers levels/2000 plus firewalls broken")

Q.credits = 1e9
Q.upOwned[1] = true
Q.owned[3] = true
Q.cleared = true
local earned = Prestige.ascend(Q)
check(earned == 29, "the ascension pays what was on offer")
check(Q.zone == 1 and Q.credits == 0, "the run is wiped back to zone 1")
check(Q.agents[1].lv == 1 and Q.agents[2].lv == 0, "agent levels are gone")
check(not Q.upOwned[1], "tools are gone")
check(not Q.owned[3], "skills you bought are gone")
check(Q.rootkits == 29 and Q.systems == 1, "rootkits and systems breached are kept")
check(not Q.cleared, "the next run starts on a live vuln")
check(Q.dps > 0, "and the framework still runs")

-- held rootkits are throughput: +10% each
local R = SimState.new_run()
R.agents[1].lv = 10
Economy.recalc(R)
local plain = R.dps
R.rootkits = 10
Economy.recalc(R)
check(R.dps == math.floor(plain * 2), "ten held rootkits double throughput")

local DI = {}
for i, d in ipairs(Systems.daemons) do DI[d.name] = i end
local function daemonCost(name) return Systems.daemons[DI[name]].cost end

-- daemons: bought with rootkits, permanent, and they change the maths
local D = SimState.new_run()
D.agents[1].lv = 10
local beaconCost = daemonCost("BEACON")
D.rootkits = beaconCost
Economy.recalc(D)
check(Prestige.buy_daemon(D, DI.BEACON), "BEACON can be bought for " .. beaconCost .. " rootkits")
check(Prestige.daemon_owned(D, DI.BEACON), "the daemon is online")
check(D.rootkits == 0, "the rootkits are spent")
check(not Prestige.buy_daemon(D, DI.BEACON), "a daemon cannot be bought twice")

local beforeBeacon = D.dps
D.daemons[DI.BEACON] = false
Economy.recalc(D)
check(math.abs(D.dps - (beforeBeacon / 1.10)) < 2, "BEACON is worth exactly +10% throughput")

local W = SimState.new_run()
W.zone = 4
Economy.recalc(W)
local pay0 = W.creditsKill
W.daemons[2] = true
Economy.recalc(W)
check(W.creditsKill == math.floor(pay0 * 1.15), "WATCHDOG lifts the payout 15%")

local H = SimState.new_run()
H.zone = 5
Combat.new_run_spawn(H)
check(H.timer == Combat.BOSS_SECONDS, "a firewall clock is 30 s by default")
H.daemons[DI.HONEYPOT] = true
Combat.spawn(H)
check(H.timer == Combat.BOSS_SECONDS + 10, "HONEYPOT buys ten more seconds")

-- ---------------------------------------------------------------- M4 acceptance
print("balance (M4 acceptance)")
local function play_to(st, target, cap)
  local dt, t, hit100 = 0.1, 0, nil
  local function shop()
    local best, bestCost = nil, math.huge
    for i = 1, #st.agents do
      if Economy.unlocked(st, i) then
        local c = Economy.next_cost(st, i)
        if c <= st.credits and c < bestCost then best, bestCost = i, c end
      end
    end
    if best then Economy.buy(st, best) return end
    for i = 1, #Upgrades.list do
      if not Economy.tool_owned(st, i) and Economy.buy_tool(st, i) then return end
    end
  end
  while t < (cap or 20 * 3600) and st.zone < target do
    if st.cleared then
      local nxt = st.zone + 1
      local need = F.is_boss_zone(nxt) and (F.boss_hp(nxt) / Combat.BOSS_SECONDS) * 1.05 or 0
      if st.dps >= need then Combat.advance_zone(st) end
    end
    Combat.tick(st, dt)
    t = t + dt
    shop()
    if not hit100 and st.zone >= 100 then hit100 = t end
  end
  return hit100, t, st.zone
end

local R4 = SimState.new_run()
R4.agents[1].lv = 1
Combat.new_run_spawn(R4)
local first100, firstTime, firstZone = play_to(R4, 140)
check(first100 ~= nil, "the first run reaches zone 100")
check(firstZone >= 140, "and can be taken to the ascend line at zone 140")
local offered = Prestige.rootkits_on_offer(R4)
check(offered > 0, "the run has rootkits to offer")

Prestige.ascend(R4)
check(R4.zone == 1 and R4.rootkits == offered, "ascension banks them and restarts the run")

local second100 = play_to(R4, 100)
check(second100 ~= nil, "the second run reaches zone 100 too")
check(second100 < first100, "and beats the first run's pace")
print(string.format("  first run: zone 100 at %.0fs (zone %d at %.0fs, +%d rootkits) | second run: zone 100 at %.0fs",
  first100, firstZone, firstTime, offered, second100))

-- ---------------------------------------------------------------- M5 port shape
print("port shape")

-- the save beat: a change is written at once, otherwise once a minute
local SV = SimState.new_run()
Combat.new_run_spawn(SV)
SV.credits = 1e6
local saves0 = SV.saves
SV.saveRequest = false
Save.sync(SV, 10)
check(SV.saves == saves0, "ten quiet seconds do not write a save")
Save.sync(SV, 50)
check(SV.saves == saves0 + 1, "a minute on the clock does")
check(SV.saveClock == 0, "and the clock resets")
check(Save.reason == "beat", "the beat is the reason")

Economy.buy(SV, 1)
check(SV.saveRequest == true, "buying marks the run dirty")
Save.sync(SV, 0.1)
check(SV.saves == saves0 + 2, "and it is written on the next frame")
check(Save.reason == "change", "as a change, not a beat")

SV.saveRequest = false
SV.cleared = true
Combat.advance_zone(SV)
check(SV.saveRequest == true, "walking into a zone marks the run dirty")

-- save round-trip keeps the newer fields
local snap = Save.deserialise(Save.serialise(Save.snapshot(SV)))
check(snap.killsRequired ~= nil, "the gate requirement is saved")
check(snap.daemons ~= nil, "daemons are saved")
check(snap.bossKills ~= nil, "the firewall tally is saved")

-- offline replay: capped at eight hours, and it walks zones by itself
local OFF = SimState.new_run()
Combat.new_run_spawn(OFF)
OFF.agents[1].lv = 40
Economy.recalc(OFF)
local report = Save.replay_offline(OFF, { saved_at = os.time() - 20 * 3600 })
check(report and report.seconds == Save.OFFLINE_CAP, "an overnight absence is capped at eight hours")
check(report and report.zones > 0, "offline time still clears zones")
local quiet = Save.replay_offline(SimState.new_run(), { saved_at = os.time() - 10 })
check(quiet == nil, "a ten second gap does not earn a report")

-- ---------------------------------------------------------------- achievements
print("achievements")
local A = SimState.new_run()
check(Achievements.earned(A) == 0, "a fresh run has unlocked nothing")
A.zone = 2
Achievements.check(A)
check(A.achDone[1], "clearing the first zone unlocks FIRST BREACH")
check(A.msg and A.msg:find("FIRST BREACH"), "and it says so on screen")

A.totalBosses = 10
A.rootkits = 10
A.systems = 1
A.zone = 100
Achievements.check(A)
check(A.achDone[2], "ten firewalls unlocks FIREWALL DOWN")
check(A.achDone[3], "ten rootkits unlocks TEN ROOTKITS")
check(A.achDone[4], "the first ascension unlocks NEW TARGET")
check(A.achDone[5], "zone 100 unlocks CORE ACCESS")

for i = 1, #A.agents do A.agents[i].lv = 1 end
A.totalKills = 100
A.bestZone = 250
Achievements.check(A)
check(A.achDone[6], "a full roster unlocks FULL ROSTER")
check(A.achDone[7], "a hundred kills unlocks SILENT RUN")
check(A.achDone[8], "best zone 250 unlocks ROOT")
check(Achievements.earned(A) == 8, "all eight can be earned")
check(Achievements.check(A) == 0, "and re-checking does not re-announce them")

-- lifetime counters
local L2 = SimState.new_run()
Combat.new_run_spawn(L2)
L2.click = 1e9
Combat.probe(L2)
check(L2.totalKills == 1, "a kill counts toward the lifetime total")
local before = L2.playtime
Combat.tick(L2, 1)
check(L2.playtime > before, "playtime accumulates with the tick")

-- ---------------------------------------------------------------- content
print("content")
local Agents, Skills, Upgrades = require("data.agents"), require("data.skills"), require("data.upgrades")
local SystemsData = require("data.systems")
local AchData = require("data.achievements")

check(#Agents.list == 12, "twelve agents")
check(#Skills == 12, "twelve skills, one for each agent")
check(#Upgrades.list == 10, "ten tools")
check(#SystemsData.daemons == 10, "ten daemons")
check(#AchData == 10, "ten achievements")
check(#Achievements.rules == #AchData, "every achievement has a rule")

-- one skill per agent, named after it, and no agent without a skill
local seenAgents, seenSkills = {}, {}
for _, sk in ipairs(Skills) do
  check(not seenSkills[sk.name], "skill names are unique: " .. sk.name)
  seenSkills[sk.name] = true
  check(not seenAgents[sk.agent], "one skill per agent: " .. sk.agent)
  seenAgents[sk.agent] = true
end
local roster = {}
for _, a in ipairs(Agents.list) do roster[a.name:upper()] = true end
for agent in pairs(seenAgents) do
  check(roster[agent] == true, "skill agent exists in the roster: " .. agent)
end
for _, a in ipairs(Agents.list) do
  check(seenAgents[a.name:upper()] == true, "every agent owns a skill: " .. a.name)
end

-- skill and daemon effects are all kinds the readers understand
local skillKinds = { dps_mul = 1, credits_mul = 1, click_mul = 1, vulnhp_mul = 1,
                     probes = 1, crit = 1 }
for _, sk in ipairs(Skills) do
  check(#sk.effects > 0, sk.name .. " does something")
  for _, e in ipairs(sk.effects) do
    check(skillKinds[e[1]] == 1, sk.name .. " effect kind is known: " .. tostring(e[1]))
  end
end
local daemonKinds = { dps_mul = 1, credits_mul = 1, click_mul = 1, probes = 1,
                      boss_seconds = 1, rootkit_bonus = 1, offline_hours = 1 }
local prevCost = 0
for _, d in ipairs(SystemsData.daemons) do
  check(#d.effects > 0, d.name .. " does something")
  for _, e in ipairs(d.effects) do
    check(daemonKinds[e[1]] == 1, d.name .. " effect kind is known: " .. tostring(e[1]))
  end
  check(d.cost > prevCost, "daemon prices climb: " .. d.name)
  prevCost = d.cost
end

-- every daemon effect actually reaches the state when it is owned
local allOwned = SimState.new_run()
for i = 1, #SystemsData.daemons do allOwned.daemons[i] = true end
local dm = SystemsData.daemon_mults(allOwned)
check(dm.dps > 1 and dm.credits > 1 and dm.click > 1, "daemon multipliers land in the reader")
check(dm.probes == 4, "CRON and TUNNEL give four extra probes")
check(dm.boss_seconds == 10, "HONEYPOT gives the firewall ten seconds")
check(dm.rootkit_bonus == 1, "SQUID adds a rootkit on ascension")
check(dm.offline_hours == 2, "SENTRY adds two offline hours")

-- ---------------------------------------------------------------- sprites
print("sprites")
local Sprites = require("ui.sprites")
local bw = 720
check(math.abs((math.floor(bw / 2 - Sprites.CENTRE.vuln * 1.4) + Sprites.CENTRE.vuln * 1.4) - bw / 2) < 1,
      "the vuln sprite is centred on its own bounds")
check(math.abs((math.floor(bw / 2 - Sprites.CENTRE.boss * 1.1) + Sprites.CENTRE.boss * 1.1) - bw / 2) < 1,
      "and so is the firewall sprite")

-- ---------------------------------------------------------------- menu
print("menu")
check(Actions.MENU_ROWS == 2, "the pause menu has two rows")
local M2 = SimState.new_run()
Actions.open_menu(M2)
local row = M2.cursor.menu
check(row == 1, "the menu opens on RESUME")
check(not M2.idle, "opening the menu stops the clock")

-- ---------------------------------------------------------------- tuning
print("tuning")
local TUNE = require("tuning")

-- the file is actually consulted: move a value, watch the system follow, put it back
local before = F.probe_damage(1000)
TUNE.probe.share = 3.0
check(F.probe_damage(1000) == 3000, "probe share comes from tuning")
TUNE.probe.share = before / 1000

local hpAt = F.vuln_hp(10)
TUNE.vuln.linear = 0
check(F.vuln_hp(10) ~= hpAt, "the vuln curve comes from tuning")
TUNE.vuln.linear = 10
check(F.vuln_hp(10) == hpAt, "and restores exactly")

local costAt = F.agent_cost(100, 5)
TUNE.agent.cost_growth = 2.0
check(F.agent_cost(100, 5) ~= costAt, "agent cost growth comes from tuning")
TUNE.agent.cost_growth = 1.07
check(F.agent_cost(100, 5) == costAt, "and restores exactly")

check(Combat.KILLS_PER_ZONE == TUNE.zone.kills_per_zone, "kills per zone comes from tuning")
check(Combat.BOSS_SECONDS == TUNE.boss.seconds, "the firewall clock comes from tuning")
check(Buffs.DURATION == TUNE.buff.duration, "skill duration comes from tuning")
check(Prestige.UNLOCK_ZONE == TUNE.prestige.unlock_zone, "the ascension gate comes from tuning")
check(Save.INTERVAL == TUNE.save.interval, "the autosave beat comes from tuning")
check(Save.OFFLINE_CAP == TUNE.save.offline_cap, "the offline cap comes from tuning")

-- and no module is hiding a copy of them
local files = { "sim/formulas.lua", "sim/economy.lua", "sim/combat.lua", "sim/buffs.lua",
                "sim/prestige.lua", "sim/save.lua" }
local banned = { "1.55", "1.145", "1.07", "0.05", "2000" }
local leaks = 0
for _, rel in ipairs(files) do
  local f = io.open("game/" .. rel, "r")
  if f then
    for line in f:lines() do
      if not line:match("^%s*%-%-") then
        for _, lit in ipairs(banned) do
          if line:find(lit, 1, true) then leaks = leaks + 1 end
        end
      end
    end
    f:close()
  end
end
check(leaks == 0, "no module keeps its own copy of a tuned constant (" .. leaks .. " found)")

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
  check(gptk.y == "c" and B.fire == "c", "printed X (SDL y) is advance and cast")
  check(gptk.x == "v", "printed Y (SDL x) stays unmapped")
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
g.owned[1] = false
love.keypressed(B.fire)
check((g.skillCd[1] or 0) == 0, "X refuses a skill you have not bought")
g.owned[1] = true
love.keypressed(B.fire)
check((g.skillCd[1] or 0) > 0, "X casts on the skills tab once it is owned")
love.keypressed(B.fire)
love.draw()

g.tab = 1
g.zone = 12
g.bestZone = 14
g.zoneSel = 12
love.keypressed(B.prevSkill)
check(g.zoneSel == 11, "L2 steps a zone back")
love.keypressed(B.fire)
check(g.zone == 11 and g.zoneSel == 11, "X walks the run to the zone you are looking at")
check(g.cleared, "a zone behind the frontier arrives open")
love.keypressed(B.nextSkill)
check(g.zoneSel == 12, "R2 steps forward again")
love.keypressed(B.fire)
check(g.zone == 12, "and X follows it")
g.zoneSel = 14

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
