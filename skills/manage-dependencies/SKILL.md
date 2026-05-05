---
name: manage-dependencies
description: Analyzes project dependencies, proposes upgrades, and resolves vulnerabilities based on external scans (e.g., WIZ CVEs) or user requests.
---

## Inputs

- Optional: specific packages to inspect or upgrade.
- Optional: CVE reports or vulnerability scan results provided by the user.

## Personas

1. `dependency-manager` — analyzes dependencies and proposes resolutions.
2. `architect` — consulted if a major dependency swap changes the system architecture.

## Rules loaded

From `.ai-local/project.yaml`: all entries under `rules.core` and
relevant entries from `rules.contextual` (specifically
`07-dependencies.md`).

## Steps

1. **Orient.** Read `.ai-local/project.yaml` to identify the active stacks. 
   Load all `rules.core` and required `rules.contextual` files. 
   Locate the relevant package manager configuration files (e.g., 
   `package.json`, `yarn.lock`, `android/build.gradle`).
2. **Analyze Input.** The `dependency-manager` parses any provided CVEs, security reports, or specific user requests.
3. **Inspect.** Review the package configuration files and lockfiles to determine current versions and their dependency trees.
4. **Formulate Strategy.** Propose specific version bumps to resolve identified vulnerabilities. If a package is deprecated, propose an established replacement. Ensure proposed versions do not violate existing `rules/stacks/<stack>/` constraints.
5. **Deliver.** Output a structured report to the user summarizing:
   - Vulnerabilities addressed.
   - Proposed version bumps (categorized by safe/minor vs breaking/major).
   - Any recommended package replacements.
6. **Execute (Optional).** If explicitly requested by the user, execute the necessary shell commands to apply the changes. **Critical Security Precaution:** You MUST check which package manager is currently used by the project (e.g., by checking for `yarn.lock`, `package-lock.json`, `Gemfile.lock`) to ensure you run the correct commands (e.g., do not run `yarn install` if the project uses `npm`). Furthermore, any installation or modification of packages MUST be explicitly approved by the user and MAY NEVER be performed automatically. Before executing any shell commands, you MUST strictly validate the exact package name and version against the official registry (e.g., `npm info`) or the existing lockfile to ensure it is a safe, known package, mitigating the risk of command injection or typo-squatting.

## Outputs

- A structured report of proposed dependency changes and security mitigations.
- Optional: modifications to package configuration and lockfiles if execution is requested.
