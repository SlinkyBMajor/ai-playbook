---
name: distil
description: Evaluate recent changes and propose updates to the project's permanent context (CLAUDE.md or .claude/context/) when something durable was learned
disable-model-invocation: true
allowed-tools: Bash(git diff*) Bash(git status*) Bash(git log*) Bash(ls *) Bash(test *) Bash(cat *) Bash(mkdir *) Bash(rm -f .claude/.playbook/distillation-pending) Read Edit Write
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

## Phase 3: Read the existing context

Before proposing where new content goes, read what's already there:

- `CLAUDE.md` at the repo root (always)
- All files in `.claude/context/` if the folder exists
- Note: `.claude/changes/` is for ephemeral change-specs, not for distillation targets — never write into it

This step is mandatory. Skipping it leads to duplicated content, contradictions with existing files, and missed opportunities to update rather than create.

## Phase 4: Decide on a target for each candidate

For each candidate observation, decide where it belongs:

- **Update CLAUDE.md** if the candidate corrects or extends something already in CLAUDE.md (most often: the Gotchas section or an outdated Stack/Commands entry).
- **Update an existing context file** if `.claude/context/` already has a file covering the affected area.
- **Create a new context file** if no existing file fits and the candidate is substantial enough to warrant its own file.
- **Add a section to an adjacent context file** if the candidate is small but related to an existing file's scope.

Naming guidance for new context files: scope each to a meaningful concept — `security.md`, `data-model.md`, `kafka-events.md`, `api-conventions.md`. Not so narrow they fragment (`that-blue-button.md` is wrong). Not so broad they become a dump (`misc.md` is wrong). Use the project's own vocabulary, not the example list.

## Phase 5: Surface the choice to the developer

For each candidate, present:

1. **What** — a one-sentence summary of the observation.
2. **Why it qualifies** — which distillation criterion it meets.
3. **Proposed target** — the specific file (existing or new) and a brief reason.

Then offer the developer three options for the routing decision:
- **Confirm** — accept the proposed target as-is
- **Override** — specify a different file name they want
- **Defer to you** — proceed with the proposal, but the developer still reviews the actual content before it lands

Wait for the developer's choice before drafting the addition.

This "ask every time" behaviour is intentional. Even when routing is obvious, the prompt keeps the developer aware of what's being captured and where — distillation is gated, not automatic.

## Phase 6: Lazy folder setup

If the routing decision involves writing to `.claude/context/` and the folder doesn't exist:

1. Create `.claude/context/` (e.g. `mkdir -p .claude/context`)
2. Copy the contents of [context-folder-template.md](./context-folder-template.md) into `.claude/context/CLAUDE.md` — minus the leading "Template for..." preamble, starting from the `# Context files` heading

This per-folder CLAUDE.md tells future agents what belongs in the folder, scoped to that location only.

## Phase 7: Write the update

For each approved candidate, write the addition or update. Apply [authoring-rules.md](../../shared/authoring-rules.md) — concise, only what can be confirmed from the change, plain prose.

Show the developer the exact diff you propose to write before writing it. Wait for explicit approval. Apply the change. Move to the next candidate.

## Phase 8: Handle change-specs (if relevant)

If a `.claude/changes/<name>.md` file exists and the changes you just distilled correspond to that change-spec, ask the developer if the change-spec should be removed now that its durable content has been captured. Only remove with explicit confirmation.

## Phase 9: Clear the distillation-pending sentinel

The plugin sets a sentinel at `.claude/.playbook/distillation-pending` after each `Write|Edit|MultiEdit` so that subsequent prompts get a soft reminder to consider distillation. Once you have reached a definitive conclusion in this run — either nothing qualified, or all approved candidates have been written — clear it:

`rm -f .claude/.playbook/distillation-pending`

Skip this step if the developer aborted the run mid-flow, since the pending state still applies.

## Notes

- If the developer invokes this skill mid-session and there's no diff yet (work hasn't been done), say so and stop.
- If the developer invokes this skill on a project with no `CLAUDE.md` at the root, say so and recommend running `/playbook:claude-md-setup` first.
- Never write to `.claude/context/` without first showing the proposed content to the developer for approval.
