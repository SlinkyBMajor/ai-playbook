---
name: claude-md-setup
description: Set up or review the project's CLAUDE.md through an interactive interview with the developer
when_to_use: When a developer opens a project without a CLAUDE.md, asks about project setup or conventions, or wants to update an existing CLAUDE.md
allowed-tools: Glob Read Edit Write
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

Do not show the developer what you found yet. This is preparation for the interview.

### Phase 2: Interview — five questions, one at a time

Work through each section of the CLAUDE.md one at a time. For each section:
1. Tell the developer what you inferred from the repo
2. Ask them to confirm, correct, or add to it
3. Wait for their response before moving to the next section

Do not present all five at once. Do not ask the developer to "review this draft." One section, one conversation, then the next.

**Section 1: What is this?**
Propose a one-paragraph description based on the README and project structure. Ask the developer if it captures what the project does and who it's for. Keep it to 2–3 sentences.

**Section 2: Stack**
List what you inferred from dependency files and config. Ask specifically about:
- Package manager (npm, pnpm, yarn, bun — don't guess, even if there's a lock file; confirm)
- Anything stack-relevant the files didn't reveal (caching layers, message queues, external services)
- Anything you listed that's wrong or outdated

**Section 3: Directory index**
Propose a directory index based on the folder structure. Ask the developer:
- Are there directories you missed that the agent should know about?
- Are any of your proposed descriptions wrong?
- Are there subdirectories worth calling out specifically?

Keep the index to top-level directories plus a few important subdirectories. Not a file tree.

Always append these two playbook-managed entries at the end of the directory index, even if the folders do not yet exist on disk. They are created lazily when `/playbook:distil` and `/playbook:spec-workflow` first run, and listing them up front gives the agent a path to discover the distilled context once it appears:

| Path | What's there |
|------|-------------|
| `.claude/context/` | Distilled project conventions and durable design choices. Consult these files when working on related areas; they outrank general defaults. |
| `.claude/changes/` | In-flight change-specs. When working on a feature with a spec here, read only that spec. Other specs are either for unrelated work or pending distillation. |

Mention to the developer that these entries are added by convention, not because the folders necessarily exist yet, and ask if they want to keep them. Default to keeping unless the developer opts out.

**Section 4: Commands**
Read the project's script definitions (package.json scripts, Makefile targets, etc.). Ask:
- Are any of these non-obvious? (e.g., needs a running database, requires a specific env file)
- Are there commands the agent would need that aren't in the script definitions?
- Anything that looks standard but behaves differently here?

Only include commands the agent wouldn't figure out on its own. A standard `npm start` in a Node project doesn't need listing.

**Section 5: Gotchas**
You have nothing to propose here — gotchas come from human experience. Ask the developer directly:
- What breaks silently or unexpectedly in this project?
- Are there values that look arbitrary but have specific reasons?
- Configuration quirks, implicit dependencies, things that surprised a new developer?
- Anything where the "obvious" approach is wrong?

If the developer has nothing, that's fine. Omit the section rather than writing "None yet."

### Phase 3: Self-review

Before presenting the draft:
1. Re-read [claude-md-rules.md](./claude-md-rules.md) and check every rule
2. Re-read [authoring-rules.md](../../shared/authoring-rules.md) and check every rule
3. Remove any section that's empty or only contains filler
4. Verify total length is under 150 lines
5. Verify no section exceeds 40 lines

Fix any violations before showing the draft.

### Phase 4: Present and confirm

Show the developer the complete draft. Ask for sign-off:
- "Here's the full CLAUDE.md. Read through it — I'll make any changes you want before writing it to disk."

Wait for explicit approval. If they request changes, make them and present the updated version.

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

Go through the existing file section by section with the developer. For each:
1. State what the section currently says
2. Note anything that looks outdated or inconsistent with the current repo state
3. Ask if anything should be added, removed, or corrected

One section at a time. Same pacing as the create flow.

If the file is missing sections that should exist (e.g., no Gotchas but the developer has some), propose adding them.
If the file has sections that don't belong (e.g., a "Future plans" section), propose removing them.

When walking through the directory index specifically, check whether `.claude/context/` and `.claude/changes/` are listed. If not, propose adding them with the standard playbook descriptions (see the create flow's Section 3 for exact wording). These entries make the playbook's distilled context discoverable to agents working anywhere in the project, so an existing CLAUDE.md written before the playbook landed should be brought up to date.

### Phase 3: Self-review

Apply the same self-review as the create flow (Phase 3 above) to the updated version.

### Phase 4: Present changes

Show the developer what changed. Present it as a before/after diff or a clean updated version — whichever is clearer for the number of changes.

Wait for explicit approval.

### Phase 5: Apply changes

Write the approved updates to `CLAUDE.md`.

---

## Interview guidelines (both paths)

- **One question at a time.** Never present multiple sections for review simultaneously.
- **Propose, then ask.** Always lead with what you inferred. The developer corrects or confirms — they shouldn't have to describe what you could have read.
- **Wait for real answers.** Don't interpret silence or "sure" as deep confirmation. If a section matters (especially Gotchas), probe once more if the initial answer is thin.
- **The developer controls the pace.** If they want to skip a section, skip it. If they want to come back to something, go back.
- **No bulk approval.** Never present the full file mid-interview and ask "does this look right?" Complete all five sections first, then show the assembled result.
- **Be concise in your questions.** State what you found, ask what's missing. Don't explain your reasoning for including or excluding things unless asked.
