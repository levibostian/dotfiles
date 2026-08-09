# Startup Daemon — Plan

A single Go binary managed by `launchd` that supervises long-running executables in this directory. One daemon talks to `launchd`; everything else just needs to be a file in `bins/`.

## Layout

```
~/.startup/            <- this dir
├─ startup             <- built Go binary (this dir, NOT in bins/)
├─ go.mod, README
└─ bins/               <- only children run
   ├─ db               <- executable, no ext  → child #1
   ├─ webapp           <- executable, no ext  → child #2
   └─ config.json      <- has ext → asset, ignored
```

## Model

- Every child is a **long-running process**. Started at startup, kept running.
- If a child exits (any exit code), restart it.
- Children are fully independent. **No ordering/dependencies** — alphabetical start order; name files to enforce order if it ever matters.
- **Boot only** for auto-start. Adding/removing children at runtime is done via `restart` (below). No directory watching.

## CLI subcommands (one binary)

- `startup daemon` — the launchd entry point. Runs the supervisor loop.
- `startup install` — writes `~/Library/LaunchAgents/com.startup.plist` (template filled with this binary's absolute path) and `launchctl load`s it.
- `startup uninstall` — `launchctl unload` + remove plist.
- `startup restart` — tells the running daemon to kill all children, rescan `bins/`, and start them again.
- `startup status` — queries the daemon, prints child list + state.

## Control channel: unix socket

- Daemon listens on `/tmp/startup.sock` (unix socket, simpler than an HTTP server for a single-command control plane).
- CLI commands dial the socket and write one line; daemon reacts.
- Daemon removes a stale socket file at startup (a crashed daemon leaves one behind), and removes it on shutdown.

## Supervisor loop

```
bins/ files with no "." in name = children, alphabetical
for each child: spawn goroutine { for {
    start child        (exec directly, cwd = bins/, stdout+stderr merged → logfile)
    if exited fast (<5s) { fastFails++ } else { fastFails = 0 }
    if fastFails >= 10 { log "giving up on <name>"; return }   // dead for the session
    sleep 1s; retry
}}
```

## Restart policy

- Child exits in <5s = a **fast-fail**. Count it.
- 10 fast-fails in a row → **give up** for the session/boot: leave it dead, log once.
- Healthy long-running children never trip the counter (it resets when a run lives ≥5s).
- `restart` kills all children and restarts them, resetting all counters.

## Logging

- Per child: `/tmp/startup-<name>.log`.
- **Truncate** (overwrite) on each run.
- **Merged** stdout + stderr, with a restart-separator line between runs, so it reads like a terminal.

## launchd wiring

- Plist is a per-user `LaunchAgent` (no sudo): `RunAtLoad` = login, `KeepAlive` = true.
- `KeepAlive` means if the daemon crashes, launchd restarts it — which re-runs all children (relaunch is restart-in-effect).

## Open calls (decided default, can change)

1. **Give-up is permanent per session.** Daemon restart (via launchd) resets the fast-fail counter. Fixes a broken child only at next boot/daemon restart. Could switch to slow periodic retry with a one-line change.
2. **Binary builds into this dir root** named `startup`. Could live in `~/bin` instead.

## Scope

- Fully independent children only; no orchestration, no readiness checks, no dependency graph. If dependencies appear, revisit.
- No per-child operations (only restart-all). Simplicity over control.