#!/bin/bash
# Build, then push to the handheld over SMB and verify by fetching each file back.
# Device address and password live in .device (chmod 600, not part of the pak).
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1

[ -f .device ] || { echo "no .device file — copy .device.example and fill it in"; exit 1; }
# shellcheck disable=SC1091
. ./.device

"$ROOT/tools/build.sh" || exit 1

if ! timeout 5 ping -c 1 -W 2 "$HOST" >/dev/null 2>&1; then
  echo "DEVICE DOWN — built, nothing pushed"
  exit 1
fi

STAMP=$(date +%s)
VER=/tmp/verify-$STAMP
mkdir -p "$VER"
LOCAL=$ROOT/port/clickeragents
PORTS=$(dirname "$REMOTE")

smb() { timeout 30 smbclient "//$HOST/$SHARE" -U "$USER%$PASS" -c "$1" 2>&1; }

# the pak folder has to exist on the device before anything can be put inside it
smb "mkdir $REMOTE" >/dev/null 2>&1 || true

put() { smb "cd $REMOTE; lcd $LOCAL; put $1" | grep -E "putting|NT_STATUS" || true; }
putat() { smb "cd $1; lcd $2; put $3" | grep -E "putting|NT_STATUS" || true; }
get() { smb "cd $REMOTE; lcd $VER; get $1" >/dev/null 2>&1; }

put clickeragents.love
put clickeragents.gptk
putat "$PORTS" "$ROOT/port" ClickerAgents.sh
# leftovers from the old pak name, if the device still has them
smb "cd $PORTS; del Downspire.sh" >/dev/null 2>&1 || true
smb "cd $PORTS; rmdir downspire" >/dev/null 2>&1 || true

get clickeragents.love
get clickeragents.gptk
get log.txt

echo "--- hashes (local vs device)"
for f in clickeragents.love clickeragents.gptk; do
  L=$(sha256sum "$LOCAL/$f" | cut -c1-16)
  if [ -f "$VER/$f" ]; then R=$(sha256sum "$VER/$f" | cut -c1-16); else R="MISSING"; fi
  [ "$L" = "$R" ] && verdict=MATCH || verdict=MISMATCH
  printf "%-18s local %s device %s  %s\n" "$f" "$L" "$R" "$verdict"
done

echo "--- launcher"
smb "cd $PORTS; ls ClickerAgents.sh" | tail -2

echo "--- device log.txt"
cat "$VER/log.txt" 2>/dev/null || echo "(no log yet)"
