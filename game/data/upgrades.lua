-- The ten global tools: one-shot purchases that lift everything.
local M = {}

local UPGRADES = {
  { "SCANNER",     "1K",   "+25% probe damage" },
  { "WORDLIST",    "5K",   "+10% all throughput" },
  { "SKIMMER",     "20K",  "+25% credits from vulns" },
  { "EXPLOIT KIT", "100K", "x2 probe damage" },
  { "BOTNET",      "500K", "+15% all throughput" },
  { "LAUNDERER",   "2M",   "+50% credits from vulns" },
  { "0-DAY",       "10M",  "x3 probe damage" },
  { "BACKDOOR",    "50M",  "+20% all throughput" },
  { "MIXER",       "250M", "+100% credits from vulns" },
  { "PERSISTENCE", "2B",   "+25% throughput, +1 rootkit per ascension" },
}

M.list, M.labels = UPGRADES, upgradeLabels
return M
