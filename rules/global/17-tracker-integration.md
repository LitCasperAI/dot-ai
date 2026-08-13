# Tracker-agnostic publish/sync contract

Governs how `create-plan`, `implement`, `archive-plan`, and
`refresh-docs` interact with an optional external issue tracker.
Stack-agnostic: this scaffold has no application code for this
feature, so "interface" below means an agent-executable contract,
not a function signature.

## The four operations

Any configured tracker type must support these, expressed
behaviourally:

- **Publish** — given a title, body, optional label set, and
  optional parent id, create an issue and return its `{id, url}`.
- **Update** — given an issue id and a body/description patch,
  apply it.
- **Close** — given an issue id, close/resolve it.
- **Link-blocked-by** — given an issue id and a list of blocking
  issue ids/references, record the relationship. Default mechanism
  is a text line appended to the issue body (`Blocked by: #12,
  #14`) for cross-tracker portability; a tracker type may
  additionally use a native blocking link where one exists, but
  text is never omitted even when the native link is used, so the
  record survives a tracker migration.

## Mechanism table

Each `tracker.type` maps the four operations to its own mechanism:

| type             | Publish/Update/Close mechanism                                                                                            |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `gitlab`         | `glab issue create/edit/close`, or GitLab REST `POST/PUT /projects/:id/issues`, authenticated via the env var named in `tracker.credential_env` (private token header). |
| `github`         | `gh issue create/edit/close`, or GitHub REST, same credential pattern.                                                      |
| `jira`           | Jira REST `POST/PUT /rest/api/2/issue`, token or basic auth via `credential_env`.                                          |
| `local` / absent | Every operation is a documented no-op. Skills log a one-line note ("tracker: local — skipping publish") and proceed exactly as they did before this rule existed. |

## Credential handling

`project.yaml` never stores a secret (per this file's own header
and `08-secrets-and-data.md`). `tracker.credential_env` names an
environment variable (e.g. `GITLAB_TOKEN`); the agent reads the
token from the process environment at call time. If the variable is
unset when a non-`local` tracker is configured, the agent stops and
surfaces the gap rather than silently no-op'ing — a configured
tracker with no credential is a misconfiguration, not "no tracker."

## Failure handling

A publish/update/close call that fails (network, auth, 4xx/5xx) is
surfaced to the user immediately; the skill does not silently
continue as if the call had succeeded, and does not retry
automatically. This matches `02-agent-conduct.md`'s honesty
requirements.
