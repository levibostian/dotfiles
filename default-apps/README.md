# default-apps

File associations for this Mac, declared once and re-applied when something changes them.

`dutis.toml` lists which app opens which extension. `./default-apps-sync` compares that file
with the real Launch Services state and fixes whatever drifted. Run it by hand after editing
the file, or let the daily cron job do it.

## Usage

```bash
~/.default-apps/default-apps-sync            # apply drift, if any
~/.default-apps/default-apps-sync --dry-run  # show what would change
dutis plan ~/.default-apps/dutis.toml        # full plan, including unchanged entries
```

Run `~/.cronjobs/sync-jobs` after editing `~/.cronjobs/jobs-list` to (re)install the cron entry.

## What it does when it runs

| State | Script output | Notification |
| --- | --- | --- |
| Everything matches `dutis.toml` | `in sync, nothing to do` | none |
| Drift, all entries fixable | `fixed N association(s)` | "Default apps updated" |
| Drift it cannot fix, or a target app is missing | reason on stderr, exit 1 | "Default apps sync needs attention" |

Silence when converged is the point: the cron job can run daily without interrupting anything,
and a notification means something actually changed on the machine.

## Why a declarative file

- Reinstalling macOS, or setting up a second Mac, is one command instead of clicking through
  Finder's "Always Open With" for every file type.
- Apps quietly re-claim file types on install/update (VS Code did this for ~130 extensions).
  The file plus the daily check undoes that.
- The file is reviewable in git, so a change to your defaults is a diff, not a mystery.

## Known limitations

- **Most of these extensions cannot be written by `dutis`/`duti`.** VS Code registered its own
  dynamic UTIs for them, and `duti` gets `error -50` from Launch Services when asked to change
  those (`failed to set dev.zed.Zed as handler for dyn.ah62... (error -50)`). They are currently
  pinned by filename-extension tag entries in the Launch Services plist, which is why the sync
  reports `in sync`. If they ever drift, the script tells you instead of fixing it; repair by hand
  with `utiluti ext set <extension> dev.zed.Zed` (or re-import the tag entries into
  `~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist` and run
  `killall lsd`).
- **Verification lags.** Launch Services keeps serving the old handler for a few seconds after a
  write, so `dutis apply` can report a failure for a change that did land. The script retries and
  re-checks the state, so a real fix is not reported as a failure and does not fail the cron run.
- **`.fs` is excluded.** Xcode ships the GLSL fragment-shader UTI for it while VS Code registers
  its own type, and `duti` and Launch Services disagree on the read-back, so `dutis` can never
  verify a change there.
- **`.zip`, `.tar`, `.gz` are excluded.** Archive Utility lives outside the directories `dutis`
  scans, so it cannot be referenced by path or bundle ID; it is the macOS default anyway.

## Files

- `dutis.toml` — the declared associations (schema version 2, see
  https://tsonglew.github.io/dutis/).
- `default-apps-sync` — check and apply script, safe for cron.

Requires `dutis` and `jq` (both in `~/homebrew/Brewfile`).
