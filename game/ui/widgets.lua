-- Reusable panels and lists. Every screen is built out of these.
local Draw = require("ui.draw")
local Config = require("config")

local px, rrect, frame = Draw.px, Draw.rrect, Draw.frame
local text, textR = Draw.text, Draw.textR
local drawText, drawTextR, drawTextC = Draw.text, Draw.textR, Draw.textC
local C = Config.C

local M = {}

-- The bars and rows use the same grammar as the hero list so the shapes are real.

local function panel(x, y, w, h, label)
  frame(x, y, w, h, 2, C.rule)
  if label then drawText(label, x + 12, y + 10, C.dim, 2) end
end

local function rowSel(x, y, w, h)
  px(x, y, w, h, C.panel)
end

-- visible: how many rows fit. A longer list scrolls, keeping the selection in view;
-- the title line then carries the position, so nothing is hidden without a number.
local function rowsPanel(x, y, w, labels, title, sel, values, visible, height)
  local rowH = 32
  local n = #labels
  local shown = (visible and visible < n) and visible or n
  -- a scrolling list takes a header line even when it has no title, because the
  -- position has to live somewhere that is not on top of a row
  local pad = (title or shown < n) and 40 or 16
  local top = 1
  if shown < n then
    top = math.max(1, math.min((sel or 1) - math.floor(shown / 2), n - shown + 1))
  end
  local h = pad + shown * rowH
  local boxH = math.max(h, height or h)
  frame(x, y, w, boxH, 2, C.rule)
  if title then
    -- keep the title clear of the position counter instead of drawing through it
    local maxChars = math.floor((w - 24 - (shown < n and 64 or 0)) / 12)
    drawText(title:sub(1, math.max(1, maxChars)), x + 12, y + 10, C.dim, 2)
  end
  if shown < n then
    drawTextR((sel or 1) .. "/" .. n, x + w - 12, y + 10, C.dim, 2)
  end
  for j = 0, shown - 1 do
    local i = top + j
    local lb = labels[i]
    local ly = y + pad + j * rowH
    if sel == i then rowSel(x + 4, ly - 6, w - 8, rowH - 2) end
    drawText(lb, x + 12, ly, sel == i and C.text or C.dim, 2)
    if values and values[i] then
      local v = values[i]
      if type(v) == "table" then
        drawTextR(v[1], x + w - 12, ly, v[2], 2)
      else
        drawTextR(v, x + w - 12, ly, sel == i and C.gold or C.text, 2)
      end
    end
    if j < shown - 1 then px(x + 12, ly + 26, w - 24, 2, C.rowsplit) end
  end
  return boxH
end

-- Greedy word wrap: returns the lines that fit maxw, so long text never

M.panel, M.rowSel, M.rowsPanel = panel, rowSel, rowsPanel
return M
