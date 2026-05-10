# Open questions

Design decisions deferred during initial implementation. Each entry: the question, what we know, what we deferred, and what a future pass should reconsider.

This file is for plugin maintainers, not consumers. Excluded from distribution via `.gitattributes`.

## Auto-triggering `/distil` — escalation beyond soft awareness

**Status:** Soft sentinel pattern is implemented. Open question is whether to escalate.

**Current mechanism.** A PostToolUse hook on `Write|Edit|MultiEdit` writes a per-project sentinel at `.claude/.ai-playbook/distillation-pending`. A UserPromptSubmit hook reads the sentinel and injects an `additionalContext` reminder telling the agent to surface `/ai-playbook:distil` when the developer's current message indicates work is wrapping up. `/distil` clears the sentinel in its final phase. See the Gotcha in [CLAUDE.md](CLAUDE.md) for the full pattern.

**Why it's not stronger.** Hook outputs cannot invoke a skill, slash command, or tool. The available primitives are `additionalContext` injection and `decision: "block"`. We chose injection because:

- Distillation is supposed to be developer-gated, not agent-driven.
- Block-based escalation costs an extra agent turn even when distillation finds nothing worth capturing.
- Soft reminders avoid noise on every edit-then-stop cycle.

**Mechanism options that remain on the table.**

- **PostToolBatch nudge.** Same `additionalContext` text, but injected immediately after each batch of edit calls instead of waiting for the next user prompt. More immediate, slightly noisier. Equivalent agent behaviour expected.
- **Stop hook block.** Forces a turn at end-of-response when the sentinel is set. Reason text directs the agent to invoke `/distil`. Requires `disable-model-invocation: false` on the distil skill (currently `true`). Cost: one extra agent turn per cycle, even on no-op distil runs. Risk: blocks every turn after edits unless throttled by a "blocked-recently" marker.
- **Combination.** Sentinel pattern as today plus a Stop block escalation when the agent ignores the reminder for N consecutive turns. Adds state complexity.

**What a future pass should reconsider.**

- Whether the soft reminder is actually heeded in practice. If agents routinely ignore it and edits accumulate without distillation, escalate to PostToolBatch or Stop.
- Whether a future hook event lets a plugin invoke a skill directly. If so, the trade-space changes — block-and-invoke becomes feasible without the `disable-model-invocation` flip.
- Whether the sentinel granularity should change. Per-project (current) is the simplest; per-task or per-change-spec would be more precise but requires inferring task boundaries.

## Hook reference correctness

Earlier passes worked from an incomplete list of hook events. The full set is documented at https://code.claude.com/docs/en/hooks — there are roughly 30 events including `PostToolBatch`, `SessionEnd`, `TaskCompleted`, `InstructionsLoaded`, etc., several of which support `additionalContext` and were not considered in initial design. When revisiting any hook-driven mechanism, fetch the docs first and inventory which events apply.
