-- The ten global tools: one-shot purchases that lift everything.
-- Each row is { name, price label, effect text, effects }; the effects table is
-- the only thing sim/formulas.upgrade_totals reads, so text and maths stay together.
local M = {}

local UPGRADES = {
  { "SCANNER",     "1K",   "+25% probe damage", { { "click_add", 0.25 } } },
  { "WORDLIST",    "5K",   "+10% all throughput", { { "dps_add", 0.10 } } },
  { "SKIMMER",     "20K",  "+25% credits from vulns", { { "credits_add", 0.25 } } },
  { "EXPLOIT KIT", "100K", "x2 probe damage", { { "click_mul", 2 } } },
  { "BOTNET",      "500K", "+15% all throughput", { { "dps_add", 0.15 } } },
  { "LAUNDERER",   "2M",   "+50% credits from vulns", { { "credits_add", 0.50 } } },
  { "0-DAY",       "10M",  "x3 probe damage", { { "click_mul", 3 } } },
  { "BACKDOOR",    "50M",  "+20% all throughput", { { "dps_add", 0.20 } } },
  { "MIXER",       "250M", "+100% credits from vulns", { { "credits_add", 1.00 } } },
  { "PERSISTENCE", "2B",   "+25% throughput, +1 rootkit per ascension",
    { { "dps_add", 0.25 }, { "rootkit_bonus", 1 } } },
}

M.list, M.labels = UPGRADES, upgradeLabels
return M
