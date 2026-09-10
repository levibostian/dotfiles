<!-- After edits to file, open agent in ~/.pi/agent/ dir and prompt "caveman compress @AGENTS.md"  -->
- Fetching URLs:

## Core ops
- GitHub URLs: use `gh` CLI only.
  - File: `gh api repos/{owner}/{repo}/contents/{path}?ref={sha}`
  - PR/issue: `gh pr view ...`, `gh issue view ...`
- Non-GitHub URLs: `curl -sSL https://markdown.new/<url>`
- Test command: prefix with `rtk test`
- Lint command: prefix with `rtk err`
- Format command: prefix with `rtk err`
- After change: run requested formatter/linter/tests, fix all errors.
- Preserve existing comments unless outdated/wrong.

<!-- From: https://github.com/multica-ai/andrej-karpathy-skills/blob/main/skills/karpathy-guidelines/SKILL.md -->
## Engineering behavior
- Think before coding. No assumptions. State tradeoffs. Ask when unclear.
- Simplicity first. Minimum code. No speculative abstractions.
- Surgical changes only. No unrelated refactor.
- Goal-driven: define success, verify before done.
<!-- karpathy -->

<!-- context-mode -->
## Context-mode (strict)
Default: use context-mode for exploration/analysis/recall.

### Priority (must follow)
1. `ctx_batch_execute`
2. `ctx_execute`
3. `ctx_execute_file`
4. `ctx_search`

### Routing
- File analysis (no edits): `ctx_execute_file`
- 2+ commands / research: `ctx_batch_execute`
- Parse/filter/count/derive: `ctx_execute`
- Web docs/pages: `ctx_fetch_and_index` then `ctx_search`
- Index local docs/specs: `ctx_index`
- Recall prior decisions/errors/docs: `ctx_search`
- Session savings: `ctx_stats`
- Diagnostics: `ctx_doctor`
- Upgrade: `ctx_upgrade`
- Purge memory: `ctx_purge` (confirm + explicit scope)

### Native tool guardrail
- Use `read`/`bash` only for exact edit targeting or one short observational command.
- No repeated read/grep/bash loops when context-mode can answer in one call.

### Failure fallback
1. Retry once with simpler context-mode call.
2. Then fallback native tool.
3. Note why fallback needed.
<!-- context-mode -->

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

## Personal code style
### Priority
- Correctness/security/user requirements override style.
- If style tradeoff unclear, ask one clarifying question.

### MUST
- Descriptive names.
- Inline one-use local constants/helpers.
- Prefer guard/early return over nesting.
- Keep feature rules near feature code unless reused.
- Functional chains fine when clear.
- Comment business policy/tradeoffs.
- Update existing comments only when wrong/outdated in touched lines.
- Swift/Kotlin: prefer extensions over util classes.

### MUST NOT
- No subclass unless explicitly requested or no practical alternative.
- No global single-use constants.
- No hidden global default timeout/retry in shared clients.

### DEFAULTS
- Skip heavy boilerplate for low-probability infra failures.
- Use typed errors for realistic runtime instability.
- Private class constants allowed when readability improves.
- If literal repeats 2+ times in same scope, extract.

### Risky changes
For auth/permissions, payments, DB migration/deletion, external API behavior, core workflow changes: ask rollout strategy (feature flag/canary vs direct).

### Style gate before final response
1. Inline one-use helper/constant unless private-class readability case.
2. Rename vague names.
3. Remove avoidable nesting.
4. Add concise why-comment for new policy/tradeoff.
5. Avoid subclass/global timeout-retry default unless required.
6. If risky category touched, ask rollout strategy.
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

