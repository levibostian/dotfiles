/**
 * Ghostty notifications for user_select + agent end.
 * Uses OSC 777 (Ghostty, iTerm2, WezTerm, rxvt-unicode)
 *
 * Disabled by default per session. Toggle with `/ghostty-notify`.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function notifyOSC777(title: string, body: string): void {
	process.stdout.write(`\x1b]777;notify;${title};${body}\x07`)
}

function notify(title: string, body: string): void {
	notifyOSC777(title, body)
}

export default function (pi: ExtensionAPI) {
	let enabled = false;

	pi.on("session_start", async () => {
		enabled = false;
	});

	pi.registerCommand("ghostty-notify", {
		description: "Toggle Ghostty desktop notifications on/off for this session",
		handler: async (_args, ctx) => {
			enabled = !enabled;
			ctx.ui.notify(enabled ? "Ghostty notifications ON" : "Ghostty notifications OFF", "info");
		},
	});

	pi.on("tool_call", async (event) => {
		if (!enabled) return;
		if (event.toolName !== "user_select") return;

		const question = (event.input as { question?: string }).question ?? "Agent needs input";
		notify("Pi question", question);
	});

	pi.on("agent_end", async () => {
		if (!enabled) return;
		notify("Pi", "Ready for input");
	});
}