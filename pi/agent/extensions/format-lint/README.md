# format-lint

Format and lint the agent's edits automatically, then let the agent fix what it broke.

Lives at `~/.pi/agent/extensions/format-lint/index.ts`. Pi loads it on start, or with `/reload`.

## Why

You finish a coding turn and the diff has formatting drift and fresh lint warnings. Fixing that by hand is a context switch, and telling the agent to "now run the linter" is a wasted turn.

This extension closes that loop:

| Without it | With it |
|---|---|
| You run `mise run format` and `mise run lint` yourself after every turn | Runs automatically once the agent stops editing |
| You paste lint output back into the chat | Lint output is handed to the agent, which fixes it in the same run |
| Formatter reformats files the agent never touched | Only the edited files are passed to the tasks |

## Features

- **Runs after the agent is done, not mid-turn.** Fires at pi's `agent_before_settle` boundary, so it never fights an in-progress edit.
- **Format first, then lint.** Lint sees the formatted files.
- **Scoped to edited files.** Only paths touched by the `edit`/`write` tools are passed to the tasks.
- **Feeds lint failures back to the agent.** Failing output is injected as a message with one continuation, so the agent fixes it without a new prompt from you.
- **No mise tasks, no noise.** If the project has no local `format`/`lint` task, the extension does nothing.
- **Loop-safe.** Stops when lint output stops changing, and caps at 2 fix rounds.

## Prerequisites

- [mise](https://mise.jdx.dev/) on `PATH`.
- A formatter and linter you can run as mise tasks. The examples use [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) and [SwiftLint](https://github.com/realm/SwiftLint).

## Quick start

Add tasks named `format` and `lint` to your project's `mise.toml`:

```toml
[tools]
swiftformat = "0.61.1"
swiftlint = "0.63.1"

[tasks.format]
run = "swiftformat --swift-version 5.9"

[tasks.lint]
run = "swiftlint lint --strict --quiet"
```

That's it. No extension config file. Start pi in the project and edit some Swift.

The commands are hardcoded to `mise run format` and `mise run lint`. If either task is missing, it is skipped silently.

## Usage

1. You ask the agent to change some Swift.
2. The agent edits files with `edit` or `write`. The extension records those paths.
3. The agent stops. The extension detects local mise tasks, then runs `mise run format` and `mise run lint` with the edited paths.
4. Formatting is applied on disk.
5. If lint passes, you get a `format-lint: clean` notification and the run ends.
6. If lint fails, the agent receives the output and gets one more turn to fix it. Then format and lint run again.

Example: the agent writes `let a = 1`, SwiftLint's `identifier_name` rule fires, and this lands in the transcript:

```
The project formatter and linter ran after your edits (fix attempt 1 of 2).

Format (`mise run format -- Lint.swift`): no problems
[format] $ swiftformat --swift-version 5.9 Lint.swift
Running SwiftFormat...
SwiftFormat completed in 0s.
0/1 files formatted.

Lint (`mise run lint -- Lint.swift`): exit 2
/tmp/proj/Lint.swift:1:5: error: Identifier Name Violation: Variable name 'a' should be between 3 and 40 characters long (identifier_name)

[lint] $ swiftlint lint --strict --quiet Lint.swift
[lint] ERROR task failed

Fix the lint problems reported above, then stop. If a problem is pre-existing and unrelated to your changes, say so instead of fixing it.
```

The agent then renames `a` to `num`, the next lint pass is clean, and the run settles.

## Making a task accept a file list

Files are passed as positional arguments after `--`, for example:

```sh
mise run lint -- Sources/A.swift Sources/B.swift
```

mise appends those arguments to an inline command, so a plain task needs no changes:

```toml
[tasks.lint]
run = "swiftlint lint --strict --quiet"
```

For a shebang or file task, read them from `$@`:

```toml
[tasks.lint]
run = '''
#!/usr/bin/env bash
swiftlint lint --strict --quiet "$@"
'''
```

To validate the interface and get completions, declare a variadic `usage` arg. mise hands it over as `usage_files`:

```toml
[tasks.lint]
usage = 'arg "[files]" var=#true'
run = '''
#!/usr/bin/env bash
eval "files=(${usage_files?})"
swiftlint lint --strict --quiet "${files[@]}"
'''
```

If a task ignores its arguments, it still runs, just on the whole project instead of the edited files.

## Configuration

There is no extension config file. Behavior is fixed:

| Setting | Value | Notes |
|---|---|---|
| Format command | `mise run format -- <files>` | Skipped when no local `format` task exists |
| Lint command | `mise run lint -- <files>` | Skipped when no local `lint` task exists |
| Task detection | `mise tasks ls --local --name-only` | Runs once per agent run, only after edits |
| Tracked tools | `edit`, `write` | Files written through `bash` are not tracked |
| Max fix rounds | 2 | Prevents an endless lint/fix loop |
| Task timeout | 120s | Reports a timeout instead of continuing |
| Output cap | 3500 chars per task | Keeps the model context small |

Example SwiftLint config for a focused project:

```yaml
# .swiftlint.yml
only_rules:
  - identifier_name
  - force_cast
  - force_try
```

## Development

- Source: `index.ts`.
- Change behavior: edit the constants at the top of the file.
- Apply changes in a running session: `/reload`.
