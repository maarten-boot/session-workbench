# Conversation 2026-11-20

## Status

- The user: "status?"
- main at 159cea0 (v1.1.31, released; both its runs passed); the 2026-11-19 log's last CI entries not committed yet.

## echo/v4 update

- The user: "do the echo/v4 update".
- Open Dependabot alerts: #6 GHSA-99jh-6h7p-pp36 and #7 GHSA-246p-cpwv-v3jq (medium), both github.com/labstack/echo/v4.
  Their advisories give only v5 as fixed (5.4.0 and 5.1.0), every v4 as vulnerable;
  the earlier note "v4.16.3 fixes them" came from echo's release notes, which say v4.16.3 fixes the remaining v4 exposure.
- Released v4 versions: up to v4.16.5 (2026-11-15); 4.16.4 and 4.16.5 fix two more advisories (an open redirect, a dropped X-Forwarded-Proto).
- Updated 4.16.1 → 4.16.5 (`go get`, `go mod tidy`): only echo changed in go.mod and go.sum.
- Echo is only in Wails' dev server (`wails dev`), not in the release binary: no version bump.
- `go build -tags dev,webkit2_41 ./...`, `go vet`, Go tests and `make build` passed.
  govulncheck is not installed (not installed here: it would add a tool to the user's system).
- Dependabot may keep #6 and #7 open while the advisories name only v5; dismissing them is for the user (the gh token here is read-only).

## CI of 77e030d

- Build run 44708088501 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.
- Dependabot marked #6 and #7 fixed (2026-11-20 09:08 UTC) after the push, although the advisories name only v5 as fixed.
- No Dependabot alerts are open now.

## D2 module move explained

- The user: "explain the D2 move to github.com/d2lang/d2".
- From v0.8.0 D2 is published as `github.com/d2lang/d2`; `oss.terrastruct.com/d2` stops at v0.7.2.
- The PLAN note was partly wrong:
  v0.8.0 and v0.8.1 need Go 1.25, only v0.8.2 and v0.9.0 need Go 1.27.
- Offered A (v0.8.1, stays on Go 1.26) or B (v0.9.0 with Go 1.27).
- The user: "yes fix the note, B is fine".
  PLAN Next now records B.

## v1.1.32: D2 v0.9.0 and Go 1.27

- The user: "yes start B as v1.1.32".
- Go 1.27.4 is used through `GOTOOLCHAIN=go1.27.4` (downloaded into the Go cache; the installed Go 1.26.8 is untouched).
- go.mod `go 1.27.0`; `oss.terrastruct.com/d2` v0.7.2 and util-go replaced by `github.com/d2lang/d2` v0.9.0 and `github.com/d2lang/util-go` v0.2.0;
  CI `GO_VERSION: '1.27.x'`.
- Only the nine import paths in `internal/diagram` changed; the API calls compile as they are.
- D2 v0.9.0 uses Go ports of dagre and ELK (dagro, elk-go) instead of JavaScript in goja:
  the Linux binary (make build) shrinks from 52.2 to 47.9 MB.
- New licences: dagro and rough-go MIT, mathjax-go Apache 2.0, elk-go EPL 2.0 (ELK was EPL before too); D2 still MPL 2.0.
- TestSVG also checks that the dark theme's text is white.
- A stray `git checkout 77e030d --` in a command detached HEAD at the same commit; `git switch main` restored it, no change lost.
- Docs: SPEC v1.42 (N1d module, Go 1.27+), README (status, Go 1.27+, D2 link), PLAN history entry, the Next item removed, Tests.md.
- Tests: Go tests and frontend tests (96) pass; all 53 GUI tests pass.
  gui-smoke-about first failed because the binary was built with `wails build` alone (no `make changes`, so no list of changes);
  after `make build` it passes.
  That first build also lacked the Makefile's flags (43.9 MB); `make build` gives 47.9 MB.
