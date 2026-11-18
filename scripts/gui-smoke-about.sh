#!/bin/bash
# Headless GUI test of Settings → About (SPEC §4.6): the binary carries the
# list of changes (scripts/changes.sh at build time); a release build shows
# "What's new" once on its first start, its button opens Settings → About
# with the version and the changes per release; the next start shows no
# notice. A build between releases (make build) never shows the notice;
# for the release case build it as one: make build VERSION=v1.1.24
# usage: xvfb-run -a -s "-screen 0 1400x900x24" scripts/gui-smoke-about.sh <binary> <outdir>
BIN=$1; OUT=$2; mkdir -p $OUT
. "$(dirname "$0")/smoke-lib.sh"
PROF=swabout$$
cleanup() { rm -rf "$HOME/.local/state/$PROF"; }
trap cleanup EXIT
CFG=$OUT/config.toml
cat >$CFG <<TOML
[[hosts]]
name = "local"
ssh_target = "localhost"
TOML
shot() { import -window root $OUT/$1.png; }
same() { [ "$(compare -metric AE $OUT/$1.png $OUT/$2.png null: 2>&1 | cut -d" " -f1)" = 0 ]; }
differ() { ! same "$@"; }
crop() { convert $OUT/$1.png -crop $2 +repage $OUT/$3.png; }
V=$($BIN -version | awk '{print $2}')
isrelease() { echo "$V" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$'; }
REL=0; isrelease && REL=1
echo "version $V (release: $REL)"
check "the binary carries the list of changes" grep -aq "## $V (\|## Since v.* (not released)" $BIN

start() {
	$BIN -config $CFG -profile $PROF >>$OUT/app.log 2>&1 &
	APP=$!
	wait_window
	sleep 3; xdotool windowactivate --sync $W 2>/dev/null
	xdotool mousemove 1250 830; sleep 3
}
start
shot 1-first-start
TOAST=300x56+1030+782                     # bottom right of the window
crop 1-first-start $TOAST 1-toast
# The notice's button: What's new → Settings → About.
xdotool mousemove 1266 809 click 1; sleep 1.5; xdotool mousemove 1250 830; sleep 0.5
shot 2-about
k() { xdotool key "$@"; sleep 0.6; }
k Escape
kill $APP; wait $APP 2>/dev/null
start
shot 3-second-start
crop 3-second-start $TOAST 3-toast
if [ $REL = 1 ]; then
	check "a release shows the notice at its first start, not again" differ 1-toast 3-toast
	check "What's new opens Settings → About" differ 1-first-start 2-about
else
	check "a build between releases shows no notice" same 1-toast 3-toast
fi
# Settings → About from the footer's What's new button: from Appearance
# (footer at y 540), the page changes to the list.
k ctrl+shift+comma; sleep 1
xdotool mousemove 423 159 click 1; sleep 0.5; xdotool mousemove 1250 830; sleep 0.5
shot 4-appearance
xdotool mousemove 410 540 click 1; sleep 1; xdotool mousemove 1250 830; sleep 0.5
shot 5-about
crop 4-appearance 640x60+370+230 4-top
crop 5-about 640x60+370+230 5-top
check "What's new turns the page to About" differ 4-top 5-top
# text there: not one plain colour
written() { [ "$(convert $OUT/$1.png -colorspace gray -format '%[fx:standard_deviation>0.02]' info:)" = 1 ]; }
check "the About page lists changes" written 5-top
k Escape
alive
kill $APP; wait $APP 2>/dev/null
finish
