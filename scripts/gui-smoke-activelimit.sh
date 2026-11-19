#!/bin/bash
# Headless GUI test of the limit on active sessions (SPEC F19): with
# max_active_sessions = 2 and 2 of 3 sessions active there is no mark;
# activating the third asks first (Cancel leaves it inactive, Activate anyway
# activates it), then the top bar starts with ⚠ 3 active (limit 2), also in a
# narrow window; New session
# asks too (Cancel: no New session dialog); the mark opens Settings →
# Terminals, and a limit of 5 saved there removes it.
# usage: xvfb-run -a -s "-screen 0 1400x900x24" scripts/gui-smoke-activelimit.sh <binary> <outdir>
BIN=$1; OUT=$2; mkdir -p $OUT
. "$(dirname "$0")/smoke-lib.sh"
PROF=swlim$$
C=s-lc$$
cleanup() {
	for s in $(tmux ls -F '#S' 2>/dev/null | grep "^cw-$PROF-"); do tmux kill-session -t "=$s"; done
	rm -rf "$HOME/.local/state/$PROF"
}
trap cleanup EXIT
mkdir -p $OUT/p1 $OUT/p2 $OUT/p3
CFG=$OUT/config.toml
cat >$CFG <<TOML
[ui]
max_active_sessions = 2
[[hosts]]
name = "local"
ssh_target = "localhost"
[[sessions]]
id = "s-la$$"
name = "alpha"
host = "local"
local_path = "$OUT/p1"
start_mode = "shell"
[[sessions]]
id = "s-lb$$"
name = "beta"
host = "local"
local_path = "$OUT/p2"
start_mode = "shell"
[[sessions]]
id = "$C"
name = "gamma"
host = "local"
local_path = "$OUT/p3"
start_mode = "shell"
inactive = true
TOML
k() { xdotool key "$@"; sleep 0.6; }
click() { xdotool mousemove $1 $2 click ${3:-1}; sleep ${4:-1}; }
# shot: the mouse inside the window but away from buttons (no tooltip).
shot() { xdotool mousemove 800 600; sleep 0.8; import -window root $OUT/$1.png; }
crop() { convert $OUT/$1.png -crop $2 +repage $OUT/$3.png; }
same() { [ "$(compare -metric AE $OUT/$1.png $OUT/$2.png null: 2>&1 | cut -d" " -f1)" = 0 ]; }
differ() { ! same "$@"; }
# gamma's inactive flag in config.toml: the lines of its [[sessions]] block.
# (The app writes the file again indented.)
inactive() { awk -v id="$C" '/^ *\[\[/{s=0} $0 ~ "^ *id = \""id"\""{s=1} s && /^ *inactive = true/{f=1} END{exit !f}' $CFG; }
active() { ! inactive; }
TOPBAR=400x30+302+52                        # the start of the top bar

$BIN -config $CFG -profile $PROF >>$OUT/app.log 2>&1 &
APP=$!
wait_window
sleep 3; xdotool windowactivate --sync $W 2>/dev/null; sleep 2
shot 1-start; crop 1-start $TOPBAR 1-top
# Activate gamma: 3 of 2, so it asks; Cancel.
click 150 225 3; click 210 572 1 1.5        # gamma → Activate session
shot 2-asks
check "activating over the limit asks first" differ 1-start 2-asks
k Escape; sleep 1
shot 3-cancelled
check "Cancel: gamma stays inactive" inactive
crop 3-cancelled $TOPBAR 3-top
check "Cancel: no mark in the top bar" same 1-top 3-top
# Again, and go ahead.
click 150 225 3; click 210 572 1 1.5
k Return; sleep 2
shot 4-activated
check "Activate anyway: gamma is active" active
crop 4-activated $TOPBAR 4-top
check "the top bar shows the mark (3 active, limit 2)" differ 3-top 4-top
# A narrow window: the mark stays in view (at the start of the bar).
xdotool windowsize $W 860 600; sleep 1.5
MARK=180x30+302+52                          # the mark itself (the tabs beside it squeeze)
shot 4b-narrow; crop 4b-narrow $MARK 4b-mark; crop 4-activated $MARK 4-mark
check "in a narrow window the mark is still there" same 4-mark 4b-mark
xdotool windowsize $W 1280 800; sleep 1.5
# New session asks too; Cancel shows no New session dialog.
k ctrl+shift+n; sleep 1
shot 5-new-asks
k Escape; sleep 1
shot 6-new-cancelled
MID=1000x620+300+100                        # the middle of the window (not the toast)
crop 4-activated $MID 4-mid; crop 5-new-asks $MID 5-mid; crop 6-new-cancelled $MID 6-mid
check "New session asks first" differ 4-mid 5-mid
check "Cancel: no New session dialog" same 4-mid 6-mid
# The mark opens Settings → Terminals; a limit of 5 removes it.
click 390 66 1 1.5
shot 7-settings
check "the mark opens Settings" differ 6-new-cancelled 7-settings
click 535 289 1 0.3; k ctrl+a; xdotool type --delay 20 '5'      # Warn above this many active sessions
click 990 573 1 2                                               # Save
shot 8-limit-5
check "the limit is saved" grep -q 'max_active_sessions = 5' $CFG
crop 8-limit-5 $TOPBAR 8-top
check "within the new limit: no mark" same 1-top 8-top
alive
stop_app
finish
