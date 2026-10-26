-- Twelve actives, one per agent, in roster order. Every one is bought with credits on
-- the SKILLS tab; nothing is granted on a new save. A cast is a buff for
-- T.buff.duration seconds and starts the skill's own cooldown.
--
-- Effects are data, like the tools: sim/buffs.lua reads them.
-- kinds: dps_mul, credits_mul, click_mul, vulnhp_mul (multipliers),
--        probes (extra probes per second), crit (every probe crits)
local M = {}

local SKILLS = {
  { name = "CRAWL",    agent = "SPIDER", cost = 2e3,   cd = 30,
    eff = "+10 probes/s for 30s",         effects = { { "probes", 10 } } },
  { name = "SPRAY",    agent = "PICK",   cost = 25e3,  cd = 45,
    eff = "x2 throughput for 30s",        effects = { { "dps_mul", 2 } } },
  { name = "PHISH",    agent = "BAIT",   cost = 250e3, cd = 60,
    eff = "every probe crits (x10), 30s", effects = { { "crit", true } } },
  { name = "SPLICE",   agent = "SPLICE", cost = 750e3, cd = 60,
    eff = "x3 probe damage for 30s",      effects = { { "click_mul", 3 } } },
  { name = "FLOOD",    agent = "RELAY",  cost = 2e6,   cd = 90,
    eff = "x1.5 throughput for 30s",      effects = { { "dps_mul", 1.5 } } },
  { name = "GRIND",    agent = "GRIND",  cost = 10e6,  cd = 90,
    eff = "x1.5 credits for 30s",         effects = { { "credits_mul", 1.5 } } },
  { name = "CICADA",   agent = "CICADA", cost = 25e6,  cd = 120,
    eff = "+25 probes/s for 30s",         effects = { { "probes", 25 } } },
  { name = "SIPHON",   agent = "MULE",   cost = 50e6,  cd = 120,
    eff = "x3 credits for 30s",           effects = { { "credits_mul", 3 } } },
  { name = "TAINT",    agent = "TAINT",  cost = 150e6, cd = 150,
    eff = "-20% vuln HP for 30s",         effects = { { "vulnhp_mul", 0.80 } } },
  { name = "HUSH",     agent = "HUSH",   cost = 400e6, cd = 180,
    eff = "x2 probe damage for 30s",      effects = { { "click_mul", 2 } } },
  { name = "BADGE",    agent = "BADGE",  cost = 1e9,   cd = 180,
    eff = "x3 throughput for 30s",        effects = { { "dps_mul", 3 } } },
  { name = "BLACKOUT", agent = "ONYX",   cost = 2e9,   cd = 240,
    eff = "-30% vuln HP for 30s",         effects = { { "vulnhp_mul", 0.70 } } },
}

for _, sk in ipairs(SKILLS) do sk.owned = false end

return SKILLS
