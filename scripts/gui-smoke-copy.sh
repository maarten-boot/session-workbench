#!/bin/bash
# Headless GUI test of copying in a terminal (SPEC T1a): a program that
# follows every mouse move (as claude does, mode 1003): a Shift+drag
# selection stays after the mouse moves on and Ctrl+Shift+C copies it;
# OSC 52 from a program puts text on the clipboard, a read request does
# nothing. The clipboard is checked by pasting it (Ctrl+Shift+V) into cat.
# usage: xvfb-run -a -s "-screen 0 1400x900x24" scripts/gui-smoke-copy.sh <binary> <outdir>
BIN=$1; OUT=$2; mkdir -p $OUT; rm -f $OUT/pasted-*
. "$(dirname "$0")/smoke-lib.sh"
CFG=$OUT/config.toml
cat >$CFG <<TOML
[ui]
theme = "light"
[[hosts]]
name = "local"
ssh_target = "localhost"
[[sessions]]
id = "s-cp$$"
name = "copier"
host = "local"
local_path = "$OUT"
start_mode = "shell"
TOML
# mouse.py: asks for every mouse move, shows a line, swallows the reports
# for 12 s, then stops.
cat >$OUT/mouse.py <<'PY'
import os, sys, termios, time, tty, select
fd = sys.stdin.fileno(); old = termios.tcgetattr(fd); tty.setraw(fd)
sys.stdout.write("\x1b[?1003h\x1b[?1006h\r\nalpha beta gamma\r\n"); sys.stdout.flush()
end = time.time() + 12
while time.time() < end:
    if select.select([fd], [], [], 0.2)[0]: os.read(fd, 4096)
sys.stdout.write("\x1b[?1003l\x1b[?1006l"); sys.stdout.flush()
termios.tcsetattr(fd, termios.TCSAFLUSH, old)
PY
k() { xdotool key "$@"; sleep 0.5; }
type() { xdotool type --delay 15 -- "$1"; }
shot() { import -window root $OUT/$1.png; }
# paste <name>: the clipboard into cat, then the file.
paste() { type "cat > $OUT/pasted-$1"; k Return; k ctrl+shift+v; k Return; k ctrl+d; sleep 0.5; }
$BIN -config $CFG >>$OUT/app.log 2>&1 &
APP=$!
wait_window
sleep 3; xdotool windowactivate --sync $W 2>/dev/null
k ctrl+alt+1; k ctrl+shift+1; sleep 2                  # Local: a shell
type "clear; python3 $OUT/mouse.py"; k Return; sleep 1.5
shot 1-mouse-program
# Shift+drag over the line, let go, move on (each move a report), copy.
xdotool mousemove 309 111; xdotool keydown shift; sleep 0.2
xdotool mousedown 1; for x in 340 380 420 440; do xdotool mousemove $x 112; sleep 0.1; done
xdotool mouseup 1; sleep 0.2
xdotool keyup shift; sleep 0.2
for x in 600 650 700 750; do xdotool mousemove $x 400; sleep 0.1; done
shot 2-selected
k ctrl+shift+c
sleep 11                                               # mouse.py ends
paste selection
check "a Shift+drag selection survives mouse moves and is copied" grep -q 'alpha beta gamma' $OUT/pasted-selection
# OSC 52: a program copies (as claude's copy and tmux do).
type "clear; printf '\\033]52;c;%s\\a' \$(printf 'from osc 52' | base64)"; k Return; sleep 1
shot 3-osc52
paste osc
check "OSC 52 puts the text on the clipboard" grep -qx 'from osc 52' $OUT/pasted-osc
# A read request changes nothing (and sends nothing back).
type "clear; printf '\\033]52;c;?\\a'"; k Return; sleep 1
paste read
check "an OSC 52 read leaves the clipboard as it was" grep -qx 'from osc 52' $OUT/pasted-read
alive
kill $APP; wait $APP 2>/dev/null
finish
