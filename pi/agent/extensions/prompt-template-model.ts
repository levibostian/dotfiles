/**
 * Allows you to specify a model in the prompt override front matter. So we switch to that model, run the flow, then switch back to what you had before. 
 * 
 * Just add: 
 * ```
 * model: provider/id
 * ```
 * 
 * to the front matter of your prompt template and that's it. 
 * 
 * Reference: https://github.com/nicobailon/pi-prompt-template-model/, but too many features. This is a minimal set.
 */

import { readFileSync } from "node:fs";
import type { Model } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { ThinkingLevel } from "@earendil-works/pi-agent-core";

type PendingRestore = {
	model?: Model<any>;
	thinking?: ThinkingLevel;
};

type PromptCommand = {
	name: string;
	source: "prompt" | string;
	sourceInfo?: { path?: string };
};

export default function promptTemplateModelMinimal(pi: ExtensionAPI) {
	let pendingRestore: PendingRestore | null = null;

	function notify(ctx: ExtensionContext | undefined, text: string, level: "info" | "warning" | "error") {
		ctx?.ui.notify(text, level);
	}

	function extractCommandName(text: string): string | null {
		if (!text.startsWith("/")) return null;
		const trimmed = text.slice(1).trimStart();
		if (!trimmed) return null;
		const spaceIndex = trimmed.indexOf(" ");
		return spaceIndex === -1 ? trimmed : trimmed.slice(0, spaceIndex);
	}

	function findPromptCommand(name: string): PromptCommand | undefined {
		return (pi.getCommands() as PromptCommand[]).find(
			(command) => command.source === "prompt" && command.name === name,
		);
	}

	function extractFrontMatter(content: string): string | null {
		if (!content.startsWith("---")) return null;
		const endIndex = content.indexOf("\n---", 3);
		if (endIndex === -1) return null;
		const sliceStart = content.indexOf("\n", 3);
		if (sliceStart === -1 || sliceStart >= endIndex) return null;
		return content.slice(sliceStart + 1, endIndex);
	}

	function extractModelFromFrontMatter(frontMatter: string): string | undefined {
		for (const line of frontMatter.split("\n")) {
			const trimmed = line.trim();
			if (!trimmed || trimmed.startsWith("#")) continue;
			if (!trimmed.startsWith("model:")) continue;
			const rawValue = trimmed.slice("model:".length).trim();
			if (!rawValue) return undefined;
			return rawValue.replace(/^['"]|['"]$/g, "");
		}
		return undefined;
	}

	function parseModelSpec(spec: string): { provider: string; id: string } | null {
		const slashIndex = spec.indexOf("/");
		if (slashIndex <= 0 || slashIndex === spec.length - 1) return null;
		const provider = spec.slice(0, slashIndex).trim();
		const id = spec.slice(slashIndex + 1).trim();
		if (!provider || !id) return null;
		if (id.split("/").some((segment) => segment.length === 0)) return null;
		return { provider, id };
	}

	async function applyPromptModelOverride(modelSpec: string, ctx: ExtensionContext) {
		const parsed = parseModelSpec(modelSpec);
		if (!parsed) {
			notify(ctx, `Prompt template model must be provider/id. Got: ${modelSpec}`, "warning");
			return;
		}

		const currentModel = ctx.model;
		if (currentModel && currentModel.provider === parsed.provider && currentModel.id === parsed.id) return;

		const resolved = ctx.modelRegistry?.find(parsed.provider, parsed.id);
		if (!resolved) {
			notify(ctx, `Model not found: ${parsed.provider}/${parsed.id}`, "error");
			return;
		}

		const switched = await pi.setModel(resolved);
		if (!switched) {
			notify(ctx, `Failed to switch to model ${parsed.provider}/${parsed.id}`, "error");
			return;
		}

		pendingRestore = { model: currentModel, thinking: pi.getThinkingLevel() };
	}

	pi.on("input", async (event, ctx) => {
		const commandName = extractCommandName(event.text);
		if (!commandName) return { action: "continue" };
		const command = findPromptCommand(commandName);
		const path = command?.sourceInfo?.path;
		if (!path) return { action: "continue" };

		let content: string;
		try {
			content = readFileSync(path, "utf8");
		} catch (error) {
			notify(ctx, `Failed to read prompt template: ${path}`, "error");
			return { action: "continue" };
		}

		const frontMatter = extractFrontMatter(content);
		if (!frontMatter) return { action: "continue" };
		const modelSpec = extractModelFromFrontMatter(frontMatter);
		if (!modelSpec) return { action: "continue" };

		await applyPromptModelOverride(modelSpec, ctx);
		return { action: "continue" };
	});

	pi.on("agent_end", async (_event, ctx) => {
		if (!pendingRestore) return;
		const restore = pendingRestore;
		pendingRestore = null;

		if (restore.model) {
			const restored = await pi.setModel(restore.model);
			if (!restored) {
				notify(ctx, `Failed to restore model ${restore.model.provider}/${restore.model.id}`, "error");
			}
		}
		if (restore.thinking !== undefined) {
			pi.setThinkingLevel(restore.thinking);
		}
	});
}
