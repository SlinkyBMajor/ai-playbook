# CLAUDE.md (template for `.claude/context/`)

This template is written verbatim into `.claude/context/CLAUDE.md` the first time the distil skill creates the folder.

---

# Context files

This folder holds the project's permanent context — distilled, durable knowledge that should outlive any single change.

Each file is scoped to one area: a single convention, a security boundary, a piece of architecture. Files stay small and stable because they grow by distillation, not accumulation.

## How to consult this folder

These files are meant to be read by agents working anywhere in the codebase, not just inside this folder. Before substantive work in a given area, read the relevant scoped file:

- Touching auth, sessions, tokens, or anything trust-related → read `security.md` (or whatever scoped file covers the area)
- Touching the API surface, request handling, or external interfaces → read `api-conventions.md` (or equivalent)
- Touching the data layer, schema, or persistence → read `data-model.md` (or equivalent)

If a file scoped to your current area exists, treat its contents as binding. They outrank general defaults and training-data assumptions. If multiple files seem related, read them all — these files are kept short specifically so reading several is cheap.

## What belongs here

- Conventions future work should follow
- Security and trust boundaries
- Durable design choices and the constraints they imply
- Non-obvious gotchas that span multiple changes

## What does not belong here

- Implementation details that the code itself documents
- Information already in the root `CLAUDE.md` (this folder supplements it, not duplicates it)
- Per-feature change-specs (those go in `.claude/changes/` and are removed after distillation)
- Aspirational or speculative content — only describe current state

## File naming

Files should be scoped to a meaningful concept: `security.md`, `data-model.md`, `kafka-events.md`, `api-conventions.md`. Not so narrow they fragment the context (no `that-blue-button.md`), not so broad they become a dump.
