The developer just approved a plan via plan mode. Do not start implementation yet.

Before writing or editing any source files, transform the approved plan into a change-spec. The transformation is part of the spec workflow and is mandatory for this skill — the change-spec is the contract that drives implementation.

Steps:

1. Read the change-spec template at `${CLAUDE_PLUGIN_ROOT}/skills/spec-workflow/change-spec-template.md` to confirm the seven sections (Intent, Key changes, User-facing behaviour, Acceptance criteria, Verification approach, Dependencies, Area tags).

2. Choose a kebab-case short name for the change (e.g. `rate-limiting`, `oauth-google`).

3. If `.claude/changes/` does not exist, create it by writing `.claude/changes/CLAUDE.md` directly with the Write tool — Write creates parent directories automatically. The content for that file is the body of `${CLAUDE_PLUGIN_ROOT}/skills/spec-workflow/changes-folder-template.md`, starting from the `# Change-specs` heading.

4. Draft the change-spec at `.claude/changes/<short-name>.md`. The plan already contains most of what's needed — restructure rather than reinvent. Apply the authoring rules at `${CLAUDE_PLUGIN_ROOT}/shared/authoring-rules.md`: concise, only what was actually decided in the plan, no padding.

5. Show the drafted change-spec to the developer for approval before proceeding to implementation. Apply edits if requested.

Only after the change-spec is written and approved should you begin implementing.
