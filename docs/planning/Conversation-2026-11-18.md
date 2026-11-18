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

## CI of 070bcad (14-day artifacts)

- Build run 44324924383 passed: linux-amd64, windows-amd64 and macos-universal; release skipped.
- Its three artifacts expire on 2026-12-02, 14 days after the build, as set.

## Cleanup of releases and artifacts (done by the user)

- The user ran the delete commands with a gh login that has write access.
- Result, checked with read-only calls:
  - releases: 1 left (v1.1.24, 5 assets);
  - tags: all 81 kept;
  - caches: 12 (6.4 GB), kept as chosen;
  - artifacts: 8 left, the 6 of the kept runs 44287562684 (v1.1.24) and 44324924383 (070bcad),
    plus 2 that were missed.
- The 2 missed artifacts are 12903435405 (run 40886619237, 49b5415) and 12115035588 (run 39069963308, a139a49).
  - Likely cause: the list was paged while deleting, so items moved to pages already read.
  - They expire on 2027-01-27 and 2027-01-15 (90-day retention from before the 14-day setting).

## CI of 12eb23d (log of the cleanup)

- Build run 44347501193 passed: linux-amd64, windows-amd64 and macos-universal; release skipped.
- Its three artifacts expire on 2026-12-02; the repository now holds 9 artifacts
  (v1.1.24, 070bcad, 12eb23d, and the 2 old ones missed by the cleanup).

## Cross-check after the cleanup

- Since the last cross-check (d500de7) only build.yml (`retention-days: 14`) and the log changed.
- README Download and PLAN M6 now say the build artifacts are kept 14 days.
- No links to the deleted releases anywhere (README, docs, code); SPEC does not describe artifact retention.
- Version 1.1.24 in wails.json matches the latest tag; nothing to bump.

## CI of 96633dd (cross-check after the cleanup)

- Build run 44350156660 passed: linux-amd64, windows-amd64 and macos-universal; release skipped.

## VM shares: Check share and VM share setup… (v1.1.25)

- The user: "do we already support sharing data to local kvm hosts via virtio ?"
- Answer: yes, as a shared file system (mode A) set up by hand, with the steps in docs/TUTORIAL.md;
  the app neither creates nor checks the mount.
  Offered: a check that the remote prefix is mounted, and a helper that writes the libvirt XML and mount commands.
- The user: "add the mount check for remote_prefix and the settings helper".
  Hosts are set up in Add/Edit host, not in Settings, so both went into the host dialog, below *Remote prefix*.
- SPEC v1.35, new item F2c; app v1.1.25 (v1.1.24 was tagged).
- internal/sharecheck:
  - Check share runs a /bin/sh script over ssh:
    exists, writable, which mount holds the folder (findmnt, else df -P), its entries;
    Evaluate compares them with the local prefix and words each finding (OK, Warning, Problem).
  - VM share setup… (MakeGuide): virt-manager steps, libvirt XML, mount commands, fstab line;
    virtiofs or virtio-9p.
- Found while trying it on this machine's autofs NFS mount:
  findmnt lists the autofs trigger before the NFS mount on the same folder, so the script takes the last line.
- Tests: Go sharecheck (4 tests), vmshare.test.mjs, scripts/gui-smoke-sharecheck.sh (in make smoke-ui);
  gui-smoke-hosts run again, as the host dialog grew.
- Docs: SPEC F2c and package layout, PLAN v1.1.25, Tests.md, README (Usage, status, layout), TUTORIAL sections 4 and 7,
  CONNECTIVITY.

## CI of 3f1ae73 (v1.1.25, Check share and VM share setup…)

- Build run 44355005784 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.
- The Go tests ran on Windows too (TestScript skipped there, as planned).
- Artifacts expire on 2026-12-02.

## CI of tag v1.1.25

- The tag (annotated, 7db169d) points to 3f1ae73.
- Build run 44365677210 passed: linux-amd64, windows-amd64, macos-universal and release.
- The release has the 5 files: .deb, .rpm, the Linux tar.gz, the macOS zip and the Windows zip.
- Its notes list the 5 commits since v1.1.24 (scripts/changes.sh), then GitHub's Full Changelog link.

