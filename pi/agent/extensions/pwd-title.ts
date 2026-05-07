import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

const UPDATE_INTERVAL_MS = 10 * 1000; // 10 seconds
const MIN_UPDATE_INTERVAL_MS = 150;

function formatPath(targetPath: string): string {
	const home = os.homedir();
	if (targetPath === home) return "~";
	if (targetPath.startsWith(`${home}${path.sep}`)) {
		return `~${targetPath.slice(home.length)}`;
	}
	return targetPath;
}

function buildTitle(cwd: string): string {
	return formatPath(cwd);
}

export default function (pi: ExtensionAPI) {
	let timer: ReturnType<typeof setInterval> | null = null;
	let lastTitle = "";
	let lastUpdate = 0;
	let updating = false;

	function stopTimer() {
		if (timer) {
			clearInterval(timer);
			timer = null;
		}
	}

	async function updateTitle(ctx: ExtensionContext) {
		if (!ctx.hasUI) return;
		if (updating) return;
		const now = Date.now();
		if (now - lastUpdate < MIN_UPDATE_INTERVAL_MS) return;

		updating = true;
		try {
			const title = buildTitle(ctx.cwd);
			if (title && title !== lastTitle) {
				ctx.ui.setTitle(title);
				lastTitle = title;
			}
		} finally {
			lastUpdate = Date.now();
			updating = false;
		}
	}

	function startTimer(ctx: ExtensionContext) {
		stopTimer();
		if (!ctx.hasUI) return;
		timer = setInterval(() => {
			void updateTitle(ctx);
		}, UPDATE_INTERVAL_MS);
	}

	pi.on("session_start", async (_event, ctx) => {
		await updateTitle(ctx);
		startTimer(ctx);
	});

	pi.on("session_before_switch", async (_event, ctx) => {
		await updateTitle(ctx);
	});

	pi.on("session_before_fork", async (_event, ctx) => {
		await updateTitle(ctx);
	});

	pi.on("session_compact", async (_event, ctx) => {
		await updateTitle(ctx);
	});

	pi.on("session_tree", async (_event, ctx) => {
		await updateTitle(ctx);
	});

	pi.on("agent_start", async (_event, ctx) => {
		await updateTitle(ctx);
	});

	pi.on("agent_end", async (_event, ctx) => {
		await updateTitle(ctx);
	});

	pi.on("turn_start", async (_event, ctx) => {
		await updateTitle(ctx);
	});

	pi.on("turn_end", async (_event, ctx) => {
		await updateTitle(ctx);
	});

	pi.on("message_start", async (_event, ctx) => {
		await updateTitle(ctx);
	});

	pi.on("message_update", async (_event, ctx) => {
		await updateTitle(ctx);
	});

	pi.on("message_end", async (_event, ctx) => {
		await updateTitle(ctx);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		stopTimer();
		await updateTitle(ctx);
	});
}
