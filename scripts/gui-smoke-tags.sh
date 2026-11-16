#!/bin/bash
# Headless GUI test of tags (SPEC F5a): Edit… saves a session's tags
# (tidied); Filter by tag lists the tags (own ones and the host) and
# narrows Active and Inactive to the sessions with all the selected tags,
# or any with the switch; none shows all again; the filter is remembered.
# The window title names the session a row opens.
# usage: xvfb-run -a -s "-screen 0 1400x900x24" scripts/gui-smoke-tags.sh <binary> <outdir>
BIN=$1; OUT=$2; mkdir -p $OUT
. "$(dirname "$0")/smoke-lib.sh"
P=s-tg$$
mkdir -p $OUT/alpha $OUT/beta $OUT/gamma $OUT/delta
CFG=$OUT/config.toml
cat >$CFG <<TOML
[[hosts]]
name = "local"
ssh_target = "localhost"
[[sessions]]
id = "${P}1"
name = "alpha"
host = "local"
local_path = "$OUT/alpha"
start_mode = "shell"
tags = ["client-x", "urgent"]
[[sessions]]
id = "${P}2"
name = "beta"
host = "local"
local_path = "$OUT/beta"
start_mode = "shell"
tags = ["client-x", "go"]
[[sessions]]
id = "${P}3"
name = "gamma"
host = "local"
local_path = "$OUT/gamma"
start_mode = "shell"
[[sessions]]
id = "${P}4"
name = "delta"
host = "local"
local_path = "$OUT/delta"
start_mode = "shell"
tags = ["client-x"]
inactive = true
TOML
k() { xdotool key "$@"; sleep 0.6; }
shot() { import -window root $OUT/$1.png; }
click() { xdotool mousemove $1 $2 click 1; sleep ${3:-1}; xdotool mousemove 700 500; sleep 0.3; }
# title: the session the window shows.
title() { xdotool getwindowname $W | sed 's/^([0-9]*) //; s/ — .*//'; }
cleanup() { for i in 1 2 3 4; do tmux kill-session -t "=cw-$P$i" 2>/dev/null; done; }
trap cleanup EXIT
$BIN -config $CFG >>$OUT/app.log 2>&1 &
APP=$!
wait_window
sleep 3; xdotool windowactivate --sync $W 2>/dev/null; sleep 2
shot 1-start
# Edit… on gamma: its tags, tidied when saved.
xdotool mousemove 150 225 click 3; sleep 0.7
click 185 284                                         # Edit…
click 825 582                                         # Tags
xdotool type --delay 15 "go, Go , urgent"; k Return; sleep 1.5
expect "Edit… saves the tags, tidied" "go urgent" \
	"$(python3 -c 'import sys,tomllib; c=tomllib.load(open(sys.argv[1],"rb")); print(*[s.get("tags") for s in c["sessions"] if s["name"]=="gamma"][0])' $CFG)"
click 130 311 1.5                                     # open Filter by tag
shot 2-filter
click 105 365                                         # urgent
click 107 340                                         # client-x: all of client-x and urgent
shot 3-both
click 100 429                                         # open Active: only alpha
shot 4-active
click 110 467 2; expect "client-x and urgent: alpha" alpha "$(title)"
click 111 394                                         # all of them → any of them
shot 5-any
click 110 537 2; expect "client-x or urgent: the third is gamma" gamma "$(title)"
alive
kill $APP; wait $APP 2>/dev/null
$BIN -config $CFG >>$OUT/app.log 2>&1 &               # the filter is remembered
APP=$!
wait_window
sleep 3; xdotool windowactivate --sync $W 2>/dev/null; sleep 2
shot 6-restart
click 110 502 2; expect "after a restart, still any: the second is beta" beta "$(title)"
click 105 365                                         # urgent off: client-x only
shot 7-client-x
click 110 467 2; expect "client-x: alpha first" alpha "$(title)"
click 110 537 2; expect "client-x: no third row (gamma left out)" alpha "$(title)"
click 175 394                                         # none: every session again
shot 8-none
click 110 537 2; expect "none: gamma is back" gamma "$(title)"
alive
kill $APP; wait $APP 2>/dev/null
finish
