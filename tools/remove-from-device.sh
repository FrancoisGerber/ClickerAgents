#!/bin/bash
# Remove Clicker Agents from the handheld completely: launcher, pak, saves, images.
# Nothing is uploaded; this only deletes, then proves the paths are gone.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1

[ -f .device ] || { echo "no .device file"; exit 1; }
# shellcheck disable=SC1091
. ./.device

smb() { timeout 90 smbclient "//$HOST/$SHARE" -U "$USER%$PASS" -c "$1" 2>&1; }

PORTS=$(dirname "$REMOTE")
echo "device $HOST, ports dir $PORTS"

echo "--- before"
smb "cd $PORTS; ls ClickerAgents.sh" | grep -i clicker || echo "  (no launcher)"
smb "cd $REMOTE; ls" | sed -n '1,20p'
smb "cd $PORTS/images; ls" | grep -i -E "clicker|agents" || echo "  (no images)"

echo "--- deleting"
smb "cd $PORTS; del ClickerAgents.sh" | grep -v NT_STATUS_NO_SUCH_FILE || true
smb "cd $PORTS; del Downspire.sh" >/dev/null 2>&1 || true
smb "cd $PORTS; deltree clickeragents" | tail -3
smb "cd $PORTS/images; del ClickerAgents.png" >/dev/null 2>&1 || true
smb "cd $PORTS/images; del ClickerAgents.jpg" >/dev/null 2>&1 || true
smb "cd $PORTS/images; del clickeragents.png" >/dev/null 2>&1 || true
smb "cd $PORTS/images; del clickeragents.jpg" >/dev/null 2>&1 || true

echo "--- after"
smb "cd $PORTS; ls" | grep -i -E "clicker|agents" && echo "  !! something remains" || echo "  launcher: gone"
smb "cd $REMOTE; ls" | grep -i -E "love|gptk|save|images" && echo "  !! pak remains" || echo "  pak dir: gone"
smb "cd $PORTS/images; ls" | grep -i -E "clicker|agents" && echo "  !! image remains" || echo "  images: gone"
