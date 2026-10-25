-- Number formatting for a screen that has to show 1.24K and 2.4aa.
local M = {}

local SUF = { "", "K", "M", "B", "T", "aa", "ab", "ac", "ad" }
local function fmt(n)
  if n < 1000 then return tostring(math.floor(n)) end
  local i, v = 0, n
  while v >= 1000 and i < #SUF - 1 do v = v / 1000; i = i + 1 end
  if v < 10 then return string.format("%.2f%s", v, SUF[i + 1])
  elseif v < 100 then return string.format("%.1f%s", v, SUF[i + 1])
  else return tostring(math.floor(v + 0.5)) .. SUF[i + 1] end
end

M.fmt = fmt
return M
