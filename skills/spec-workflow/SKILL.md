---
name: spec-workflow
description: Drive substantial work through plan mode and a written change-spec, then implement against it
when_to_use: When the developer is starting substantial work — adding a feature, building or implementing something new, refactoring across multiple files, or anything with acceptance criteria they can't hold in their head. Trigger on phrases like "let's add", "I want to build", "we need to implement", "help me refactor", or any request describing scope that sounds like more than a single-file change. Not for one-line fixes, typos, config tweaks, or contained edits — those go through the direct path without a spec. Phase 1 of the skill establishes the scope (asking the developer if the invocation didn't include one) and confirms it warrants the spec path, so it is safe to trigger on borderline or bare invocations; the developer can redirect if they want the direct path instead.
allowed-tools: Glob Read Edit Write
hooks:
  PostToolUse:
    - matcher: "ExitPlanMode"
      hooks:
        - type: command
          command: "node \"${CLAUDE_PLUGIN_ROOT}/scripts/inject.js\" \"${CLAUDE_PLUGIN_ROOT}/shared/spec-workflow-exit-plan-instructions.md\" PostToolUse"
          timeout: 5
---

You are running the spec path of the playbook. The developer has work substantial enough to warrant a written contract before implementation begins.

Before doing anything, read these supporting files:
- [change-spec-template.md](./change-spec-template.md) — the seven-section structure your change-spec must follow
- [authoring-rules.md](../../shared/authoring-rules.md) — writing standards for any text you produce

## Phase 1: Establish and confirm scope

First, locate the work.

- If the developer's invoking message already describes the change ("let's add X", "help me refactor Y"), use that as the scope.
- If the message is bare (e.g. just `/playbook:spec-workflow` with no surrounding description), ask one open question: "What do you want to build?" Do not propose options. Do not infer candidates from the repo. Wait for the developer's answer.

Once you have a described scope, briefly confirm it warrants the spec path. If it's small (one file, one line, a typo, a config tweak), suggest they skip the skill and just do the work directly — the playbook is explicit that the direct path is correct for contained changes.

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

1. Write `.claude/changes/CLAUDE.md` using the Write tool — it creates parent directories automatically, so no separate `mkdir` is needed (this is what keeps the skill cross-platform). The content is the body of [changes-folder-template.md](./changes-folder-template.md) minus the leading "Template for..." preamble, starting from the `# Change-specs` heading.

Then write the approved change-spec to `.claude/changes/<short-name>.md`.

## Phase 5: Implement against the spec

Now implement the work. The change-spec is the contract — refer back to its acceptance criteria as you go. If implementation reveals something the plan didn't anticipate (a constraint, a missing dependency, a wrong assumption), pause and discuss with the developer before continuing. Update the change-spec if the contract itself needs to change.

Do not silently expand scope. If the work needs to grow beyond what's in the spec, that's a decision for the developer, not for the agent mid-implementation.

## Phase 6: Verify against acceptance criteria

When implementation feels complete, walk through the change-spec's acceptance criteria one by one. For each, produce one of three outcomes: **met**, **unverified**, or **not met**. "Met" requires evidence; never claim it without producing one.

What counts as evidence depends on the criterion's type:

- **Behavioural criteria** ("endpoint returns 429 after N requests", "save flow shows a success toast"): require *observed output*. Paste the test command and its actual output inline, or paste the result of the manual step you ran. A reference to a test file's path is not evidence on its own — the test has to have run, and you have to show that it passed. If you did not run anything, the criterion is **unverified**, not met.
- **Structural criteria** ("middleware registered on every route in `routes/api.ts`", "old `JWT_TTL` config key removed"): a file/line citation is sufficient evidence, because the criterion is about presence or shape rather than behaviour. Quote the relevant lines inline so the developer can confirm without re-opening the file.

If any criterion is **not met**, the work isn't done — keep going.

If a criterion is **unverified** (e.g. no test runner is set up, manual verification needs the developer's environment), say so plainly and ask the developer how they want to resolve it — run it themselves, accept the gap, or pause until a test exists. Do not silently flip it to "met".

If verification reveals the criteria were wrong (e.g. a missed edge case, an unverifiable phrasing), that's a contract issue. Discuss with the developer, update the spec, then continue.

## Phase 7: Hand off to distillation

Once the work is verified, the change-spec has done its job. Tell the developer:

> The work is verified against the acceptance criteria. Run `/playbook:distil` when you're ready to capture any durable knowledge from this change into the project's permanent context. After distillation, this change-spec can be removed.

Do not run distillation yourself, and do not delete the change-spec. Both are explicit developer actions.

## Notes

- Plan mode is the interview engine. Don't try to replicate plan mode's behaviour outside it — use it.
- A change-spec is a *contract*, not a *plan record*. The plan can be discarded; the spec persists until distilled.
- If the developer interrupts mid-flow (e.g. asks to skip ahead, change scope, abandon), follow their lead. The skill is a default pathway, not a forced one.
