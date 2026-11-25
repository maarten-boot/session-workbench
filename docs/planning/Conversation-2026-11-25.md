# Conversation 2026-11-25

## The notices check

- The user: "drop the output folding for now what is the second open item ?"
- Answered: TestThirdPartyNotices checks the versions of what THIRD-PARTY-NOTICES.txt lists, not that a new module or package is listed;
  for JavaScript a test can compare the lock file, for Go go.mod names more modules than the program is built from,
  so CI can write the file again and fail on a change.
- The user: "yep build the notices check, output folding can be removed."
- TestThirdPartyNotices: every production package of package-lock.json is listed (tried: removing nspell's line fails it).
- CI, Linux job, after the frontend: "Third-party notices up to date" runs scripts/notices.sh and `git diff --exit-code`;
  locally the file is written identically.
- Output folding removed from PLAN Next (nothing queued now).
- Version 1.2.2: wails.json, README, SPEC, PLAN.

## CI of f200ab4 (v1.2.2)

- Build run 45600554604 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.
- The new step "Third-party notices up to date" ran on Linux and passed (the file written in CI is the committed one).

## Cross-check of v1.2.2

- The user: "do a crosscheck".
- README, SPEC §7.6, Tests.md and PLAN describe the check; the Makefile's and scripts/notices.sh's comments named only the test: now the CI step too.
- Noted in PLAN: a dependency update (e.g. a Dependabot pull request) fails CI until `make notices` is committed with it.
