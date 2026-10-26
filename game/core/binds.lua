-- The gptk is the source of truth for which key each printed button sends. The
-- game reads it at load, so editing the pak remaps the controls with no code
-- change; the headless suite fails if the two ever disagree.
local Log = require("core.log")
local dbg = Log.dbg

local M = {}

local function readBinds()
  -- CWD differs between "love game" from the repo and a launch on the device,
  -- so try the repo layout, the game dir, and the pak layout next to main.lua.
  local src = (love and love.filesystem and love.filesystem.getSource
               and love.filesystem.getSource()) or nil
  local paths = {
    "port/clickeragents/clickeragents.gptk",
    "clickeragents.gptk",
    "../port/clickeragents/clickeragents.gptk",
  }
  if src then
    paths[#paths + 1] = src .. "/clickeragents.gptk"
    paths[#paths + 1] = src .. "/../port/clickeragents/clickeragents.gptk"
  end
  for _, p in ipairs(paths) do
    local f = io.open(p, "r")
    if f then
      local map = {}
      for line in f:lines() do
        local k, v = line:match("^%s*([%w_]+)%s*=%s*(%w+)")
        if k then map[k] = v end
      end
      f:close()
      if map.a and map.b then
        -- gptokeyb names buttons by POSITION. On this unit the printed A reports
        -- as SDL "b" (proved from the device log: pressing A emitted the key
        -- bound to "b"), so the pair is crossed on purpose.
        -- printed X reports as SDL "y" on these units, so fire follows the y line
        local fire = map.y or map.x or "c"
        dbg("[binds] A=" .. map.b .. " B=" .. map.a .. " X=" .. fire .. " from " .. p)
        return {
          buy = map.b, click = map.a,
          fire = fire,
          prevSkill = map.l2 or "f", nextSkill = map.r2 or "g",
          src = p,
        }
      end
    end
  end
  dbg("[binds] no gptk found, falling back to A=x B=z X=c L2=f R2=g")
  return { buy = "x", click = "z", fire = "c",
           prevSkill = "f", nextSkill = "g", src = "fallback" }
end

local BINDS

M.read = readBinds
return M
