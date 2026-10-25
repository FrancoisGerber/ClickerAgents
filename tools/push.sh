#!/bin/bash
# Build, then push to the handheld over SMB and verify by fetching each file back.
# Device address and password live in .device (chmod 600, not part of the pak).
#
# Every file goes up as <name>.new and is renamed into place only once the remote
# size matches. A flaky link already truncated clickeragents.love to 0 bytes once;
# this makes that impossible — the live copy is never touched by a bad upload.
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
FAILED=0

smb() { timeout 60 smbclient "//$HOST/$SHARE" -U "$USER%$PASS" -c "$1" 2>&1; }

remote_size() {
  smb "cd $1; ls $2" | awk -v f="$2" '$1==f {print $3}' | head -1
}

# upload beside the target, check the size, then swap it in
swap_in() {
  local dir=$1 file=$2 src=$3
  local want got
  want=$(stat -c %s "$src/$file")
  smb "cd $dir; lcd $src; put $file $file.new" | grep -E "putting|NT_STATUS" || true
  got=$(remote_size "$dir" "$file.new")
  if [ "${got:-0}" != "$want" ]; then
    echo "  !! $file: ${got:-0} of $want bytes arrived — keeping the old copy"
    smb "cd $dir; del $file.new" >/dev/null 2>&1 || true
    FAILED=1
    return 1
  fi
  smb "cd $dir; del $file" >/dev/null 2>&1 || true
  smb "cd $dir; rename $file.new $file" | grep -E "NT_STATUS" || true
  return 0
}

smb "mkdir $REMOTE" >/dev/null 2>&1 || true
smb "mkdir $REMOTE/images" >/dev/null 2>&1 || true

swap_in "$REMOTE" clickeragents.love "$LOCAL"
swap_in "$REMOTE" clickeragents.gptk "$LOCAL"
swap_in "$REMOTE/images" cover.png "$LOCAL/images"
swap_in "$REMOTE/images" logo.png "$LOCAL/images"
swap_in "$PORTS" ClickerAgents.sh "$ROOT/port"

# leftovers from the old pak name, if the device still has them
smb "cd $PORTS; del Downspire.sh" >/dev/null 2>&1 || true

get() { smb "cd $REMOTE; lcd $VER; get $1" >/dev/null 2>&1; }
get clickeragents.love
get clickeragents.gptk
get log.txt

echo "--- hashes (local vs device)"
for f in clickeragents.love clickeragents.gptk; do
  L=$(sha256sum "$LOCAL/$f" | cut -c1-16)
  if [ -f "$VER/$f" ]; then R=$(sha256sum "$VER/$f" | cut -c1-16); else R="MISSING"; fi
  if [ "$L" = "$R" ]; then verdict=MATCH; else verdict=MISMATCH; FAILED=1; fi
  printf "%-18s local %s device %s  %s\n" "$f" "$L" "$R" "$verdict"
done

echo "--- images"
smb "cd $REMOTE/images; ls" | grep -E "png" || echo "(none)"

echo "--- device log.txt"
cat "$VER/log.txt" 2>/dev/null || echo "(no log yet)"

[ "$FAILED" = "0" ] || { echo "PUSH INCOMPLETE — see above"; exit 1; }
