# Conversation 2026-11-21

## CI of v1.2.0

- Release run 44832934289 passed on the first attempt: linux-amd64, windows-amd64, macos-universal and release.
- The release has the .deb, .rpm, Linux tar.gz, Windows zip and macOS zip; the notes list the two commits since v1.1.32.
- Release check: 10 releases, no artifacts older than 14 days, so no cleanup warning.

## v1.2.1: MIT and BSD licence notices

- The user: "add the MIT and BSD notices in v1.2.1".
- THIRD-PARTY-NOTICES.txt now covers everything the program is built from (208 KB):
  part 4 all 59 Go modules (Linux, Windows, macOS) with the licences their files name, part 5 Go itself,
  part 6 the 29 JavaScript packages of the lock file's production tree, part 7 the spelling dictionary.
- A source-map build of the frontend showed 26 of the 29 packages in the bundle (not @codemirror/lint, @codemirror/streamparser, crelt);
  listing the whole production tree is simpler and needs no build.
- Dual licences (go-toast: Unlicense OR MIT; go-text/typesetting) are listed as "MIT, Unlicense", not "and".
- scripts/notices.sh rewritten with Python; it stops when a module has no licence file or node_modules differs from package-lock.json.
- TestThirdPartyNotices checks Go modules against go.mod and JavaScript packages against package-lock.json; a wrong version of each fails it (tried).
- packaging/copyright: a section for the rest, the holders checked against the licence files (Wails, Go, xterm.js, CodeMirror).
- Version 1.2.1: wails.json, README, SPEC v1.44, PLAN. Go tests, frontend tests (96) and gui-smoke-about pass.

## CI of c3731e9 (v1.2.1)

- Build run 44838565024 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.
  TestThirdPartyNotices passed on all three, Windows with its CRLF checkout.
