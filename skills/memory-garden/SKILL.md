---
name: memory-garden
description: Maintain the long-term health of the knowledge base by consolidating, promoting, and archiving project memory.
---

# skill: memory-garden

The "Gardening" (or Defragmentation) process manages the growth of the repository's `.ai-memory/` directory. It ensures that critical knowledge is distilled into formal rules while outdated or redundant context is archived, preventing "session window bloat".

## Personas

1. `curator` — analyzes the memory files and proposes triage actions.
2. `architect` — evaluates promotions to global rules (`GEMINI.md`) or local rules (`.ai-local/rules/`).

## Rules loaded

From `project.yaml`: `rules.core`, plus `14-memory-protocol.md`.

## Steps

### 1. Analysis
- Read all Markdown files in `.ai-memory/` (excluding the `archive/` subdirectory).
- Identify common themes, repeated patterns, and related insights.
- Check for outdated instructions or information that has been superseded by newer files.

### 2. Triage & Strategy
For each memory file, decide on one of the following actions:
- **RETAIN:** The memory is recent (less than 7 days old), highly relevant to an ongoing task, or a unique project-specific fact that doesn't belong in rules yet.
- **CONSOLIDATE:** Multiple files cover the same topic. Merge them into a single, cohesive "Lessons Learned" or "Topic Summary" file. Use the most recent file's date as the reference.
- **PROMOTE:** The memory describes a settled architectural decision or a team convention that should be permanent. Move it to `.ai-local/rules/` or append it to `GEMINI.md`.
- **ARCHIVE:** The memory is related to a completed feature, an old version, or has been fully "PROMOTED".

### 3. Execution (Sequential)
- **Consolidation:** Create the merged file and mark the source files for archiving.
- **Promotion:**
    - For `.ai-local/rules/`: If the pattern is project-specific but permanent, create or update a file in `.ai-local/rules/`.
    - For `GEMINI.md`: If the pattern is a core mandate or workspace-wide workflow, update `GEMINI.md`.
- **Archiving:**
    - Create `.ai-memory/archive/` if it doesn't exist.
    - Move processed/old files to the archive.
- **Cleanup:** Delete files from the root `.ai-memory/` that have been consolidated, promoted, or archived.

### 4. Verification
- Ensure no data is lost during consolidation (use summaries, not just deletions).
- Verify that promoted rules are clear and follow the project's formatting conventions.
- Provide a summary report of the "Gardening" results.

## Criteria for Promotion
- A pattern has been mentioned in 3 or more separate memory files.
- The user has explicitly stated "This is how we always do X".
- An architectural decision has been made.

## Criteria for Archiving
- Files older than 30 days that haven't been referenced recently.
- Memories related to closed PRs or completed features.
- Files that have been fully summarized into a "Consolidated" memory.
