#!/bin/bash
# Headless GUI test of the repository check: planted hook and config are
# flagged (sidebar + Files banner + details, a window that moves by its
# heading and resizes at its corner), "Mark as reviewed" silences them, and a
# later change brings the warning back. Nothing planted runs.
# usage: xvfb-run -a -s "-screen 0 1400x900x24" scripts/gui-smoke-repocheck.sh <binary> <outdir>
BIN=$1; OUT=$2; mkdir -p $OUT
. "$(dirname "$0")/smoke-lib.sh"
B=$OUT/bad; C=$OUT/clean; rm -rf $B $C $OUT/HOOK-RAN; mkdir -p $B $C
for r in $B $C; do git -C $r init -q -b main; echo x >$r/a.txt; git -C $r add -A; git -C $r -c user.name=t -c user.email=t@example.com commit -q -m base; done
printf '#!/bin/sh\ntouch %s\n' "$OUT/HOOK-RAN" >$B/.git/hooks/pre-push; chmod +x $B/.git/hooks/pre-push
git -C $B config credential.helper '!f() { cat >/dev/null; }; f'
git -C $B config remote.origin.pushurl 'https://me:secret-token@evil.example/repo.git'
CFG=$OUT/config.toml
cat >$CFG <<TOML
[[hosts]]
name = "local"
ssh_target = "localhost"
[[sessions]]
id = "s-rcb"
name = "planted"
host = "local"
local_path = "$B"
start_mode = "shell"
[[sessions]]
id = "s-rcc"
name = "clean"
host = "local"
local_path = "$C"
start_mode = "shell"
TOML
k() { xdotool key "$@"; sleep 0.5; }
shot() { import -window root $OUT/$1.png; }
# drag x1 y1 x2 y2: with the left button held, in small steps.
drag() {
	xdotool mousemove $1 $2 mousedown 1; sleep 0.2
	for i in 1 2 3 4 5; do
		xdotool mousemove $(($1 + ($3 - $1) * i / 5)) $(($2 + ($4 - $2) * i / 5)); sleep 0.1
	done
	xdotool mouseup 1 mousemove 1330 840; sleep 0.8
}
crop() { convert $OUT/$1.png -crop $2 +repage $OUT/$3.png; }
same() { [ "$(compare -metric AE $OUT/$1.png $OUT/$2.png null: 2>&1 | cut -d" " -f1)" = 0 ]; }
$BIN -config $CFG >>$OUT/app.log 2>&1 &
APP=$!
wait_window
sleep 4; xdotool windowactivate --sync $W 2>/dev/null
k ctrl+alt+1; k ctrl+shift+2; sleep 1.5
shot 1-warned                                   # sidebar ⚠ on "planted" only, banner in Files
k shift+Tab; k Return; sleep 1                  # banner: Details…
shot 2-details
# The details window moves by its heading (y 214) and resizes at its corner
# (1035,709).
drag 500 214 400 164                            # 100 left, 50 up
shot 2a-moved
crop 2-details 220x30+370+200 head-2; crop 2a-moved 220x30+270+150 head-2a
check "details: the heading moved with the mouse" same head-2 head-2a
drag 935 659 1035 809                           # the corner: 100 wider, 150 taller
shot 2b-resized
crop 2a-moved 60x60+1005+779 corner-2a; crop 2b-resized 60x60+1005+779 corner-2b
check "details: the corner is where it was dragged to" bash -c "$(declare -f same); OUT=$OUT; ! same corner-2a corner-2b"
xdotool mousemove 953 602 click 1; sleep 1.5  # Mark as reviewed (where the move put it)
shot 3-reviewed                                 # warning gone
printf '#!/bin/sh\ntouch %s\necho changed\n' "$OUT/HOOK-RAN" >$B/.git/hooks/pre-push   # the agent changes it
k ctrl+alt+2; sleep 1; k ctrl+alt+1; sleep 2
shot 4-changed-again                            # warning back
alive
stop_app
expect "\"Mark as reviewed\" saved for the planted repository only" 1 "$(grep -c trusted_git $CFG)"
check "the planted hook did not run" test ! -e $OUT/HOOK-RAN
for id in s-rcb s-rcc; do ssh -o BatchMode=yes localhost "tmux kill-session -t '=cw-$id'" 2>/dev/null; done
finish
