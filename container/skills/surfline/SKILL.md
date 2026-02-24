---
name: surfline
description: Check surf conditions, wave forecasts, and tides for any Surfline spot. Use whenever someone asks about waves, surf, ocean conditions, or wants a surf report.
allowed-tools: Bash(surfline:*)
---

# Surfline — Surf Conditions & Forecasts

## Quick start

```bash
surfline conditions <spotId>    # Current conditions for a spot
surfline forecast <spotId>      # Hourly wave forecast (next day)
surfline search <query>         # Find spot IDs by name
surfline favorites              # List saved favorite spots
```

## Commands

### Current conditions

```bash
surfline conditions 584204204e65fad6a7709aa7
```

Returns: spot name, conditions rating, wave height range (meters), wind speed/direction (KPH), water temp (°C), tide state.

### Wave forecast

```bash
surfline forecast 584204204e65fad6a7709aa7       # Next 24 hours
surfline forecast 584204204e65fad6a7709aa7 3     # Next 3 days
```

Returns: hourly wave heights with timestamps.

### Search for spots

```bash
surfline search "pipeline"
surfline search "nazare"
surfline search "sdot yam"
```

Returns: matching spot names and IDs (up to 5 results).

### Favorite spots

```bash
surfline favorites
```

Returns the preconfigured list of favorite spots with IDs.

## Default favorite spots

These are the user's current favorite Surfline spots. When the user asks about "the waves" or "conditions" without specifying a spot, check these:

| Spot | ID |
|------|----|
| Sdot Yam | 584204204e65fad6a7709aa7 |
| Atlit Beach | 640a6699451905095aa61467 |
| Poleg Beach | 640a665799dd44dd3d0c88df |
| Nahsholim | 640a668b4519052578a61175 |
| Beit Yanai | 584204204e65fad6a7709aa8 |
| Hazuk Beach | 584204204e65fad6a7709aaf |

## Workflow examples

### "How are the waves?"

When the user asks about surf conditions without specifying a spot, check their local favorites (the Israeli coast spots). Run `surfline conditions` for each and summarize which spots look best.

### "What's the forecast for this weekend?"

Use `surfline forecast <spotId> 3` for relevant spots and summarize the best windows.

### Setting up a daily surf report

When the user asks for daily surf reports, use `mcp__nanoclaw__schedule_task` to create a scheduled task:

```
Tool: mcp__nanoclaw__schedule_task
Arguments:
  name: "morning-surf-report"
  schedule: "0 6 * * *"
  prompt: "Check surf conditions for my favorite spots using the surfline tool. Run surfline conditions for each of these spot IDs: 584204204e65fad6a7709aa7, 640a6699451905095aa61467, 640a665799dd44dd3d0c88df, 640a668b4519052578a61175, 584204204e65fad6a7709aa8, 584204204e65fad6a7709aaf. Summarize which spots have the best conditions right now, mentioning wave height, wind, and rating. Keep it concise."
```

Adjust the cron schedule and spot list based on the user's preferences.
