-- Ten milestones, checked against run state.
local M = {}

local ACHIEVEMENTS = {
  { "FIRST BREACH",  "clear zone 1" },
  { "FIREWALL DOWN", "beat 10 boss firewalls" },
  { "TEN ROOTKITS",  "hold 10 rootkits at once" },
  { "NEW TARGET",    "ascend for the first time" },
  { "CORE ACCESS",   "reach zone 100" },
  { "FULL ROSTER",   "deploy all 12 agents" },
  { "SILENT RUN",    "clear 100 vulns" },
  { "ROOT",          "reach zone 250" },
  { "FULL ARMOURY",  "own all ten tools" },
  { "EVERY SCRIPT",  "own all twelve skills" },
}

local st                     -- the run state, filled in below

return ACHIEVEMENTS
