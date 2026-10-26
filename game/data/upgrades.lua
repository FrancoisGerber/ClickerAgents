-- The ten global tools: one-shot purchases that lift everything.
-- Each row is { name, price, effect text, effects }; the effects table is
-- the only thing sim/formulas.upgrade_totals reads, so text and maths stay together.
local M = {}

local UPGRADES = {
  { "SCANNER",     500,   "+25% probe damage", { { "click_add", 0.25 } } },
  { "WORDLIST",    2500,  "+10% all throughput", { { "dps_add", 0.10 } } },
  { "SKIMMER",     10e3,  "+25% credits from vulns", { { "credits_add", 0.25 } } },
  { "EXPLOIT KIT", 50e3,  "x2 probe damage", { { "click_mul", 2 } } },
  { "BOTNET",      250e3, "+15% all throughput", { { "dps_add", 0.15 } } },
  { "LAUNDERER",   1e6,   "+50% credits from vulns", { { "credits_add", 0.50 } } },
  { "0-DAY",       5e6,   "x3 probe damage", { { "click_mul", 3 } } },
  { "BACKDOOR",    25e6,  "+20% all throughput", { { "dps_add", 0.20 } } },
  { "MIXER",       125e6, "+100% credits from vulns", { { "credits_add", 1.00 } } },
  { "PERSISTENCE", 1e9,   "+25% throughput, +1 rootkit per ascension",
    { { "dps_add", 0.25 }, { "rootkit_bonus", 1 } } },
}

M.list, M.labels = UPGRADES, upgradeLabels
return M
