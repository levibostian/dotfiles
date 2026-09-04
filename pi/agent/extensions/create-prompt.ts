import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { exec } from "node:child_process";
import * as fs from "node:fs/promises";
import * as os from "node:os";
import * as path from "node:path";

const DEFAULT_FRONTMATTER = `---
description: 
---

`;

export default function (pi: ExtensionAPI) {
  pi.registerCommand("create-prompt", {
    description: "Create a new prompt template and open in VS Code",
    handler: async (args, ctx) => {
      let name = args?.trim();

      if (!name) {
        const input = await ctx.ui.input("Prompt name:");
        name = input?.trim();
      }

      if (!name) {
        ctx.ui.notify("Prompt name required", "warning");
        return;
      }

      const fileName = name.endsWith(".md") ? name : `${name}.md`;
      const promptsDir = path.join(os.homedir(), ".pi", "agent", "prompts");
      const filePath = path.join(promptsDir, fileName);

      try {
        await fs.mkdir(promptsDir, { recursive: true });

        // Don't overwrite existing prompt
        try {
          await fs.access(filePath);
          ctx.ui.notify(`Prompt ${fileName} exists. Opening in VS Code...`, "info");
        } catch {
          await fs.writeFile(filePath, DEFAULT_FRONTMATTER, "utf8");
          ctx.ui.notify(`Created prompt: ${fileName}`, "info");
        }

        exec(`code -n "${promptsDir}" "${filePath}"`, (error) => {
          if (error) {
            ctx.ui.notify(`Failed to open in VS Code: ${error.message}`, "error");
          }
        });
      } catch (error) {
        const msg = error instanceof Error ? error.message : String(error);
        ctx.ui.notify(`Error creating prompt: ${msg}`, "error");
      }
    },
  });
}
