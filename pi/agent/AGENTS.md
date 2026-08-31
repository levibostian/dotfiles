<!-- After edits to file, open agent in ~/.pi/agent/ dir and prompt "caveman compress @AGENTS.md"  -->
- Fetching URLs:
  - If URL host is `github.com` (or GitHub raw/content URLs), ALWAYS use `gh` CLI.
    - Example (file): `gh api repos/{owner}/{repo}/contents/{path}?ref={sha}`
    - Example (PR/issue): `gh pr view ...`, `gh issue view ...`
  - For non-GitHub URLs, use:
    `curl -sSL https://markdown.new/<url>`
- Running a command to run tests? Prefix with `rtk test`. Example: if going to run `deno task test`, use `rtk test deno task test` instead. 
- Running a command to lint? Prefix with `rtk err`. Example: if going to run `deno lint`, use `rtk err deno lint` instead. 
- Running a command to format? Prefix with `rtk err`. Example: if going to run `deno fmt`, use `rtk err deno fmt` instead. 
- After change, run formatter/linter/tests (if told commands), fix all errors
- After change, run scoped tests (if told commands), fix all errors
- Preserve existing comments. Only delete if they're outdated or wrong. Even comments that explain what the code does should be kept when they're already in the file — they were put there intentionally and changing them without cause is noise.

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

### Personal code style (enforced)

Code should read like a book. Reader should understand flow without jumping across files.

#### Priority
- Correctness, security, and explicit user requirements override style.
- If style tradeoff is unclear, ask one clarifying question before coding.

#### MUST
- Use descriptive variable/function/type names. Be verbose when clarity improves.
- Inline single-use values and single-use helpers in local scope.
- Prefer guard-style flow (`guard` / `if ... return`) over nested conditionals.
- Keep feature-specific rules near feature code (for example route/service), unless rule is reused across multiple flows.
- Use functional chains when callbacks stay simple and final result name stays clear.
- Add comments for product/business policy and non-obvious technical tradeoffs.
- Rewrite existing comments only when touching same lines and comment is outdated/wrong.
- For Swift/Kotlin, prefer extensions over util classes.

#### MUST NOT
- Do not create subclasses unless user explicitly asks or no practical alternative exists.
- Do not add global single-use constants.
- Do not force one default timeout/retry policy in global/shared clients; caller should choose.

#### DEFAULTS
- For low-probability infrastructure failures, avoid heavy boilerplate error handling.
- For realistic runtime failures (for example hardware/bluetooth/external instability), use typed errors so callers can branch if needed.
- Private class single-use constants are allowed when readability improves.
- If literal repeats 2+ times in same scope, extract it.
- Keep functional chains unless result intent becomes unclear.

#### Risky changes: ask before direct ship
For auth/permissions, payments/billing, DB migration/data deletion, external API behavior changes, or core user workflow changes, ask whether to use feature flag/canary vs direct replace.

#### Style gate (required before final response)
Before sending final answer, run checklist and fix violations:
1. One-use local constant/helper added? Inline unless private-class readability case.
2. Any vague names or unclear result names? Rename descriptively.
3. Any avoidable nesting? Use guard/early return.
4. Any new policy/tradeoff without comment? Add one concise why-comment.
5. Any subclass or global default timeout/retry policy added? Replace unless explicitly required.
6. Any risky change category touched? Ask rollout strategy first.

#### Examples (bad → good)

- Inline single-use helper
```ts
// bad
function isAllowed(user: User) {
  return user.emailVerified && user.role === "admin"
}
if (!isAllowed(user)) return forbidden()

// good
if (!(user.emailVerified && user.role === "admin")) return forbidden()
```

- Clear result naming in functional style
```ts
// bad
const x = users.filter((user) => user.emailVerified).map((user) => user.id)

// good
const verifiedUserIds = users
  .filter((user) => user.emailVerified)
  .map((user) => user.id)
```

- Comment policy/tradeoff, not line narration
```ts
// bad
// increment retry count
retryCount++

// good
// Backoff protects upstream rate limits during incident traffic spikes.
retryCount++
```

- Caller-owned retry/timeout in shared client
```ts
// bad (global default hidden in shared client)
await paymentClient.charge(request)

// good (caller explicit)
await paymentClient.charge(request, { timeoutMs: 3000, retries: 1 })
```

