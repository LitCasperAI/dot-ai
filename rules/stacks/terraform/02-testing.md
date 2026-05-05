# Terraform / IaC Testing

## Module testing

- **Terratest (Go) or `terraform test` (built-in)** for module
  integration tests. Every shared module has at least one test
  that provisions real resources in a sandbox project, asserts
  outputs, and destroys.
- **Tests run in an isolated GCP project** designated for
  ephemeral infra. Never run tests against dev, staging, or
  production.
- **Test cleanup is mandatory.** Tests that fail must still
  destroy resources. Use `defer` (Terratest) or ensure the
  test framework handles cleanup.

## Validation

- `terraform validate` — syntax and internal consistency.
- `tflint` with the Google Cloud plugin — provider-specific
  linting.
- `checkov` or `tfsec` — security policy checks.
- All three run on every PR in CI. Failures block merge.

## Plan review

- Every PR attaches the full `terraform plan` output for each
  affected environment. Reviewers check:
  - No unexpected destroys or replacements.
  - Resource counts match expectations.
  - Sensitive values are redacted.

## Cost estimation

- `infracost` runs on PRs that modify infra to surface cost
  impact. Significant cost increases require explicit approval.

