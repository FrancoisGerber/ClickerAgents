-- Everything a button press can do, independent of which screen is showing.
-- Keeps main.lua a router and the screens pure drawing.
local Skills = require("data.skills")
local Upgrades = require("data.upgrades")
local Achievements = require("data.achievements")
local Systems = require("data.systems")
local Economy = require("sim.economy")
local Combat = require("sim.combat")
local Save = require("sim.save")
local Toast = require("ui.toast")
local fmt = require("core/numbers").fmt

local M = {}

function M.row_count(st, tab)
  if tab == 1 then return #st.agents end
  if tab == 2 then return #Skills end
  if tab == 3 then return #Upgrades.list end
  if tab == 4 then return #Systems.daemons + 1 end      -- daemons plus ASCEND
  if tab == 5 then return #Achievements end
  if tab == 6 then return 8 end                          -- stats: read-only rows
  return 0
end

function M.set_tab(st, n)
  st.tab = n
  st.msg, st.msgT = nil, 0
end

function M.move_cursor(st, d)
  local n = M.row_count(st, st.tab)
  st.cursor[st.tab] = ((st.cursor[st.tab] - 1 + d) % n) + 1
end

function M.say(st, msg) Toast.say(st, msg) end

-- X on the SKILLS tab: cast the highlighted skill unless it is cooling
function M.cast_skill(st, i)
  local sk = Skills[i]
  if not sk then return end
  if not st.owned[i] then return M.say(st, "NEED " .. sk.cost .. " CREDITS") end
  local cd = st.skillCd[i] or 0
  if cd > 0 then return M.say(st, sk.name .. " · " .. math.ceil(cd) .. "S") end
  st.skillCd[i] = sk.cd
  st.flashT = 0.4
  M.say(st, sk.name .. " ACTIVE")
end

-- X does one of two things on the arena: walk through a cleared zone, or bring
-- the view back to the live one. It never moves the run on by itself.
function M.advance_or_snap(st)
  if st.cleared then
    if Combat.advance_zone(st) then M.say(st, "ZONE " .. st.zone) end
  else
    M.move_zone(st, st.zone - (st.zoneSel or st.zone))
  end
end

-- L2/R2 walk the zones you have already cleared; X snaps back to the live one
function M.move_zone(st, d)
  local cur = st.zoneSel or st.zone
  local nxt = math.max(1, math.min(st.zone, cur + d))
  if nxt == cur then return end
  st.zoneSel = nxt
  M.say(st, "ZONE " .. nxt .. (nxt == st.zone and "" or " · EARLIER"))
end

function M.buy_selected(st)
  local bought = Economy.buy_amount(st, st.sel, st.amount)
  if bought == 0 then
    local a = st.agents[st.sel]
    if not Economy.unlocked(st, st.sel) then
      M.say(st, "LOCKED · ZONE " .. tostring(a.lock))
    else
      M.say(st, "NEED " .. fmt(Economy.next_cost(st, st.sel)) .. " CREDITS")
    end
  end
end

-- A on a list screen. Each tab decides what "select" means.
function M.activate(st)
  local c = st.cursor[st.tab] or 1
  if st.tab == 2 then
    local sk = Skills[c]
    if st.owned[c] then M.say(st, sk.name .. " OWNED")
    else M.say(st, "NEED " .. sk.cost .. " CREDITS") end

  elseif st.tab == 3 then
    M.say(st, "NEED " .. Upgrades.list[c][2] .. " CREDITS")

  elseif st.tab == 4 then
    if c == #Systems.daemons + 1 then
      M.say(st, st.zone >= 100 and "ASCEND READY" or "LOCKED · ZONE 100")
    else
      local d = Systems.daemons[c]
      M.say(st, d[1] .. " · " .. d[2] .. " ROOTKITS")
    end

  elseif st.tab == 5 then
    M.say(st, Achievements[c][1])

  end
end

-- The menu is an overlay, not a tab: START opens it from anywhere, pauses the
-- clock and writes a save before it appears.
M.MENU_ROWS = 3

function M.open_menu(st)
  st.screen = "menu"
  st.cursor.menu = st.cursor.menu or 1
  st.paused = true
  st.savedOnPause = Save.write(st)
end

function M.close_menu(st)
  st.screen = "game"
  st.paused = false
end

function M.activate_menu(st)
  local c = st.cursor.menu or 1
  if c == 1 then
    M.close_menu(st)
  elseif c == 2 then
    M.say(st, Save.write(st) and "SAVED" or "SAVE FAILED")
  else
    love.event.quit()
  end
end

function M.move_menu(st, d)
  local n = M.MENU_ROWS
  st.cursor.menu = ((st.cursor.menu - 1 + d) % n) + 1
end

-- SELECT cycles the buy amount; it used to be START, which now belongs to the menu
function M.cycle_amount(st)
  if st.amount == 1 then st.amount = 10
  elseif st.amount == 10 then st.amount = 100
  elseif st.amount == 100 then st.amount = 0      -- 0 = MAX
  else st.amount = 1 end
end

function M.probe(st)
  Combat.probe(st)
end

return M
