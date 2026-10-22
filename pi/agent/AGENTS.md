<!-- After edits to file, open agent in ~/.pi/agent/ dir and prompt "caveman compress @AGENTS.md"  -->
- Fetching URLs:

## Core ops
- GitHub URLs: use `gh` CLI only.
  - File: `gh api repos/{owner}/{repo}/contents/{path}?ref={sha}`
  - PR/issue: `gh pr view ...`, `gh issue view ...`
- Non-GitHub URLs: `curl -sSL https://markdown.new/<url>`
- Preserve existing comments unless outdated/wrong.

<!-- From: https://github.com/multica-ai/andrej-karpathy-skills/blob/main/skills/karpathy-guidelines/SKILL.md -->
## Engineering behavior
- Think before coding. No assumptions. State tradeoffs. Ask when unclear.
- Simplicity first. Minimum code. No speculative abstractions.
- Surgical changes only. No unrelated refactor.
- Goal-driven: define success, verify before done.
<!-- karpathy -->

<!-- context7 -->
## ctx7 docs policy
Use ctx7 for library/framework/SDK/API/CLI/cloud docs (even common libs).

Do not use ctx7 for: refactor-from-scratch, business logic debug, general concepts.

Flow:
1. `npx ctx7@latest library <name> "<full question>"`
2. Choose best `/org/project` (or versioned `/org/project/vX.Y.Z`)
3. `npx ctx7@latest docs <libraryId> "<full question>"`
4. Answer from docs.

Rules:
- Must run `library` first unless ID already provided.
- Max 3 commands per question.
- No sensitive data in query.
- Quota error: tell user `npx ctx7@latest login` or set `CONTEXT7_API_KEY`.
<!-- context7 -->

## Docs style
Must include:
- Purpose + layer boundary
- Responsibilities
- Non-goals
- Design guardrail (what belongs here vs elsewhere)
- Typical usage flow (ordered)
- Maintenance note

Style: concise, concrete, implementation-facing.

