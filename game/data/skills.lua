-- Six actives, one per agent. Bought and cast on the SKILLS tab.
local M = {}

local SKILLS = {
  { name = "CRAWL",    agent = "SPIDER",   cost = 2e3,   cd = 30,
    eff = "+10 probes/s for 30s",   owned = true },
  { name = "SPRAY",    agent = "PICK",  cost = 25e3,  cd = 45,
    eff = "x2 throughput for 30s",  owned = true },
  { name = "PHISH",    agent = "BAIT",     cost = 250e3, cd = 60,
    eff = "every hit crits, 30s",   owned = false },
  { name = "SIPHON",   agent = "MULE",     cost = 2e6,   cd = 90,
    eff = "x3 credits for 30s",     owned = false },
  { name = "FLOOD",    agent = "RELAY",    cost = 25e6,  cd = 120,
    eff = "+100% probe dmg, 30s",   owned = false },
  { name = "BLACKOUT", agent = "ONYX", cost = 500e6, cd = 180,
    eff = "-15% vuln HP, 30s",      owned = false },
}

return SKILLS
