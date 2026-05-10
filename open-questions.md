# Open questions

Design decisions deferred during initial implementation. Each entry: the question, what we know, what we deferred, and what a future pass should reconsider.

This file is for plugin maintainers, not consumers. Excluded from distribution via `.gitattributes`.

## Auto-triggering `/distil` — escalation beyond soft awareness

**Status:** Soft sentinel pattern is implemented. Open question is whether to escalate.

**Current mechanism.** A PostToolUse hook on `Write|Edit|MultiEdit` writes a per-project sentinel at `.claude/.playbook/distillation-pending`. A UserPromptSubmit hook reads the sentinel and injects an `additionalContext` reminder telling the agent to surface `/playbook:distil` when the developer's current message indicates work is wrapping up. `/distil` clears the sentinel in its final phase. See the Gotcha in [CLAUDE.md](CLAUDE.md) for the full pattern.

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

## Collapse `.claude/context/` into `.claude/rules/` for native discoverability

**Status:** Deferred. Discoverability is currently solved by seeding `.claude/context/` into the root CLAUDE.md directory index so agents working anywhere in the project know to consult it. This works but relies on the agent actually reading the index and choosing to load files.

**The alternative.** Per the Claude Code hook docs, `.claude/rules/*.md` files are auto-loaded into context (the `InstructionsLoaded` event fires with `load_reason: path_glob_match` for them). Moving distilled content from `.claude/context/` to `.claude/rules/` would make every distilled file load automatically every session, no agent action required.

**Why we did not do this.**

- The playbook's research and templates use `.claude/context/` as a deliberate name. "Rules" reads as imperative ("you must do X"); "context" reads as informational ("here is how this project works"). Distilled knowledge is the latter — conventions, security boundaries, design choices — not commandments.
- Auto-loading every distilled file every session bypasses the "read what is relevant when it is relevant" pattern. For a project with ten context files totalling a few thousand tokens, that is fine. For a project that has been distilled aggressively for a year, it becomes a context-window tax paid on every session regardless of what the work needs.
- Conflating context and rules removes a meaningful distinction. The plugin already supports rules-style content if a project wants it — users can drop their own files into `.claude/rules/` independently. Forcing distilled context into the same bucket is a one-way change.

**What a future pass should reconsider.**

- Whether the directory-index pointer is enough in practice. If agents routinely ignore `.claude/context/` despite the index entry, native auto-load becomes more attractive.
- Whether a hybrid is worth shipping: a small set of "always-load" files at `.claude/rules/` plus the broader `.claude/context/` library for on-demand reads. The distil skill would need to route candidates between the two based on how universally relevant they are.
- Whether Claude Code grows a third option (e.g. lazy-glob-load on file pattern match) that captures the best of both — load context files when the agent touches related code, ignore them otherwise.

## Hook reference correctness

Earlier passes worked from an incomplete list of hook events. The full set is documented at https://code.claude.com/docs/en/hooks — there are roughly 30 events including `PostToolBatch`, `SessionEnd`, `TaskCompleted`, `InstructionsLoaded`, etc., several of which support `additionalContext` and were not considered in initial design. When revisiting any hook-driven mechanism, fetch the docs first and inventory which events apply.
