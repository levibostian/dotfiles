import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execSync } from "node:child_process";
import { type AgentMessage } from "@earendil-works/pi-ai";

function clipboardCopy(text: string) {
  execSync("pbcopy", { input: text });
}

function extractText(
  content: string | { type: string; text?: string }[] | undefined,
): string {
  if (!content) return "";
  if (typeof content === "string") return content;
  return content
    .filter((b): b is { type: string; text: string } => b.type === "text" && !!b.text)
    .map((b) => b.text)
    .join("\n");
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("copy-last-user-message", {
    description: "Copy last user message to clipboard",
    handler: async (_args, ctx) => {
      const entries = ctx.sessionManager.getBranch();
      let text = "";

      for (let i = entries.length - 1; i >= 0; i--) {
        const e = entries[i];
        if (e.type === "message" && e.message.role === "user") {
          text = extractText(e.message.content);
          break;
        }
      }

      if (!text) {
        ctx.ui.notify("No user message found", "error");
        return;
      }

      clipboardCopy(text);
      ctx.ui.notify(`Copied ${text.length} chars to clipboard`, "info");
    },
  });

  pi.registerCommand("copy-last-agent-message", {
    description: "Copy last assistant message to clipboard",
    handler: async (_args, ctx) => {
      const entries = ctx.sessionManager.getBranch();
      let text = "";

      for (let i = entries.length - 1; i >= 0; i--) {
        const e = entries[i];
        if (e.type === "message" && e.message.role === "assistant") {
          text = extractText(e.message.content);
          break;
        }
      }

      if (!text) {
        ctx.ui.notify("No assistant message found", "error");
        return;
      }

      clipboardCopy(text);
      ctx.ui.notify(`Copied ${text.length} chars to clipboard`, "info");
    },
  });
}