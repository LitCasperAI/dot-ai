# Terraform / IaC Constraints

Hard rules for Terraform and infrastructure-as-code in this
project. If a constraint here conflicts with what you're about
to write, stop and escalate — don't route around it.

These are constraints, not suggestions. Every item in this file
is something that should trigger pushback in code review.

---

## Language and tooling

- **Terraform >= 1.6** with the **OpenTofu** compatibility
  path kept open. Do not use features exclusive to one fork
  without an ADR.
- **Terragrunt** is the orchestration layer for multi-environment
  deployments. Raw `terraform` commands are used for module
  development only.
- **HCL only.** No JSON-based `.tf.json` files. No CDKTF or
  Pulumi unless the project has an ADR approving the switch.
- **Google Cloud Provider** (`hashicorp/google` and
  `hashicorp/google-beta`) is the primary provider. Pin exact
  versions in `required_providers`.

## Module structure

```
infra/
├── modules/
│   └── <module-name>/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── README.md
├── environments/
│   ├── dev/
│   │   └── terragrunt.hcl
│   ├── staging/
│   │   └── terragrunt.hcl
│   └── prod/
│       └── terragrunt.hcl
└── terragrunt.hcl          ← root config (remote state, provider)
```

- **One module per concern.** A module provisions a single
  logical resource group (e.g., GKE cluster, Cloud SQL
  instance, IAM bindings). Multi-concern modules are split.
- **Every module has a `README.md`** generated or maintained
  by `terraform-docs`. It lists inputs, outputs, and a usage
  example.

## State management

- **Remote state in GCS** with state locking enabled. No local
  state files checked in — ever. `terraform.tfstate` is in
  `.gitignore`.
- **One state file per environment per module.** State
  boundaries match blast radius boundaries. A single state file
  that contains dev + prod is a critical finding.
- **State manipulation (`terraform state mv/rm/import`) requires
  peer review** before execution. Document what was done and
  why in the PR.

## Variables and outputs

- **Every variable has a `description` and a `type`.**
  `any` type is rejected. Use precise types (`string`,
  `number`, `list(string)`, `object({…})`).
- **Sensitive variables are marked `sensitive = true`.** This
  prevents them from appearing in plan output and logs.
- **No hardcoded values.** Project IDs, regions, CIDR ranges,
  and resource names come from variables or Terragrunt inputs,
  not from literal strings in `.tf` files.
- **Outputs are declared for any value consumed by another
  module or environment.** Use `terraform_remote_state` or
  Terragrunt `dependency` blocks to wire them.

## Naming

- **Resource names follow `<project>-<env>-<purpose>`.**
  Example: `<org>-prod-api-cluster`.
- **Terraform resource names (the label after the type) are
  snake_case** and descriptive: `google_container_cluster.api`,
  not `google_container_cluster.this`.
- **Tags/labels are mandatory** on every resource that supports
  them: `project`, `environment`, `managed-by: terraform`,
  `team`.

## Security

- **No inline IAM policies.** Use `google_project_iam_member`
  or `google_project_iam_binding` with least-privilege roles.
  `roles/owner` and `roles/editor` are rejected in review.
- **Service account keys are not created by Terraform.** Use
  Workload Identity Federation or impersonation. If a key is
  absolutely required, it is stored in Secret Manager and
  rotated.
- **Secrets are never in `.tf` or `.tfvars` files.** Use
  `google_secret_manager_secret_version` data sources or
  environment-injected variables.
- **Network rules default to deny.** Firewall rules and VPC
  configurations start closed and open specific ports/ranges
  with justification.

## Plans and applies

- **Every PR includes a `terraform plan` output** as a comment
  or artifact. Reviewers verify what will change before
  approving.
- **`terraform apply` runs only in CI** (or via Terragrunt in
  CI). Manual applies are blocked by the sandbox guard scripts
  unless `ALLOW_TF_APPLY=1` is set.
- **`terraform destroy` is blocked by default.** The sandbox
  Terraform guard intercepts it. Intentional destruction
  requires `ALLOW_TF_DESTROY=1` and a documented reason.
- **No `-auto-approve` in CI for production.** Production
  applies require an explicit approval gate.

## Drift and compliance

- **Scheduled drift detection** runs `terraform plan` nightly
  (or on a defined cadence) and alerts on unexpected changes.
- **`terraform validate` and `tflint` run in CI** on every PR.
  `tflint` uses the Google Cloud ruleset.
- **`checkov` or `tfsec`** scans for security misconfigurations
  as part of the CI pipeline.

## Things that are out of scope for this file

Testing conventions (`02-testing.md`), performance and cost
(`03-cost-and-performance.md`), and module authoring conventions
(`04-module-conventions.md`) each live in their own file.
Don't pile them into this one.

