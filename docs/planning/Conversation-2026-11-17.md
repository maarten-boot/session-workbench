# Conversation 2026-11-17

## D2 diagrams in Notes and Q&A (v1.1.22)
- The user: "could we embed D2 graphs in the Notes tab ?"
  Offered the D2 Go library in the app (A) or a `d2` program (B), and Mermaid as the alternative GitHub draws.
- The user: "A with D2, also in Q&A".
- D2 v0.8/v0.9 (`github.com/d2lang/d2`) need Go 1.27; the project uses Go 1.26,
  so `oss.terrastruct.com/d2` v0.7.2 for now.
- The app grows from 27.8 MB to 51.8 MB; the ELK layout engine is 3.7 MB of that.
- First drawings had no labels:
  the web view draws no text with fonts embedded in an SVG shown as an image,
  so the embedded fonts are replaced by the system's (bold and italic kept).
- Edge labels were grey (#676C7E): D2's text colours are set to black (white in the dark theme).
- D2 logged a stack trace per drawing ("missing slog.Logger"): it gets a silent logger.
- A GUI-test pitfall: with the pointer outside the window (no window manager),
  keys go nowhere; the test parks the pointer inside.
- Tests: internal/diagram pass; npm test 85 pass; gui-smoke-d2 pass;
  gui-smoke-notes, gui-smoke-qa, gui-smoke-appnotes pass; a dark-theme run checked by eye.
- Next: D2 v0.8+ when the build moves to Go 1.27 (PLAN Next).

## Copying in the Remote tab (v1.1.22)
- The user: "why does copy no longer work in the Remote window, no matter what i try i cannot get the data in the clipboard"
- Suggested Shift+drag; the user: "when i do shift + drag and release either shift or mouse the selection disapears".
- Cause, found in xterm.js:
  claude asks for every mouse move (mode 1003);
  after the drag each move is reported to claude,
  and xterm.js clears the selection on every report (it counts as input).
- Fix: while there is a selection, moves without a button are not reported;
  OSC 52 from claude or tmux puts text on the clipboard (write only, reads ignored);
  Option+drag selects on macOS.
- Tests: npm test 85 pass (osc52.test.mjs);
  gui-smoke-copy pass (Shift+drag in a mode-1003 program, OSC 52, a read request),
  and it fails on a build without the fix.

## CI
- 7b3b5c2 (with 5e84339 and 252bc54; run 44068743484): linux-amd64, windows-amd64, macos-universal pass (the first build with D2); release skipped (no tag).
- Dependabot's dependency graph update for the new go.mod (run 44068751596): success.
- v1.1.22 tag (7b3b5c2, run 44070481738): all three builds pass; release with 5 assets (.rpm, .deb, linux tar.gz, macOS zip, Windows zip).

## Cross-check after v1.1.22 (7b3b5c2)
- SPEC N1c, T2a and F18 match the code:
  0.6 s redraw, the last 64 drawings cached, 64 KB and 15 s limits, unclosed blocks not drawn, TALA refused;
  OSC 52 write only, 1 MB, the "Copied to the clipboard" notice;
  the Cost sort remembered.
- The dark D2 theme follows the app's theme, which is only light or dark (config.ValidateUI): no system setting to follow.
- Fixed:
  the SPEC status summary now names the Cost sort (F18), T2a and N1c;
  the README status names D2 diagrams and tags (tags were missing since v1.1.20);
  the README layout lists internal/examples (missing since v1.1.19).

## CI
- ba36c0c (cross-check, run 44077600309): linux-amd64, windows-amd64, macos-universal pass; release skipped (no tag).

## Copy image of a D2 drawing (v1.1.23)
- The user: "could we add a copy image to clipboard of the D2 rendered image ?"
- Wails copies text only.
  `golang.design/x/clipboard` v0.11.0 writes images without cgo
  (X11 and Wayland, Windows, macOS; MIT); the app grows 0.2 MB.
- Right-click on a drawing (Notes, Q&A, also an SVG picture in Q&A): *Copy image*;
  the frontend draws it on a canvas at twice its size, on the page's background,
  and App.CopyImage checks the PNG (at most 32 MB) and puts it on the clipboard.
- Tests: TestPNGImage; gui-smoke-d2 pass
  (Notes and Q&A copies read back by scripts/clipimage as PNGs at twice the size,
  and a text copy still works after an image copy);
  gui-smoke-notes and gui-smoke-qa pass; npm test 85 pass; vet for Windows passes.

## CI of 4646913 (v1.1.23, not tagged)

- Build run 44163007057 passed: linux-amd64, windows-amd64 and macos-universal; release skipped.
- Dependabot "Graph Update: go_modules" run 44163012778 passed (go.mod changed).

## CI of tag v1.1.23 (4646913)

- Run 44165186127 failed: linux-amd64 and windows-amd64 passed;
  macos-universal was cancelled after 15 minutes in the queue
  ("The job was not acquired by Runner of type hosted even after multiple attempts";
  GitHub notes macOS arm64 capacity constraints), so the release job was skipped.
- No code fault: the user runs macOS builds of other projects at the same time,
  which compete for the runners;
  they will build one project at a time and re-run the failed job.
- Re-run of the failed jobs (attempt 2) passed: macos-universal and release;
  the release has the 5 assets (rpm, deb, linux tar.gz, macOS zip, Windows zip).

## Cross-check after v1.1.23

- The user: "do a crosscheck".
- SPEC used N1c twice: TODO marks (since v0.9.0) and D2 diagrams (v1.1.22).
  D2 diagrams (with Copy image) are now N1d, placed after N1c;
  references in SPEC, PLAN, Tests.md, the code comments and gui-smoke-d2 follow.
  Earlier entries in this log keep N1c for D2.
- README layout lists scripts/clipimage/.
- SPEC v1.33.
  Otherwise SPEC N1d, README, TUTORIAL, Tests.md and PLAN match the code of v1.1.23.
- Committed as 9fb5353.

## What changed per release (v1.1.24)

- The user: "dow we show a changes since last release in  the settings or somewhere ?"
  (read as: do we show the changes since the last release).
- Found: only the version in the Settings footer;
  the .deb/.rpm changelogs list the commits, the GitHub release notes only a compare link.
- Offered: the list in the app (Settings → About, once after an update) and in the release notes.
  The user: "yes commit first, then do both".
- scripts/changes.sh: commit subjects (no merges) per v* tag, newest first,
  the commits since the last tag first; at most 5 releases and 60 commits each;
  `--release <tag>` for the release notes.
  Plain bash 3.2 (macOS), no `| head` (SIGPIPE under pipefail).
- The build carries frontend/public/changes.txt (make build/dev, CI's Frontend step);
  Settings shows it on the About page, opened by *What's new* at the left of the footer
  (before the version, so it stays in place however long the version is).
  A tenth tab wrapped the tab bar and moved every page down (gui-smoke-cost failed),
  so About has no tab.
- A release build (vX.Y.Z) shows "Session Workbench vX.Y.Z  What's new" once at its first start.
- CI: the release job checks out the repository (full history) and passes
  `--notes-file` with `--generate-notes` (GitHub appends its Full Changelog link).
- .gitattributes: *.sh stay LF, since the Windows runner now runs changes.sh.
- While testing, a command of mine ran `git stash` by mistake;
  `git stash pop` restored everything at once (the stash list is empty).
- Tests: TestChangesScript (a new repository, 70 commits), changes.test.mjs (npm test 89 pass),
  gui-smoke-about (as a release build and as a build between releases);
  gui-smoke-settings, cost, colors, qa, notes, spell, record, history and d2 pass.
