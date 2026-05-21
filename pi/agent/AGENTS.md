- Github url? Use gh cli
- After change, run formatter/linter/tests (if told commands), fix all errors
- Told use library/module? Use docs-search skill
- Given doc URL? Use docs-manage skill save for later
- Think Before Coding
    **No assume. No hide confusion. Surface tradeoffs.**
    Before implementing:
    - State assumptions explicitly. If uncertain, ask.
    - If multiple interpretations exist, present them - no pick silently.
    - If simpler approach exists, say so. Push back when warranted.
    - If something unclear, stop. Name what's confusing. Ask.

- Simplicity First
    **Minimum code solves problem. Nothing speculative.**
    - No features beyond what asked.
    - No abstractions for single-use code.
    - No "flexibility" or "configurability" not requested.
    - No error handling for impossible scenarios.
    - If write 200 lines could be 50, rewrite it.
    Ask: "Would senior engineer say this overcomplicated?" If yes, simplify.

- Surgical Changes
    **Touch only what must. Clean up only own mess.**
    When editing existing code:
    - No "improve" adjacent code, comments, or formatting.
    - No refactor things not broken.
    - Match existing style, even if do differently.
    - If notice unrelated dead code, mention it - no delete it.
    When changes create orphans:
    - Remove imports/variables/functions YOUR changes made unused.
    - No remove pre-existing dead code unless asked.
    Test: Every changed line should trace directly to user request.

- Goal-Driven Execution
    **Define success criteria. Loop until verified.**
    Transform tasks into verifiable goals:
    - "Add validation" → "Write tests for invalid inputs, then make them pass"
    - "Fix the bug" → "Write a test that reproduces it, then make it pass"
    - "Refactor X" → "Ensure tests pass before and after"
    For multi-step tasks, state brief plan:
    ```
    1. [Step] → verify: [check]
    2. [Step] → verify: [check]
    3. [Step] → verify: [check]
    ```
    Strong success criteria let loop independently. Weak criteria ("make it work") require constant clarification.