# startup

A single Go binary supervised by `launchd` (per-user LaunchAgent, no `sudo`)
that keeps long-running executables in `bins/` alive.

## Layout

```
~/.startup/
├─ startup        <- built binary (scripts in bins/, not this)
├─ bins/          <- only these children run
   ├─ db          <- executable, no extension -> child #1
   ├─ webapp      <- executable, no extension -> child #2
   └─ config.json <- has an extension -> asset, ignored
```

A child is any **executable** file in `bins/` whose name contains no `.`.
Files with a dot are assets and ignored. Children run with `bins/` as their
working directory.

Build it (`mise` manages Go unless configured otherwise):

```
go build -o startup .
```

## Usage

```
startup install      write + load the LaunchAgent, start now and at login
startup uninstall    unload + remove the plist
startup restart      tell the daemon to kill all children, rescan bins/, restart
startup status       print each child's live state
startup daemon       the launchd entry point (usually not run by hand)
```

`install` writes `~/Library/LaunchAgents/com.startup.plist` pointing at this
binary's absolute path, so install from wherever the binary will live. `db`
and `webapp` appear once the binaries are dropped into `bins/`.

## Behavior

- Every child is started at boot and restarted whenever it exits, any code.
- A child exiting in under 5s is a **fast-fail**; 10 in a row and the daemon
  **gives up** on it for the session/boot (breaks a loop on a corrupt binary).
  A run that lives ≥5s resets the counter. `restart` resets all counters.
- Children are independent — started alphabetically, no ordering/dependencies.
- Children run with `bins/` as their working directory and inherit the daemon's
  environment. launchd starts the daemon with a bare `PATH`, so the plist sets a
  predictable one (mise shims, `~/.local/bin`, homebrew, `/usr/bin`, …) — same
  approach as `~/.cronjobs/sync-jobs`. It's baked into the plist at `install`
  time; re-run `install` to refresh it and `unload`+`load` the LaunchAgent for
  launchd to re-spawn the daemon with the new PATH. `startup restart` won't apply
  a changed plist PATH — it only reloads `bins/`, and children get their
  environment at daemon spawn.
- Per-child log, stdout+stderr merged, truncated each run, at
  `/tmp/startup-<name>.log`.

## Control channel

The daemon owns a unix socket at `/tmp/startup.sock` (one-line commands:
`status` → JSON report, `restart` → all children reloaded). `startup status`
and `startup restart` talk to it. The socket is removed on clean shutdown and
any stale file at startup.

## Testing

Unit + integration tests cover the control plane and the supervisor loop:

```
go test -race ./...
```

Integration tests use a real manager + unix socket in a temp dir and shrink the
supervisor timings (`Config`) so fast-fail / give-up behaviour is observable in
milliseconds. `Config` defaults are the production values.

## Notes for future edits

Keep the supervisor loop in `daemon.go` (`Manager.reload` → `spawn` →
`supervise`). A child is killed by cancelling the per-run `context` that its
`exec.CommandContext` derives from, so a restart/shutdown goroutine never
pokes `*exec.Cmd` internals directly — keep it that way or you reintroduce a
data race.