---
name: readme-style
disable-model-invocation: true
description: >
  User's preferred README style. User-first, value-first, implementation
  details go in docs/DEVELOPMENT.md. Use when the user asks to create a
  README or write a README file.
---

# README style

READMEs are user-facing, not contributor-facing. Implementation details
(file structure, module list, architecture) go in `docs/DEVELOPMENT.md`.
README sells the tool and shows how to use it.

## Structure (in order)

### 1. Elevator pitch
One-line summary of what it does and why it exists.

> "Ship PRs faster. One agent session per fix, one branch at a time."

Not "X is a tool for..." — punchy, benefit-first.

### 2. Why
The pain point or repetitive workflow it solves. Concrete bullet list of
what the user does manually today vs what the tool automates. Makes the
value proposition immediately clear.

### 3. Features
Bullet list of capabilities, each one a short phrase + brief explainer.
No technical implementation detail.

### 4. Prerequisites
Quick checklist of what the user needs installed. Links to install pages.

### 5. Quick start
Minimal copy-paste to get running. Config file template inline via heredoc,
then the run command. No more than ~15 lines.

### 6. Usage
Walk through what happens when you run it. Include an example of the output
(a terminal session or status panel) so the user knows what to expect before
they run it. Numbered steps for the flow.

### 7. Configuration
Reference table. Field, required/optional, description. No YAML tutorial,
just the schema.

### 8. Development
Just the task commands (check, test, start/run) with a link to
`docs/DEVELOPMENT.md`. Three lines max.

## Style rules

- Start with one punchy line. Not "X is a tool for..." — "Ship PRs faster."
- "Why" before "What". Sell the problem solved before describing the
  solution.
- Example output (terminal blocks, config snippets) so users recognize the
  tool when they run it.
- Tables for config schemas. Bullets for features.
- No file structure, no module responsibilities, no architecture diagrams,
  no design patterns in README. Those go in DEVELOPMENT.md and the README
  has one link to it.