-- The twelve agents you deploy. Cheapest first; each one is a specialist.
--
-- Throughput at level 1 equals the price: one DPS per credit. That ratio is what
-- lets the ladder keep up with vuln HP, which grows 55% per zone early and 14.5%
-- per zone past 140. Costs then grow 1.07^level, so stacking one agent falls
-- behind and you are meant to deploy the next one.
local M = {}

local AGENTS = {
  { name = "Spider", lv = 0, cost = 12,        base = 12 },
  { name = "Pick",   lv = 0, cost = 214,       base = 214 },
  { name = "Bait",   lv = 0, cost = 1400,      base = 1400 },
  { name = "Splice", lv = 0, cost = 4200,      base = 4200 },
  { name = "Relay",  lv = 0, cost = 9800,      base = 9800 },
  { name = "Grind",  lv = 0, cost = 41000,     base = 41000 },
  { name = "Cicada", lv = 0, cost = 190000,    base = 190000,    lock = 26 },
  { name = "Mule",   lv = 0, cost = 400000,    base = 400000,    lock = 34 },
  { name = "Taint",  lv = 0, cost = 2000000,   base = 2000000,   lock = 43 },
  { name = "Hush",   lv = 0, cost = 10000000,  base = 10000000,  lock = 53 },
  { name = "Badge",  lv = 0, cost = 50000000,  base = 50000000,  lock = 64 },
  { name = "Onyx",   lv = 0, cost = 250000000, base = 250000000, lock = 76 },
}

M.list = AGENTS
return M
