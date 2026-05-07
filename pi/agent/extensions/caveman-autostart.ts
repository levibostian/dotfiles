/**
 * caveman-autostart
 *
 * Purpose: make pi-caveman enabled by default for every new/resumed session
 * without modifying the pi-caveman extension itself. 
 *
 * How: after each session_start, run the existing `/caveman full` command.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const DEFAULT_LEVEL = "full" as const; // "lite" | "full" | "ultra"

export default function (pi: ExtensionAPI) {
  // Run after all other session_start handlers (pi-caveman resets to off on session_start)
  pi.on("session_start", async (_event, ctx) => {
    // Avoid doing this in non-interactive modes if you want, but default: always enable.

    // Defer so pi-caveman's session_start reset runs first.
    setTimeout(() => {
      try {
        pi.sendUserMessage(`/caveman ${DEFAULT_LEVEL}`);
      } catch (e) {
        // No UI here. Fail silently.
      }
    }, 0);
  });
}
