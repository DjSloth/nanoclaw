---
name: youtube
description: Inspect, transcribe, or download any YouTube video by URL. Use when the user shares a YouTube or youtu.be link and asks to summarize, analyze, discuss, or extract content from it. Pulls metadata and auto-generated captions by default; falls back to audio (for Whisper) or frame sampling (for visual reasoning) when needed.
allowed-tools: Bash(youtube:*)
---

# YouTube — Inspect & Transcribe Videos

## Quick start

```bash
youtube info <url>                  # metadata only (title, channel, duration, has_captions)
youtube transcript <url>            # auto-captions as plain text — start here
youtube audio <url>                 # mp3 to /tmp/youtube/<id>.mp3 (for Whisper)
youtube frames <url> --n 12         # JPG frames to /tmp/youtube/<id>/ (for visual reasoning)
youtube download <url>              # full mp4 (slowest, use sparingly)
```

## When the user shares a YouTube link

Default to `youtube transcript`. It's free, fast, and answers most "what is this video about?" requests. Only escalate when captions are missing or the question is about visuals.

| User intent | Command | Notes |
|---|---|---|
| Summarize / discuss content | `youtube transcript` | Use the transcript as context. Cite quotes when asked. |
| Verify channel, length, publish date | `youtube info` | Cheapest call; metadata only. |
| No captions available | `youtube audio` then send to Whisper | Skill itself does not transcribe audio — it just downloads. |
| Question about visuals (something captions can't convey) | `youtube frames` | Returns evenly-spaced JPGs; pass them as image inputs. |
| Need the raw video file | `youtube download` | Slowest, largest. Avoid unless explicitly required. |

## Commands

### `youtube info <url>`

Prints JSON: `id`, `title`, `channel`, `duration_sec`, `upload_date`, `view_count`, `has_captions`, `description` (truncated to 1000 chars).

```bash
youtube info https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

### `youtube transcript <url> [--lang en] [--with-timestamps]`

Prints plain-text transcript with HTML tags and WebVTT timestamps stripped. Exits with code 2 if no captions exist for the requested language — fall back to `youtube audio` in that case. Pass `--with-timestamps` to keep the raw VTT (useful when the user asks about a specific moment).

```bash
youtube transcript https://youtu.be/dQw4w9WgXcQ
youtube transcript https://youtu.be/dQw4w9WgXcQ --lang he
youtube transcript https://youtu.be/dQw4w9WgXcQ --with-timestamps
```

### `youtube audio <url> [--out DIR]`

Downloads `bestaudio` as 192 kbps mp3. Default destination: `/tmp/youtube/<id>.mp3`. Prints the resulting path on stdout.

```bash
AUDIO=$(youtube audio https://youtu.be/dQw4w9WgXcQ)
# now hand $AUDIO to a Whisper transcriber
```

### `youtube frames <url> [--n 12] [--out DIR]`

Samples N evenly-spaced frames as JPGs. Default `N=12`, default destination `/tmp/youtube/<id>/`. Prints the directory on stdout. Internally downloads a 720p mp4, samples with ffmpeg, and deletes the mp4.

```bash
DIR=$(youtube frames https://youtu.be/dQw4w9WgXcQ --n 8)
ls "$DIR"
```

### `youtube download <url> [--out DIR] [--max-height 720]`

Downloads merged mp4 (yt-dlp + ffmpeg merge). Default destination `/tmp/youtube/<id>.mp4`, default max height 720. Prints the resulting path on stdout.

## Common patterns

**"Summarize this video":**

1. `youtube info <url>` — capture title + channel for the response
2. `youtube transcript <url>` — read the transcript
3. If step 2 exits non-zero → `youtube audio <url>` and tell the user captions weren't available so you couldn't read it directly (or escalate to Whisper if available)
4. Summarize from the transcript. Lead with the title + channel so the user can sanity-check the source.

**"What's said at minute 4?"**

`youtube transcript <url> --with-timestamps` — the WebVTT output is timestamp-aligned. Find the cue around `00:04:00` and quote it.

**"What does the video show?"**

`youtube frames <url> --n 8` — describe the JPGs as image inputs.

## Failure modes

| Symptom | Cause | What to do |
|---|---|---|
| `transcript` exits with code 2 | Captions disabled or wrong language | Try `--lang en` (or omit). If still no captions, fall back to `audio`. |
| `Sign in to confirm your age` | Age-restricted video | Tell the user — the skill has no auth. |
| `Video unavailable` | Private, region-blocked, or removed | Tell the user. |
| Downloads to `/tmp/youtube/` fill disk | Long videos | Caller cleans up; the skill does not. |

## Notes

- Captions are YouTube's auto-generated transcripts — they include filler ("um", "uh") and miss specialty terminology. Treat as approximate.
- Live streams: only post-stream archives are usable.
- The skill returns raw materials only. The summarization/analysis/discussion is the agent's job.
