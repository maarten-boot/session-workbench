# Conversation 2026-11-18

## CI of a9e23bf (v1.1.24, not tagged)

- The user pushed 9fb5353 (cross-check v1.1.23) and a9e23bf (v1.1.24, what changed per release).
- Build run 44286936542 passed: linux-amd64, windows-amd64 and macos-universal; release skipped.
  Its Frontend step ran scripts/changes.sh on all three runners
  (macOS's bash 3.2, Git Bash on Windows).
- The release notes from scripts/changes.sh --release are first written at the next tag.

## CI of tag v1.1.24 (a9e23bf)

- Run 44287562684 passed: linux-amd64, windows-amd64, macos-universal and release;
  the release has the 5 assets (rpm, deb, linux tar.gz, macOS zip, Windows zip).
- The release notes list the 2 commits since v1.1.23 under "Changes since v1.1.23",
  followed by GitHub's Full Changelog link, as intended.

## Cross-check after v1.1.24

- The user: "do a crosscheck".
- SPEC §4.6 About, Tests.md, PLAN, the tutorial and the Makefile match the code of v1.1.24.
- README: the status names What's new;
  the layout lists the frontend files it missed
  (qa.js, qaparse.js, diagram.js, cost.js, tags.js, idle.js,
  dockerfile.js, services.js, osc52.js, changes.js).
- Left as is: the tutorial screenshot of Settings (30-settings.png) predates the What's new link;
  make tutorial-shots would renew it.
