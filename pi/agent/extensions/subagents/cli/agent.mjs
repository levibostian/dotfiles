#!/usr/bin/env node
/**
 * agent — run a pi subagent from any terminal.
 *
 *   agent <name> <task...>
 *   agent --list
 *
 * A subagent is a directory under `<agent-dir>/subagents/<name>/` with an
 * optional `settings.json` and an optional `SYSTEM.md`. This is the single
 * runner: it composes the `pi --print` invocation and streams the agent's final
 * message to stdout. The pi extension shells out to this same CLI.
 */

import { spawn } from "node:child_process";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const AGENT_DIR_NAME = "subagents";
const VALID_NAME = /^[\w.-]+$/;

const agentDir = process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent");
const agentsRoot = join(agentDir, AGENT_DIR_NAME);
// Per-computer tier map: { "low": "provider/model", "medium": ..., "high": ... }.
// Machine-specific on purpose, so it is gitignored rather than synced.
const tierMapPath = join(agentsRoot, "models.json");

function fail(message, code = 2) {
  process.stderr.write(`agent: ${message}\n`);
  process.exit(code);
}

function listAgents() {
  if (!existsSync(agentsRoot)) return [];
  let entries;
  try {
    entries = readdirSync(agentsRoot, { withFileTypes: true });
  } catch {
    return [];
  }
  return entries
    .filter((entry) => (entry.isDirectory() || entry.isSymbolicLink()) && !entry.name.startsWith(".") && VALID_NAME.test(entry.name))
    .map((entry) => entry.name)
    .filter((name) => existsSync(join(agentsRoot, name)))
    .sort();
}

function asString(value) {
  return typeof value === "string" && value.trim() ? value.trim() : undefined;
}

function asToolList(value) {
  const raw = Array.isArray(value) ? value : typeof value === "string" ? value.split(",") : [];
  const tools = raw.filter((tool) => typeof tool === "string").map((tool) => tool.trim()).filter(Boolean);
  return tools.length > 0 ? tools : undefined;
}

function loadAgent(name) {
  const dir = join(agentsRoot, name);
  const settingsPath = join(dir, "settings.json");
  let settings = {};
  if (existsSync(settingsPath)) {
    try {
      const parsed = JSON.parse(readFileSync(settingsPath, "utf8"));
      if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) settings = parsed;
    } catch (error) {
      // A malformed settings file must not stop the agent from running.
      process.stderr.write(`agent: ignoring ${settingsPath}: ${error instanceof Error ? error.message : String(error)}\n`);
    }
  }

  const systemPromptPath = join(dir, "SYSTEM.md");
  return {
    model: asString(settings.model),
    provider: asString(settings.provider),
    thinking: asString(settings.thinking),
    tools: asToolList(settings.tools),
    systemPromptPath: existsSync(systemPromptPath) ? systemPromptPath : undefined,
  };
}

/**
 * Resolve `model` to a concrete id. A value of `tier:<name>` is looked up in the
 * per-computer tier map so synced agents stay machine-agnostic.
 */
function resolveModel(model) {
  if (!model || !model.startsWith("tier:")) return model;

  const tier = model.slice("tier:".length).trim();
  if (!tier) fail('invalid model "tier:" — expected tier:<name>');
  if (!existsSync(tierMapPath)) {
    fail(
      `agent asks for tier "${tier}" but no tier map exists at ${tierMapPath}.\n` +
        'Create it, e.g. { "low": "provider/fast", "medium": "provider/mid", "high": "provider/strong" }',
    );
  }

  let map;
  try {
    map = JSON.parse(readFileSync(tierMapPath, "utf8"));
  } catch (error) {
    fail(`cannot read ${tierMapPath}: ${error.message}`);
  }
  if (!map || typeof map !== "object" || Array.isArray(map)) {
    fail(`${tierMapPath} must be a JSON object mapping tier name to model id`);
  }

  const resolved = asString(map[tier]);
  if (!resolved) {
    fail(`tier "${tier}" is not defined in ${tierMapPath}. Available: ${Object.keys(map).join(", ") || "none"}`);
  }
  return resolved;
}

function buildPiArgs(agent, name, prompt) {
  const args = ["--print", "--name", `subagent:${name}`];
  if (agent.provider) args.push("--provider", agent.provider);
  if (agent.model) args.push("--model", agent.model);
  if (agent.thinking) args.push("--thinking", agent.thinking);
  if (agent.tools) args.push("--tools", agent.tools.join(","));
  if (agent.systemPromptPath) args.push("--system-prompt", agent.systemPromptPath);
  args.push("--", prompt);
  return args;
}

function usage() {
  process.stdout.write(
    [
      "agent — run a pi subagent",
      "",
      "Usage:",
      "  agent <name> <task...>   Run the <name> subagent on <task>",
      "  agent --list             List available subagents",
      "  agent --help             Show this help",
      "",
      `Subagents live in ${agentsRoot}/<name>/ with an optional settings.json`,
      "and SYSTEM.md. Honors PI_CODING_AGENT_DIR and PI_BIN.",
      "",
    ].join("\n"),
  );
}

const argv = process.argv.slice(2);
if (argv.length === 0) {
  usage();
  process.exit(2);
}
if (argv[0] === "-h" || argv[0] === "--help") {
  usage();
  process.exit(0);
}
if (argv[0] === "--list") {
  for (const name of listAgents()) process.stdout.write(`${name}\n`);
  process.exit(0);
}

const name = argv[0];
const prompt = argv.slice(1).join(" ").trim();

if (!VALID_NAME.test(name)) fail(`invalid agent name "${name}"`);
if (!existsSync(join(agentsRoot, name))) {
  const available = listAgents();
  fail(`unknown agent "${name}". Available: ${available.join(", ") || "none"}`);
}
if (!prompt) fail(`missing task. Usage: agent ${name} "your prompt"`);

const agent = loadAgent(name);
agent.model = resolveModel(agent.model);
const piBin = process.env.PI_BIN || "pi";
const child = spawn(piBin, buildPiArgs(agent, name, prompt), { stdio: ["ignore", "inherit", "inherit"] });

// Forward termination so Ctrl+C reaches the subagent, not just this wrapper.
for (const signal of ["SIGINT", "SIGTERM"]) process.on(signal, () => child.kill(signal));

child.on("error", (error) => fail(`cannot run "${piBin}": ${error.message}`, 127));
child.on("close", (code) => process.exit(code ?? 1));
