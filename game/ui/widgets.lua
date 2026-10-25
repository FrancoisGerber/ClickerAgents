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

local function rowsPanel(x, y, w, labels, title, sel, values)
  local rowH = 32
  local pad = title and 40 or 16
  local h = pad + #labels * rowH
  frame(x, y, w, h, 2, C.rule)
  if title then drawText(title, x + 12, y + 10, C.dim, 2) end
  for i, lb in ipairs(labels) do
    local ly = y + pad + (i - 1) * rowH
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
    if i < #labels then px(x + 12, ly + 26, w - 24, 2, C.rowsplit) end
  end
  return h
end

-- Greedy word wrap: returns the lines that fit maxw, so long text never

M.panel, M.rowSel, M.rowsPanel = panel, rowSel, rowsPanel
return M
