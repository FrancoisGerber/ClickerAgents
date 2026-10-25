-- Headless check for Clicker Agents: geometry at three screen sizes, plus the
-- buttons changing the numbers. No window, no LÖVE.
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
    setLineStyle = function() end,
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
_G.DS_TEST = true                       -- silence the game's debug prints
local M = dofile("game/main.lua")

local function checkLayout(label)
  local L = M.layoutOf()
  assert(L.heroW + L.battleW == SW, label .. ": columns do not tile the width")
  assert(L.topH + (L.H - L.topH - L.hintH) + L.hintH == SH, label .. ": bands do not tile the height")
  assert(L.heroW % 8 == 0, label .. ": hero column is not on an 8-px multiple")
  assert(L.rows >= 6, label .. ": fewer than six hero rows")
  print(string.format("  %-9s %dx%d  profile=%-7s hero=%-3d battle=%-3d rows=%d dps-col=%s",
    label, L.W, L.H, L.profile, L.heroW, L.battleW, L.rows, tostring(L.showDps)))
end

local function drawAll(label)
  M.state.screen, M.state.splashT = "splash", 0
  love.draw()                                  -- title screen
  M.state.screen = "welcome"
  love.draw()                                  -- offline report
  M.state.screen = "game"
  local rows = { 12, 6, 10, 5, 8, 8, 3 }
  for tab = 1, 7 do
    M.state.tab = tab
    M.state.cursor[tab] = 1
    love.draw()                                -- top of the list
    M.state.cursor[tab] = rows[tab]
    love.draw()                                -- bottom of the list, selection drawn
    M.state.cursor[tab] = 1
    love.draw()
  end
  M.state.tab = 1
  love.draw()
  checkLayout(label)
end

SW, SH = 720, 480
love.load()
drawAll("720x480")

for _, s in ipairs({ { "640x480", 640, 480 }, { "720x720", 720, 720 }, { "720x480", 720, 480 } }) do
  SW, SH = s[2], s[3]
  love.load()
  drawAll(s[1])
end

-- the splash hands over to the offline report, and only then to the game
M.state.screen, M.state.splashT = "splash", 0
love.draw()
love.keypressed(M.bindsOf().buy)
assert(M.state.screen == "welcome", "a button did not leave the splash for the report")
assert(M.state.gold == 1240, "the splash button also bought something")
love.keypressed(M.bindsOf().click)              -- B must NOT close the report
assert(M.state.screen == "welcome", "a non-A button closed the welcome report")
love.keypressed(M.bindsOf().buy)
assert(M.state.screen == "game", "the welcome report did not close on A")

-- L/R cycle the five tabs, B comes back to battle
local visited = {}
for _ = 1, 7 do
  love.keypressed("e")
  table.insert(visited, M.state.tab)
  love.draw()
