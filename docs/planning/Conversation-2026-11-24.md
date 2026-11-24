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
