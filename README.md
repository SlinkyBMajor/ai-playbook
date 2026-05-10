# ai-playbook

A Claude Code plugin that gives a small, opinionated workflow for AI-assisted development. The premise: a single well-maintained `CLAUDE.md` plus a small `.claude/context/` folder beats elaborate process documentation, and a written change-spec is the right governance for substantial work — not a meeting.

The plugin contains three skills, three plugin-level hooks, and an optional bundled MCP server. Together they automate the parts of the workflow most often skipped: writing the initial context file, planning substantial changes properly, and keeping the permanent context current as work happens.

## Installation

```
claude /plugin install github.com/SlinkyBMajor/ai-playbook
```

The repo is named `ai-playbook`, but the plugin registers itself in Claude Code as `playbook`, so all commands are namespaced as `/playbook:<skill>`.

## Usage guide

### The mental model

The playbook organises any work into one of two paths, with the same closing step.

- **Direct path.** Small, contained changes — a config tweak, a one-line fix, a typo. No spec, no overhead. Just edit and move on.
- **Spec path.** Substantial work — multiple files, a new pattern, acceptance criteria you can't hold in your head. You enter a structured flow that produces a written change-spec at `.claude/changes/<name>.md`, then implements against it and verifies the work against the criteria.

Both paths converge on **distillation**. When work is done, ask: *did this change anything a future developer would want to know?* If yes, the durable knowledge gets captured into `CLAUDE.md` or a file under `.claude/context/`. The change-spec, if there was one, is then retired.

This is what keeps the permanent context small and current. Specs don't accumulate; they distil.

### Day one — set up the project

```
/playbook:claude-md-setup
```

Walks you through five questions one at a time: what the project is, the stack, where things live, commands, and gotchas. The skill reads the repo first and only asks about what it can't infer. Output is a concise `CLAUDE.md` at the repo root that the agent loads on every future session.

If a `CLAUDE.md` already exists, the same skill switches into review-and-update mode.

### Doing substantial work — the spec path

You can describe the work in plain language — *"let's add rate limiting to the API"*, *"I want to build a new auth flow"*, *"help me refactor the payments module"* — and the agent will recognise the scope and offer to enter the spec workflow. Or invoke it directly:

```
/playbook:spec-workflow
```

Either way, the skill enters plan mode and interviews you thoroughly — slower than the default pace, surfacing acceptance criteria, dependencies, and out-of-scope before code gets written. When you approve the plan, a hook fires that asks the agent to transform it into a seven-section change-spec at `.claude/changes/<name>.md`. You review and approve the spec. Implementation follows. The agent verifies its work against the acceptance criteria when it thinks the work is done.

The skill confirms scope as its first phase, so if the agent triggers it on borderline-substantial work you can redirect with one sentence ("just do it directly"). If you know the work is small to begin with, skip the skill entirely — the playbook is explicit that the direct path exists for a reason.

### Doing small work — the direct path

Just edit. Use Claude however you usually do.

The plugin still helps you here. After every `Write`, `Edit`, or `MultiEdit` in your project, a `PostToolUse` hook marks the project as having pending distillation candidates. On your next prompt, the agent receives a soft reminder: if your message reads as "wrapping up", surface `/playbook:distil` as the next step. The reminder doesn't fire distillation automatically — it just makes sure durable knowledge isn't silently slipping past.

### Closing the loop — distillation

```
/playbook:distil
```

Reads the recent changes (uncommitted diff first, recent commits if the tree is clean), evaluates them against five criteria — new conventions, security boundaries, durable design choices, non-obvious gotchas, corrections to existing context — and proposes updates to either `CLAUDE.md` or a file in `.claude/context/`. You're asked where each addition should land. Nothing is written until you approve.

If nothing in the change qualifies, the skill says so and stops. A turn that produces no distillation is the common case, not a failure.

After a successful run, the skill clears the pending-distillation sentinel so the soft reminder stops firing until the next round of edits.

## Skills

| Command | When to use | Invocation |
|---|---|---|
| `/playbook:claude-md-setup` | Project has no `CLAUDE.md`, or the existing one needs review | User or agent |
| `/playbook:spec-workflow` | Work touches multiple files, introduces a new pattern, or has acceptance criteria you can't hold in your head | User or agent |
| `/playbook:distil` | Recent changes may have produced durable knowledge worth capturing | User only |

## Hooks

The plugin installs three hooks that run automatically:

| Event | Behaviour |
|---|---|
| `SessionStart` | Injects an instruction telling the agent to use Context7 for up-to-date library docs when the MCP server is enabled. Harmless when disabled. |
| `PostToolUse` on `Write\|Edit\|MultiEdit` | Touches `.claude/.playbook/distillation-pending` so the next user prompt carries a distillation reminder. |
| `UserPromptSubmit` | Reads the sentinel; if present, injects the reminder text into the agent's context. |

The `spec-workflow` skill also installs a skill-scoped `PostToolUse` hook on `ExitPlanMode` that fires only while that skill is running.

## Files the plugin creates in your project

| Path | Created by | Purpose |
|---|---|---|
| `CLAUDE.md` | `claude-md-setup` | Root context file loaded on every session |
| `.claude/context/` | `distil` (lazy) | Permanent, distilled knowledge — small files scoped to one area each |
| `.claude/changes/` | `spec-workflow` (lazy) | Ephemeral change-specs; removed after distillation |
| `.claude/.playbook/distillation-pending` | PostToolUse hook | Sentinel for the soft auto-trigger; the directory is self-gitignored |

`.claude/context/` and `.claude/changes/` each carry their own slim per-folder `CLAUDE.md` describing what belongs there.

## Bundled MCP servers

**Context7** — fetches current library and framework documentation on demand. Disabled by default in `.mcp.json`. Enable it in your project if you want the agent to verify API usage against up-to-date docs. The SessionStart instruction is phrased conditionally, so it remains harmless when Context7 is off.