end
assert(#visited == 7 and visited[7] == 1, "R did not cycle all seven screens back to battle")
love.keypressed("e")                        -- to SKILLS
assert(M.state.tab == 2, "R did not reach SKILLS")
love.keypressed(M.bindsOf().click)                        -- B returns to battle
assert(M.state.tab == 1, "B did not return to battle")
love.keypressed("q")                        -- L wraps to MENU
assert(M.state.tab == 7, "L did not wrap to MENU")
love.draw()
M.state.tab = 1

-- the boss timer is only drawn while a boss is live (no assertion possible on
-- pixels here, but both states must render without leaving the screen)
M.state.timer = 14
love.draw()
M.state.timer = 0
love.draw()
print("  tabs: " .. table.concat(visited, " -> ") .. ", L wraps to MENU")

-- every screen's controls respond, and activation only ever toasts
local goldBefore = M.state.gold

M.state.tab = 3                                  -- UPGRADES
M.state.cursor[3] = 1
love.keypressed("down")
assert(M.state.cursor[3] == 2, "the upgrades cursor did not move")
love.keypressed(M.bindsOf().buy)
assert(M.state.msg and M.state.msgT > 0, "A gave no feedback on the upgrades screen")
love.draw()
print("  upgrades: cursor " .. M.state.cursor[3] .. ", toast: " .. tostring(M.state.msg))

M.state.tab = 4                                  -- PRESTIGE
M.state.cursor[4] = 5
love.keypressed(M.bindsOf().buy)
assert(M.state.msg and M.state.msg:find("LOCKED"), "ascend did not report being locked")
love.draw()
print("  prestige: toast: " .. tostring(M.state.msg))

M.state.cursor[4] = 1
love.keypressed(M.bindsOf().buy)
assert(M.state.msg and M.state.msg:find("ROOTKITS"), "daemon press gave no cost feedback")
love.draw()

M.state.tab = 5                                  -- ACHIEVEMENTS
M.state.cursor[5] = 1
love.keypressed(M.bindsOf().buy)
assert(M.state.msg and M.state.msg:find("FIRST BREACH"), "achievements gave no feedback")
love.keypressed("down")
assert(M.state.cursor[5] == 2, "the achievements cursor did not move")
love.draw()
print("  achievements: cursor " .. M.state.cursor[5] .. ", toast: " .. tostring(M.state.msg))

-- the two screens that felt frozen: the cursor must move on both
M.state.tab = 4                                  -- PRESTIGE
M.state.cursor[4] = 1
love.keypressed("down")
assert(M.state.cursor[4] == 2, "the prestige cursor did not move")
love.draw()
M.state.tab = 7                                  -- MENU
M.state.cursor[7] = 1
love.keypressed("down")
assert(M.state.cursor[7] == 2, "the menu cursor did not move")
love.draw()
M.state.cursor[7] = 1

M.state.tab = 7                                  -- MENU
M.state.cursor[7] = 1
love.keypressed(M.bindsOf().buy)
assert(M.state.tab == 1, "RESUME did not return to battle")
for _ = 1, 6 do love.keypressed("e") end
assert(M.state.tab == 7, "could not get back to MENU")
M.state.cursor[7] = 2
love.keypressed(M.bindsOf().buy)
assert(M.state.msg and M.state.msg:find("SAVE"), "SAVE gave no feedback")
love.draw()

assert(M.state.gold == goldBefore, "activation changed gold on a wireframe screen")
print("  activation: menus toast, no state changed")

-- A selects on every wireframe tab, B goes back. No other arrangement.
for _, tab in ipairs({ 2, 3, 4, 5, 7 }) do
  M.state.tab = tab
  M.state.cursor[tab] = (tab == 7) and 2 or 1   -- menu row 1 is RESUME, which leaves
  local press = M.bindsOf().buy
  love.keypressed(press)
  assert(M.state.tab == tab, "A (the buy key) left tab " .. tab .. " instead of selecting")
  love.keypressed(M.bindsOf().click)
  assert(M.state.tab == 1, "B (the click key) did not go back from tab " .. tab)
end
print("  face buttons: A selects, B goes back, on every tab")

-- zone selection: L2/R2 walk the cleared zones, X snaps back to the front
local sb = M.bindsOf()
M.state.tab = 1
M.state.zone = 12
M.state.zoneSel = 12
love.keypressed(sb.prevSkill)
assert(M.state.zoneSel == 11, "L2 did not step back a zone")
love.keypressed(sb.prevSkill)
assert(M.state.zoneSel == 10, "L2 did not step back again")
love.keypressed(sb.nextSkill)
assert(M.state.zoneSel == 11, "R2 did not step forward a zone")
love.keypressed(sb.nextSkill)
love.keypressed(sb.nextSkill)                     -- clamped at the live zone
assert(M.state.zoneSel == 12, "R2 ran past the live zone")
love.keypressed(sb.prevSkill)
assert(M.state.zoneSel == 11, "L2 did not move after the clamp")
love.keypressed(sb.fire)
assert(M.state.zoneSel == 12, "X did not snap back to the live zone")
love.draw()
print("  zones: L2/R2 select, X back to front, toast " .. tostring(M.state.msg))
-- the strip is gone: the arena now runs to the hint bar
M.state.zoneSel = 12
love.draw()

-- SKILLS: X casts the highlighted skill, and the cooldown blocks a second cast
M.state.tab = 2
M.state.cursor[2] = 1                              -- CLICKSTORM, owned
M.state.skillCd[1] = 0
love.keypressed(sb.fire)
assert((M.state.skillCd[1] or 0) > 0, "X did not start the skill cooldown")
assert(M.state.msg and M.state.msg:find("ACTIVE"), "cast gave no feedback")
local cdAfter = M.state.skillCd[1]
love.keypressed(sb.fire)                           -- still cooling
assert(M.state.skillCd[1] == cdAfter, "a second press restarted the cooldown")
assert(M.state.msg and M.state.msg:find("S$"), "cooldown press gave no countdown: " .. tostring(M.state.msg))
love.draw()
print(string.format("  skills: X cast, cooldown %.0fs blocks, toast %q", cdAfter, M.state.msg))

-- a locked skill cannot be cast
M.state.cursor[2] = 4                              -- LUCKY STRIKE, 250K
M.state.skillCd[4] = 0
love.keypressed(sb.fire)
assert((M.state.skillCd[4] or 0) == 0, "a locked skill was cast")
assert(M.state.msg and M.state.msg:find("NEED"), "locked cast gave no reason")
love.draw()
M.state.cursor[2] = 1
M.state.skillCd[1] = 0
M.state.tab = 1
love.draw()

-- A buys, B clicks (selection starts on Brann, who is affordable)
local gold0 = M.state.gold
local lv0 = M.state.agents[2].lv
love.keypressed(M.bindsOf().buy)
love.draw()
assert(M.state.gold < gold0, "A did not buy: no gold spent")
assert(M.state.agents[2].lv == lv0 + 1, "A did not buy: no level gained")
print(string.format("  A buy: gold %d -> %d, Brann lv %d -> %d, DPS now %d",
  gold0, M.state.gold, lv0, M.state.agents[2].lv, M.state.dps))

love.keypressed("return")
local before = M.state.gold
love.keypressed(M.bindsOf().buy)
love.draw()
assert(M.state.gold <= before, "the x10 buy went backwards")

-- B hits the monster: HP drops by the click damage, the sprite flashes
local hp0, clk = M.state.hp, M.state.click
love.keypressed(M.bindsOf().click)
love.draw()
assert(M.state.hp == hp0 - clk, "B did not damage the monster")
assert(M.state.flashT > 0, "B did not flash the monster")
print(string.format("  B click: hp %d -> %d (-%d)", hp0, M.state.hp, clk))

-- a killing click refills the bar and ticks the counter
M.state.hp = 10
local kills0 = M.state.kills
love.keypressed(M.bindsOf().click)
assert(M.state.hp == M.state.hpMax and M.state.kills == kills0 + 1,
  "a killing click did not refill and tick the kill counter")
print(string.format("  kill: hp back to %d, kills %d -> %d", M.state.hpMax, kills0, M.state.kills))

-- Start cycles 1, 10, 100, MAX
local seen, sawMax = {}, false
for _ = 1, 4 do
  table.insert(seen, M.state.amount)
  if M.state.amount == 0 then sawMax = true end
  love.keypressed("return")
end
assert(sawMax, "the amount cycle never reached MAX")
print("  amount cycle: " .. table.concat(seen, " -> ") .. " -> " .. M.state.amount)

love.keypressed("tab")
love.draw()
assert(M.state.idle == true, "select did not toggle the auto-click flag")

love.keypressed("down")
assert(M.state.gain == M.state.agents[M.state.sel + 1].base,
  "the footer gain did not follow the selection")
print(string.format("  selection: sel=%d gain=+%d", M.state.sel, M.state.gain))

-- the gptk file and the game must agree: SDL "a" (the printed A) buys,
-- SDL "b" (the printed B) clicks. This is the guard against a double swap.
local fh = assert(io.open("port/clickeragents/clickeragents.gptk", "r"))
local gptk = {}
for line in fh:lines() do
  local k, v = line:match("^%s*([%w_]+)%s*=%s*(%w+)")
  if k then gptk[k] = v end
end
fh:close()
assert(gptk.a and gptk.b, "the gptk has no a/b mapping")

local b = M.bindsOf()
-- crossed on purpose: the printed A arrives as SDL "b" on this unit
assert(b.buy == gptk.b, "the game did not bind the printed A to gptk's b")
assert(b.click == gptk.a, "the game did not bind the printed B to gptk's a")
local allBinds = M.bindsOf()
assert(allBinds.buy and allBinds.click and allBinds.fire
       and allBinds.prevSkill and allBinds.nextSkill,
       "a bind is nil: a button would do nothing")
print("  binds: A->" .. b.buy .. " B->" .. b.click .. " (" .. b.src .. ")")

M.state.sel, M.state.amount, M.state.gold = 1, 1, 100000
local goldA = M.state.gold
love.keypressed(b.buy)
assert(M.state.gold < goldA, "printed A (" .. b.buy .. ") did not buy")

M.state.hp = M.state.hpMax
local hpB = M.state.hp
love.keypressed(b.click)
assert(M.state.hp < hpB, "printed B (" .. b.click .. ") did not click the monster")
print(string.format("  hardware: printed A=%s buys, printed B=%s clicks", b.buy, b.click))

love.keypressed("q"); love.keypressed("e"); love.draw()
love.keypressed("2"); love.draw()
love.keypressed("3"); love.draw()
love.keypressed("1"); love.draw()
for _ = 1, 12 do love.keypressed("down") end
love.draw()

print(string.format("rects drawn: %d", calls.rect))
print(string.format("errors: %d", #calls.errors))
for _, e in ipairs(calls.errors) do print("  - " .. e) end
assert(#calls.errors == 0, "geometry errors found")
print("OK: three screen sizes, buttons change numbers, nothing leaves the screen")
