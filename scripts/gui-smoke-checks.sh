#!/bin/bash
# Headless GUI test of the intervals in Settings (SPEC §4.6 Checks, F4): the
# Checks page shows a hand-edited interval and keeps it; choices on Checks,
# the message time (Appearance) and the notification gap (Terminals) are
# saved; a bad hand-edited value is read as the default.
# usage: xvfb-run -a -s "-screen 0 1400x900x24" scripts/gui-smoke-checks.sh <binary> <outdir>
BIN=$1; OUT=$2; mkdir -p $OUT
. "$(dirname "$0")/smoke-lib.sh"
CFG=$OUT/config.toml
cat >$CFG <<TOML
[ui]
repo_check_every = "90s"        # not in the list: shown and kept
web_runs_active_every = "1s"    # too short: read as 15s
TOML
k() { xdotool key "$@"; sleep 0.4; }
shot() { import -window root $OUT/$1.png; }
uival() { sed -n '/^\[ui\]/,/^\[/p' $CFG | grep -E "^ *$1 =" | sed 's/^ *//; s/ *#.*//'; }
$BIN -config $CFG >>$OUT/app.log 2>&1 &
APP=$!
wait_window
sleep 3; xdotool windowactivate --sync $W 2>/dev/null
k ctrl+shift+comma; sleep 0.8
xdotool mousemove 330 433 click 1; sleep 0.6      # Checks (tabs on the left)
shot 1-checks
k Escape; k ctrl+shift+comma; sleep 0.8           # opens on Checks again, its first field focused
# The page's fields in order: repository, build runs, while one runs, cost.
# A closed select takes the first letter of an option.
k Tab; k h                                        # build runs: hour
k Tab; k 1                                        # while one runs: 10 seconds
k Tab; k 2                                        # cost: 2 minutes
shot 2-checks-chosen
xdotool mousemove 330 161 click 1; sleep 0.5      # Appearance
xdotool mousemove 632 409 click 1; k ctrl+a; xdotool type 7   # seconds a message stays
xdotool mousemove 330 195 click 1; sleep 0.5      # Terminals
xdotool mousemove 632 310 click 1; sleep 0.5; shot 3-notify-open
k Escape
xdotool mousemove 330 433 click 1; sleep 0.5      # Checks: Save (below the tab column)
xdotool mousemove 1090 553 click 1; sleep 1.5
shot 4-saved
alive
stop_app
expect "a hand-edited repository interval is kept" 'repo_check_every = "90s"' "$(uival repo_check_every)"
expect "build runs: hour" 'web_runs_every = "1h"' "$(uival web_runs_every)"
expect "build runs while one runs: 10 seconds (the bad 1s was read as 15s)" 'web_runs_active_every = "10s"' "$(uival web_runs_active_every)"
expect "cost: 2 minutes" 'cost_every = "2m"' "$(uival cost_every)"
expect "message time saved" 'message_seconds = 7' "$(uival message_seconds)"
expect "notification gap: the default" 'notify_every = "1m"' "$(uival notify_every)"
finish
