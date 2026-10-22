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
# 1. On each computer, map tiers to real model IDs (see `pi --list-models`).
mkdir -p ~/.pi/agent/subagents
cat > ~/.pi/agent/subagents/models.json <<'EOF'
{
  "low": "openrouter/anthropic/claude-haiku-4.5",
  "medium": "openrouter/anthropic/claude-sonnet-4.5",
  "high": "openrouter/anthropic/claude-opus-4.8"
}
EOF

# 2. Create the agent once. The directory name is the agent name.
mkdir -p ~/.pi/agent/subagents/code-reviewer
cat > ~/.pi/agent/subagents/code-reviewer/settings.json <<'EOF'
{
  "model": "tier:medium",
  "thinking": "high",
  "tools": ["read", "bash", "grep", "find", "ls"]
}
EOF
cat > ~/.pi/agent/subagents/code-reviewer/SYSTEM.md <<'EOF'
You are a meticulous code reviewer. Return a prioritized list of concrete fixes.
EOF

# 3. Confirm it is discovered (no pi session needed).
agent --list
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
the agent name, so `code-reviewer/` is invoked as `/agent:code-reviewer`. Names
may contain letters, digits, `_`, `.`, and `-` only — no spaces or colons.

### Creating an agent

1. `mkdir ~/.pi/agent/subagents/<name>` — the name must match `[A-Za-z0-9_.-]+`.
2. Optionally add `settings.json` and/or `SYSTEM.md`. `SYSTEM.md` is plain Markdown — no frontmatter.
3. Verify with `agent --list` (or just run it).
4. Already inside pi? Run `/reload` so `/agent:<name>` appears.

An empty directory is a valid agent: it inherits pi's default model, thinking
level, tools, and system prompt (from your shared pi settings — not your
currently selected session model). Add files only to override.

For an agent that must not change files — a reviewer, say — restrict `tools` to
read-only ones, e.g. `"tools": ["read", "grep", "find", "ls"]`. Leave `edit`,
`write`, and `bash` out.

```bash
# Minimal agent — inherits everything, only adds a system prompt.
mkdir -p ~/.pi/agent/subagents/researcher
echo "You research topics and return concise, sourced summaries." > ~/.pi/agent/subagents/researcher/SYSTEM.md
```

To rename or remove an agent, rename or delete its directory and run `/reload`
inside pi.

| File | Required | Description |
|---|---|---|
| `settings.json` | No | Per-agent overrides. See fields below. Missing file = inherit everything. |
| `SYSTEM.md` | No | Replaces the subagent's system prompt (`--system-prompt`). Plain Markdown, no frontmatter. Missing = pi's default prompt. |

`settings.json` fields:

| Field | Required | Description |
|---|---|---|
| `model` | No | A concrete model ID (`openrouter/anthropic/claude-sonnet-4.5`), or `tier:<name>` to resolve from this computer's [tier map](#model-tiers-per-computer). Find IDs with `pi --list-models`. Default: pi's configured default model. |
| `provider` | No | Provider name, only needed when the model ID exists on multiple providers. |
| `thinking` | No | `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, or `max`. Default: pi's configured default level. |
| `tools` | No | Array (or comma-separated string) of tools the agent may use, e.g. `["read", "bash", "grep"]`. Default: pi's defaults. |

Unknown keys are ignored. Credentials (`~/.pi/agent/auth.json`) and custom model
endpoints (`~/.pi/agent/models.json`) are shared automatically — you never repeat
auth per agent.

Agents are real pi processes, so your installed packages, extensions, and global
settings apply to them too. A globally enabled extension that modifies prompts
(for example a caveman-mode extension) will also affect agent output.

### Model tiers (per computer)

Agent files are synced between machines, but the exact model you have access to
is not. Instead of hardcoding an ID in every agent, point the agent at a tier:

```json
{ "model": "tier:medium" }
```

and map tiers to real model IDs once per computer in
`~/.pi/agent/subagents/models.json`:

```json
{
  "low": "openrouter/anthropic/claude-haiku-4.5",
  "medium": "openrouter/anthropic/claude-sonnet-4.5",
  "high": "openrouter/anthropic/claude-opus-4.8"
}
```

Tier names are free-form — define whatever scale you like. A value without the
`tier:` prefix is used as a literal model ID. If an agent asks for a tier that is
not defined, the run fails with the list of available tiers.

This file is machine-specific, so keep it out of version control (this repo
already gitignores it). Both `agent` and `/agent:<name>` resolve tiers the same
way, because the extension runs the same CLI.

## Development

Design notes live in the header comment of [`index.ts`](./index.ts). No build
step; pi loads the TypeScript directly.
