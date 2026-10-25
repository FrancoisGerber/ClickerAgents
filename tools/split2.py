#!/usr/bin/env python3
"""Second half of the one-off split: data, sprites, screens, input."""
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


# ---------------------------------------------------------------- sprites
write("ui/sprites.lua", '''-- The target, drawn as a machine: a service node that cracks as its HP drains,
-- and the logo badge the title screen shows.
local Draw = require("ui.draw")
local Config = require("config")

local px, rrect, frame = Draw.px, Draw.rrect, Draw.frame
local C, ART = Config.C, Config.ART

local M = {}

''' + cut(120, 263).replace("---------------------------------------------------------------- the target\n", "")
  .replace("---------------------------------------------------------------- the logo mark\n", "")
  .replace("-- a vuln is a vulnerable service", "-- a vuln is a vulnerable service") + '''

M.drawVuln, M.drawBossVuln, M.drawMark = drawVuln, drawBossVuln, drawMark
return M
''')

# ---------------------------------------------------------------- data
write("data/agents.lua", '''-- The twelve agents you deploy. Cheapest first; each one is a specialist.
local M = {}

''' + cut(390, 415) + '''

M.list = AGENTS
return M
''')

write("data/skills.lua", '''-- Six actives, one per agent. Bought and cast on the SKILLS tab.
local M = {}

''' + cut(318, 331) + '''

return SKILLS
''')

write("data/achievements.lua", '''-- Eight milestones, checked against run state.
local M = {}

''' + cut(335, 346) + '''

return ACHIEVEMENTS
''')

write("data/upgrades.lua", '''-- The ten global tools: one-shot purchases that lift everything.
local M = {}

''' + cut(897, 908) + '''

M.list, M.labels = UPGRADES, upgradeLabels
return M
''')

write("data/systems.lua", '''-- Targets, layers, the vulns found in each layer, and the daemons rootkits buy.
local M = {}

''' + cut(350, 386) + '''

-- Daemons are the permanent boons bought with rootkits: code of yours that keeps
-- running whether you are watching or not.
local DAEMONS = {
  { "CRON",     "5",  "+1 probe per second" },
  { "WATCHDOG", "12", "+15% credits from vulns" },
  { "BEACON",   "30", "+10% throughput" },
  { "HONEYPOT", "75", "boss firewalls give 10s longer" },
}

M.list, M.daemons, M.vulns = SYSTEMS, DAEMONS, VULNS
M.name = systemName
M.layer = layerName
M.vuln = vulnName
return M
''')

# ---------------------------------------------------------------- toast
write("ui/toast.lua", '''-- Transient one-line messages ("NEED 20K CREDITS"). Screen-local: it draws over
-- whatever is behind it and clears itself.
local Draw = require("ui.draw")
local Config = require("config")

local text, textW = Draw.text, Draw.textW
local px, frame = Draw.px, Draw.frame
local C = Config.C

local M = {}

function M.say(st, msg, seconds)
  st.msg, st.msgT = msg, seconds or 1.6
end

function M.draw(ctx)
  local st, L = ctx.state, ctx.layout
  if not st.msg or (st.msgT or 0) <= 0 then return end
  local w = textW(st.msg, 2) + 24
  local x = math.floor((L.W - w) / 2)
  local y = L.H - L.hintH - 40
  px(x, y, w, 24, C.panel)
  frame(x, y, w, 24, 2, C.gold)
  text(st.msg, x + 12, y + 6, C.text, 2)
end

return M
''')
