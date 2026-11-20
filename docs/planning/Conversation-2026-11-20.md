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
