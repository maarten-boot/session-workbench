#!/bin/bash
# Headless GUI test of a remembered Disconnect (SPEC R3, F1): session menu →
# Disconnect ends its Local and Remote connections (tmux keeps running) and
# writes disconnected = true; after a restart (connect_on_start = eager) it
# still connects nothing, its dot looks as right after the Disconnect (not
# as when connected) and its line says "disconnected"; Enter in a tab
# connects it and clears the mark.
# usage: xvfb-run -a -s "-screen 0 1400x900x24" scripts/gui-smoke-disconnect.sh <binary> <outdir>
BIN=$1; OUT=$2; mkdir -p $OUT
. "$(dirname "$0")/smoke-lib.sh"
A=s-dis$$
mkdir -p $OUT/p1
CFG=$OUT/config.toml
cat >$CFG <<TOML
[ui]
connect_on_start = "eager"
[[hosts]]
name = "local"
ssh_target = "localhost"
[[sessions]]
id = "$A"
name = "one"
host = "local"
local_path = "$OUT/p1"
start_mode = "shell"
TOML
k() { xdotool key "$@"; sleep 0.6; }
shot() { xdotool mousemove 800 600; sleep 0.5; import -window root $OUT/$1.png; }
menu() { sleep 0.3; for c in "$@"; do xdotool key "$c"; sleep 0.15; done; xdotool key Return; sleep 2; }
has_tmux() { tmux has-session -t "=cw-$1" 2>/dev/null; }
# The app's ssh children (the Remote tab) and shells in p1 (the Local tab).
sshs() { pgrep -P $APP -x ssh | wc -l; }
shells_in() { for p in $(pgrep -P $APP); do readlink /proc/$p/cwd; done 2>/dev/null | grep -cx "$1"; }
disconnected_in_file() { grep -q '^ *disconnected = true' $CFG; }
DOT=12x12+78+125                                   # the session's status dot
dot() { convert $OUT/$1.png -crop $DOT +repage $OUT/dot-$1.png; }
same() { [ "$(compare -metric AE $OUT/dot-$1.png $OUT/dot-$2.png null: 2>&1 | cut -d" " -f1)" = 0 ]; }
cleanup() { tmux kill-session -t "=cw-$A" 2>/dev/null; }
trap cleanup EXIT
start() { $BIN -config $CFG >>$OUT/app.log 2>&1 & APP=$!; wait_window; sleep 3; xdotool windowactivate --sync $W 2>/dev/null; sleep 5; }

start
shot 1-connected; dot 1-connected
check "eager: it connects" has_tmux $A
xdotool mousemove 114 131 click 3; menu d          # Disconnect
shot 2-disconnected; dot 2-disconnected
expect "Disconnect: no ssh left" 0 "$(sshs)"
expect "and no Local shell" 0 "$(shells_in $OUT/p1)"
check "tmux keeps running" has_tmux $A
check "config.toml remembers it" disconnected_in_file
check "the dot changed" bash -c "$(declare -f same); OUT=$OUT; ! same 1-connected 2-disconnected"
alive
stop_app
start                                              # restart, eager
shot 3-restarted; dot 3-restarted
expect "after a restart: no ssh" 0 "$(sshs)"
expect "and no Local shell" 0 "$(shells_in $OUT/p1)"
check "the dot is as after the Disconnect" same 2-disconnected 3-restarted
convert $OUT/3-restarted.png -crop 200x20+95+137 +repage -scale 400% $OUT/line.png
xdotool mousemove 84 131; sleep 1.5; shot 4-dot-tooltip
xdotool mousemove 114 131 click 1; sleep 2         # open it: the tab shows Disconnected.
shot 5-open
k Return; sleep 3                                  # Enter: the tab connects
shot 6-enter
check "Enter connects" test "$(sshs)$(shells_in $OUT/p1)" != 00
check "and clears the mark" bash -c "! grep -q '^ *disconnected' $CFG"
alive
stop_app
finish
