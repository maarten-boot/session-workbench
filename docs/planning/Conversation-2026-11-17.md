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
