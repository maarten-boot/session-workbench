#!/bin/bash
# Headless GUI test: Settings, the host dialog and VM share setup… move by
# their heading and resize at their corner (SPEC §4.7); closed and opened
# again in the same run they come back where and as large as they were.
# usage: xvfb-run -a -s "-screen 0 1400x900x24" scripts/gui-smoke-dialogs.sh <binary> <outdir>
BIN=$1; OUT=$2; mkdir -p $OUT
. "$(dirname "$0")/smoke-lib.sh"
PROF=swdlg$$
cleanup() { rm -rf "$HOME/.local/state/$PROF"; }
trap cleanup EXIT
CFG=$OUT/config.toml
cat >$CFG <<TOML
[[hosts]]
name = "local"
ssh_target = "localhost"
local_prefix = "$OUT"
remote_prefix = "$OUT"
TOML
# shot: the mouse out of the way first (the heading's "Drag to move" tooltip), inside
# the window: without a window manager the keys go where the mouse is.
shot() { xdotool mousemove 1330 840; sleep 2; import -window root $OUT/$1.png; }
same() { [ "$(compare -metric AE $OUT/$1.png $OUT/$2.png null: 2>&1 | cut -d" " -f1)" = 0 ]; }
differ() { ! same "$@"; }
crop() { convert $OUT/$1.png -crop $2 +repage $OUT/$3.png; }
k() { xdotool key "$@"; sleep 0.6; }
click() { xdotool mousemove $1 $2 click ${3:-1}; sleep ${4:-1}; }
# drag x1 y1 x2 y2: press, move in steps, release.
drag() {
	xdotool mousemove $1 $2 mousedown 1; sleep 0.2
	for i in 1 2 3 4 5; do
		xdotool mousemove $(($1 + ($3 - $1) * i / 5)) $(($2 + ($4 - $2) * i / 5)); sleep 0.1
	done
	xdotool mouseup 1 mousemove 1330 840; sleep 0.8   # off the heading before its tooltip shows
}

$BIN -config $CFG -profile $PROF >>$OUT/app.log 2>&1 &
APP=$!
wait_window
sleep 3; xdotool windowactivate --sync $W 2>/dev/null

# Settings: heading at y 119, corner at (1139,611) (60,50 window origin).
click 261 833 1 1.5                        # Settings…
shot s1-open
drag 500 119 400 99                        # 100 left, 20 up
shot s2-moved
crop s1-open 200x40+270+100 s1-head; crop s2-moved 200x40+170+80 s2-head
check "Settings: the heading moved with the mouse" same s1-head s2-head
drag 1035 587 1135 787                     # the corner: 100 wider, 200 taller
shot s3-resized
check "Settings: the corner made it larger" differ s2-moved s3-resized
CORNER=60x60+1100+757                      # around the corner after the drag (1135,787)
crop s3-resized $CORNER s3-corner; crop s2-moved $CORNER s2-corner
check "Settings: the corner is where it was dragged to" differ s2-corner s3-corner
k Escape
click 261 833 1 1.5                        # Settings… again
shot s4-again
# The heading and the corner (not the fields: the first one has the focus ring now).
crop s4-again 200x40+170+80 s4-head; crop s4-again $CORNER s4-corner
check "Settings: opened again where and as large as it was" bash -c "$(declare -f same); OUT=$OUT; same s2-head s4-head && same s3-corner s4-corner"
k Escape

# VM share setup… over the host dialog: heading at y 76.
click 100 103 3; k e Return; sleep 1       # LOCAL → Edit host…
shot h1-open
click 634 811 1 1.5                        # VM share setup…
shot v1-open
drag 600 76 600 176                        # 100 down
shot v2-moved
crop v1-open 300x40+370+60 v1-head; crop v2-moved 300x40+370+160 v2-head
check "VM share: the heading moved with the mouse" same v1-head v2-head
k Escape
click 634 811 1 1.5                        # VM share setup… again
shot v3-again
crop v3-again 300x40+370+160 v3-head
check "VM share: opened again where it was" same v2-head v3-head
k Escape

# The host dialog: 100 left, then the corner 100 narrower.
drag 600 76 500 76
shot h2-moved
crop h1-open 200x26+450+63 h1-head; crop h2-moved 200x26+350+63 h2-head
check "host dialog: the heading moved with the mouse" same h1-head h2-head
drag 855 846 755 846                       # the corner (bottom right, at the window's edge)
shot h3-resized
EDGE=120x100+700+380                       # the right edge before (855) and after (755)
crop h2-moved $EDGE h2-edge; crop h3-resized $EDGE h3-edge
check "host dialog: the corner made it narrower" differ h2-edge h3-edge
k Escape
click 100 103 3; k e Return; sleep 1       # Edit host… again
shot h4-again
crop h4-again 200x26+350+63 h4-head; crop h4-again $EDGE h4-edge
check "host dialog: opened again where and as large as it was" bash -c "$(declare -f same); OUT=$OUT; same h2-head h4-head && same h3-edge h4-edge"
k Escape
alive
kill $APP; wait $APP 2>/dev/null
finish
