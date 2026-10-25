#!/usr/bin/env python3
"""Third part of the split: screens, chrome and input."""
import pathlib

ROOT = pathlib.Path("/home/francois/Documents/Dev/Personal/ClickerAgents/game")
ORIG = pathlib.Path("/tmp/main_orig.lua").read_text().split("\n")


def cut(a, b):
    return "\n".join(ORIG[a - 1:b])


def write(rel, text):
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text if text.endswith("\n") else text + "\n")
    print("  wrote", rel)


HEAD = '''local Draw = require("ui.draw")
local W = require("ui.widgets")
local Config = require("config")
local Numbers = require("core/numbers")

local px, rrect, frame = Draw.px, Draw.rrect, Draw.frame
local text, textR, textC, textW = Draw.text, Draw.textR, Draw.textC, Draw.textW
local fit, wire, wireWrap = Draw.fit, Draw.wire, Draw.wireWrap
local panel, rowSel, rowsPanel = W.panel, W.rowSel, W.rowsPanel
local C = Config.C
local fmt = Numbers.fmt

local M = {}
local st, L, opts

'''

battle_body = cut(577, 744)
battle_body = battle_body.replace("---------------------------------------------------------------- battle column\n", "")
battle_body = battle_body.replace("---------------------------------------------------------------- hero column\n", "")

write("screens/battle.lua", HEAD + '''local Sprites = require("ui.sprites")
local Systems = require("data.systems")
local drawVuln, drawBossVuln = Sprites.drawVuln, Sprites.drawBossVuln
local systemName, layerName, vulnName = Systems.name, Systems.layer, Systems.vuln

''' + battle_body + '''

function M.draw(ctx)
  st, L, opts = ctx.state, ctx.layout, ctx.opts or {}
  battleCol(opts)
  heroCol()
end

return M
''')

write("screens/stats.lua", HEAD + cut(812, 827) + '''

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  statsScreen()
end

return M
''')

write("screens/skills.lua", HEAD + 'local SKILLS = require("data.skills")\n\n' + cut(829, 871) + '''

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  skillsScreen()
end

return M
''')

write("screens/achievements.lua", HEAD + 'local ACHIEVEMENTS = require("data.achievements")\n\n'
      + cut(873, 895) + '''

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  achievementsScreen()
end

return M
''')

write("screens/upgrades.lua", HEAD + '''local Upgrades = require("data.upgrades")
local UPGRADES = Upgrades.list
local upgradeLabels = Upgrades.labels

''' + cut(910, 939) + '''

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  upgradesScreen()
end

return M
''')

prestige_body = cut(941, 965).replace('''  local sysRows, sysState = {}, {}
  for i = 1, 4 do
    sysRows[i] = SYSTEMS[i]
    sysState[i] = { "LOCKED", C.rule }
  end
  rowsPanel(x2, y, wR, sysRows, "SYSTEMS · ROOTKIT SPEND",
            (c <= 4) and c or nil, sysState)''',
'''  local names, costs = {}, {}
  for i, d in ipairs(DAEMONS) do
    names[i], costs[i] = d[1], d[2]
  end
  rowsPanel(x2, y, wR, names, "DAEMONS · ROOTKIT SPEND", (c <= 4) and c or nil, costs)''')

write("screens/prestige.lua", HEAD + '''local Systems = require("data.systems")
local DAEMONS = Systems.daemons

''' + prestige_body + '''

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  prestigeScreen()
end

return M
''')

write("screens/menu.lua", HEAD + cut(967, 988) + '''

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  menuScreen()
end

return M
''')

write("screens/splash.lua", HEAD + '''local Sprites = require("ui.sprites")
local drawMark = Sprites.drawMark

''' + cut(990, 1009) + '''

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  splashScreen()
end

return M
''')

write("screens/welcome.lua", HEAD + cut(1011, 1027) + '''

function M.draw(ctx)
  st, L = ctx.state, ctx.layout
  welcomeScreen()
end

return M
''')

chrome_body = cut(496, 574).replace("---------------------------------------------------------------- chrome\n", "")

write("ui/chrome.lua", '''-- The persistent furniture: the top bar of live numbers and the hint strip with
-- the tab dots.
local Draw = require("ui.draw")
local Config = require("config")
local Numbers = require("core/numbers")

local px, frame, rrect = Draw.px, Draw.frame, Draw.rrect
local text, textR, textW = Draw.text, Draw.textR, Draw.textW
local C = Config.C
local fmt = Numbers.fmt

local M = {}
local st, L, opts

''' + chrome_body + '''

M.TABS, M.NTABS, M.K = TABS, NTABS, K

function M.topBar(ctx)
  st, L, opts = ctx.state, ctx.layout, ctx.opts or {}
  topBar()
end

function M.hintBar(ctx)
  st, L = ctx.state, ctx.layout
  hintBar()
end

return M
''')
