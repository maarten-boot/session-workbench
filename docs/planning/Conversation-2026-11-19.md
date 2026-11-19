# Conversation 2026-11-19

## CI of 8457e02 (README logo)

- Build run 44406723494 passed: linux-amd64, windows-amd64 and macos-universal; release skipped.

## The logo on Settings → About (v1.1.27)

- The user: "add the logo to settings about".
- The About page starts with the logo (100 px high, rounded corners) and, beside it,
  the name and version in black text (the logo's green name is below 4.5:1).
- The frontend build cannot load docs/logo.png, which is outside its folder;
  frontend/src/assets/logo.png is a copy, imported by main.js.
  TestLogoCopy (Go) fails when the two differ.
- gui-smoke-about checks the logo's blue at its place (0.45 on About, 0 on Appearance).
- Version 1.1.27 (v1.1.26 was tagged); SPEC v1.37 (§4.6 About).
- PLAN Next keeps one idea: the logo as the app icon (needs a square version without the name).
- Tests: go test ./... and npm test (91) pass; gui-smoke-about passes.
- Next, by the rule of 2026-11-18: after this commit's CI, a cross-check before the tag.

## CI of 1913d56 (v1.1.27, the logo on About)

- Build run 44503984673 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.
  TestLogoCopy ran on all three (the logo file is binary: no CRLF on Windows).

## Cross-check v1.1.27 (before the tag)

- SPEC §4.6 About, PLAN, Tests.md, README (status, layout) and TUTORIAL section 6 match the code;
  the two logo files are equal; version 1.1.27 in wails.json, README and SPEC.
- No tutorial screenshot shows the About page, so none is out of date.
- Fixed: SPEC's About paragraph had lines of up to 117 characters; rewrapped to at most 96.

## CI of 4d85643 (cross-check v1.1.27)

- Build run 44509092338 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.
- v1.1.27 is ready to tag at 4d85643 (feature 1913d56 plus its cross-check).

## CI of v1.1.27

- Release run 44521263592 failed on the first attempt:
  linux-amd64 stopped in "Linux build dependencies" (apt: security.ubuntu.com answered 503 Service Unavailable);
  windows-amd64 and macos-universal passed; release skipped, so no GitHub release yet.
- An Ubuntu mirror outage, not the code: the same commit 4d85643 passed in run 44509092338.
  Next: rerun the failed job (`gh run rerun 44521263592 --failed`).
- The rerun (attempt 2) passed: linux-amd64, windows-amd64, macos-universal and release.
  Release v1.1.27 has 5 assets (.deb, .rpm, linux tar.gz, macOS zip, Windows zip);
  its notes list the 4 commits since v1.1.26.
- Cleanup check after the release: 4 releases, no CI artifacts older than 14 days, so no warning.

## The logo as the app icon (v1.1.28)

- The user: "add the logo as the app icon".
- The rounded square was cut from the logo's original (tmp/image_9a8d16db.jpg, about 355 px),
  made transparent outside its rounded corners and scaled to 960 px on a 1024 px canvas;
  128 colours with the alpha kept bring it from 825 KB to 321 KB.
- `make icons` makes build/windows/icon.ico (256 to 16 px) and packaging/icons (256, 128, 48) from build/appicon.png.
- TestAppIcon checks sizes, transparent corners and the logo's blue in each, also every size in the .ico;
  it fails on the old icons.
- Found on the way: the Linux window never had an icon.
  The binary embedded the 1024 px PNG, which GTK leaves out (too large for one X request);
  a GTK test window took a 256 px icon and not the 1024 px one.
  main.go now embeds packaging/icons/256.png.
- gui-smoke-icon.sh runs xfwm4 on the Xvfb display (GDK sets _NET_WM_ICON only under a window manager),
  with its settings in the output folder and a private bus:
  FAIL on the binary built before the fix, PASS after.
- Go tests, npm test (91 pass) and make build passed.

## CI of 81e48f7 (v1.1.28)

- Build run 44547187133 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.
- TestAppIcon passed on Windows too (the .ico read as bitmaps, no path or CRLF issues).
- Next: the cross-check of v1.1.28 before the tag.

## Cross-check v1.1.28

- The CI build of 81e48f7 carries the new icon:
  the macOS app's iconfile.icns (1024, 512, 256, 64, 32 px, transparent corner, the logo's blue)
  and the Windows exe (all 6 sizes; the 256 one with a transparent corner and the blue).
- README: `make icons` added to the make targets;
  the smoke-ui line lists what the Makefile's comment lists (idle, cost, headings, examples, tags, copy, D2, About, Check share, dialogs, window icon);
  xfwm4 named as optional for the GUI tests.
- Makefile `icons`: `convert` when there is no `magick` (ImageMagick 6 on Ubuntu 24.04 and Debian);
  `-strip`, so a second run gives the same files (the PNGs held their creation date); same output with magick and convert.
  The 3 package icons were made again (smaller, no date); rebuilt, gui-smoke-icon passed again.
- PLAN: the logo's original (tmp/image_9a8d16db.jpg) is the user's and not in git (tmp/ is ignored).
- Go tests, npm test (91 pass) passed.
- The user (for the next version): "can we add the start date of a session to the cost view ?"
- The user chose option 2: "option 2 as that is the cost base" (the date of the session's first claude conversation, from its transcripts).
