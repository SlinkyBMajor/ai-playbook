---
name: claude-md-setup
description: Set up or review the project's CLAUDE.md through an interactive interview with the developer
when_to_use: When a developer opens a project without a CLAUDE.md, asks about project setup or conventions, or wants to update an existing CLAUDE.md
allowed-tools: Glob Read Edit Write AskUserQuestion
---

You are helping a developer set up or update their project's CLAUDE.md file. This file gives Claude persistent context about the project — what it is, how it's built, where things live, how to run it, and what's non-obvious.

Before you write anything, read these supporting files:
- [claude-md-rules.md](./claude-md-rules.md) — quality rules your draft must satisfy (in this skill's directory)
- [authoring-rules.md](../../shared/authoring-rules.md) — cross-cutting writing standards (in the plugin's `shared/` folder)
- [example-output.md](./example-output.md) — a concrete example of a well-formed CLAUDE.md (in this skill's directory)

First, determine whether `CLAUDE.md` already exists at the repo root. Use the Glob tool (pattern `CLAUDE.md`) or the Read tool. If it exists, follow the "Review and update" path below. If it does not, follow the "Create from scratch" path.

---

## Create from scratch (when CLAUDE.md does not exist)

### Phase 1: Silent reconnaissance

Before asking the developer anything, gather what you can from the repo. Use the Read and Glob tools — do not shell out, since the skill should run on any platform.

- `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `composer.json`, or equivalent
- `README.md` or `README`
- Top-level directory listing — use the Glob tool with pattern `*` to enumerate
- Any existing `.claude/` configuration
- CI config (`.github/workflows/`, `.gitlab-ci.yml`, `Makefile`, etc.)
- Docker or container config (`Dockerfile`, `docker-compose.yml`)
- **Persisted playbook config.** Read `.claude/.playbook/config.json` if it exists. If it has a `docs_folder` field, that is the authoritative durable-context folder for this scope (set by `/playbook:init`). Note the value.
- **Likely docs roots.** If no config is set, scan top-level directories for any that could serve as the project's durable-context home: `docs/`, `documentation/`, `wiki/`, `claude-context/`, `.claude/context/` (legacy). Note which ones exist and whether they already contain a `CLAUDE.md` (the playbook's marker for "this is the durable-context folder"). This feeds Section 3 — the directory index needs to point future agents at the right folder.

Do not show the developer what you found yet. This is preparation for the interview.

### Phase 2: Interview — five sections, one at a time

Work through each section of the CLAUDE.md one at a time. Do not present multiple sections at once, and do not ask the developer to "review this draft" mid-interview.

#### Two rules that govern every question

1. **Probe what exists, never what might be added.** [authoring-rules.md](../../shared/authoring-rules.md) excludes aspirational content from the output file; the same rule applies to the questions you ask. Anchor every probe in something observable in the repo or in the developer's lived experience with the project. Do not invite the developer to brainstorm tooling, scripts, infrastructure, or processes that aren't already in place — if it isn't there, it doesn't belong in CLAUDE.md and it doesn't belong in your question.

2. **Make the turn boundary visible.** The developer needs to know when it's their move. Two mechanisms:
   - For **closed-form questions** (yes/no, pick-one-of-a-known-set), use the `AskUserQuestion` tool. The chip UI signals "your turn" unambiguously, and an "Other" option is added automatically so the developer can type a custom answer when none of the choices fit.
   - For **open-form questions** (where the developer has to write prose), end your message with the literal sentence: *Reply `ok` to confirm, or tell me what to change.*
   - Either way, **every section ends with an `AskUserQuestion` call** offering **Approve / Edit / Skip** so the developer can advance, revise, or omit the section explicitly. This is the only signal that the section is done.

#### Section format

Open every section with the header and the italic purpose blurb verbatim, then your inferred content, then your questions. The template:

```
**Section N — <Title>**

_<one-sentence purpose, italics, copied from this skill>_

<what you inferred from the repo, in 1–3 sentences>

<your follow-up questions or AskUserQuestion calls>
```

---

**Section 1 — What is this**

_One short paragraph: what the repo does, who it's for. No history, no roadmap._

Propose a 2–3 sentence description based on the README and project structure. If the README is thin or absent, say so plainly rather than padding the paragraph.

Ask: "Is anything in this description wrong or missing?" Close with *Reply `ok` to confirm, or tell me what to change.* Then call `AskUserQuestion` with options **Approve / Edit / Skip**.

**Section 2 — Stack**

_Key pieces only: framework, language/runtime, styling, data layer, package manager. No version numbers, no dev-tool noise._

List the stack pieces visible in dependency files and config. Then:

- Call `AskUserQuestion` for the **package manager** (options: `npm`, `pnpm`, `yarn`, `bun`) even when a lock file is present — lock files can be stale or committed by accident.
- In chat, ask: "Are any of these wrong, and is there anything in the *running* system that wouldn't show up in this repo (for example, a Redis used by the deployed service)?" This is the one place you can probe beyond what's in the source tree, because production dependencies aren't always checked in — but anchor the question in things that exist in production, not things the developer might add later. Close with *Reply `ok` to confirm, or tell me what to change.*
- End with `AskUserQuestion`: **Approve / Edit / Skip**.

Do not ask about test runners, CI plugins, or other tooling that isn't already configured in the repo.

**Section 3 — Directory index**

_Short table mapping top-level dirs (plus select subdirs) to what they contain. Not a file tree._

Propose a directory index from the actual folder structure. Then in chat ask: "Are any of the descriptions wrong, or are there subdirectories I left out that the agent should know about?" Close with *Reply `ok` to confirm, or tell me what to change.*

After the developer responds, append the playbook-managed entries below so the agent can discover the playbook's output once it appears. Pick the docs-folder path using this precedence (stop at the first match) — the same logic distil uses, so the index stays accurate even before any distillation has happened:

1. The `docs_folder` value from `.claude/.playbook/config.json`, if present (set by `/playbook:init`).
2. An existing folder at the repo root with a playbook-style `CLAUDE.md` inside it (the marker — see distil's `context-folder-template.md`).
3. An existing `docs/` folder, even without a marker.
4. Seed `docs/` by convention if none of the above apply — `/playbook:distil` will create it on first write.

| Path | What's there |
|------|-------------|
| `<docs-folder>/` | Durable project context — distilled conventions, security boundaries, design choices, and gotchas. Maintained by `/playbook:distil` in small files scoped to one area each. Consult related files before substantive work in the area they cover; they outrank general defaults. |
| `.claude/changes/` | In-flight change-specs. When working on a feature with a spec here, read only that spec. Other specs are either for unrelated work or pending distillation. |

Substitute the actual folder path for `<docs-folder>` — e.g. `docs/`, `documentation/`. Explain to the developer that these are added by convention so future agents can find the playbook's output. Then call `AskUserQuestion` with options **Keep both (recommended)** / **Drop both** — defaulting to keep.

If the docs folder you're pointing at already contains hand-written documentation, mention that briefly: distilled files will live alongside the existing content, and the per-folder `CLAUDE.md` (written by distil on first use) describes only what the playbook writes — not the team's other docs.

End the section with another `AskUserQuestion`: **Approve / Edit / Skip**.

**Section 4 — Commands**

_How to run, test, build, lint, and any commands the agent is likely to need. Only those that aren't obvious from the project type._

Read the script definitions (`package.json` scripts, `Makefile` targets, `justfile`, etc.) and propose a shortlist of commands worth documenting. Then in chat ask, focusing strictly on what already exists:

- Are any of the existing scripts non-obvious in behaviour? (e.g. needs a running database, requires a specific env file)
- Anything that looks standard but behaves differently here?

Do **not** ask whether there are commands the agent would need that aren't in the script definitions, and do not ask about test runners or build tooling the developer "plans to add". If none of the existing scripts are non-obvious, omit the section.

Close with *Reply `ok` to confirm, or tell me what to change.* End with `AskUserQuestion`: **Approve / Edit / Skip**.

**Section 5 — Gotchas**

_Non-obvious things that come from human experience: configuration quirks, implicit dependencies, values that look arbitrary but aren't, things that break silently. Highest value-per-word in the file._

You have nothing to propose from the repo here. Ask the developer to draw on lived experience with the project — not to invent hypothetical pitfalls:

- Has anything broken silently or unexpectedly in this project?
- Are there values that look arbitrary but have a specific reason?
- Has anything caught a new developer off guard?

If the developer has nothing concrete, omit the section. Do not press, and do not pad with speculation.

Close with *Reply `ok` to confirm, or tell me what to change.* End with `AskUserQuestion`: **Approve / Edit / Skip**.

### Phase 3: Self-review

Before presenting the draft:
1. Re-read [claude-md-rules.md](./claude-md-rules.md) and check every rule
2. Re-read [authoring-rules.md](../../shared/authoring-rules.md) and check every rule
3. Remove any section that's empty or only contains filler
4. Verify total length is under 150 lines
5. Verify no section exceeds 40 lines

Fix any violations before showing the draft.

### Phase 4: Present and confirm

Show the developer the complete assembled draft (all five sections in order). Then call `AskUserQuestion` with options **Write to disk / Edit / Discard** — this is the unambiguous sign-off step. If they pick Edit, ask in chat what to change, apply the edits, present the updated draft, and call `AskUserQuestion` again. Do not write the file until the developer picks **Write to disk**.

### Phase 5: Write to disk

Write the approved content to `CLAUDE.md` at the repo root.

---

## Review and update (when CLAUDE.md already exists)

### Phase 1: Read the existing file

Read the current `CLAUDE.md`. Assess it against [claude-md-rules.md](./claude-md-rules.md):
- Does it follow the five-section structure?
- Is anything outdated based on what you can see in the repo (dependency changes, new directories, removed scripts)?
- Is anything violating the quality rules (too long, padded, decorative)?

### Phase 2: Walk through each section

Go through the existing file section by section with the developer. The same two rules from the create flow apply here — **probe what exists, never what might be added**, and **make every turn boundary visible** (use `AskUserQuestion` for closed turns; close open questions with *Reply `ok` to confirm, or tell me what to change.*).

For each section:
1. Use the same header + italic-blurb opener as the create flow.
2. Quote what the section currently says.
3. Note anything that looks outdated or inconsistent with the current repo state, anchoring each note in a specific file or directory you can point to.
4. Ask the developer in chat whether anything should be added, removed, or corrected. Do not invite them to brainstorm content that isn't in the repo or in their lived experience.
5. End the section with `AskUserQuestion`: **Keep as-is / Apply edits / Drop section**.

If the file is missing a section that should exist (e.g. no Gotchas but the developer has some when prompted), propose adding it using the create-flow template. If the file has sections that don't belong (e.g. a "Future plans" section), point that out and offer to remove it via the same `AskUserQuestion`.

When walking through the directory index specifically, check whether the project's durable-context folder and `.claude/changes/` are listed. Identify the docs-folder candidate using the same precedence as the create flow's Section 3 (persisted config → existing playbook-marked folder → existing `docs/` → seed `docs/` by convention; legacy projects may still have `.claude/context/` listed, which is fine to leave or update). If either entry is missing, propose adding them with the standard playbook descriptions and confirm via `AskUserQuestion` (**Keep both (recommended)** / **Drop both**). These entries make the playbook's distilled context discoverable to agents working anywhere in the project, so an existing CLAUDE.md written before the playbook landed should be brought up to date.

### Phase 3: Self-review

Apply the same self-review as the create flow (Phase 3 above) to the updated version.

### Phase 4: Present changes

Show the developer what changed. Present it as a before/after diff or a clean updated version — whichever is clearer for the number of changes. Then call `AskUserQuestion` with options **Apply changes / Edit further / Discard**. Do not modify the file until the developer picks **Apply changes**.

### Phase 5: Apply changes

Write the approved updates to `CLAUDE.md`.

---

## Interview guidelines (both paths)

The turn-boundary and probe-what-exists rules in Phase 2 already cover the mechanics. A few principles that aren't captured by those rules:

- **Propose, then ask.** Always lead with what you inferred from the repo. The developer corrects or confirms — they shouldn't have to describe what you could have read.
- **Wait for real answers.** Don't interpret silence, "sure", or a fast Approve click as deep confirmation. If a section matters (especially Gotchas) and the answer is thin, probe once more before moving on.
- **The developer controls the pace.** Skip a section if they ask. Go back to an earlier section if they ask. The `AskUserQuestion` **Skip** option is a real choice, not an escape hatch you should discourage.
- **Be concise.** State what you found, ask what's missing, then hand the turn over. Don't justify why you included or excluded something unless the developer asks.
