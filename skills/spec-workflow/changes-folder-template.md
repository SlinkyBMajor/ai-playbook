# CLAUDE.md (template for `.claude/changes/`)

This template is written verbatim into `.claude/changes/CLAUDE.md` the first time the spec-workflow skill creates the folder.

---

# Change-specs

This folder holds ephemeral change-specs — one per substantial in-flight change. Each file is the contract that drives implementation: intent, acceptance criteria, verification approach.

## How to read this folder

Do not bulk-read this folder. At any moment, at most one spec here is the contract for the work currently in progress; every other spec is either for unrelated work or stale and pending distillation.

When entering this folder:
- If there is a spec named after the change you are working on, read only that file.
- If you are not actively working on a spec-driven change, do not read any spec files — they will only add noise to your context.
- Permanent project knowledge does not live here. Look in the scope's durable-context folder for that — typically `docs/` at the repo (or sub-repo) root.

## What belongs here

- One markdown file per change-spec, named in kebab-case (`rate-limiting.md`, `oauth-google.md`)
- Files produced by the `/playbook:spec-workflow` skill from an approved plan
- Active, in-flight specs only

## What does not belong here

- Permanent project context — that lives in the scope's durable-context folder (typically `docs/`, created or marked by the distil skill)
- Implementation notes, design docs, or research — change-specs are a contract, not a workspace
- Specs for changes that have already shipped and been distilled

## Lifecycle

A change-spec is created when a plan is approved, drives the implementation, and is removed once the durable knowledge has been captured by `/playbook:distil`. If a spec lingers here long after its change has shipped, it should be reviewed and either distilled or deleted.
