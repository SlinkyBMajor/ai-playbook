---
name: init
description: Configure the playbook for this scope — choose where durable project context lives, mark the folder, and persist the choice. Recommended as the first playbook command in a fresh repo, before /playbook:claude-md-setup. Safe to re-run to change the location.
disable-model-invocation: true
allowed-tools: Glob Read Write Edit AskUserQuestion
---

You are configuring the playbook for the current scope. The developer is telling you where this scope's durable project context will live — the folder where `/playbook:distil` writes distilled knowledge.

Init is per-scope. In a super-repo with sub-repos, run it once at each scope you want to configure. The choice is persisted to `<scope>/.claude/.playbook/config.json`, and the chosen folder is marked with a small `CLAUDE.md` that future agents can recognise.

Before doing anything, read:
- [authoring-rules.md](../../shared/authoring-rules.md) — writing standards for any text you produce
- [context-folder-template.md](../distil/context-folder-template.md) — the marker file you will write into the chosen folder

## Phase 1: Identify the scope

The scope is the current working directory. Init does not walk upward looking for a parent scope; the developer ran it where they ran it.

A `CLAUDE.md` at the scope root is **not required**. The recommended order is `/playbook:init` first, then `/playbook:claude-md-setup` — so a missing root CLAUDE.md is normal on a fresh setup. Note whether one exists; Phase 7 only runs if it does.

## Phase 2: Check for existing config

Read `<scope>/.claude/.playbook/config.json` if it exists. If it does, show the current `docs_folder` value and call `AskUserQuestion`:

- **Keep as-is** — exit the skill, report no changes
- **Change location** — proceed to Phase 3
- **Cancel** — exit the skill

If the file does not exist, proceed.

## Phase 3: Discover candidate folders

Use the Glob tool to list top-level directories in the scope. Classify candidates into three groups, omitting any group that's empty:

- **Already playbook-marked.** Any folder containing a `CLAUDE.md` whose first non-blank heading is `# Durable project context` (the marker the playbook writes from [context-folder-template.md](../distil/context-folder-template.md)). To identify these, read the first ~30 lines of each candidate folder's `CLAUDE.md`.
- **Existing docs roots.** `docs/`, `documentation/`, `wiki/` — folders that look like documentation homes even without a playbook marker.
- **Legacy playbook locations.** `.claude/context/` — the older default the playbook used to write into. Worth noting because it may contain content to migrate.

Show the developer concisely what you found in each group. Do not auto-pick.

## Phase 4: Choose the folder

Call `AskUserQuestion` with up to four options, ordered by strength. Include only the rows that apply, and let the `AskUserQuestion`-provided "Other" option cover anything not listed:

- The strongest already-marked candidate, if any — labelled e.g. **Use existing marked folder `docs/`**
- One reasonable existing docs root, if any (and different from the above) — labelled e.g. **Use existing `documentation/`**
- **Create or use `docs/`** — applies whether or not `docs/` exists; the playbook's default
- **Type a custom path** — for cases like `claude-context/`, `internal/docs/`, etc.

If the developer picks a folder that already contains hand-written content, tell them in plain text before continuing: a small `CLAUDE.md` marker will be written into the folder describing what `/playbook:distil` writes into it. The marker explicitly acknowledges that hand-written docs alongside it are fine. Confirm once with a brief chat reply (no second `AskUserQuestion` needed).

## Phase 5: Mark the folder

Write `<chosen-folder>/CLAUDE.md` using the body of [context-folder-template.md](../distil/context-folder-template.md), dropping the leading "# CLAUDE.md (template for...)" preamble — start from the `# Durable project context` heading. Use the Write tool; it creates parent directories automatically, so a non-existent `<chosen-folder>` is fine.

If `<chosen-folder>/CLAUDE.md` already exists:

- Read it. If its first non-blank heading is `# Durable project context`, treat it as already marked — leave it alone and report no change in Phase 9.
- If it differs, show the developer the existing content briefly and call `AskUserQuestion`: **Overwrite with template** / **Leave existing** / **Cancel init**.

## Phase 6: Migration notice (manual)

If Phase 3 found a legacy playbook location (typically `.claude/context/`) with `.md` files in it, and the developer did *not* choose that same folder as the destination, surface this to the developer as a one-time notice:

> Init found `<n>` files at `<old-location>`:
> - `security.md`
> - `data-model.md`
> - …
>
> These will not be moved automatically. To migrate them, move the files into `<chosen-folder>/` using your platform's tools (e.g. `mv` on macOS/Linux, `move` on Windows). After moving, you can delete the empty source folder if you no longer need it.

This is a notice, not a question. Init does not invoke shell commands or move files itself.

If the developer chose the legacy location as the destination, skip this phase.

## Phase 7: Update the root CLAUDE.md directory index (only if CLAUDE.md exists)

Skip this phase entirely if no `CLAUDE.md` exists at the scope root — `/playbook:claude-md-setup` will read the persisted config in Phase 8 and seed the entry then.

If a CLAUDE.md exists, read it and find the `## Directory index` section. Three cases:

- **Already listed correctly** (the chosen folder appears in the table with a reasonable description) → no change.
- **Outdated entry** pointing at the old location (e.g. the table still lists `.claude/context/`) → propose an Edit replacing the path and description with the chosen folder and the standard description below. Call `AskUserQuestion`: **Apply** / **Skip**.
- **No entry** for the chosen folder → propose an Edit adding a new row to the table. Call `AskUserQuestion`: **Apply** / **Skip**.

Standard description text (matches `claude-md-setup`):

> Durable project context — distilled conventions, security boundaries, design choices, and gotchas. Maintained by `/playbook:distil` in small files scoped to one area each. Consult related files before substantive work in the area they cover; they outrank general defaults.

## Phase 8: Persist the choice

Write `<scope>/.claude/.playbook/config.json` with the chosen folder path, relative to the scope root:

```json
{
  "docs_folder": "docs/"
}
```

Substitute the developer's actual choice. Keep a trailing slash for readability. Overwrite the file if it already exists — the chosen value supersedes any previous one. The Write tool creates the parent directory if needed.

## Phase 9: Summarise

One short message to the developer, listing only the bullets that apply:

- Chosen folder, and whether it was created or already existed
- Whether the marker `CLAUDE.md` was written, was already present, or was overwritten
- Whether the root CLAUDE.md directory index was updated (or skipped because no CLAUDE.md exists yet)
- Path of the persisted config: `.claude/.playbook/config.json`
- If a legacy location was detected with files: a one-line reminder that the developer is migrating manually
- If no CLAUDE.md exists at the scope root: a single line suggesting `/playbook:claude-md-setup` as the next step — it will read the config you just wrote

## Notes

- Init is per-scope. In a super-repo, run it once at each scope you want to configure. The repo root and each sub-repo are independent.
- The config file is plain JSON. Developers can edit it by hand later, or re-run `/playbook:init` to update marker and index alongside the config in one step.
- Both `/playbook:distil` and `/playbook:claude-md-setup` read this config. If the file is absent, both fall back to a `docs/` default plus discovery of any playbook-marked folder.
- Init does not move files, run shell commands, or modify anything outside the scope's `CLAUDE.md`, the chosen folder's marker, and the config file.
