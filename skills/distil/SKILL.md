---
name: distil
description: Evaluate recent changes and propose updates to the project's permanent context (CLAUDE.md or the scope's docs folder) when something durable was learned
disable-model-invocation: true
allowed-tools: Bash(git diff*) Bash(git status*) Bash(git log*) Bash(node *) Glob Read Edit Write
---

You are running the distillation step of the playbook. The developer has invoked you because they think recent changes might have introduced durable knowledge worth capturing.

Before doing anything, read these supporting files:
- [distillation-criteria.md](../../shared/distillation-criteria.md) — the heuristic for deciding what's worth capturing
- [authoring-rules.md](../../shared/authoring-rules.md) — writing standards for any text you produce

## Phase 1: Determine what changed

Identify the changes you're evaluating. In order of preference:

1. **Uncommitted changes** — `git diff HEAD` and `git status --short`. If there are uncommitted changes, those are the scope.
2. **Recent commits** — if the working tree is clean, look at `git log -5 --oneline` and `git diff HEAD~1 HEAD` (or further back if the developer specified a range in arguments).
3. **No git** — if this isn't a git repo, ask the developer to describe what they changed.

Read enough of the diff to understand what was modified. For large diffs, prioritize: config files, files in security-sensitive paths, new files, files with structural changes (added/removed exports, schema changes).

## Phase 2: Evaluate against criteria

Apply [distillation-criteria.md](../../shared/distillation-criteria.md) to what you found. For each candidate observation, ask: which criterion does this hit?

If nothing in the change meets any criterion, say so explicitly to the developer and stop. Do not invent reasons to write something. A turn that produces no distillation is the common case, not a failure.

If something does qualify, hold each candidate as a separate item — they may route to different files.

## Phase 3: Map the scope of each candidate

This project may be a single repo, or it may be a super-repo containing sub-repos that each carry their own `CLAUDE.md` and durable-context folder. The playbook supports both. The routing target for any candidate must be the *most-local* scope whose contents the candidate describes — otherwise, knowledge that belongs to one sub-repo ends up at the super-repo level where someone working inside the sub-repo alone will never see it.

For each changed path in the diff, find the **nearest-ancestor scope** — the closest ancestor directory (starting from the file itself and walking upward) that contains a `CLAUDE.md`. The repo root counts; intermediate directories with their own `CLAUDE.md` count first.

For each scope, determine its **durable-context folder** using this precedence (stop at the first match):

1. **Persisted config.** Read `<scope>/.claude/.playbook/config.json` if it exists. If the file has a `docs_folder` field, that path (relative to the scope root) is the authoritative durable-context folder. This is what `/playbook:init` writes when the developer runs it.
2. **Existing playbook-marked folder.** Any folder at the scope whose `CLAUDE.md` begins with the `# Durable project context` heading is the marker the playbook writes. If exactly one such folder exists, use it.
3. **Existing `docs/` with a marker.** If `<scope>/docs/` exists and its `CLAUDE.md` is playbook-marked, use it.
4. **Fallback default.** `<scope>/docs/`. The folder may or may not exist yet; if it exists without a marker, treat it as a regular project-docs folder the playbook has not yet claimed — you can still propose writing there, but tell the developer the folder will be marked with a `CLAUDE.md` on first write.

Then read what already exists in every scope you identified:

- The `CLAUDE.md` files at each scope root
- All `*.md` files in the scope's durable-context folder, if it exists and is playbook-marked
- Note: `.claude/changes/` is for ephemeral change-specs, never a distillation target

This step is mandatory. Reading every relevant scope prevents duplicated content, contradictions with existing files, and missed opportunities to update rather than create.

## Phase 4: Decide on a target for each candidate

For each candidate observation, pick a destination using two questions in this order:

