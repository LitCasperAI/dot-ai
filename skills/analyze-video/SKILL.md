---
name: analyze-video
description: Fetch a YouTube video transcript, evaluate its relevance to software engineering, break down key insights, and produce an actionable brief mapped to the current project context.
---

# skill: analyze-video

Accepts a YouTube URL, fetches the video transcript, filters for
software engineering relevance, and produces a structured brief with
actionable recommendations mapped to the active project context via
persona evaluation.

## Inputs

- A YouTube URL (any format: `youtube.com/watch?v=`, `youtu.be/`,
  embed, or bare 11-char video ID).

## Personas

1. `architect` — evaluates architectural insights, design patterns,
   system boundaries.
2. `implementer` — evaluates coding techniques, library usage,
   refactoring opportunities.
3. `security-reviewer` — evaluates security practices, vulnerability
   patterns.
4. `tester` — evaluates testing strategies, quality approaches.

Persona engagement is dynamic — only those relevant to the detected
content are invoked.

## Rules loaded

From `project.yaml`: all entries under `rules.load`. Additionally
reads active stacks to inform context mapping.

## Steps

### 1. Parse URL

Extract the YouTube video ID from the provided URL. Accept:
- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://youtube.com/embed/VIDEO_ID`
- Bare 11-character video ID (`[A-Za-z0-9_-]{11}`)

Strip query parameters (timestamps, playlists, tracking). If the
input doesn't match any known format, stop and ask the user for
clarification.

### 2. Fetch Transcript

Run the bundled transcript fetcher script:

```bash
python3 .ai/skills/analyze-video/fetch-transcript.py VIDEO_ID
```

The script outputs a JSON object to stdout with keys: `text`,
`word_count`, `segments`, `language`, `language_code`, `is_generated`.

**Do NOT rewrite or inline this script.** Use the bundled version as-is.

**If the script exits with an error or returns `{"error": ...}`:**
Stop and report to the user: "This video has no transcript available.
The analyze-video skill requires text transcripts to function."

**Note:** `youtube-transcript-api` v1.x uses the YouTube InnerTube API
directly. It works from residential/developer IPs but may be blocked
from cloud data-center IPs (PoToken/BotGuard). If you get a persistent
error, inform the user that the video may be geo-restricted or require
authentication.

### 3. Relevance Gate

Analyze the video title (if extractable from metadata) and the first
500 words of the transcript. Classify the content:

**PASS** (proceed to Step 4): The content is primarily about software
engineering, DevOps, system architecture, programming, developer
tooling, CI/CD, testing, cloud infrastructure, databases, APIs,
security, observability, developer workflows, or technical leadership
in a software context.

**FAIL** (stop): The content is primarily about music, gaming,
cooking, fitness, politics, entertainment, vlogs, unboxing, product
reviews (non-dev-tools), or any other non-software topic. Respond:

> "This video appears to be about [detected topic], which is not
> relevant to a software engineering context. The analyze-video skill
> is designed exclusively for software development content."

**AMBIGUOUS** (ask): If the classification is unclear (e.g.,
general productivity, business strategy that *might* apply to SW
teams), ask the user to confirm before proceeding.

### 4. Content Breakdown

Process the full transcript text:

- If ≤ 30,000 words: analyze as a single block.
- If > 30,000 words: split into ~10,000-word chunks with 200-word
  overlap. Summarize each chunk independently, then merge the
  summaries into a unified analysis.

Extract:
- **Key topics** (3–10 per video, named concisely)
- **Specific insights** per topic (concrete claims, recommendations,
  patterns, anti-patterns, or techniques mentioned)
- **Tools/libraries/technologies** referenced by name

### 5. Context Mapping

For each extracted insight:

1. Read `.ai-local/project.yaml` to determine active stacks and
   project type.
2. Search the codebase for related patterns, files, or existing
   implementations.
3. Check loaded rules for alignment or contradiction with the insight.
4. Rate relevance to *this specific project*:
   - **HIGH** — directly applicable, addresses a known gap or
     improves an existing pattern.
   - **MEDIUM** — interesting, needs adaptation or further
     investigation to apply.
   - **LOW** — informational only, no clear application path.

### 6. Cross-Reference Existing Analyses

Before generating the final brief, check for existing video analysis
briefs:

```bash
ls <paths.briefs>/active/*video* 2>/dev/null
```

If previous briefs exist:
1. Read their **Key Insights** and **Prioritized Actions** sections.
2. Identify overlaps: Does the new video reinforce, contradict, or
   extend prior findings?
3. Note connections in the output brief under a **Cross-References**
   section:
   - `Reinforces: <brief-id> — <insight title>` (same conclusion)
   - `Extends: <brief-id> — <insight title>` (builds on prior work)
   - `Contradicts: <brief-id> — <insight title>` (opposing view)
4. If an insight has been marked GO in a prior brief but not yet
   implemented, flag it as **recurring priority**.

If no prior briefs exist, skip this step silently.

### 7. Persona Evaluation

Route each HIGH or MEDIUM insight to the appropriate persona based
on its category:

| Category | Persona |
|----------|---------|
| Architecture, design patterns, system boundaries | `architect` |
| Coding techniques, libraries, refactoring | `implementer` |
| Security practices, vulnerability patterns | `security-reviewer` |
| Testing strategies, TDD, quality | `tester` |

Each persona provides:
- A 2–3 sentence evaluation of the insight's applicability.
- A recommendation: **GO** (implement), **CONSIDER** (investigate
  further), or **SKIP** (not worth pursuing in our context).
- If GO or CONSIDER: a concrete next step.

Insights that span multiple categories get evaluated by the primary
persona with a note referencing the secondary.

### 8. Generate Output Brief

Create a brief at `<paths.briefs>/active/YYYY-MM-DD-video-<slug>.md`
where `<slug>` is derived from the video title (lowercase-kebab,
max 40 chars). Use the standard `brief.md` template with these
additional sections:

```markdown
## Video Source

- **Title:** <video title>
- **Channel:** <channel name if available>
- **URL:** <original URL provided by user>
- **Language:** <original language> (analyzed in English)

## Key Insights

### 1. <Insight title>
**Topic:** <category>
**Relevance:** HIGH | MEDIUM
**Evaluated by:** <persona name>

<2-3 sentence description>

**Current state in our project:**
<what we do today, with file/rule references>

**Recommendation:** GO | CONSIDER | SKIP
<proposed concrete action>

---

### 2. ...

## Prioritized Actions

1. <highest priority action> — Owner: <persona>
2. <next action> — Owner: <persona>
...

## Not Applicable

- <LOW relevance insights with brief reasoning>
```

Set frontmatter: `id: video-<slug>`, `type: brief`,
`status: draft`, `owner: product-analyst`.

### 9. Present Summary

After writing the brief file, present a concise terminal summary:
- Video title + classification
- Number of insights extracted (HIGH/MEDIUM/LOW counts)
- Cross-references to prior analyses (if any)
- Top 3 prioritized actions
- Path to the full brief file

## Outputs

- `<paths.briefs>/active/YYYY-MM-DD-video-<slug>.md` — a draft
  brief following scaffold conventions, ready to flow into the
  standard spec → plan → implement pipeline.

## Prerequisites

- `youtube-transcript-api` v1.x is **pre-installed** in the agent
  container. Do NOT run `pip install` — it is already available.
- Egress allowlist must include `youtube.com`, `www.youtube.com`,
  `youtu.be`, and `youtubei.googleapis.com`.
