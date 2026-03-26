---
name: red-alert
description: Query historical Israeli Red Alert (Tzeva Adom) rocket/missile alert data. Look up stats by city, area, date, or nationwide. Use whenever someone asks about rocket attacks, red alerts, sirens, or alert history in Israel.
allowed-tools: Bash(red-alert:*)
---

# Red Alert — Israeli Rocket Alert History

Data source: [tzevaadom.co.il](https://www.tzevaadom.co.il) — the official Red Alert aggregator.
Coverage: May 20, 2021 → present (~53 groups/day currently, ~6,650+ total groups).

## Setup

**First run:** `sync` downloads the full history (~10 min, ~6,650 groups). After that, re-run `sync` daily for incremental updates (seconds).

```bash
red-alert sync
```

**Recommended:** Schedule a daily sync via NanoClaw's scheduler (see below).

---

## Commands

### `red-alert sync`

Fetch cities reference and all missing alert groups from the API.
Resumable — skips already-fetched IDs. Safe to run repeatedly.

```bash
red-alert sync
# ✅ Synced 142 new groups (total: 6650)
```

---

### `red-alert recent [--hours N]`

Summary of recent alerts grouped by area. Default: last 24 hours.

```bash
red-alert recent
red-alert recent --hours 48
```

---

### `red-alert city <name> [--period week|month|year|all]`

Stats for a specific city. Accepts Hebrew or English name (fuzzy match).
Default period: all time.

```bash
red-alert city Sderot
red-alert city שדרות
red-alert city Ashkelon --period year
red-alert city "Kiryat Shmona" --period month
```

Shows: total alerts, rockets vs aircraft, worst day/month, last alert, year/month quick stats.

---

### `red-alert area <name> [--period week|month|year|all]`

Stats for a zone/area. Accepts Hebrew or English zone name (fuzzy match).

```bash
red-alert area "Gaza Envelope"
red-alert area "עוטף עזה"
red-alert area "Northern Border" --period year
red-alert area "Tel Aviv" --period week
```

Shows: total alerts, cities hit, top cities, peak day, year/month quick stats.

---

### `red-alert date <YYYY-MM-DD>`

All alerts on a specific date with area breakdown and hourly timeline.

```bash
red-alert date 2023-10-07
red-alert date 2024-04-14
```

---

### `red-alert nationwide [--period week|month|year|all]`

Israel-wide aggregate stats.

```bash
red-alert nationwide
red-alert nationwide --period year
```

Shows: total alerts, rockets vs aircraft, cities hit, peak day/month, year/month/week quick stats.

---

## Threat codes

| Code | Meaning |
|------|---------|
| 0 | Rockets / missiles |
| 5 | Hostile aircraft / anti-tank fire |

Drills are excluded from all counts.

---

## Scheduling daily sync

Add to `/workspace/project/groups/main/scheduled-tasks.json`:

```json
{
  "name": "red-alert-daily-sync",
  "enabled": true,
  "schedule_type": "cron",
  "schedule_value": "0 6 * * *",
  "target_group_jid": "<your-group-JID>",
  "context_mode": "group",
  "prompt": "Run: red-alert sync. Report how many new groups were synced.",
  "description": "Daily red alert data sync"
}
```

Or use `mcp__nanoclaw__schedule_task` for an immediate one-off sync.
