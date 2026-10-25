-- Debug logging. Silenced while the headless suite runs so test output stays
-- readable; on the device it lands in log.txt via the launcher's tee.
local M = {}
local enabled = not _G.DS_TEST

function M.dbg(s)
  if enabled then print(s) end
end

function M.set_enabled(v) enabled = v end
return M
