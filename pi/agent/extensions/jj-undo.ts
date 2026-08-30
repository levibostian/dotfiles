/**
 * Purpose: /undo reverts code to the state at your last user message and rewinds pi history
 * so you can edit that message; /redo restores both forward. Uses jj operation snapshots.
 * Responsibilities: Snapshot the jj op id whenever a user message arrives (TUI or RPC),
 * then on /undo restore the repo to it (jj op restore) and re-run the /last command; on
 * /redo restore the pre-undo op and navigate the session tree back to the pre-undo leaf.
 * Scope: Single-level undo/redo per session. State persists in the session via custom entries
 * so it survives /reload.
 * Invariants/Assumptions: Works in jj repositories only. Restoring to an op abandons later
 * ops but never deletes them, so /redo can always restore by op id.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const STATE_CUSTOM_TYPE = "jj-undo-state";

interface UndoState {
  /** jj op id captured when the last interactive user message arrived (code restore target) */
  snapshotOpId: string | null;
  /** jj op id captured right before /undo ran (code restore target for /redo) */
  redoOpId: string | null;
  /** session leaf entry id right before /undo ran (history forward target for /redo) */
  redoLeafId: string | null;
}

export default function (pi: ExtensionAPI) {
  const state: UndoState = { snapshotOpId: null, redoOpId: null, redoLeafId: null };

  // jj op log auto-snapshots the dirty working copy before printing, so the captured
  // op id always includes every edit the agent made since the last jj command.
  const captureCurrentOpId = async (cwd: string): Promise<string | null> => {
    const result = await pi.exec("jj", ["op", "log", "-n", "1", "--no-pager", "--color", "never"], { cwd });
    if (result.code !== 0) return null;
    const match = result.stdout.match(/^@\s+([0-9a-f]+)/);
    return match?.[1] ?? null;
  };

  const persist = () => {
    // Append-only API: later reads take the last entry, older copies are ignored.
    pi.appendEntry(STATE_CUSTOM_TYPE, state);
  };

  // Rebuild in-memory state after /reload or session switch.
  pi.on("session_start", (_event, ctx) => {
    const entries = ctx.sessionManager.getEntries();
    for (let i = entries.length - 1; i >= 0; i -= 1) {
      const entry = entries[i];
      if (entry.type === "custom" && entry.customType === STATE_CUSTOM_TYPE) {
        const saved = entry.data as Partial<UndoState> | undefined;
        state.snapshotOpId = saved?.snapshotOpId ?? null;
        state.redoOpId = saved?.redoOpId ?? null;
        state.redoLeafId = saved?.redoLeafId ?? null;
        return;
      }
    }
  });

  // Snapshot the code state at every user message (TUI or RPC); never for extension-injected input.
  pi.on("input", async (event, ctx) => {
    if (event.source === "extension") return;
    const opId = await captureCurrentOpId(ctx.cwd);
    if (!opId) return; // not a jj repo; /undo will report no snapshot
    state.snapshotOpId = opId;
    // A new user message moves history forward, so any stale redo target no longer applies.
    state.redoOpId = null;
    state.redoLeafId = null;
    persist();
  });

  pi.registerCommand("undo", {
    description: "Restore code to the state at your last user message and rewind history to it",
    handler: async (_args, ctx) => {
      await ctx.waitForIdle();
      if (!state.snapshotOpId) {
        ctx.ui.notify("No snapshot yet — send a message first (jj repo required)", "warning");
        return;
      }

      // Capture pre-undo positions first: the running restore rewinds the op log,
      // so the current op id must be read (and leaf saved) before restoring.
      // The op log read auto-snapshots the working copy, capturing all agent edits.
      const preUndoOpId = await captureCurrentOpId(ctx.cwd);
      const preUndoLeafId = ctx.sessionManager.getLeafId();
      if (!preUndoOpId) {
        ctx.ui.notify("jj op log failed — aborting undo", "error");
        return;
      }

      const restore = await pi.exec("jj", ["op", "restore", state.snapshotOpId], { cwd: ctx.cwd });
      if (restore.code !== 0) {
        ctx.ui.notify(`jj op restore failed:\n${restore.stderr.trim() || "unknown error"}`, "error");
        return;
      }

      state.redoOpId = preUndoOpId;
      state.redoLeafId = preUndoLeafId;
      persist();

      ctx.ui.notify("Code restored to the state at your last message", "info");

      // Rewind pi history to the last user message and drop its text into the editor
      // (reuses the /last command from the pi-edit-last-message package).
      pi.sendUserMessage("/last", { expandPromptTemplates: true });
    },
  });

  pi.registerCommand("redo", {
    description: "Restore code to the pre-undo state and move history forward again",
    handler: async (_args, ctx) => {
      await ctx.waitForIdle();
      if (!state.redoOpId) {
        ctx.ui.notify("Nothing to redo", "warning");
        return;
      }

      const restore = await pi.exec("jj", ["op", "restore", state.redoOpId], { cwd: ctx.cwd });
      if (restore.code !== 0) {
        ctx.ui.notify(`jj op restore failed:\n${restore.stderr.trim() || "unknown error"}`, "error");
        return;
      }

      // Move the session leaf forward to the pre-undo position. Skipped when the
      // target is a user message: navigateTree would treat it as a rewind target.
      const targetEntry = state.redoLeafId ? ctx.sessionManager.getEntry(state.redoLeafId) : undefined;
      if (targetEntry && !(targetEntry.type === "message" && targetEntry.message.role === "user")) {
        try {
          await ctx.navigateTree(state.redoLeafId!, { summarize: false });
        } catch (error) {
          ctx.ui.notify(`Code restored, but history rewind failed: ${(error as Error).message}`, "warning");
        }
      }

      state.redoOpId = null;
      state.redoLeafId = null;
      persist();

      ctx.ui.notify("Redo complete — code and history restored to the pre-undo state", "info");
    },
  });
}