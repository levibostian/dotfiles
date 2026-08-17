---
name: pr-monitor
description: Monitors GitHub PR status checks and notifies when complete. Use when the user wants to watch a PR's CI checks finish and get a desktop notification when done.
---

# PR Monitor

Monitors a GitHub pull request's status checks using `gh pr checks --watch`, then sends a desktop notification and opens the PR in the default browser.

## Usage

```bash
# Monitor a PR by URL
gh pr checks "https://github.com/owner/repo/pull/123" --watch

# When checks finish, notify:
~/.binnys/ghostty-notify "PR checks complete" "owner/repo #123" "https://github.com/owner/repo/pull/123"
```

## Workflow

1. Get the PR URL from the user or extract it from context
2. Run `gh pr checks "<url>" --watch` — this blocks until all status checks finish
3. On exit, send notification + open URL: `~/.binnys/ghostty-notify "PR checks complete" "<repo> #<pr-number>" "<pr-url>"`
4. Report the check results to the user (pass/fail summary)

## Details

- `gh pr checks --watch` blocks the agent until all checks finish. Exit code 0 = all passed, non-zero = some failed/timed out.
- Use the full PR URL or number. If number, `gh` auto-detects the repo from the current directory.
- The skill does NOT use `--fail-fast` — it waits for ALL checks to complete regardless of failures.
- The notification title includes "PR checks complete" and the body includes the repo + PR number for identification.

## Edge Cases

- **No checks configured**: `gh pr checks` exits immediately. Still send notification.
- **Repo not in CWD**: Always use full URL to avoid repo detection issues. If only a number is given and CWD is wrong, `gh` will error.
- **Long-running checks**: The `--watch` default interval is 10s. Set `--interval <secs>` for slower/faster polling if needed.
- **Tool timeout**: If the agent's tool has a timeout, run in background with `nohup` or use `--watch` inside a subcommand that daemonizes (rarely needed with typical timeouts).