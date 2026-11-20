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

## CI of 46df6ed (v1.1.32)

- Build run 44739485135 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal on Go 1.27; release skipped.
- The Linux binary in CI: 47.9 MB (v1.1.31's release: 52.2 MB), as measured locally.
  The compressed downloads barely change (the tar.gz about 16 MB, the macOS zip 31 MB, the Windows zip 15.8 MB):
  the JavaScript that left compressed well.

## Cross-check of v1.1.32

- The user: "do a crosscheck".
- Searched for the old module path, goja, Go 1.26 and ELK across the code and docs.
- `scripts/deps.sh` still required Go ≥ 1.26: now `GO_MIN=1.27`.
  In this folder an older Go fetches 1.27.0 itself (go.mod; `go env GOVERSION` says go1.27.0 with Go 1.26.8 installed),
  so the check passed anyway; README's build requirements now say so.
- PLAN's v1.1.22 entry claimed D2 v0.8+ needs Go 1.27: corrected in place (only v0.8.2 and later).
- Left as they are: `go >= 1.26` in the Requirements examples (README, the Requirements dialog, requirements tests)
  and `GO_VERSION=1.26.0` in the Dockerfile template are about the user's projects, not this build.
- Found, not changed (older than v1.1.32): packaging/copyright (the .deb/.rpm licence file) lists only the app (MIT) and the spelling dictionaries;
  D2 (MPL-2.0) is named in README's "Third-party code" only, and ELK (EPL-2.0, before as JavaScript, now elk-go) nowhere.

## Licence notices in v1.1.32

- The user: "add the licence notices in v1.1.32, then commit, i push".
- D2 v0.9.0 ships a THIRD_PARTY_NOTICES.txt for what it builds on:
  dagro (dagre), rough-go (Rough.js), mathjax-go, go-text/typesetting, golang.org/x/image, Noto Color Emoji, elk-go (EPL-2.0).
- New scripts/notices.sh (`make notices`) writes THIRD-PARTY-NOTICES.txt from the module cache:
  D2's MPL-2.0 licence with its source link, util-go's licence, D2's notices file, unchanged.
- Shipped: in the Linux tar.gz and the Windows and macOS zips beside the program (CI Package step),
  in the .deb (/usr/share/doc/session-workbench/) and the .rpm (/usr/share/licenses/session-workbench/);
  packaging/copyright has a D2 section pointing to it.
  Checked locally: tar, 7z and zip listings, dpkg-deb -c, the rpm's file names.
- TestThirdPartyNotices: the file names the d2 and util-go versions in go.mod; a wrong version fails it (tried).
- Not covered yet: other Apache-2.0 Go modules (anthropic-sdk-go, OpenTelemetry, go-logr, go.yaml.in/yaml/v4 with a NOTICE).

## CI of 6bfb340

- Build run 44742003192 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.
- THIRD-PARTY-NOTICES.txt is in every artifact (checked after download):
  the tar.gz and the Windows zip beside the program, the macOS zip beside session-workbench.app,
  the .deb under /usr/share/doc/session-workbench/, the .rpm's file list.
- The Windows copy has CRLF line endings (Windows checkout), the same text otherwise (63873 bytes without the CRs).

## v1.1.32 tagged; next version

- The user pushed and tagged v1.1.32 (tag object 0ba42b3 on 6bfb340); release build run 44743067750.
- The user: "on the next release go to v1.2.0".

## CI of v1.1.32

- Release run 44743067750 passed on the first attempt: linux-amd64, windows-amd64, macos-universal and release.
- The release has the .deb, .rpm, Linux tar.gz, Windows zip and macOS zip; the notes list the three commits since v1.1.31.
- Release check: 9 releases, no artifacts older than 14 days, so no cleanup warning.

## v1.2.0: Apache licence notices

- The user: "add the Apache licence notices in v1.2.0".
- The modules the program is built from: `go list -deps` for linux, windows and darwin with the Wails tags, 65 modules;
  the Linux list matches `go version -m` of the binary exactly (the other six are Windows or macOS only).
- Apache-2.0 or with a NOTICE file, outside D2's own: anthropic-sdk-go, purego, go-logr/logr and stdr, ordered-map, go-reflector,
  OpenTelemetry (4), go.yaml.in/yaml/v4 (NOTICE).
- scripts/notices.sh adds them as part 4, licence and NOTICE files unchanged, a repeated text named instead of repeated:
  THIRD-PARTY-NOTICES.txt 64 → 115 KB.
- TestThirdPartyNotices checks the listed versions against go.mod; a wrong version fails it (tried).
- Version 1.2.0: wails.json, README, SPEC v1.43, PLAN.

## CI of 413bf68 (v1.2.0)

- The scratchpad poll script had been removed (scratchpad cleared); recreated, the run polled again.
- Build run 44821172928 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.
- The Linux tar.gz carries the new THIRD-PARTY-NOTICES.txt (115 KB, the same as in git).

## Cross-check of v1.2.0

- The user: "do a crosscheck".
- scripts/notices.sh run again: THIRD-PARTY-NOTICES.txt identical to the committed one.
- packaging/copyright's Apache section named holders without checking them; now from the modules' sources:
  2023 Anthropic, PBC; The OpenTelemetry Authors; 2019-2021 The logr Authors; 2022-2025 The Ebitengine Authors (purego, missing before);
  2011-2016 Canonical Ltd. and 2006-2010 Kirill Simonov (yaml/v4, missing before); ordered-map and go-reflector name nobody.
- README, SPEC §7.6, Tests.md, Makefile and the version (wails.json 1.2.0, README, SPEC v1.43, PLAN) agree.
- Limit, not changed: TestThirdPartyNotices catches a listed module whose version changed, not a new Apache-licensed module;
  `make notices` after module updates covers that.

## CI of ea20994

- Build run 44831922778 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.
- v1.2.0 is ready to tag (cross-check done).

## v1.2.0 tagged

- The user pushed and tagged v1.2.0 (tag object 19f73c8 on ea20994); release build run 44832934289.
- The user changed origin to git@github.com:maarten-boot/session-workbench.git (ssh, the repository's new name).
