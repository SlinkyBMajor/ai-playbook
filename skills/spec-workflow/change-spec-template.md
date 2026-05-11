# Change-spec template

Use this template when transforming an approved plan into a change-spec. The file lives at `.claude/changes/<short-name>.md`. The short name is a kebab-case slug describing the change (e.g. `rate-limiting`, `oauth-google`).

Each section below has a purpose. Fill what applies; remove what doesn't. Resist the urge to pad — a change-spec is a contract, not a narrative.

---

# {Title — short noun phrase, e.g. "API rate limiting"}

## Intent

What's being changed and why. Plain language. Two to four sentences.

State the problem this change addresses and the outcome it produces. Do not describe implementation here.

## Key changes

A short list of the substantive changes the plan introduces. One bullet per change. Summarize what the work *introduces*, not the step-by-step task breakdown.

- {First substantive change}
- {Second substantive change}
- {Third substantive change}

## User-facing behaviour

The behaviour the user (or calling system) will observe once the change ships. Concrete, testable from the outside.

For purely internal changes with no observable surface, write "None — internal only" and remove this section's body.

## Acceptance criteria

Explicit, testable conditions that must be true for the change to be considered complete. Each must be specific enough that "did this pass?" has a clear yes or no answer.

Phrase each criterion as something a verifier can *run or observe*, not something they have to interpret. Two styles work:

- **Behavioural criteria**: name the input and the expected observable output. "Endpoint returns 429 with a `Retry-After` header after 100 requests from one IP within 60s" beats "rate limiting works correctly".
- **Structural criteria**: name the file, symbol, or config key and the expected state. "`RateLimiter` middleware is registered on every route in `routes/api.ts`" beats "rate limiter is applied everywhere".

A criterion phrased so the only check is "the agent reviewed it and said yes" is unverifiable — rewrite it.

- {Criterion 1 — checkable condition, behavioural or structural}
- {Criterion 2}
- {Criterion 3}

## Verification approach

How acceptance will be checked. Names the mechanism, not the test code itself.

Examples:
- "Integration tests in `test/api/rate-limit.test.ts` cover all acceptance criteria"
- "Manual verification: hit endpoint X 101 times within a minute and confirm the 101st returns 429"
- "Both: unit tests for the limiter implementation, manual verification for the 429 response"

## Dependencies

Other parts of the system this change relies on or interacts with. Internal modules, external services, libraries, or other in-flight work. Skip if standalone.

- {Dependency 1}
- {Dependency 2}

## Area tags

Free-form indicators of which parts of the system the work touches. Used by distillation to route updates to the right permanent specs.

`{tag1}` `{tag2}` `{tag3}`

Examples: `auth`, `api`, `data-layer`, `ui`, `infra`, `security`, `migrations`.
