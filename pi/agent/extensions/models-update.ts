import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function modelsUpdateExtension(pi: ExtensionAPI) {
	pi.registerCommand("models-update", {
		description: "Refresh model catalogs with pi update --models",
		handler: async (_args, ctx) => {
			try {
				const result = await pi.exec("pi", ["update", "--models"]);
				const output = [result.stdout.trim(), result.stderr.trim()].filter(Boolean).join("\n");

				if (result.code === 0) {
					ctx.ui.notify(output || "Model catalogs refreshed.", "info");
					return;
				}

				ctx.ui.notify(
					`Model catalog refresh failed (exit ${result.code})${output ? `:\n${output}` : ""}`,
					"error",
				);
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				ctx.ui.notify(`Model catalog refresh failed: ${message}`, "error");
			}
		},
	});
}
