# Validation discipline

Rules for enforcing project-specific verification during the
development lifecycle. Stack-agnostic.

## Define success criteria first

- Before starting, transform the task into a verifiable goal rather
  than a vague instruction. "Add validation" becomes "write tests
  for invalid inputs, then make them pass." "Fix the bug" becomes
  "write a test that reproduces it, then make it pass."
- For multi-step tasks, state the plan as step → verify pairs:
  ```
  1. [Step] → verify: [check]
  2. [Step] → verify: [check]
  ```
- Weak success criteria ("make it work") force constant
  clarification; strong ones let you loop to done independently.

## Finality through Validation

- **Validation is Mandatory**: You are strictly prohibited from marking a task as complete or providing a final summary until you have autonomously executed the project's relevant verification suite (e.g., linting, type-checking, or tests).
- **Autonomous Execution**: Verification is a required part of the implementation lifecycle. Execute these checks proactively as part of your "Act" and "Validate" phases without seeking per-task authorization.
- **Verification Integrity**: If validation fails, you must diagnose and fix the issue or revert the change. Never report a "successful" implementation that leaves the codebase in a broken state or violates established workspace standards.
- **Verification is Path to Finality**: A task is not finished when the code is written; it is finished when the work is verified by the project's own tools.
