# Subagents

Delegate work to a separate pi agent and bring back only the answer.

## Why

Some tasks want a clean, focused context — a code review, a research sweep, a
second opinion — and you don't want that whole exploration polluting your main
session (or your token bill). Today you'd either:

- paste a long prompt into your main session and keep all the tool noise forever, or
- open a second terminal, run `pi`, then copy the final answer back by hand.

This extension automates the second one. You define an agent once, trigger it
with a slash command, and its **final message alone** lands back in your session
as context. The main agent can then act on it.

## Features

- **Explicit trigger only** — nothing happens unless you type `/agent:<name>`. The model can never spawn an agent on its own.
- **Isolated context** — each run is a fresh headless `pi` process. Your main session only receives the final message.
- **Shared auth, per-agent model** — agents reuse your global credentials; each agent can still pick its own model, thinking level, and tools.
- **Main agent continues** — the result is added to your session and triggers a turn, so a review agent's findings can be applied immediately.
- **Also a standalone CLI** — `agent <name> "<task>"` runs the same agent from any terminal, no pi session needed.
- **Blocking** — the command waits for the agent to finish, then hands you the result. `Ctrl+C` stops it.

## Prerequisites

- [pi](https://pi.dev) installed and on your `PATH`.
- Model auth already configured (`pi auth check`, or `/login` inside pi).
- macOS, Linux, or any OS where pi runs.

## Quick start

```bash
mkdir -p ~/.pi/agent/subagents/code-reviewer
cat > ~/.pi/agent/subagents/code-reviewer/settings.json <<'EOF'
{
  "model": "provider/model-id",
  "thinking": "high",
  "tools": ["read", "bash", "grep", "find", "ls"]
}
EOF
echo "You are a meticulous code reviewer. Return a prioritized list of concrete fixes." \
  > ~/.pi/agent/subagents/code-reviewer/SYSTEM.md
```

Then in pi, run `/reload` and use it:

```
/agent:code-reviewer review src/auth.ts and list the concrete fixes
```

## Usage

1. Type `/agent:<name> <task>`, where `<name>` is a directory under `~/.pi/agent/subagents/`.
2. The agent runs headless in your current working directory with its own system prompt, model, and tools.
3. When it exits, its final message is added to your session and the main agent takes a turn on it.

```
> /agent:code-reviewer review src/auth.ts and list the concrete fixes

⠋ running code-reviewer…

✓ subagent "code-reviewer" output
  1. `validateToken` accepts expired tokens — expiry check uses `<` instead of `<=` (src/auth.ts:42).
  2. Missing null check on `session.user` before `.id` access (src/auth.ts:57).
  3. Token comparison is not constant-time; use `crypto.timingSafeEqual`.

> I'll fix those three now.
  …
```

Add a new agent directory, then run `/reload` to pick it up. Agents are discovered
at extension load, so an agent added while pi is running is not visible until then.

### From any terminal

The same agents run outside pi through the `agent` CLI (symlinked into
`~/.pi/agent/bin`):

```bash
cd ~/code/some-project
agent code-reviewer "review src/auth.ts and list the concrete fixes"
agent --list      # show available agents
agent --help      # full usage
```

It composes the identical headless `pi` invocation and prints the agent's final
message to stdout, so it pipes like any other command. Exit code matches the
subagent's.

## Configuration

Each agent is a directory under `~/.pi/agent/subagents/`. The directory name is
the agent name, so `code-reviewer/` is invoked as `/agent:code-reviewer`.

| File | Required | Description |
|---|---|---|
| `settings.json` | No | Per-agent overrides. See fields below. Missing file = inherit everything. |
| `SYSTEM.md` | No | Replaces the subagent's system prompt (`--system-prompt`). Missing = pi's default prompt. |

`settings.json` fields:

| Field | Required | Description |
|---|---|---|
| `model` | No | Model ID to run this agent with, e.g. `anthropic/claude-sonnet-4-5`. Default: your session's model. |
| `provider` | No | Provider name, only needed when the model ID exists on multiple providers. |
| `thinking` | No | `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, or `max`. Default: your session's level. |
| `tools` | No | Array (or comma-separated string) of tools the agent may use, e.g. `["read", "bash", "grep"]`. Default: pi's defaults. |

Unknown keys are ignored. Credentials (`~/.pi/agent/auth.json`) and custom model
endpoints (`~/.pi/agent/models.json`) are shared automatically — you never repeat
auth per agent.

## Development

Design notes live in the header comment of [`index.ts`](./index.ts). No build
step; pi loads the TypeScript directly.
