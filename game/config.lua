-- Palette, art colours and the few global preferences. Everything visual reads
-- from here, so retheming the game is a single file.
local M = {}

local function hex(s)
  return {
    tonumber(s:sub(2, 3), 16) / 255,
    tonumber(s:sub(4, 5), 16) / 255,
    tonumber(s:sub(6, 7), 16) / 255,
  }
end

local C = {
  ground  = hex("#0B0D12"), panel   = hex("#161A24"), rule     = hex("#2A3040"),
  text    = hex("#E6E9F0"), dim     = hex("#8A93A6"), gold     = hex("#E8B45A"),
  hp      = hex("#B4402E"), hpEmpty = hex("#3A1A16"), gain     = hex("#5FBF6A"),
  poor    = hex("#8A3B34"), warn    = hex("#E8453C"), aura     = hex("#6B2230"),
  rowsplit = hex("#1A1E27"), iconOff = hex("#1B2028"), iconFg = hex("#20252F"),
  flashLt = hex("#B0765F"), bossDk  = hex("#2C1915"),
}

local ART = {
  sky       = hex("#171210"), floor     = hex("#0E0C0F"), horizon   = hex("#241A17"),
  pillar    = hex("#211A18"), pillarLt  = hex("#2A211F"), monster   = hex("#59332A"),
  monsterDk = hex("#3E241D"), monsterLt = hex("#6E4236"), shadow    = hex("#100C0A"),
}

M.C = C
M.ART = ART
M.prefs = { list = "auto" }     -- "auto" | "narrow" | "wide"
M.VERSION = "1"
M.TITLE = "CLICKER AGENTS"
return M


