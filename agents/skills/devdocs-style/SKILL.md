---
name: devdocs-style
disable-model-invocation: true
description: >
  User's preferred DEVELOPMENT.md style. Implementation-facing, design-decision
  focused. Only what code can't tell you. Use when the user asks to create or
  write a DEVELOPMENT.md file.
---

# DEVELOPMENT.md style

DEVELOPMENT.md is for contributors, not users. It documents things the source
code cannot express on its own. If the information is trivially recoverable
from the source tree (ls, cat), it has no business here.

The file should be short — if it's longer than the README, delete half of it.

## Sections (keep order, drop any that don't apply)

### 1. Architecture

A high-level diagram (ASCII art or Mermaid) showing the system boundaries
and data flow. Purpose: a new contributor can trace a request through the
system in one glance.

No component descriptions, no list of modules. The diagram is the description.

If proxying/layering/adapting an external service (webhook receiver, SDK
wrapper, reverse proxy), show the external boundary clearly.

### 2. Data flow

Numbered steps tracing one complete end-to-end run. Concrete: which function
runs when, what it does in one phrase. This is the executable spec.

No prose paragraphs between steps — each step is `{trigger} → {action},
{action}` on one line.

### 3. Key design decisions

This is the most important section. Each decision is a short heading + 2-3
sentences explaining WHY, not WHAT.

Include decisions that:
- Look wrong at first glance but are correct (e.g., raw fetch over SDK)
- Would rot if not documented (e.g., intentional edge case handling)
- Are easy to accidentally undo (e.g., lazy import to avoid load error)
- Have no visible trace in code (e.g., "we don't use a queue because...")

Omit decisions that:
- Are standard practice (e.g., "we use HTTPS") — no value
- Are obvious from the code (e.g., "the config is read from env vars")

### 4. Maintenance

Bullet list of what future editors need to know:
- Pinned dependency versions with upgrade risk notes
- Deliberate behaviors that look like bugs (e.g., skipping subdirs in a
  directory scan)
- External API contracts that could break silently
- `ponytail:` shortcuts with their ceiling + upgrade path

## Rules

- No source file content that lives in its own file. No copy/pasted
  `Dockerfile`, `deno.json`, `compose.yaml`, `Makefile`, config files, etc.
  Reference them by path if needed: "see `Dockerfile`".
- No env vars table. That belongs in README (user-facing configuration).
- No "Running locally" section. That belongs in README (user-facing).
- No source file table. `ls src/` is always fresher. If a module has a
  non-obvious responsibility, mention it inline in a design decision.
- One sentence per data flow step. No prose paragraphs.
- Architecture diagram must be the first thing after the heading. No preamble.
- If the file takes more than 60 seconds to read, it's too long.
- Delete over add. Every line should answer "would a new contributor be
  confused without this line?" If no, delete it.