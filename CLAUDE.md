# CLAUDE.md

This file is for agents working on the `playbook` plugin itself (repo: `ai-playbook`). It is excluded from plugin distribution via `.gitattributes`. Per the Claude Code docs, a CLAUDE.md at a plugin's root is not loaded as project context for plugin consumers — plugins contribute context through skills only.

## What is this

Source repository for the `playbook` Claude Code plugin (repo name: `ai-playbook`): a consultancy playbook for AI-assisted development. The plugin ships three skills (`claude-md-setup`, `distil`, `spec-workflow`) plus shared instructions, hooks, and a bundled MCP server.

The original design intent lives in `ai-playbook-research.md` at the repo root.

## Stack

| Piece | Choice |
|-------|--------|
| Format | Markdown skill content, JSON config, small shell scripts |
| Runtime | Runs inside Claude Code; no build step, no test framework, no package manager |
| Validation | Install locally and invoke skills in a test project |

## Directory index

| Path | What's there |
|------|-------------|
| `.claude-plugin/plugin.json` | Plugin manifest (name, version, description) |
| `skills/<skill-name>/SKILL.md` | Skill entry point; supporting files (templates, rules) live alongside the SKILL.md |
| `shared/` | Cross-skill content: authoring rules, distillation criteria, text injected by hooks |
| `scripts/` | Hook helper scripts. `inject-additional-context.sh` is a generic file-to-additionalContext emitter. `set-distillation-sentinel.sh` and `check-distillation-sentinel.sh` implement the soft auto-trigger for `/distil` (see Gotchas) |
| `hooks/hooks.json` | Plugin-level hooks: SessionStart context7 injection, PostToolUse Write/Edit/MultiEdit sentinel writer, UserPromptSubmit sentinel-reading reminder |
| `.mcp.json` | Bundled MCP server config (Context7, disabled by default) |
| `ai-playbook-research.md` | The original research note. Source of intent, not source of truth (see Gotchas) |
| `open-questions.md` | Design decisions deferred during implementation, with context for the next pass |

## Commands

No build or test commands. To verify changes end-to-end:

- Install: `claude /plugin install <path-to-this-repo>` in a test project
- Invoke a skill via its namespaced slash command: `/playbook:<skill-name>`
- Reload after changes: re-running `/plugin install` picks up the new version

## Gotchas

- **Do not assume what Claude Code supports — look up the docs.** Plugin, hook, and skill APIs have non-obvious boundaries: `SubagentStart` does not support `additionalContext` but `PostToolUse` does; skill-frontmatter hooks exist and are scoped to the skill's lifetime; `${CLAUDE_PLUGIN_ROOT}` works in hook commands but only `${CLAUDE_SKILL_DIR}` substitutes inside skill markdown. Before claiming a feature exists or designing around it, fetch the relevant page yourself with WebFetch — start at https://code.claude.com/docs/en/hooks, https://code.claude.com/docs/en/skills, and https://code.claude.com/docs/en/plugins-reference. Do not rely on agent-summarized answers when correctness matters; subagents have hallucinated and contradicted themselves on these specifics multiple times in this project.

- **The research file is intent, not specification.** Where `ai-playbook-research.md` conflicts with the Claude Code docs, the docs win and the implementation deviates. Document the deviation when it happens (e.g. the spec-workflow `SubagentStart` hook described in the research was dropped because the event doesn't support context injection).

- **Shared files are referenced two different ways.** Skill content references them via relative paths (`../../shared/<file>.md`) so the agent reading the skill can resolve them. Hook commands reference them via `${CLAUDE_PLUGIN_ROOT}/shared/<file>.md` because hooks run as shell commands with that variable set. These are not interchangeable.

- **Hook scripts must exit 0 silently when their input is missing.** Failing a SessionStart or PostToolUse hook with a non-zero exit pollutes the user's session. The generic helper at `scripts/inject-additional-context.sh` returns 0 with no output when the text file is absent.

- **The plugin is content-only.** No code is compiled or tested. The "verification" of changes is manual end-to-end invocation. There is no CI to catch a broken hook script or a malformed `plugin.json` — broken changes will only surface when a developer installs the plugin.

- **The `/distil` auto-trigger is a sentinel pattern, not a forced invocation.** No hook output field invokes a skill, so `/distil` cannot be called directly by the plugin. Instead, `set-distillation-sentinel.sh` (PostToolUse) writes `.claude/.playbook/distillation-pending` after each Write/Edit/MultiEdit, and `check-distillation-sentinel.sh` (UserPromptSubmit) reads it to inject a reminder via `additionalContext`. The agent is told to surface `/playbook:distil` only when the developer's current message reads as "wrapping up". `/distil` clears the sentinel as its final phase. The state directory is self-gitignored. Past attempts to use the `Stop` hook for this failed because Stop cannot inject `additionalContext` and cannot invoke skills — see [open-questions.md](open-questions.md) for the trade-space.
