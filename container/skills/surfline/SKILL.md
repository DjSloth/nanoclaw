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

Returns: spot name, break type, conditions rating, wave height range, swell direction & period, energy (kJ), wind compass direction & speed, water temp, tide state.

Example output:
```
Sdot Yam [Beach Break]
  Conditions: POOR_TO_FAIR
  Waves: 0.9-1.4m (Waist to shoulder)
  Swell: WNW @ 8s | Energy: 226 kJ
  Wind: WSW 11 KPH Onshore (gusts 14)
  Water temp: 20°C
  Tide: RISING (0.2m) → next: HIGH (0.3m)
```

### Wave forecast

```bash
surfline forecast 584204204e65fad6a7709aa7       # Next 24 hours
surfline forecast 584204204e65fad6a7709aa7 3     # Next 3 days
```

Returns: hourly wave heights, swell direction & period, energy (kJ), consistency (%), and human description.

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
| Nazare | 58bdfa7882d034001252e3d8 |
| Poleg Beach | 640a665799dd44dd3d0c88df |
| Backdoor Haifa | 640a6677606c4529b9b9fe18 |
| Nahsholim | 640a668b4519052578a61175 |
| Beit Yanai | 584204204e65fad6a7709aa8 |
| The Rock | 60428abd890fe2578439c1dd |
| Hazuk Beach | 584204204e65fad6a7709aaf |
| Hiriketiya Beach | 640a5e554eb3752f629bd155 |

## Spot knowledge

Use these profiles to assess whether a spot is working. Cross-reference live data (energy, wind, swell direction) against each profile to give informed recommendations.

### Sdot Yam — 584204204e65fad6a7709aa7
- **Type**: Deep point break-like spot
- **Location notes**: North of a power plant, sheltered from southern winds
- **Energy window**: 150–900 kJ
- **Wind tolerance**: S to SSW up to 35–40 km/h is fine (sheltered). Other directions less tolerant.
- **Swell**: Needs bigger swells to work. Small days won't produce here.
- **Summary**: A power spot — needs energy but handles south winds well.

### Poleg Beach — 640a665799dd44dd3d0c88df
- **Type**: Shallow beach break
- **Energy window**: 50–250 kJ
- **Wind tolerance**: Needs offshore wind (E/SE). Sensitive to onshore.
- **Swell**: Works on smaller days. Gets messy when too big.
- **Summary**: The small-day option — clean and fun when it's mellow.

### Atlit Beach — 640a6699451905095aa61467
- **Profile incomplete** — ask the user for: break type, energy window, wind tolerance, local quirks.

### Backdoor Haifa — 640a6677606c4529b9b9fe18
- **Profile incomplete** — ask the user for: break type, energy window, wind tolerance, local quirks.

### Nahsholim — 640a668b4519052578a61175
- **Profile incomplete** — ask the user for: break type, energy window, wind tolerance, local quirks.

### Beit Yanai — 584204204e65fad6a7709aa8
- **Profile incomplete** — ask the user for: break type, energy window, wind tolerance, local quirks.

### The Rock — 60428abd890fe2578439c1dd
- **Profile incomplete** — ask the user for: break type, energy window, wind tolerance, local quirks.

### Hazuk Beach — 584204204e65fad6a7709aaf
- **Profile incomplete** — ask the user for: break type, energy window, wind tolerance, local quirks.

### Nazare — 58bdfa7882d034001252e3d8
- **Profile incomplete** — ask the user for: break type, energy window, wind tolerance, local quirks.

### Hiriketiya Beach — 640a5e554eb3752f629bd155
- **Profile incomplete** — ask the user for: break type, energy window, wind tolerance, local quirks.

## Agent behavior

### Assessing conditions ("How are the waves?")

1. Run `surfline conditions` for each favorite spot
2. For each spot with a profile, compare live data against the profile:
   - Is energy within the spot's window?
   - Is wind direction/speed within tolerance?
   - Is swell direction favorable?
3. **Lead with the best-working spots** — the ones where live data falls within their profile
4. Give nuanced reasoning, not just "good" or "bad":
   - "Sdot Yam is firing — 320 kJ is right in its sweet spot and the SSW wind at 25 km/h is no problem with its shelter"
   - "Poleg is borderline — 240 kJ is near the top of its range, might be closing out"
   - "Sdot Yam needs more energy — only 100 kJ, below its 150 kJ minimum"
5. For spots without profiles, report raw data and note the profile is missing

### Forecast analysis ("What's the weekend look like?")

1. Run `surfline forecast` for relevant spots (2–3 days out)
2. Identify the best windows: time slots where energy, wind, and consistency align with spot profiles
3. Recommend specific sessions: "Saturday morning at Poleg looks clean — 80 kJ, offshore, 85% consistency"

### Gap detection — completing spot profiles

When you encounter a favorite spot with an incomplete profile (or a newly added spot):
- **Proactively ask the user** to describe it: "I don't have local knowledge for Atlit Beach yet. Can you tell me: what type of break is it? What energy range works? What winds does it handle?"
- Once the user provides info, ask them to update the profile in this file or remember it for future reports
- Don't ask about all missing spots at once — ask about one at a time, when it's relevant (e.g., when reporting conditions for that spot)

### Scheduled surf reports

The user can ask you to set up recurring surf reports sent to any WhatsApp chat.

**Creating a report:**
- Use `mcp__nanoclaw__schedule_task` to create a scheduled task
- If the user doesn't specify which chat, **ask them** — "Which WhatsApp chat should I send the report to?"
- The prompt should instruct the agent to use spot profiles for smart analysis, not just dump raw numbers

Example:
```
Tool: mcp__nanoclaw__schedule_task
Arguments:
  name: "morning-surf-report"
  schedule: "0 6 * * *"
  prompt: "Check surf conditions for my favorite spots using the surfline tool. Run surfline conditions for each of these spot IDs: 584204204e65fad6a7709aa7, 640a6699451905095aa61467, 640a665799dd44dd3d0c88df, 640a668b4519052578a61175, 584204204e65fad6a7709aa8, 584204204e65fad6a7709aaf. Cross-reference the data with each spot's profile from the surfline skill. Lead with the best-working spots and explain why. Keep it concise and actionable."
```

**Modifying a report:**
- Use `mcp__nanoclaw__list_tasks` to find existing tasks, then `mcp__nanoclaw__update_task` to modify schedule, spots, or prompt

**Removing a report:**
- Use `mcp__nanoclaw__delete_task` with the task name or ID

Adjust the cron schedule, spot list, and target chat based on the user's preferences.
