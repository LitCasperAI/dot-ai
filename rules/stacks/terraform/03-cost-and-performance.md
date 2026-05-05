# Terraform / IaC Cost and Performance

## Cost governance

- **Labels are mandatory.** Every resource carries `project`,
  `environment`, `team`, and `managed-by` labels. Billing
  dashboards filter by these.
- **Right-sizing is reviewed.** Machine types, disk sizes, and
  replica counts are reviewed for cost-appropriateness. A
  `n2-standard-64` for a low-traffic service is a review
  finding.
- **Committed use discounts and sustained use** are managed
  centrally, not per-module. Modules declare resource types;
  the platform team handles discount contracts.

## Performance

- **Terraform plan/apply performance** is kept reasonable by
  limiting state size. A state file with >500 resources is a
  signal to split.
- **Provider parallelism** (`-parallelism=N`) is tuned in CI
  to avoid API rate limits. Default is 10; increase only with
  evidence.
- **Module composition over monoliths.** Small focused modules
  plan faster and have smaller blast radius than one module
  that provisions everything.

