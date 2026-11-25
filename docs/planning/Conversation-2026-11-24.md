# Conversation 2026-11-24

## Intervals in Settings

- The user: "add the check interval time on web to the settings menue, any other internal constants we currently have make sense in settings ?"
- v1.2.1 is pushed, not tagged: these changes stay in v1.2.1 (no cross-check of v1.2.1 was done yet).
- Survey of fixed timings: Web build runs (2 min, 15 s while one runs), repository check of all sessions (2 min),
  messages on screen (4 s, errors 8 s, with a button 15 s), desktop notification gap (1 min), cost update (1 min; shares SW_IDLE_TICK with the idle check).
  Timeouts (ssh, gh, diagram), retry backoffs and the idle check were left fixed.
- Offered four; the user chose all four.
- New Settings page Checks (repository, build runs, build runs while one runs, cost); Appearance: message time; Terminals: notification gap.
- Backend: config.Intervals (validation, defaults), CostEvery; the cost loop reads the interval each round and is woken by SaveUI.
- Frontend: intervals.js (durationMs, every, messageMs), used by web.js, ui.js (toasts) and main.js (repository check, notifications).
- Tests: TestIntervals, intervals.test.mjs (99 frontend tests pass), all Go tests pass.
- GUI: the new Checks page and the taller Appearance and Terminals pages moved Save, What's new and the Keys tab;
  about, activelimit, dialogs, examples, idle and settings follow. New gui-smoke-checks.

## Disconnect remembered

- The user: "if we press disconnect on a session , that is currently not rememebered right ?"
- Answered: right; Disconnect ends the connection in this run only; after a restart the session connects again
  (when viewed, or at startup with "all at startup"); Deactivate is what is remembered.
- The user: "yes remember disconnect in v1.2.1 (and show its color button after a restart)".
  Asked what "color button" means; the user: the sidebar status dot.
- `disconnected` in the session's config; after a restart its Local and Remote tabs wait for Enter ("Disconnected."),
  the dot is orange, the sidebar line says "· disconnected"; connecting again or activating clears it.
- The dot had no words (color only): it now has a tooltip with its state.
- Tests: TestDisconnected, gui-smoke-disconnect (13 checks).

## Sidebar colors

- The user (mid-turn): "we should probably allow users to configure the sidebar colors".
- Asked which and when; the user: background, selected row, status dot colors, per folder / host; in v1.2.1.
- Settings page Sidebar (after Checks): a field per color (#rrggbb, picker, "Aa" with the text on it, × back to the theme's),
  host and folder lists. Text black unless it misses 4.5:1 (or the Appearance minimum); dots below 3:1 against the background named.
- First try: with only a dark background set, the selected row kept the theme's light blue but took white text; fixed
  (the selected row's text is computed for its own background); the general Settings label style squeezed the rows; fixed.
- Folder and host colors follow renames and go with deletes.
- Tests: TestSidebarColors, TestSidebarColorsFollow, sidebarcolors.test.mjs (104 frontend tests pass), gui-smoke-sidebarcolors.
- The user: "going home", then "ok commit first i will push": committed while the full GUI suite still runs
  (the 9 changed or new tests passed on the final build); the tutorial's Settings screenshots are not retaken yet.

## CI of 2f0e70a

- Build run 45428814941 passed: linux-amd64, windows-amd64 and macos-universal; release skipped.
- The full GUI suite stopped after 3 tests when the session ended (all 3 passed); the other 54 run again.
- All 57 GUI tests pass on the final build (3 before the session ended, 54 after).
- The tutorial's Settings screenshots (30, 31, 32) retaken: the tab column has Checks and Sidebar, Appearance the message time.
  The other screenshots of that step differed only in the top bar's cost and the times (a few hundred pixels): kept as they were.

## CI of 49ee5e2

- Build run 45456551034 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.

## Cross-check of v1.2.1

- The user: "do a crosscheck".
- THIRD-PARTY-NOTICES.txt written again: identical (no module changed).
- Import builds a new session from chosen fields: an imported session does not take `disconnected` along (right).
- Fixed: the tutorial's table of Settings pages lacked Checks and Sidebar (and the message time, the notification gap);
  README's config reference lacked the new [ui] keys and the session's `disconnected`;
  SPEC's summary did not list the intervals, the remembered Disconnect and the sidebar colors;
  SPEC now says one sidebar color serves both themes and an own background has no hover tint.

## CI of c5873be

- Build run 45461911782 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.
- v1.2.1 is ready to tag (cross-check done).

## CI of v1.2.1

- The user pushed and tagged v1.2.1 (tag object 5fbd846 on c5873be).
- Release run 45464656143 passed on the first attempt: linux-amd64, windows-amd64, macos-universal and release.
- The release has the .deb, .rpm, Linux tar.gz, Windows zip and macOS zip; the notes list the four commits since v1.2.0.
- Release check: 11 releases, no artifacts older than 14 days, so no cleanup warning.