## Cross-check v1.1.25

- SPEC F2c against the code: the 60 s limit, 5000 entries a side, 5 names, the 36-character target name,
  the marks and words, disabled for plain logins, the values as typed: all as written.
- PLAN, Tests.md (Go, node and GUI rows), README, TUTORIAL and CONNECTIVITY name the feature.
- Out of date: the tutorial screenshot docs/tutorial/02-add-host.png lacked the two new buttons;
  taken again with `scripts/tutorial-shots.sh … first` (only 01 and 02; 01 came out the same).

## CI of af0ac4e (cross-check v1.1.25)

- Build run 44374793041 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.

## Settings and host dialogs: move and resize (v1.1.26)

- The user: "what happened with the settings popup resize and move ?"
- Found: it was never asked for. The only request (2026-11-02) was for the Dockerfile window,
  done in v1.1.2 with ui.js movable() and a CSS resize corner; the Services window got the same later.
  Settings, the host dialog and VM share setup… opened at a fixed size and place.
- The user: "yes add it to settings, host and vm share dialogs".
- main.js moveWindow() makes each movable once and pins it when it opens;
  style.css gives the three a resize corner and overflow scrolling.
- Found in testing:
  - VM share setup… was pinned before its contents were drawn, so it opened small, centred, and grew off the screen;
    it is now drawn first.
  - A max-height for the host dialog moved it by 3 px against the GUI tests; left out.
- Version 1.1.26 (v1.1.25 was tagged); SPEC v1.36 (§4.7).
- Tests: new scripts/gui-smoke-dialogs.sh (in make smoke-ui), passed twice;
  the GUI tests that click in these dialogs were run again.

## CI of 64d520b (v1.1.26, movable and resizable dialogs)

- Build run 44395217563 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.

## CI of tag v1.1.26

- The tag (annotated, eb728a8) points to 64d520b.
- Build run 44397939398 passed: linux-amd64, windows-amd64, macos-universal and release.
- The release has the 5 files; its notes list the 2 commits since v1.1.25, then GitHub's Full Changelog link.

## Cross-check v1.1.26

- SPEC §4.7 said "at least 80 px of it stays in the window"; ui.js place() keeps the top in the window
  and 80 px of the width and 40 px of the height showing. SPEC now says that.
- The tutorial screenshot docs/tutorial/30-settings.png was from v1.1.20: no What's new link (v1.1.24),
  no resize corner (v1.1.26). Taken again with `scripts/tutorial-shots.sh … main`; only that picture kept
  (the others of that step changed only in made-up data and were restored).
- ~/.claude.json changed during the screenshot run (checksum before and after).
  The script never touches it, the demo sessions start a shell (no claude), and it has no entries for the demo folders;
  the change is this Claude Code session's own bookkeeping.
- PLAN, Tests.md, README, TUTORIAL and the code otherwise agree.
- The user asked whether a cross-check should always come before a release.
- The user: "yes commit and save the rule". From now on: version commit, CI, cross-check (fixes stay in the
  untagged version), CI, then the tag. Saved in memory (crosscheck-before-release).

## CI of 2d5e982 (cross-check v1.1.26)

- Build run 44403006628 passed on the first attempt: linux-amd64, windows-amd64 and macos-universal; release skipped.

## Logo

- The user: "i added a logo file to tmp/ we can use that in the readme als later possibly in the settings"
  (read as "and later").
- tmp/image_9a8d16db.jpg (1408x768 JPEG, git-ignored folder): trimmed to the icon and name,
  24 px border in its background colour, 128 colours: docs/logo.png (629x475, 59 KB).
- README: the logo centred above the title, 320 px wide, with alt text; README layout names it.
- PLAN Next: the logo in Settings → About, possibly as the app icon.
  Its green name is below 4.5:1 on the light background; a logo is exempt, but in the app the name stays black text.
- Session start check (global rule): 3 releases (v1.1.24–v1.1.26), no artifacts older than 14 days: no cleanup needed.
