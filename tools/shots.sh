#!/bin/bash
# Capture Clicker Agents at three screen sizes by patching conf.lua in throwaway copies.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$ROOT/design"
SRC=$ROOT/game
OUT=$ROOT/design
i=0
for size in 720x480 640x480 720x720; do
  w=${size%x*}; h=${size#*x}
  i=$((i+1))
  T=/tmp/ds-$size
  rm -rf "$T"; cp -r "$SRC" "$T"
  python3 - "$T/conf.lua" "$w" "$h" <<'PY'
import sys
p, w, h = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(p).read()
import re
s = re.sub(r"t\.window\.width = \d+", "t.window.width = " + w, s)
s = re.sub(r"t\.window\.height = \d+", "t.window.height = " + h, s)
s = s.replace("t.window.resizable = false", "t.window.resizable = true")
open(p, "w").write(s)
PY
  D=$((90+i))
  Xvfb :$D -screen 0 ${w}x${h}x24 >/tmp/xvfb$D.log 2>&1 &
  XPID=$!
  sleep 2
  DISPLAY=:$D love "$T" >/tmp/ds$D.log 2>&1 &
  LPID=$!
  sleep 8
  DISPLAY=:$D import -window root "$OUT/running-$size.png" 2>/dev/null
  kill $LPID 2>/dev/null; kill $XPID 2>/dev/null
  sleep 1
  echo "$size -> $(python3 -c "
from PIL import Image; im=Image.open('$OUT/running-$size.png'); print(im.size)")"
done
