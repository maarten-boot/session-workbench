#!/bin/bash
# Headless GUI test of the window icon on Linux (SPEC §4.6 App icon): the
# window carries the logo's square as _NET_WM_ICON, transparent at the
# corner, its blue near the bottom middle. GDK sets the icon only under a
# window manager that supports it, so the test runs xfwm4 on the Xvfb
# display (its settings in $OUT, a private bus); without xfwm4 it is skipped.
# Fails with the 1024 px icon embedded before v1.1.28: GTK leaves out an icon
# too large for one X request.
# usage: xvfb-run -a -s "-screen 0 1400x900x24" scripts/gui-smoke-icon.sh <binary> <outdir>
if [ -z "$SW_IN_DBUS" ]; then
	SW_IN_DBUS=1 exec dbus-run-session -- "$0" "$@"
fi
BIN=$1; OUT=$2; mkdir -p $OUT
. "$(dirname "$0")/smoke-lib.sh"
if ! command -v xfwm4 >/dev/null; then
	echo "SKIP: $(basename "$0" .sh): no xfwm4 (a window manager is needed for the window icon)"
	exit 0
fi
PROF=swicon$$
WM=
cleanup() { kill $WM 2>/dev/null; rm -rf "$HOME/.local/state/$PROF"; }
trap cleanup EXIT
CFG=$OUT/config.toml
: >$CFG
mkdir -p $OUT/wm
HOME=$OUT/wm XDG_CONFIG_HOME=$OUT/wm/config XDG_CACHE_HOME=$OUT/wm/cache \
	xfwm4 --compositor=off >$OUT/wm.log 2>&1 &
WM=$!
sleep 2

$BIN -config $CFG -profile $PROF >>$OUT/app.log 2>&1 &
APP=$!
wait_window
sleep 3
# The toplevel with the icon: GTK's client leader window has none.
ICONWIN=
for c in $(xdotool search --pid $APP 2>/dev/null); do
	xprop -id $c _NET_WM_ICON 2>/dev/null | grep -q "^_NET_WM_ICON(CARDINAL)" && { ICONWIN=$c; break; }
done
check "the window has an icon (_NET_WM_ICON)" test -n "$ICONWIN"
# The largest icon in the property: size, a corner, the blue.
xprop -id "${ICONWIN:-$W}" -notype 32c _NET_WM_ICON >$OUT/icon.txt 2>&1
python3 - $OUT/icon.txt >$OUT/icon-check.txt <<'PY'
import sys
t = open(sys.argv[1]).read()
if '=' not in t:
    print('none'); sys.exit()
v = [int(x) for x in t.split('=', 1)[1].replace(',', ' ').split()]
best, i = None, 0
while i + 2 <= len(v):
    w, h = v[i], v[i + 1]
    if best is None or w > best[0]:
        best = (w, h, v[i + 2:i + 2 + w * h])
    i += 2 + w * h
w, h, d = best
px = lambda x, y: d[y * w + x]
a = lambda p: p >> 24 & 255
r, g, b = (lambda p: (p >> 16 & 255, p >> 8 & 255, p & 255))(px(w // 2, h * 88 // 100))
print(w, h, 'corner-clear' if a(px(0, 0)) == 0 else 'corner-filled',
      'blue' if a(px(w // 2, h * 88 // 100)) == 255 and b > r + 64 and b > g else 'not-blue')
PY
expect "the window icon is the logo's square (256 px, transparent corner, blue)" \
	"256 256 corner-clear blue" "$(cat $OUT/icon-check.txt)"
alive
kill $APP; wait $APP 2>/dev/null
finish
