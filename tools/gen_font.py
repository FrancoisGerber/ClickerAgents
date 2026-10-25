#!/usr/bin/env python3
"""Extract the 5x7 glyph table from design/mockup.html and emit game/font.lua.

The mockup is the source of truth for the font, so the running game cannot drift
from the design. Re-run after editing the mockup's glyphs.
"""
import re, pathlib

root = pathlib.Path(__file__).resolve().parents[1]
html = (root / "design" / "mockup.html").read_text(encoding="utf-8")

m = re.search(r"const GL = \{(.*?)\n\};", html, re.S)
if not m:
    raise SystemExit("GL table not found in mockup.html")

body = m.group(1)
# entries look like: 'A':"01110/10001/...",   or   '…':"00000/...",
entries = re.findall(r"'((?:\\'|[^'])+)'\s*:\s*\"([^\"]+)\"", body)
if len(entries) < 60:
    raise SystemExit(f"only parsed {len(entries)} glyphs")

def lua_str(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'

lines = ["-- Generated from design/mockup.html by tools/gen_font.py — do not edit by hand.",
         "-- 5x7 bitmap font: 5 columns, 7 rows, advance 6 cells, drawn at 2x = 12 px per char.",
         "local GL = {"]
for ch, rows in entries:
    parts = rows.split("/")
    if len(parts) != 7 or any(len(p) != 5 for p in parts):
        raise SystemExit(f"bad glyph {ch!r}: {rows!r}")
    ch = ch.replace("\\'", "'")
    lines.append(f"  [{lua_str(ch)}] = {lua_str(rows)},")
lines.append("}")
lines.append("")
lines.append("return GL")
(root / "game" / "font.lua").write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"wrote game/font.lua with {len(entries)} glyphs")
