---
name: security-review
description: Run a focused security review on a spec, plan, or diff that touches auth, authorisation, PII, payments, cryptography, session handling, or secret storage. Produces a stated threat model, a findings list, and — where a load-bearing decision is made — an ADR. Distinct from review-change's conditional security pass, which is lighter and inline.
---

## Inputs

- One of:
  - Path to a spec in `<paths.specs>/` (any status) whose design
    touches a security-sensitive area.
  - Path to a plan in `<paths.plans>/` (any status) for a
    security-sensitive feature.
  - A diff or PR reference for a change already in flight.
- Optional: `threat-model=<path>` pointing at an existing threat
  model document to review against, instead of authoring a new
  one.

## Personas

1. `security-reviewer` (from
   `.ai/personas/security-reviewer.md`, plus any
   `.ai/overrides/<stack>/security-reviewer.md`). Primary.
2. `architect` — consulted when findings require design change.
   The security-reviewer does not rewrite the spec; it surfaces
   findings that the architect resolves, producing an ADR where
   the decision is load-bearing.

## Rules loaded

From `.ai-local/project.yaml`: all entries under `rules.core`,
plus relevant entries from `rules.contextual` (specifically 
`08-secrets-and-data.md` and any stack-specific security rules).
The review cites the sanctioned primitives those rules declare — 
it does not invent its own.

## Steps

1. **Orient.** Read `.ai-local/project.yaml`. Resolve `paths.*`. Load
   the `security-reviewer` persona, all `rules.core`, and required
   `rules.contextual` files. Load the input artefact (spec, plan, or
   diff).

2. **Establish the threat model (security-reviewer).** If a
   threat model was supplied, load it. Otherwise author a short
   one for this change, covering:

   - **Assets** — what is worth protecting in scope of this
     change (credentials, user data, payment tokens, session
     state).
   - **Actors** — who could attack: unauthenticated internet,
     authenticated user, malicious insider, compromised device.
   - **Capabilities** — what each actor can do (send crafted
     input, intercept network, read device storage).
   - **Out of scope** — what this review does not cover, stated
     explicitly so silence is not taken as approval.
     A review without a stated threat model is a style review;
     per the persona, do not skip this step.

3. **Map the change to the threat model (security-reviewer).**
   Walk the artefact. For each asset named in step 2, identify
   where in the change it is created, passed, stored, logged,
   or destroyed. A change that touches an asset without a clear
   lifecycle is a finding.

4. **Check sanctioned primitives (security-reviewer).** Verify:

   - Crypto, auth, session, and secure-storage usage goes
     through the primitives declared by the loaded rules.
   - Input at trust boundaries (user input, URLs, deep-link
     params, third-party responses) is validated before it is
     trusted.
   - Logs and telemetry do not capture secrets, tokens, auth
     headers, or unredacted PII, per
     `global/08-secrets-and-data.md`.
   - Error paths do not silently drop privilege checks.
     Each finding names the rule or primitive at stake and
     proposes the smallest correct change.

5. **Classify findings (security-reviewer).** Label each
   finding:

   - **Block** — cannot ship as designed.
   - **Change-required** — must be addressed before merge but
     a design change is not needed.
   - **Advisory** — observation for the author; does not block.
     Do not downgrade a block to an advisory to unblock a
     release.

6. **Author an ADR when the decision is load-bearing
   (architect, if required).** If the review produces a
   decision that is hard to reverse or sets project-wide
   posture (new crypto primitive, change to session lifetime,
   new secret-storage boundary), the architect authors an ADR
   per `global/03-documentation.md`. The security-reviewer
   surfaces the need; the architect writes the ADR. The ADR
   links back to the spec or plan under review.

7. **Compose the review.** Produce a Markdown document
   structured as:

   - **Threat model** — from step 2.
   - **Asset lifecycles** — from step 3.
   - **Findings** — grouped by classification from step 5.
     Each finding: location, rule or primitive cited, proposed
     fix.
   - **Decisions** — links to any ADRs authored in step 6.
   - **Out-of-scope reminder** — restated from step 2 so the
     author does not read approval as blanket.

8. **Deliver and route.** Output the review document to the
   user. If the input was a PR or diff, offer to post the
   review as a single structured comment — but do not post
   without explicit user approval, per
   `global/02-agent-conduct.md`. Block-classified findings
   prevent merge regardless of whether the review is posted;
   the block lives in the review's verdict, not in the posting.

## Outputs

- A Markdown security review document delivered to the user.
- Zero or more ADRs under `<paths.decisions>/`, authored by
  `architect` when the review produced a load-bearing
  decision.
- No edits to the spec, plan, or diff being reviewed. The
  security-reviewer finds; the architect or implementer
  resolves.
