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
