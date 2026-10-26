-- Clicker Agents - a rogue framework eating computer systems.
--
-- This file is only the LÖVE lifecycle and the screen router. The game lives in:
--   data/      content tables (agents, skills, tools, daemons, systems)
--   sim/       the run: state, formulas, economy, combat, save
--   ui/        drawing primitives, widgets, sprites, chrome, toasts
--   screens/   one file per screen
--   app/       what a button press does

local Layout = require("layout")
local Config = require("config")
local Binds = require("core.binds")
local Log = require("core.log")
local Chrome = require("ui.chrome")
local Toast = require("ui.toast")
local Actions = require("app.actions")
local SimState = require("sim.state")
local Economy = require("sim.economy")
local Combat = require("sim.combat")
local Save = require("sim.save")

local Splash = require("screens.splash")
local Welcome = require("screens.welcome")
local Battle = require("screens.battle")
local SkillsScreen = require("screens.skills")
local UpgradesScreen = require("screens.upgrades")
local PrestigeScreen = require("screens.prestige")
local AchievementsScreen = require("screens.achievements")
local StatsScreen = require("screens.stats")
local MenuScreen = require("screens.menu")

local C = Config.C

-- everything the screens read, passed to each draw/action call
local ctx = {
  state = nil, layout = nil, prefs = Config.prefs,
  binds = nil, opts = {}, report = nil,
}

local autosave = 0

local function rebuild()
  local w, h = love.graphics.getDimensions()
  ctx.layout = Layout.compute(w, h, ctx.prefs.list)
end

local function screen_for(tab)
  if tab == 2 then return SkillsScreen end
  if tab == 3 then return UpgradesScreen end
  if tab == 4 then return PrestigeScreen end
  if tab == 5 then return AchievementsScreen end
  if tab == 6 then return StatsScreen end
  return Battle
end

function love.load()
  love.graphics.setBackgroundColor(C.ground)
  love.graphics.setDefaultFilter("nearest", "nearest")

  local st = SimState.new_run()
  ctx.state = st
  ctx.binds = Binds.read()
  rebuild()

  local saved = Save.read()
  if saved then
    Save.apply(st, saved)
    ctx.report = Save.replay_offline(st, saved)
    st.welcome = ctx.report ~= nil
  else
    Combat.new_run_spawn(st)
    st.welcome = false
  end
  Log.dbg("[load] saved=" .. tostring(saved ~= nil) .. " zone=" .. st.zone)
end

function love.resize() rebuild() end

function love.draw()
  local st = ctx.state
  if st.screen == "splash" then Splash.draw(ctx) return end
  if st.screen == "welcome" then Welcome.draw(ctx, ctx.report) return end
  if st.screen == "menu" then MenuScreen.draw(ctx) return end

  Chrome.topBar(ctx)
  screen_for(st.tab).draw(ctx)
  Chrome.hintBar(ctx)
  Toast.draw(ctx)
end

function love.update(dt)
  local st = ctx.state
  st.flashT = math.max(0, (st.flashT or 0) - dt)
  st.msgT = math.max(0, (st.msgT or 0) - dt)
  for i = 1, #st.skillCd do
    if (st.skillCd[i] or 0) > 0 then st.skillCd[i] = math.max(0, st.skillCd[i] - dt) end
  end

  if st.screen == "splash" then
    st.splashT = st.splashT + dt
    if st.splashT > 2.5 then st.screen = st.welcome and "welcome" or "game" end
    return
  end
  if st.screen == "menu" then return end        -- paused: no tick, no autosave
  if st.screen ~= "game" then return end

  Combat.tick(st, dt)
  autosave = autosave + dt
  if autosave > 30 then
    autosave = 0
    Save.write(st)
  end
end

local function toggle_list_width()
  local p = ctx.prefs.list
  ctx.prefs.list = (p == "auto" and "narrow") or (p == "narrow" and "wide") or "auto"
  rebuild()
end

function love.keypressed(key)
  local st = ctx.state
  local B = ctx.binds
  Log.dbg("[key] " .. tostring(key))
  st.lastKey = key

  if st.screen == "splash" then
    if key == "escape" then love.event.quit() end
    st.screen = st.welcome and "welcome" or "game"
    return
  end
  if st.screen == "welcome" then
    if key == "escape" then love.event.quit()
    elseif key == B.buy then st.screen = "game" end    -- A continues, nothing else
    return
  end
  if st.screen == "menu" then
    if key == "up" then Actions.move_menu(st, -1)
    elseif key == "down" then Actions.move_menu(st, 1)
    elseif key == "return" or key == B.click then Actions.close_menu(st)
    elseif key == B.buy then Actions.activate_menu(st)
    elseif key == "escape" then Actions.activate_menu(st)   -- the QUIT row if selected
    end
    return
  end

  if key == "up" then
    if st.tab == 1 then Economy.select(st, st.sel - 1) else Actions.move_cursor(st, -1) end
  elseif key == "down" then
    if st.tab == 1 then Economy.select(st, st.sel + 1) else Actions.move_cursor(st, 1) end
  elseif key == "left" then
    st.amount = math.max(0, (st.amount == 0) and 100 or st.amount - 1)
  elseif key == "right" then
    st.amount = math.min(100, (st.amount == 0) and 100 or st.amount + 1)
  elseif key == "q" then Actions.set_tab(st, ((st.tab - 2) % Chrome.NTABS) + 1)
  elseif key == "e" then Actions.set_tab(st, (st.tab % Chrome.NTABS) + 1)
  elseif key == B.buy then
    if st.tab == 1 then Actions.buy_selected(st) else Actions.activate(st) end
  elseif key == B.prevSkill then
    if st.tab == 1 then Actions.move_zone(st, -1) end
  elseif key == B.nextSkill then
    if st.tab == 1 then Actions.move_zone(st, 1) end
  elseif key == B.fire then
    if st.tab == 1 then Actions.advance_or_snap(st)
    elseif st.tab == 2 then Actions.cast_skill(st, st.cursor[2]) end
  elseif key == B.click then
    if st.tab == 1 then Actions.probe(st) else Actions.set_tab(st, 1) end
  elseif key == "return" then Actions.open_menu(st)      -- START: pause anywhere
  elseif key == "tab" then Actions.cycle_amount(st)      -- SELECT: buy amount
  elseif key == "m" then toggle_list_width()
  elseif key == "escape" then love.event.quit()
  end
end

function love.quit()
  Save.write(ctx.state)
end

-- exposed for tests/headless.lua
return {
  ctx = ctx,
  state = function() return ctx.state end,
  bindsOf = function() return ctx.binds end,
  layoutOf = function() return ctx.layout end,
}
