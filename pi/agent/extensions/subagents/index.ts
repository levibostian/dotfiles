/**
 * Subagents — expose the standalone `agent` CLI as `/agent:<name> <task>`.
 *
 * Triggered only by the user typing `/agent:<name> <task>`. No tool is
 * registered, so the model can never spawn an agent on its own.
 *
 * The CLI (`cli/agent.mjs`) owns everything that composes and runs the headless
 * `pi --print` invocation; this extension only discovers agent names to register
 * commands, captures the CLI's stdout, and feeds the final message back into the
 * session. The CLI is usable directly as `agent <name> <task>`.
 */

import { existsSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI, ExtensionCommandContext, ExecResult } from "@earendil-works/pi-coding-agent";
import { getAgentDir } from "@earendil-works/pi-coding-agent";

const AGENT_DIR_NAME = "subagents";
const CLI_PATH = fileURLToPath(new URL("./cli/agent.mjs", import.meta.url));
const OUTPUT_CAP_BYTES = 50 * 1024;
const VALID_NAME = /^[\w.-]+$/;

function discoverAgentNames(): string[] {
  const root = join(getAgentDir(), AGENT_DIR_NAME);
  if (!existsSync(root)) return [];

  let entries;
  try {
    entries = readdirSync(root, { withFileTypes: true });
  } catch (error) {
    console.warn(`[subagents] cannot read ${root}: ${error instanceof Error ? error.message : String(error)}`);
    return [];
  }

  return entries
    .filter((entry) => (entry.isDirectory() || entry.isSymbolicLink()) && !entry.name.startsWith(".") && VALID_NAME.test(entry.name))
    .map((entry) => entry.name)
    .filter((name) => existsSync(join(root, name)))
    .sort();
}

function truncateOutput(text: string): string {
  const bytes = Buffer.byteLength(text, "utf8");
  if (bytes <= OUTPUT_CAP_BYTES) return text;

  let truncated = text.slice(0, OUTPUT_CAP_BYTES);
  while (Buffer.byteLength(truncated, "utf8") > OUTPUT_CAP_BYTES) truncated = truncated.slice(0, -1);
  const omitted = bytes - Buffer.byteLength(truncated, "utf8");
  return `${truncated}\n\n[Output truncated: ${omitted} bytes omitted]`;
}

function failureText(name: string, result: ExecResult): string {
  const stderr = result.stderr.trim();
  const stdout = result.stdout.trim();
  const reason = result.killed
    ? "killed"
    : result.code === 0
      ? "returned no output"
      : `exited with code ${result.code}`;
  const detail = stderr || stdout;
  return `[subagent "${name}" ${reason}]${detail ? `\n${truncateOutput(detail)}` : ""}`;
}

async function runAgent(pi: ExtensionAPI, ctx: ExtensionCommandContext, name: string, task: string): Promise<void> {
  ctx.ui.setStatus("subagent", `running ${name}…`);
  try {
    const result = await pi.exec(process.execPath, [CLI_PATH, name, task], {
      cwd: ctx.cwd,
      signal: ctx.signal,
    });
    const message = result.code === 0 && result.stdout.trim()
      ? `[subagent "${name}" output]\n${truncateOutput(result.stdout.trim())}`
      : failureText(name, result);
    // Idle → start a turn now; streaming → queue so the main model still sees it.
    if (ctx.isIdle()) pi.sendUserMessage(message);
    else pi.sendUserMessage(message, { deliverAs: "followUp" });
  } finally {
    ctx.ui.setStatus("subagent", undefined);
  }
}

export default function (pi: ExtensionAPI) {
  for (const name of discoverAgentNames()) {
    pi.registerCommand(`agent:${name}`, {
      description: `Delegate a task to the "${name}" subagent`,
      handler: async (args, ctx) => {
        const task = args.trim();
        if (!task) {
          ctx.ui.notify(`Usage: /agent:${name} <task>`, "warning");
          return;
        }
        ctx.ui.notify(`Running subagent "${name}"…`, "info");
        await runAgent(pi, ctx, name, task);
      },
    });
  }
}
