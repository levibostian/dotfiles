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

### Personal code style

This section defines some of my personal code style preferences. These are universal to all languages, but I may have additional preferences for specific languages (I put the lang in parentheses if it's language specific). These styles should be followed unless there is a good reason to deviate. If you are unsure, ask me.

I think that you can sum-up a lot of my personal code styles with: code should read like a book. You do not need to jump around the codebase to understand what is happening, the variable and function names should be descriptive and convey their purpose, and the code should be easy to read and understand.

- Avoid making constants for things that are only used once. If a value is only used in one place, it is better to just use the literal value instead of creating a constant for it. This helps to void developers from having to look up the value of the constant and makes the code easier to read.
- Avoid creating helper functions for things that are only used once. If a piece of code is only used in one place, it is better to just write it inline instead of creating a separate function for it. This helps to avoid the developer from having to jump around the codebase to understand what is happening. 
- I do not like making subclasses in object-oriented programming. Design patterns like Swift's protocol-oriented programming is preferred over subclassing. If you find yourself creating a subclass, consider if there is a better way to achieve the same functionality without creating a new class.
- Variable names should be descriptive and convey the purpose of the variable. Do not be afraid to be verbose with variable names if it helps to clarify their purpose. 
- Code comments a great way to explain "why" something is being done to remind yourself and others in the future. The code comments I do not like are ones that explain what is happening in the code such as: 

```swift
// Calculate the length of the string
let lengthOfString = str.count
```

In the above example, the variable name `lengthOfString` already conveys what is happening in the code, so the comment is unnecessary.

- I like to use guard statements. Langs like Swift has a `guard` keyword but other languages can `if ... return` instead. 
- (Swift, Kotlin) Use extensions over Util classes. 




