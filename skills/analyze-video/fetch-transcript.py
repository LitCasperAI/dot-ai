#!/usr/bin/env python3
"""Fetch YouTube video transcript and output structured JSON.

Usage:
    python3 fetch-transcript.py VIDEO_ID

Output (stdout): JSON object with keys:
    text, word_count, segments, language, language_code, is_generated

On error: JSON object with key "error", exit code 1.

Requires: youtube-transcript-api >= 1.0 (pre-installed in agent container)
"""

import sys
import json

from youtube_transcript_api import YouTubeTranscriptApi


def main():
    if len(sys.argv) != 2:
        print(json.dumps({"error": "Usage: fetch-transcript.py VIDEO_ID"}))
        sys.exit(1)

    video_id = sys.argv[1]

    try:
        api = YouTubeTranscriptApi()
        result = api.fetch(video_id)

        text = " ".join(snippet.text for snippet in result.snippets)
        print(
            json.dumps(
                {
                    "text": text,
                    "word_count": len(text.split()),
                    "segments": len(result.snippets),
                    "language": result.language,
                    "language_code": result.language_code,
                    "is_generated": result.is_generated,
                }
            )
        )
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    main()
