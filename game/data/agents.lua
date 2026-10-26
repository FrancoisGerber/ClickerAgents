-- The twelve agents you deploy. Cheapest first; each one is a specialist.
--
-- Throughput at level 1 equals the price: one DPS per credit. That ratio is what
-- lets the ladder keep up with vuln HP, which grows 55% per zone early and 14.5%
-- per zone past 140. Costs then grow 1.07^level, so stacking one agent falls
-- behind and you are meant to deploy the next one.
local M = {}

local AGENTS = {
  { name = "Spider", lv = 0, cost = 6,        base = 6 },
  { name = "Pick",   lv = 0, cost = 107,       base = 107 },
  { name = "Bait",   lv = 0, cost = 700,      base = 700 },
  { name = "Splice", lv = 0, cost = 2100,      base = 2100 },
  { name = "Relay",  lv = 0, cost = 4900,      base = 4900 },
  { name = "Grind",  lv = 0, cost = 20500,     base = 20500 },
  { name = "Cicada", lv = 0, cost = 95000,    base = 95000,    lock = 26 },
  { name = "Mule",   lv = 0, cost = 200000,    base = 200000,    lock = 34 },
  { name = "Taint",  lv = 0, cost = 1000000,   base = 1000000,   lock = 43 },
  { name = "Hush",   lv = 0, cost = 5000000,  base = 5000000,  lock = 53 },
  { name = "Badge",  lv = 0, cost = 25000000,  base = 25000000,  lock = 64 },
  { name = "Onyx",   lv = 0, cost = 125000000, base = 125000000, lock = 76 },
}

M.list = AGENTS
return M
