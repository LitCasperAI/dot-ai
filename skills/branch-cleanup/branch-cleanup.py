#!/usr/bin/env python3
"""branch-cleanup.py — Audit git branches and generate a cleanup report.

Usage:
    python3 branch-cleanup.py [--main BRANCH] [--repo-name NAME] [--output DIR]

The script classifies local and remote branches, analyses release/hotfix
tags, and writes a structured report to both stdout (terminal-friendly)
and a Markdown file (properly rendered).

Designed to be invoked by the branch-cleanup AI skill.  The AI agent
handles user interaction (approvals, deletions) after reviewing the
report output.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional


# ---------------------------------------------------------------------------
# Git helpers
# ---------------------------------------------------------------------------

def git(*args: str, check: bool = True) -> str:
    """Run a git command and return stripped stdout."""
    result = subprocess.run(
        ["git"] + list(args),
        capture_output=True, text=True, check=check, timeout=120,
    )
    return result.stdout.strip()


def git_lines(*args: str, check: bool = True) -> list[str]:
    out = git(*args, check=check)
    return [l for l in out.splitlines() if l.strip()] if out else []


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------

@dataclass
class BranchInfo:
    name: str
    is_remote: bool = False
    category: str = ""          # merged, squash-merged, stale, active, current
    last_commit_date: Optional[datetime] = None
    days_ago: int = 0
    tag_status: str = ""        # tagged-at-head, tagged-behind, untagged, n/a
    matching_tag: str = ""
    tag_behind_count: int = 0
    merged: bool = False

    @property
    def short_name(self) -> str:
        if self.is_remote and self.name.startswith("origin/"):
            return self.name[7:]
        return self.name

    @property
    def is_release_or_hotfix(self) -> bool:
        sn = self.short_name
        return sn.startswith("release/") or sn.startswith("hotfix/")

    @property
    def version(self) -> str:
        sn = self.short_name
        for prefix in ("release/", "hotfix/"):
            if sn.startswith(prefix):
                return sn[len(prefix):]
        return ""


# ---------------------------------------------------------------------------
# Detection helpers
# ---------------------------------------------------------------------------

def detect_main_branch(override: Optional[str]) -> str:
    if override:
        return override
    # Try symbolic ref
    try:
        ref = git("symbolic-ref", "refs/remotes/origin/HEAD", check=True)
        return ref.replace("refs/remotes/origin/", "")
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        pass
    # Probe common names
    for candidate in ("main", "master", "develop"):
        try:
            git("rev-parse", "--verify", f"origin/{candidate}", check=True)
            return candidate
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            continue
    print("ERROR: Cannot detect main branch. Use --main.", file=sys.stderr)
    sys.exit(1)


def resolve_repo_name(override: Optional[str]) -> str:
    """Resolve human-readable repo name (sandbox-aware)."""
    if override:
        return override
    cwd = os.getcwd()
    # /workspace/<name> where name doesn't start with '.'
    m = re.match(r"^/workspace/([^./][^/]*)", cwd)
    if m:
        return m.group(1)
    # /workspace/.mnt/.repoN — scan symlinks
    m = re.match(r"^/workspace/\.mnt/(\.repo\d+)", cwd)
    if m:
        repo_id = m.group(1)
        ws = Path("/workspace")
        if ws.exists():
            for link in ws.iterdir():
                if link.is_symlink():
                    target = os.readlink(str(link))
                    if target == f".mnt/{repo_id}":
                        return link.name
    # Fallback: git toplevel basename
    try:
        toplevel = git("rev-parse", "--show-toplevel")
        return os.path.basename(toplevel)
    except Exception:
        return "unknown"


def get_current_branch() -> Optional[str]:
    try:
        return git("symbolic-ref", "--short", "HEAD")
    except subprocess.CalledProcessError:
        return None  # detached HEAD


def get_gone_branches() -> set[str]:
    """Return set of local branch names whose upstream is gone (remote deleted)."""
    gone = set()
    for line in git_lines("branch", "-vv", "--format=%(refname:short) %(upstream:track)"):
        parts = line.strip().split(None, 1)
        if len(parts) == 2 and "[gone]" in parts[1]:
            gone.add(parts[0])
    return gone


def get_commit_date(ref: str) -> Optional[datetime]:
    try:
        ts = git("log", "-1", "--format=%aI", ref)
        return datetime.fromisoformat(ts)
    except Exception:
        return None


def is_merged_into(branch: str, main: str) -> bool:
    """Check if branch is in --merged list of main."""
    merged = git_lines("branch", "-a", "--merged", main)
    cleaned = [b.strip().lstrip("* ") for b in merged]
    return branch in cleaned


def is_squash_merged(branch: str, main: str) -> bool:
    """Check if a branch was squash-merged into main.

    Uses `git cherry` which compares patch-ids: if all commits on the
    branch have equivalents on main (prefix '-'), the branch is
    effectively merged even though git doesn't see it as --merged.

    Falls back to empty-diff check if git cherry fails.
    """
    try:
        # git cherry: '-' = already on upstream, '+' = unique to branch
        lines = git_lines("cherry", main, branch, check=False)
        if lines and all(line.startswith("-") for line in lines):
            return True
    except Exception:
        pass

    # Fallback: check if the tree at branch tip is identical to main
    try:
        result = subprocess.run(
            ["git", "diff", f"{main}...{branch}", "--quiet"],
            capture_output=True, timeout=30,
        )
        return result.returncode == 0
    except Exception:
        return False


def get_all_tags() -> dict[str, str]:
    """Return {tag_name: commit_sha} for all tags."""
    tags = {}
    for line in git_lines("tag", "-l", "--format=%(refname:short) %(objectname:short)"):
        parts = line.split(None, 1)
        if len(parts) == 2:
            tags[parts[0]] = parts[1]
    # Also dereference annotated tags
    for line in git_lines("tag", "-l", "--format=%(refname:short) %(*objectname:short)"):
        parts = line.split(None, 1)
        if len(parts) == 2 and parts[1]:
            tags[parts[0]] = parts[1]
    return tags


def analyse_release_tag(branch: BranchInfo, all_tags: dict[str, str]) -> None:
    """Determine tag status for a release/hotfix branch."""
    version = branch.version
    if not version:
        branch.tag_status = "n/a"
        return

    # Get branch tip commit
    ref = branch.name if not branch.is_remote else branch.name
    try:
        tip_sha = git("rev-parse", "--short", ref)
    except Exception:
        branch.tag_status = "untagged"
        return

    # Check common tag patterns
    candidates = [
        version,                # 171.0.0
        f"v{version}",         # v171.0.0
        f"release/{version}",  # release/171.0.0
        f"hotfix/{version}",   # hotfix/171.0.0
        f"release-{version}",  # release-171.0.0
        f"hotfix-{version}",   # hotfix-171.0.0
    ]

    matching_tag = None
    tag_sha = None
    for candidate in candidates:
        if candidate in all_tags:
            matching_tag = candidate
            tag_sha = all_tags[candidate]
            break

    if not matching_tag:
        branch.tag_status = "untagged"
        return

    branch.matching_tag = matching_tag

    # Is tag at HEAD?
    if tag_sha == tip_sha:
        branch.tag_status = "tagged-at-head"
    else:
        # Count commits between tag and branch tip
        try:
            count_str = git("rev-list", "--count", f"{tag_sha}..{tip_sha}")
            branch.tag_behind_count = int(count_str)
        except Exception:
            branch.tag_behind_count = -1
        branch.tag_status = "tagged-behind"


# ---------------------------------------------------------------------------
# Classification
# ---------------------------------------------------------------------------

def classify_branches(main_branch: str) -> list[BranchInfo]:
    now = datetime.now(timezone.utc)
    stale_days = 90
    current = get_current_branch()
    all_tags = get_all_tags()
    gone_branches = get_gone_branches()

    # Merged branch lists (for fast lookup)
    merged_local = set(
        b.strip().lstrip("* ")
        for b in git_lines("branch", "--merged", main_branch)
    )
    merged_remote = set(
        b.strip()
        for b in git_lines("branch", "-r", "--merged", main_branch)
    )

    branches: list[BranchInfo] = []

    # --- Local branches ---
    for raw in git_lines("branch", "--format=%(refname:short)"):
        name = raw.strip()
        if name == main_branch:
            continue

        bi = BranchInfo(name=name, is_remote=False)

        if name == current:
            bi.category = "current"
            branches.append(bi)
            continue

        # Date info
        bi.last_commit_date = get_commit_date(name)
        if bi.last_commit_date:
            bi.days_ago = (now - bi.last_commit_date).days

        # Merged?
        bi.merged = name in merged_local
        if not bi.merged:
            bi.merged = is_squash_merged(name, main_branch)
            if bi.merged:
                bi.category = "squash-merged"

        # Upstream gone (remote branch deleted after merge)?
        if not bi.merged and name in gone_branches:
            bi.merged = True
            bi.category = "merged"

        if bi.merged and not bi.category:
            bi.category = "merged"

        # Release/hotfix tag analysis
        if bi.is_release_or_hotfix:
            analyse_release_tag(bi, all_tags)
            if bi.tag_status == "tagged-at-head":
                bi.category = "release-safe"
            elif bi.tag_status in ("tagged-behind", "untagged"):
                bi.category = "release-inspect"
                # Override even if merged — user should see it
            # If already merged AND tagged-at-head, keep as release-safe
            if bi.merged and bi.tag_status == "tagged-at-head":
                bi.category = "release-safe"
            elif bi.merged and bi.tag_status in ("tagged-behind", "untagged"):
                bi.category = "release-inspect"
        elif not bi.merged:
            if bi.days_ago > stale_days:
                bi.category = "stale"
            else:
                bi.category = "active"

        branches.append(bi)

    # --- Remote branches ---
    for raw in git_lines("branch", "-r", "--format=%(refname:short)"):
        name = raw.strip()
        # origin/HEAD renders as just "origin" with %(refname:short)
        if name == "origin" or name.startswith("origin/HEAD"):
            continue
        short = name.replace("origin/", "", 1)
        if short == main_branch:
            continue

        bi = BranchInfo(name=name, is_remote=True)

        bi.last_commit_date = get_commit_date(name)
        if bi.last_commit_date:
            bi.days_ago = (now - bi.last_commit_date).days

        bi.merged = name in merged_remote
        if not bi.merged:
            bi.merged = is_squash_merged(name, main_branch)
            if bi.merged:
                bi.category = "squash-merged"

        if bi.merged and not bi.category:
            bi.category = "merged"

        if bi.is_release_or_hotfix:
            analyse_release_tag(bi, all_tags)
            if bi.tag_status == "tagged-at-head":
                bi.category = "release-safe"
            elif bi.tag_status in ("tagged-behind", "untagged"):
                bi.category = "release-inspect"
            if bi.merged and bi.tag_status == "tagged-at-head":
                bi.category = "release-safe"
            elif bi.merged and bi.tag_status in ("tagged-behind", "untagged"):
                bi.category = "release-inspect"
        elif not bi.merged:
            if bi.days_ago > stale_days:
                bi.category = "stale"
            else:
                bi.category = "active"

        branches.append(bi)

    return branches


# ---------------------------------------------------------------------------
# Report generation
# ---------------------------------------------------------------------------

def _branch_detail(bi: BranchInfo) -> str:
    """One-line description for a branch."""
    parts = []
    if bi.category in ("merged", "squash-merged"):
        parts.append(bi.category)
        # Note if upstream is gone (remote deleted after merge)
        if not bi.is_remote and bi.category == "merged":
            try:
                track = git("for-each-ref", "--format=%(upstream:track)",
                           f"refs/heads/{bi.name}", check=False)
                if "[gone]" in track:
                    parts.append("upstream gone")
            except Exception:
                pass
    elif bi.category == "release-safe":
        parts.append(f"tagged at HEAD: {bi.matching_tag}")
    elif bi.category == "release-inspect":
        if bi.tag_status == "tagged-behind":
            behind = f"{bi.tag_behind_count} commit(s)" if bi.tag_behind_count > 0 else "unknown"
            parts.append(f"tag {bi.matching_tag} is {behind} behind HEAD")
        else:
            parts.append("⚠️ never tagged — inspect before deleting")
    elif bi.category == "stale":
        parts.append("not merged")

    if bi.days_ago and bi.category != "current":
        parts.append(f"last commit {bi.days_ago}d ago")

    return ", ".join(parts)


def _section(title: str, branches: list[BranchInfo], show_max: int = 0) -> list[str]:
    """Generate a report section. Returns lines of markdown."""
    lines: list[str] = []
    lines.append(f"### {title}")
    lines.append("")

    local = [b for b in branches if not b.is_remote]
    remote = [b for b in branches if b.is_remote]

    for label, group in [("Local", local), ("Remote", remote)]:
        if not group:
            continue
        lines.append(f"**{label}:**")
        lines.append("")
        shown = group if show_max == 0 else group[:show_max]
        for bi in shown:
            detail = _branch_detail(bi)
            detail_str = f" ({detail})" if detail else ""
            lines.append(f"- `{bi.name}`{detail_str}")
        if show_max and len(group) > show_max:
            lines.append(f"- *… and {len(group) - show_max} more*")
        lines.append("")

    if not local and not remote:
        lines.append("*(none)*")
        lines.append("")

    return lines


def generate_report(
    branches: list[BranchInfo],
    repo_name: str,
    main_branch: str,
) -> tuple[str, str, dict]:
    """Generate terminal report and markdown file report.

    Returns (terminal_text, markdown_text, summary_dict).
    """
    safe = [b for b in branches if b.category in ("merged", "squash-merged", "release-safe")]
    inspect = [b for b in branches if b.category == "release-inspect"]
    stale = [b for b in branches if b.category == "stale"]
    active = [b for b in branches if b.category == "active"]
    current = [b for b in branches if b.category == "current"]

    local_count = sum(1 for b in branches if not b.is_remote)
    remote_count = sum(1 for b in branches if b.is_remote)

    safe_local = [b for b in safe if not b.is_remote]
    safe_remote = [b for b in safe if b.is_remote]
    inspect_local = [b for b in inspect if not b.is_remote]
    inspect_remote = [b for b in inspect if b.is_remote]
    stale_local = [b for b in stale if not b.is_remote]
    stale_remote = [b for b in stale if b.is_remote]

    summary = {
        "safe_local": len(safe_local),
        "safe_remote": len(safe_remote),
        "inspect": len(inspect),
        "stale_local": len(stale_local),
        "stale_remote": len(stale_remote),
        "active": len(active),
        "current": len(current),
    }

    # --- Markdown report (full) ---
    md: list[str] = []
    md.append(f"# 🔍 Branch Cleanup Report — {repo_name}")
    md.append("")
    md.append(f"- **Main branch:** `{main_branch}`")
    md.append(f"- **Total:** {local_count} local, {remote_count} remote")
    md.append(f"- **Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    md.append("")

    md.extend(_section(
        "🟢 SAFE TO DELETE (merged into main or tagged at HEAD)", safe))
    md.extend(_section(
        "🟠 RELEASE/HOTFIX — NEEDS INSPECTION", inspect))
    md.extend(_section(
        "🟡 STALE (>90 days, not merged) — review recommended", stale))
    md.extend(_section(
        "🔵 ACTIVE (keeping)", active))
    md.extend(_section(
        "⚪ CURRENT (checked out — never touched)", current))

    # --- Proposed actions ---
    md.append("---")
    md.append("")
    md.append("## 📋 Proposed Actions")
    md.append("")
    if safe_local:
        md.append(f"1. Delete **{len(safe_local)}** local merged branches")
    if safe_remote:
        md.append(f"2. Delete **{len(safe_remote)}** remote merged branches (`git push origin --delete`)")
    if stale_local:
        md.append(f"3. Delete **{len(stale_local)}** local stale branches (⚠️ not merged)")
    if stale_remote:
        md.append(f"4. Delete **{len(stale_remote)}** remote stale branches (⚠️ not merged)")
    if inspect:
        md.append(f"5. Review **{len(inspect)}** release/hotfix branches needing inspection (🟠)")
    if not any([safe_local, safe_remote, stale_local, stale_remote, inspect]):
        md.append("✨ Repository is clean — no stale or merged branches found.")
    md.append("")

    markdown_text = "\n".join(md)

    # --- Terminal report (truncated) ---
    TERM_MAX = 20
    term: list[str] = []
    term.append(f"🔍 Branch Cleanup Report — {repo_name}")
    term.append("═" * 50)
    term.append("")
    term.append(f"📌 Main branch: {main_branch}")
    term.append(f"📊 Total: {local_count} local, {remote_count} remote")
    term.append("")

    def _term_section(emoji: str, title: str, items: list[BranchInfo], max_show: int = TERM_MAX):
        term.append(f"{emoji} {title}")
        term.append("─" * 50)
        if not items:
            term.append("  (none)")
            term.append("")
            return
        for bi in items[:max_show]:
            detail = _branch_detail(bi)
            detail_str = f"  ({detail})" if detail else ""
            term.append(f"  • {bi.name}{detail_str}")
        if len(items) > max_show:
            term.append(f"  … and {len(items) - max_show} more")
        term.append("")

    _term_section("🟢", "SAFE TO DELETE (merged / tagged at HEAD)", safe)
    _term_section("🟠", "RELEASE/HOTFIX — NEEDS INSPECTION", inspect)
    _term_section("🟡", "STALE (>90 days, not merged)", stale)
    _term_section("🔵", "ACTIVE (keeping)", active)
    _term_section("⚪", "CURRENT (never touched)", current)

    terminal_text = "\n".join(term)

    return terminal_text, markdown_text, summary


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Git branch cleanup auditor")
    parser.add_argument("--main", help="Main branch name (auto-detected if omitted)")
    parser.add_argument("--repo-name", help="Human-readable repo name (auto-resolved)")
    parser.add_argument("--output", help="Directory to write the report file", default=".")
    parser.add_argument("--json", action="store_true", help="Also emit JSON summary to stdout")
    args = parser.parse_args()

    # Verify git repo
    try:
        git("rev-parse", "--git-dir")
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("ERROR: Not a git repository.", file=sys.stderr)
        sys.exit(1)

    repo_name = resolve_repo_name(args.repo_name)
    main_branch = detect_main_branch(args.main)

    # Fetch + prune
    print(f"📌 Main branch: {main_branch}")
    print("⏳ Fetching remote state…")
    try:
        git("fetch", "--prune", "origin")
    except Exception as e:
        print(f"⚠️  Fetch failed (continuing with local data): {e}", file=sys.stderr)

    # Classify
    print("⏳ Classifying branches…")
    branches = classify_branches(main_branch)

    # Generate reports
    terminal_text, markdown_text, summary = generate_report(branches, repo_name, main_branch)

    # Write markdown file
    out_dir = Path(args.output)
    out_dir.mkdir(parents=True, exist_ok=True)
    date_str = datetime.now().strftime("%Y-%m-%d")
    report_path = out_dir / f"branch-cleanup-report-{date_str}.md"
    report_path.write_text(markdown_text, encoding="utf-8")

    # Print terminal report
    print()
    print(terminal_text)
    print(f"📄 Full report saved to {report_path}")

    # Optional JSON for agent consumption
    if args.json:
        summary["report_file"] = str(report_path)
        summary["repo_name"] = repo_name
        summary["main_branch"] = main_branch
        print()
        print("--- JSON SUMMARY ---")
        print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()

