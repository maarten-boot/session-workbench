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

## CI of 23291f7

- Build run 45604733400 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.
- v1.2.2 is ready to tag (cross-check done).

## CI of v1.2.2

- The user pushed and tagged v1.2.2 (tag object 22e9a5e on 23291f7).
- Release run 45607643587 passed on the first attempt: linux-amd64, windows-amd64, macos-universal and release.
- The release has the .deb, .rpm, Linux tar.gz, Windows zip and macOS zip; the notes list the two commits since v1.2.1.
- Release check: 12 releases, no artifacts older than 14 days, so no cleanup warning.

## GUI tests stop with stop_app

- The user: "switch the remaining GUI tests to stop_app".
- 61 one-for-one replacements in 51 scripts (`kill $APP; wait $APP` and the stop() helpers of examples, sessions and tutorial-shots).
- Left as they were: gui-smoke-autosave (quitting while saving is what it tests), gui-smoke-window (SIGTERM), the MEASURE debug exits.
- No version bump: only the tests change; it goes out with v1.2.3.
- All 57 GUI tests pass with stop_app; afterwards no test state folder is left in ~/.local/state.

## CI of b4a651f

- Build run 45622163982 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.
- Only the tests changed: no tag needed; it goes out with v1.2.3.

## Repository check window moves and resizes (v1.2.3)

- The user: "the hooks warning popup window where we review the hooks should be resizable and movable."
- The repository check's Details… (#dlg-repo) now moves by its heading and resizes at its corner (moveWindow, as Settings and the host dialogs).
- First tries: a flex layout to let the list take the extra height squeezed the list to one line, then kept the window small;
  WebKit sized the flex dialog as if the scrolling list were empty. Now the list is no box of its own: it shows whole, the window scrolls.
- gui-smoke-repocheck drags the heading and the corner (checked) and clicks Mark as reviewed where the move put it; gui-smoke-dialogs passes.
- Version 1.2.3 (the stop_app commit b4a651f goes out with it): wails.json, README, SPEC, PLAN, TUTORIAL, Tests.md.
