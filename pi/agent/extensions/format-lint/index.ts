/**
 * Purpose: Run the project's `mise run format` and `mise run lint` tasks after the
 * agent finishes editing files, then hand failing lint output back to the agent so it
 * can fix what it caused.
 * Responsibilities: Collect the paths the agent edited, detect which local mise tasks
 * exist, run format then lint on only those paths once per settle, feed failing lint
 * output back as a custom message with one continuation, and stop when output stops
 * changing or the attempt cap is reached.
 * Non-goals: Committing, staging, or auto-fixing lint output; running mid-turn; parsing
 * linter-specific output formats; tracking edits made through bash.
 * Design guardrail: The task names are fixed here; the project owns what the tasks do.
 * Files reach the tasks as positional arguments after `--`, so a task must consume
 * `$@` (or a `usage` variadic arg) to scope itself to the changed files.
 * Maintenance note: An unconditional `continue: true` loops forever. Keep the
 * fingerprint comparison and the attempt cap when changing the settle handler.
 */
import { isAbsolute, normalize, relative } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const MISE = "mise";
const FORMAT_TASK = "format";
const LINT_TASK = "lint";
const MAX_FIX_ATTEMPTS = 2;
const TASK_TIMEOUT_MS = 120_000;
const DETECT_TIMEOUT_MS = 10_000;
const MAX_OUTPUT_CHARS = 3_500;

interface CommandRun {
  label: string;
  command: string[];
  stdout: string;
  stderr: string;
  code: number;
  killed: boolean;
}

interface RunState {
  editedFiles: Set<string>;
  fixAttempts: number;
  /** Raw format+lint output already shown to the agent; identical output means no progress. */
  lastFingerprint: string | null;
  /** Local mise task names for this run, detected lazily; null means not checked yet. */
  availableTasks: Set<string> | null;
}

function toProjectRelative(cwd: string, path: string): string {
  return normalize(isAbsolute(path) ? relative(cwd, path) : path);
}

async function detectLocalTasks(pi: ExtensionAPI, cwd: string): Promise<Set<string>> {
  const result = await pi.exec(MISE, ["tasks", "ls", "--local", "--name-only"], { cwd, timeout: DETECT_TIMEOUT_MS });
  if (result.code !== 0) return new Set();
  return new Set(
    result.stdout
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean),
  );
}

function truncate(text: string, limit: number): string {
  if (text.length <= limit) return text;
  return `${text.slice(0, limit)}\n… [truncated ${text.length - limit} chars]`;
}

function renderCommand(run: CommandRun): string {
  const status = run.killed ? "timed out" : run.code === 0 ? "no problems" : `exit ${run.code}`;
  const output = truncate([run.stdout, run.stderr].filter((part) => part.trim()).join("\n").trim(), MAX_OUTPUT_CHARS);
  const header = `${run.label} (\`${run.command.join(" ")}\`): ${status}`;
  return output ? `${header}\n${output}` : header;
}

function renderReport(format: CommandRun | undefined, lint: CommandRun, attempt: number, maxAttempts: number): string {
  const lines = [`The project formatter and linter ran after your edits (fix attempt ${attempt} of ${maxAttempts}).`, ""];
  if (format) lines.push(renderCommand(format), "");
  lines.push(renderCommand(lint), "");
  lines.push(
    "Fix the lint problems reported above, then stop. If a problem is pre-existing and unrelated to your changes, say so instead of fixing it.",
  );
  return lines.join("\n");
}

async function runMiseTask(
  pi: ExtensionAPI,
  label: string,
  task: string,
  files: string[],
  ctx: ExtensionContext,
): Promise<CommandRun> {
  // `--` keeps file paths that start with `-` from being read as mise flags.
  const args = ["run", task, "--", ...files];
  const result = await pi.exec(MISE, args, { cwd: ctx.cwd, timeout: TASK_TIMEOUT_MS, signal: ctx.signal });
  return { label, command: [MISE, ...args], stdout: result.stdout, stderr: result.stderr, code: result.code, killed: result.killed };
}

export default function (pi: ExtensionAPI) {
  const state: RunState = {
    editedFiles: new Set(),
    fixAttempts: 0,
    lastFingerprint: null,
    availableTasks: null,
  };

  pi.on("before_agent_start", async () => {
    // A new run resets edit tracking and the fix-attempt budget. Continuations from
    // this extension do not fire this event, so the budget survives fix rounds.
    state.editedFiles = new Set();
    state.fixAttempts = 0;
    state.lastFingerprint = null;
    state.availableTasks = null;
  });

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "edit" && event.toolName !== "write") return;
    const path = (event.input as { path?: unknown }).path;
    if (typeof path === "string" && path !== "") state.editedFiles.add(toProjectRelative(ctx.cwd, path));
  });

  pi.on("agent_before_settle", async (_event, ctx) => {
    if (state.editedFiles.size === 0) return;

    if (state.availableTasks === null) {
      state.availableTasks = await detectLocalTasks(pi, ctx.cwd);
    }
    const hasFormat = state.availableTasks.has(FORMAT_TASK);
    const hasLint = state.availableTasks.has(LINT_TASK);
    // No matching task in this project: stay silent rather than nag on every run.
    if (!hasFormat && !hasLint) return;

    if (state.fixAttempts >= MAX_FIX_ATTEMPTS) {
      ctx.ui.notify(`format-lint: still failing after ${state.fixAttempts} fix attempt(s); stopping`, "warning");
      return;
    }

    const files = [...state.editedFiles].sort();
    const format = hasFormat ? await runMiseTask(pi, "Format", FORMAT_TASK, files, ctx) : undefined;
    const lint = hasLint ? await runMiseTask(pi, "Lint", LINT_TASK, files, ctx) : undefined;

    const formatFailed = format !== undefined && format.code !== 0;
    const lintFailed = lint !== undefined && lint.code !== 0;
    const lintOutput = lint ? `${lint.stdout}${lint.stderr}`.trim() : "";

    // A killed process reports code 0, so check timeouts before exit codes.
    if (format?.killed || lint?.killed) {
      const which = lint?.killed ? "lint" : "formatter";
      ctx.ui.notify(`format-lint: ${which} timed out after ${TASK_TIMEOUT_MS}ms`, "warning");
      return;
    }
    if (!lintFailed) {
      ctx.ui.notify(formatFailed ? "format-lint: formatter failed; see output" : "format-lint: clean", formatFailed ? "warning" : "info");
      return;
    }
    if (lintOutput === "") {
      // Exit != 0 with no output is usually a broken task, not a lint finding.
      ctx.ui.notify(`format-lint: lint task exited ${lint.code} with no output`, "error");
      return;
    }

    const fingerprint = `${format ? renderCommand(format) : ""}\n${renderCommand(lint)}`;
    if (fingerprint === state.lastFingerprint) {
      ctx.ui.notify("format-lint: no new lint output; stopping", "warning");
      return;
    }

    state.fixAttempts += 1;
    state.lastFingerprint = fingerprint;
    ctx.ui.notify(`format-lint: lint failed; asking agent to fix (attempt ${state.fixAttempts}/${MAX_FIX_ATTEMPTS})`, "warning");

    return {
      entries: [
        {
          type: "custom_message",
          customType: "format-lint",
          content: renderReport(format, lint, state.fixAttempts, MAX_FIX_ATTEMPTS),
          display: true,
        },
      ],
      continue: true,
    };
  });
}
