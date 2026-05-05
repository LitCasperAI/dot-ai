# Version control

Applies to every stack. Stacks may tighten these rules; they may
not relax them.

## Branches

- Work on a feature branch, never directly on `main` (or the
  project's declared default branch).
- Branch names are lowercase-kebab and carry a short purpose:
  `fix-login-timeout`, `spec-offline-mode`. Avoid personal
  prefixes unless the team requires them.

## Commits

- One logical change per commit. A commit that mixes a refactor
  with a behaviour change is two commits.
- Commit messages use the imperative mood: "add retry to uploader,"
  not "added" or "adds."
- The subject line is under 72 characters. The body explains
  _why_, not _what_; the diff already shows what.
- Do not amend a commit that has been pushed to a shared branch.
  Add a new commit instead.

## Multi-line messages — use a file

Shell escaping of `\n` inside `git commit -m` and `gh pr create
--body` is **unreliable across platforms** (literal `\n` on
Windows cmd/PowerShell, swallowed newlines in some CI shells).
Always use a **temp file** for any message longer than a single
line:

```bash
# git commit
cat > /tmp/commit-msg.md <<'EOF'
feat: add scaffold governance rule

Adds 13-scaffold-governance.md to the global rule set.
Ensures agents know to contribute general scaffold content
via PR to beep-dot-ai-root, not by editing the submodule.
EOF
git commit -F /tmp/commit-msg.md

# gh pr create / edit
cat > /tmp/pr-body.md <<'EOF'
## Summary
…multi-line description…
EOF
gh pr create --title "feat: …" --body-file /tmp/pr-body.md
```

- Use `git commit -F <file>`, not `-m` with embedded newlines.
- Use `gh pr create --body-file <file>`, not `--body`.
- Use `gh pr edit --body-file <file>` for updates.
- Clean up the temp file after the command succeeds.

## Pushing and merging

- Never `git push --force` (or `--force-with-lease`) to a shared
  or protected branch without explicit user approval.
- Never skip commit hooks (`--no-verify`) or signing
  (`--no-gpg-sign`) unless the user has explicitly asked for it.
  If a hook fails, fix the cause.
- Do not merge your own PR without the review the project
  requires. "LGTM from the author" is not review.

## Pull requests

- Keep PRs small enough to review in one sitting. If a change
  needs a narrative to be understood, split it.
- The PR description links to the brief, spec, plan, or ADR that
  motivated the change. If none exists, say so and explain.
- Do not close or reopen someone else's PR or issue without a
  clear reason written into the comment.

## What never goes in git

- Secrets, credentials, tokens, `.env` files with real values,
  private keys, customer data.
- Build artefacts, `node_modules`, `.venv`, editor caches, OS
  junk — these belong in `.gitignore`.
- Large binaries unless the repo uses LFS and the team has agreed
  the file belongs there.
