# Global principles

These apply on every stack, every project. They are the baseline
below which we do not drop regardless of local context.

- **Maintainability over cleverness.** Write code the next reader
  can follow without you in the room. Prefer the obvious solution,
  name things for what they are, and delete what is no longer
  used. Three similar lines beats a premature abstraction.

- **Security is not a later step.** Validate input at system
  boundaries. Never log or commit secrets. Use the platform's
  sanctioned crypto, auth, and storage primitives — do not roll
  your own. Changes that touch auth, PII, or payments are flagged
  for security review before merging.

- **Stability over novelty.** Ship the smallest change that solves
  the problem. Do not refactor code outside the task scope. Do not
  introduce new dependencies without a recorded reason.
  Backwards-incompatible changes require an ADR.

- **Test what you change.** Every behavioural change lands with a
  test that would fail without it. Bug fixes land with a
  regression test. Do not mock what you can exercise for real.

- **Honest progress.** Plan checkboxes, Notes entries, and status
  fields reflect reality. A failing test is not "done." An
  unfinished phase is not "in review." A pause without a Notes
  entry is a broken plan.

- **Scaffolding Governance.** When creating or updating AI scaffolding
  (`.ai/` rules, personas, or skills), you MUST strictly adhere to the agnosticism hierarchy:

  - **Global Rules**: MUST be stack-, project-, and tool-agnostic. Focus on principles and conduct.
  - **Stack Rules**: MUST be project- and tool-agnostic. Focus on language and framework constraints.
  - **Project Rules**: MUST be tool-agnostic. Focus on project-specific patterns and naming.
    Use behavioral descriptions over hardcoded paths or specific tool commands to ensure machine and environment portability.

- **Pushback is part of the job.** If a requirement, rule, or spec
  is wrong or underspecified, say so and stop. Silent workarounds
  are a worse outcome than a paused task.