**1. Which scope owns this knowledge?** Default to the nearest-ancestor scope of the changed paths the candidate describes. Promote to a higher scope (a parent repo's `CLAUDE.md` or durable-context folder) only when the candidate is genuinely cross-cutting — it describes a convention multiple sub-repos must follow, names a relationship between sub-repos, or constrains how they integrate. When unsure, propose the local target. The developer can override; over-correction toward the super-repo is harder to undo because it leaks shared-looking content into a place sub-repos can't see standalone.

**2. Inside that scope, which file?**

- **Update the scope's `CLAUDE.md`** if the candidate corrects or extends something already there (most often: the Gotchas section or an outdated Stack/Commands entry).
- **Update an existing context file** if the scope's durable-context folder already has a file covering the affected area.
- **Create a new context file** if no existing file fits and the candidate is substantial enough to warrant its own file.
- **Add a section to an adjacent context file** if the candidate is small but related to an existing file's scope.

Naming guidance for new context files: scope each to a meaningful concept — `security.md`, `data-model.md`, `kafka-events.md`, `api-conventions.md`. Not so narrow they fragment (`that-blue-button.md` is wrong). Not so broad they become a dump (`misc.md` is wrong). Use the project's own vocabulary, not the example list.

## Phase 5: Surface the choice to the developer

For each candidate, present:

1. **What** — a one-sentence summary of the observation.
2. **Why it qualifies** — which distillation criterion it meets.
3. **Proposed target** — the specific file (existing or new) and a brief reason. When the project has multiple scopes, name the target by full path from the cwd (e.g. `services/api/docs/api-conventions.md`) so the developer can see which scope you chose and override if it should live higher up.

Then offer the developer three options for the routing decision:
- **Confirm** — accept the proposed target as-is
- **Override** — specify a different file name they want
- **Defer to you** — proceed with the proposal, but the developer still reviews the actual content before it lands

Wait for the developer's choice before drafting the addition.

This "ask every time" behaviour is intentional. Even when routing is obvious, the prompt keeps the developer aware of what's being captured and where — distillation is gated, not automatic.

## Phase 6: Lazy folder setup

If the routing decision involves writing to a durable-context folder that the playbook has not yet marked (i.e. the folder either does not exist or exists but has no `CLAUDE.md` inside it):

1. Write `<scope>/<docs-folder>/CLAUDE.md` using the Write tool — it creates parent directories automatically, so no separate `mkdir` is needed (this is what keeps the skill cross-platform). The content is the body of [context-folder-template.md](./context-folder-template.md) minus the leading "Template for..." preamble, starting from the `# Durable project context` heading.

`<scope>` is whichever scope root the candidate routes to — the repo root in the single-repo case, a sub-repo's root in the hierarchical case. `<docs-folder>` is `docs/` by default; if a different folder at that scope already carries a playbook-style `CLAUDE.md`, use that one instead. This per-folder CLAUDE.md tells future agents what belongs in the folder, scoped to that location only.

If you are about to mark a folder that already contains unrelated content (e.g. an existing `docs/` with human-written documentation), surface this to the developer before writing — the marker `CLAUDE.md` is small and unobtrusive, but the developer should know it's landing alongside their other files.

## Phase 7: Write the update

For each approved candidate, write the addition or update. Apply [authoring-rules.md](../../shared/authoring-rules.md) — concise, only what can be confirmed from the change, plain prose.

Show the developer the exact diff you propose to write before writing it. Wait for explicit approval. Apply the change. Move to the next candidate.

## Phase 8: Handle change-specs (if relevant)

If a `.claude/changes/<name>.md` file exists and the changes you just distilled correspond to that change-spec, ask the developer if the change-spec should be removed now that its durable content has been captured. Only remove with explicit confirmation.

## Phase 9: Clear the distillation-pending sentinel

The plugin sets a sentinel at `.claude/.playbook/distillation-pending` after each `Write|Edit|MultiEdit` so that subsequent prompts get a soft reminder to consider distillation. Once you have reached a definitive conclusion in this run — either nothing qualified, or all approved candidates have been written — clear it by running the bundled helper via the Bash tool:

`node "${CLAUDE_PLUGIN_ROOT}/scripts/clear-sentinel.js"`

Skip this step if the developer aborted the run mid-flow, since the pending state still applies.

## Notes

- If the developer invokes this skill mid-session and there's no diff yet (work hasn't been done), say so and stop.
- If the developer invokes this skill on a project with no `CLAUDE.md` at the root, say so and recommend running `/playbook:claude-md-setup` first. In a super-repo with sub-repos that have their own `CLAUDE.md` files, a missing super-repo `CLAUDE.md` is fine — the recommendation only applies when there's no `CLAUDE.md` anywhere in the changed scopes.
- Never write to a scope's durable-context folder without first showing the proposed content to the developer for approval.
