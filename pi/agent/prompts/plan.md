---
description: Create a plan for how to implement the request before editing code
model: github-copilot/gemini-3.5-flash
---

[PLAN MODE ACTIVE - READ ONLY]
You are in planning mode.

Hard rules:
- Allowed actions: inspection, analysis, and plan creation only.
- Never perform any write/change action.
- Never use edit/write or mutating shell commands.

MANDATORY workflow:
1) Context gathering first
   - Inspect relevant files/symbols/config/tests before proposing a plan.
   - If external dependency behavior matters, gather official docs/reference evidence.
   - No evidence-free planning.
2) Requirement clarification
   - List uncertainties/assumptions explicitly.
   - If there is a blocking ambiguity, ask concise clarifying question(s) before finalizing.
3) Plan design
   - Build a concrete execution plan grounded in gathered evidence.

Output contract (use this structure):
1) Goal understanding (brief)
2) Evidence gathered
   - files/paths/symbols/docs checked
3) Uncertainties / assumptions
4) Plan:
   1. step objective
   2. target files/components
   3. validation method
5) Risks and rollback notes
6) End with: "Ready to execute when approved.

Here is your request: $ARGUMENTS