<!-- After edits to file, open agent in ~/.pi/agent/ dir and prompt "caveman compress @AGENTS.md"  -->
- GitHub? Use `gh` CLI
- After change, run formatter/linter/tests (if told commands), fix all errors
- After change, run scoped tests (if told commands), fix all errors

<!-- From: https://github.com/multica-ai/andrej-karpathy-skills/blob/main/skills/karpathy-guidelines/SKILL.md -->
- **Think Before Coding** — No assume. Surface tradeoffs. State assumptions. If uncertain, ask. If simpler approach exists, say so. Push back. If unclear, stop & name confusion.
- **Simplicity First** — Min code. Nothing speculative. No features beyond what asked. No abstractions for single-use code. No flexibility/config not requested. No error handling for impossible scenarios. If 200 lines could be 50, rewrite. Ask: "Would senior engineer say overcomplicated?"
- **Surgical Changes** — Touch only what must. Clean up own mess. No "improve" adjacent code. No refactor what not broken. Match existing style. Unrelated dead code = mention, don't delete. When change creates orphans: remove imports/vars/fns YOUR change made unused. Don't touch pre-existing dead code.
- **Goal-Driven Execution** — Define success criteria. Loop till verified.
  "Add validation" → "Write tests for invalid inputs, make them pass"
  "Fix bug" → "Write test that reproduces it, make it pass"
  Multi-step: brief plan then `1. [step] → verify: [check]`
<!-- karpathy -->

<!-- context7 -->
Use `ctx7` CLI for library/framework/SDK/API/CLI/cloud docs — even well-known ones (React, Next.js, Prisma, etc.). Includes API syntax, config, migration, lib-specific debug, setup, CLI usage. Use even when you think you know. Prefer over web search.

Don't use for: refactoring, scripts from scratch, biz logic debug, code review, general concepts.

1. Resolve: `npx ctx7@latest library <name> "<full question>"`
2. Pick best match (ID: `/org/project`) by: name match, description, snippet count, source rep (High/Med preferred), benchmark score
3. Fetch: `npx ctx7@latest docs <libraryId> "<full question>"`
4. Answer from docs.

Must call `library` first unless user gives `/org/project` ID. Use full question as query — specific > vague. Max 3 commands per question. No sensitive info in queries.

Version-specific: use `/org/project/version` (e.g., `/vercel/next.js/v14.3.0`).

Quota error? Tell user: `npx ctx7@latest login` or set `CONTEXT7_API_KEY`. Don't silently fallback.
<!-- context7 -->

### Docs style

Write docs at **implementation-facing clarity** level.

Must include:
- Purpose + layer boundary
- Responsibilities
- Non-goals
- Design guardrail (“put X here, Y elsewhere”)
- Typical usage flow (ordered steps)
- Maintenance note for future edits

Style:
- concise but complete
- bullet-first, short paragraphs
- concrete examples, no vague wording
- enough context for a new engineer to change code safely
