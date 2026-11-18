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

## Cleaning up old releases and artifacts

- The user: "can we cleanup all releases and artifacts except for the last version ?"
- On GitHub: 20 releases (1.1 GB), 653 workflow artifacts (8.7 GB, none expired),
  12 Actions caches (6.4 GB), 81 tags, 245 runs.
- The user chose: delete the 19 releases before v1.1.24 and the artifacts of all runs
  except the v1.1.24 tag build and the latest main build; keep all tags
  (scripts/changes.sh and the package changelogs read them); keep the caches and the run history;
  artifacts kept 14 days from now on.
- Deleting failed: gh's token here is read-only
  ("HTTP 403: Resource not accessible by personal access token"); nothing was deleted.
  The token needs Contents and Actions with write access for this repository.
- build.yml: upload-artifact gets `retention-days: 14`.

## CI of d500de7 (cross-check v1.1.24)

- Build run 44308744528 failed: linux-amd64 and windows-amd64 passed;
  macos-universal was cancelled after 15 minutes in the queue, never started
  ("The job was not acquired by Runner of type hosted even after multiple attempts"):
  macOS runner contention, as on 2026-11-17, not the code (only README and the log changed).
- The user re-ran the failed job in the browser (gh here has a read-only token);
  attempt 2 passed: macos-universal got a runner after 10 minutes in the queue; release skipped.
