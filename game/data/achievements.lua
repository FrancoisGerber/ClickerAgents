-- Eight milestones, checked against run state.
local M = {}

local ACHIEVEMENTS = {
  { "FIRST BREACH",  "clear layer 1" },
  { "FIREWALL DOWN", "beat 10 boss firewalls" },
  { "TEN ROOTKITS",  "hold 10 rootkits at once" },
  { "NEW TARGET",    "ascend for the first time" },
  { "CORE ACCESS",   "reach layer 100" },
  { "FULL ROSTER",   "deploy all 12 agents" },
  { "SILENT RUN",    "clear 100 vulns" },
  { "ROOT",          "reach layer 250" },
}

local st                     -- the run state, filled in below

return ACHIEVEMENTS
