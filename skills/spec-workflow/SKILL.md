---
name: spec-workflow
description: Drive substantial work through plan mode and a written change-spec, then implement against it
when_to_use: When the developer is starting work that touches multiple files, introduces a new pattern, or has acceptance criteria they can't hold in their head. Not for one-line fixes or contained tweaks — those go through the direct path without a spec.
disable-model-invocation: true
allowed-tools: Bash(ls *) Bash(test *) Bash(mkdir *) Bash(date *) Read Edit Write
hooks:
  PostToolUse:
    - matcher: "ExitPlanMode"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/inject-additional-context.sh \"${CLAUDE_PLUGIN_ROOT}/shared/spec-workflow-exit-plan-instructions.md\" PostToolUse"
          timeout: 5
---

You are running the spec path of the playbook. The developer has work substantial enough to warrant a written contract before implementation begins.

Before doing anything, read these supporting files:
- [change-spec-template.md](./change-spec-template.md) — the seven-section structure your change-spec must follow
- [authoring-rules.md](../../shared/authoring-rules.md) — writing standards for any text you produce

## Phase 1: Confirm scope

Briefly confirm with the developer that this work warrants the spec path. If they describe something small (one file, one line, a typo, a config tweak), suggest they skip the skill and just do the work directly — the playbook is explicit that the direct path is correct for contained changes.

If the work is genuinely substantial, proceed.

## Phase 2: Enter plan mode and interview verbosely

Enter plan mode using the EnterPlanMode tool.

Inside plan mode, interview the developer thoroughly. Plan mode's default behaviour is to ask clarifying questions — go further than the default. Keep asking until you genuinely understand:

- What outcome the developer wants (not just what code to write)
- Which existing patterns or modules this should integrate with
- What's deliberately out of scope
- What "done" looks like — concrete, testable conditions
- How acceptance will be verified — automated tests, manual steps, or both
- Other parts of the system this change touches or depends on

Do not produce a plan until you can answer all of the above. If the developer's answers are thin, probe once more before proceeding. One question at a time. Wait for real answers.

When you have enough, produce the plan inside plan mode and present it for approval (via ExitPlanMode).

## Phase 3: After plan approval — write the change-spec BEFORE implementing

This step is mandatory and must happen before any file modifications. A `PostToolUse` hook scoped to this skill will inject a reminder of this when ExitPlanMode runs, but treat the hook as belt-and-suspenders, not the primary instruction.

Once the developer approves the plan via ExitPlanMode:

1. Read [change-spec-template.md](./change-spec-template.md)
2. Choose a kebab-case short name for the change (e.g. `rate-limiting`, `oauth-google`)
3. Transform the approved plan into a change-spec following the template's seven sections — Intent, Key changes, User-facing behaviour, Acceptance criteria, Verification approach, Dependencies, Area tags
4. Apply [authoring-rules.md](../../shared/authoring-rules.md) — concise, only what was actually decided in the plan, no padding

The plan already contains most of what the spec needs. The transformation is restructuring, not reinventing.

Show the developer the drafted change-spec. Wait for explicit approval. Apply edits if requested.

## Phase 4: Lazy folder setup

If the routing target is `.claude/changes/<name>.md` and the folder doesn't exist:

1. Create `.claude/changes/` (e.g. `mkdir -p .claude/changes`)
2. Copy the contents of [changes-folder-template.md](./changes-folder-template.md) into `.claude/changes/CLAUDE.md` — minus the leading "Template for..." preamble, starting from the `# Change-specs` heading

Then write the approved change-spec to `.claude/changes/<short-name>.md`.

## Phase 5: Implement against the spec

Now implement the work. The change-spec is the contract — refer back to its acceptance criteria as you go. If implementation reveals something the plan didn't anticipate (a constraint, a missing dependency, a wrong assumption), pause and discuss with the developer before continuing. Update the change-spec if the contract itself needs to change.

Do not silently expand scope. If the work needs to grow beyond what's in the spec, that's a decision for the developer, not for the agent mid-implementation.

## Phase 6: Verify against acceptance criteria

When implementation feels complete, walk through the change-spec's acceptance criteria one by one. For each:

- State whether it's met
- Point to the evidence (test output, manual verification step performed, file showing the change)

If any criterion is not met, the work isn't done — keep going.

If verification reveals the criteria were wrong (e.g. a missed edge case), that's a contract issue. Discuss with the developer, update the spec, then continue.

## Phase 7: Hand off to distillation

Once the work is verified, the change-spec has done its job. Tell the developer:

> The work is verified against the acceptance criteria. Run `/ai-playbook:distil` when you're ready to capture any durable knowledge from this change into the project's permanent context. After distillation, this change-spec can be removed.

Do not run distillation yourself, and do not delete the change-spec. Both are explicit developer actions.

## Notes

- Plan mode is the interview engine. Don't try to replicate plan mode's behaviour outside it — use it.
- A change-spec is a *contract*, not a *plan record*. The plan can be discarded; the spec persists until distilled.
- If the developer interrupts mid-flow (e.g. asks to skip ahead, change scope, abandon), follow their lead. The skill is a default pathway, not a forced one.
