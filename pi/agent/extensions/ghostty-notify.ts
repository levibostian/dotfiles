/**
 * Ghostty notifications for user_select + agent end.
 * Uses OSC 777 (Ghostty, iTerm2, WezTerm, rxvt-unicode)
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function notifyOSC777(title: string, body: string): void {
	process.stdout.write(`\x1b]777;notify;${title};${body}\x07`)
}

function notify(title: string, body: string): void {
	notifyOSC777(title, body)
}

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event) => {
		// this tool is: @fgladisch/pi-user-select
		if (event.toolName !== "user_select") return

		const question = (event.input as { question?: string }).question ?? "Agent needs input"
		notify("Pi question", question)
	})

	pi.on("agent_end", async () => {
		notify("Pi", "Ready for input")
	})
}
