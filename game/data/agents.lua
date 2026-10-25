-- The twelve agents you deploy. Cheapest first; each one is a specialist.
local M = {}

local AGENTS = {
  { name = "Spider",   lv = 12, cost = 12,        base = 1 },
  { name = "Pick",     lv = 11, cost = 214,       base = 5 },
  { name = "Bait",     lv = 6,  cost = 1400,      base = 16 },
  { name = "Splice",   lv = 0,  cost = 4200,      base = 74 },
  { name = "Relay",    lv = 0,  cost = 9800,      base = 245 },
  { name = "Grind",    lv = 0,  cost = 41000,     base = 1000 },
  { name = "Cicada",   lv = 0,  cost = 190000,    base = 4300,    lock = 26 },
  { name = "Mule",     lv = 0,  cost = 400000,    base = 17000,   lock = 34 },
  { name = "Taint",    lv = 0,  cost = 2000000,   base = 75000,   lock = 43 },
  { name = "Hush",     lv = 0,  cost = 10000000,  base = 320000,  lock = 53 },
  { name = "Badge",    lv = 0,  cost = 50000000,  base = 1400000, lock = 64 },
  { name = "Onyx",     lv = 0,  cost = 250000000, base = 6000000, lock = 76 },
}

st = {
  gold = 1240, dps = 0, souls = 12, zone = 12, zoneSel = 12, kills = 7, timer = 0, click = 0,
  hp = 483, hpMax = 1270, goldKill = 63, sel = 1, amount = 1, gain = 0,
  agents = AGENTS, systems = 0, idle = false, flashT = 0,
  tab = 1, screen = "splash", splashT = 0, welcome = true,
  cursor = { 1, 1, 1, 1, 1, 1, 1 },  -- one selection per tab
  skillSel = 1, skillCd = {}, skillFlash = 0, owned = {}, upOwned = {}, achDone = {},
  msg = nil, msgT = 0,               -- transient toast for "does nothing yet"
}

local opts = {}                     -- preview flags: boss / held / flash

M.list = AGENTS
return M
