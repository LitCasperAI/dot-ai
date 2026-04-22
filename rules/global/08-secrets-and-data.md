# Secrets and data handling

Stack-agnostic rules for how secrets, credentials, and sensitive
data are handled in code, logs, and commits. Stack rules define
the concrete tools (vault, secret manager, KMS); this file
defines the posture.

## Secrets never live in the repo

- No credentials, tokens, API keys, private keys, or `.env` files
  with real values in git — not in history, not in comments, not
  in tests, not in fixtures.
- Example configs (`.env.example`, `config.sample.yaml`) carry
  placeholder values only, clearly marked.
- If a secret is committed by accident, treat it as leaked: rotate
  the credential first, scrub history second.

## Loading secrets at runtime

- Secrets come from the environment or the project's sanctioned
  secret store. Code does not hardcode fallbacks.
- A missing required secret is a startup error, not a silent
  default.
- Do not pass secrets on the command line where they will appear
  in shell history or process lists. Use env vars or stdin.

## Logging and telemetry

- Never log secrets, tokens, auth headers, session cookies,
  passwords, or full payment details.
- Personal data (names, emails, IP addresses, device IDs) is
  logged only when there is a recorded reason, and is redacted or
  hashed where possible.
- Error traces that may capture request bodies must scrub
  sensitive fields before shipping to any sink.

## Test data

- Tests use synthetic data. Do not copy production data, even
  scrubbed, into the repo.
- Fixtures that look like real PII (real-shaped emails, plausible
  names) are fine; data that *is* real PII is not.

## Handling customer data at rest

- Use the platform's sanctioned storage and crypto primitives. Do
  not roll your own.
- Any change that touches authentication, authorization, PII
  storage, or payments is flagged for security review before
  merging, per `01-principles.md`.
