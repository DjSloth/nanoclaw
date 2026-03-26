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
| The Power Plant (Sdot Yam) | 584204204e65fad6a7709aa7 |
| The Fort (The Old Port at Atlit) | 640a6699451905095aa61467 |
| The Sandbox (Poleg Beach) | 640a665799dd44dd3d0c88df |

## Consistency scale

Consistency % is a MAJOR factor — always report it:
- **< 30%**: Rubbish — long waits between sets
- **31–60%**: Meh — mediocre
- **61–80%**: OK — decent session potential
- **81–95%**: Good — consistent waves
- **96–100%**: FIRE 🔥 — non-stop sets, epic session

## Wind guidelines (Israel)

- **Best**: No wind
- **Manageable**: Light winds up to 6–8 km/h (any direction)
- **Offshore (E)**: Clean waves, acceptable even when stronger
- **Onshore (W)**: Messy — avoid if strong
- Sheltered spots (Power Plant, Fort) handle specific wind directions that would ruin other spots

## Spot knowledge

Use these profiles to assess whether a spot is working. Cross-reference live data (energy, wind, swell direction, consistency) against each profile.

### The Power Plant (Sdot Yam) — 584204204e65fad6a7709aa7
- **Type**: Beach break that acts like a point break — waves break off the marina pier
- **Location**: Near power plant; marina to the south provides shelter
- **Energy window**: 150–800 kJ. Deep water near the marina requires high energy to break properly. Below 150 kJ = flat.
- **Wind tolerance**: Protected from S/SSW up to 35–40 km/h. Best with no wind or light offshore (E). Other directions are a major factor.
- **Swell**: Needs bigger swells — small days won't produce
- **Crowd factor**: PACKED on stormy S/SSW days — shelter attracts everyone, shortboarders and kooks everywhere. Consider crowds when recommending this spot on south wind days.
- **Summary**: A power spot — needs energy but handles south winds well. Beware crowds on busy south days.

### The Sandbox (Poleg Beach) — 640a665799dd44dd3d0c88df
- **Actual location**: ~1.5–2km north of Poleg Beach proper
- **Type**: Shallow beach/rocks break — sand on rocks creates consistent breaks
- **Energy window**: 50–200 kJ sweet spot. Works even in ankle biters. Gets messy above 200 kJ.
- **Wave types**:
  - Wind swell (6–7s period): 50–200 kJ, up to chest-shoulder high
  - Ground swell (10–12s+ period): shoulder to overhead, higher quality
- **Break zones**: Small conditions = inside reef; firing = far reef (needs ground swell + high interval between sets)
- **Wind tolerance**: Protected by 5–10m cliffs to the west. Best with no wind or light winds (up to 6–8 km/h). Offshore (E) protected on small days.
- **Crowd factor**: VERY LOW — 6–7 min hike + rocky entry filters out kooks. Usually just The Balcony gang. Big advantage for catching waves.
- **Summary**: The small-day option — clean, fun, and uncrowded.

### The Fort (Atlit Old Port) — 640a6699451905095aa61467
- **Type**: Deep point break-like spot, deeper than Sdot Yam
- **Location**: Natural old Roman harbour; pier and fortress structures shelter from the south
- **Energy window**: 250–900 kJ
- **Wind tolerance**: Protected from S/SSW up to 35–40 km/h (ancient pier/fortress). Similar to The Power Plant.
- **Swell**: Needs bigger swells — requires more energy than Sdot Yam
- **Summary**: A power spot — handles south winds well but needs serious swell.

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

### Single-spot forecast — preferred output format

When asked about a specific spot for a specific day, present an **hourly list** (no table headers) followed by a short summary. Designed for WhatsApp mobile — rows must be self-describing if they wrap.

**Row format:**
```
HH:MM  RATING  🌊 Size  Swell@period  ⚡EnergyKJ  🎯Consistency%  💨 WindDir Speedkph WindType
·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·
```

**Example:**
```
*🏭 Power Plant — Saturday 28 March* 🌅 06:35 🌇 18:58 🦈

06:00  FAIR  🌊 Waist-chest  WNW@7s  ⚡181kJ  🎯82%  💨 ESE 3kph Offshore
·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·
07:00  FAIR  🌊 Waist-chest  WNW@7s  ⚡168kJ  🎯80%  💨 SE 4kph Offshore
·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·
08:00  FAIR  🌊 Waist-chest  WNW@7s  ⚡155kJ  🎯76%  💨 SE 5kph Offshore

*The story:*
• Energy & consistency — ...
• Wind — ...
• Best window: ...
```

**Rules:**
- Emoji key: 🌊 wave size · ⚡ energy · 🎯 consistency · 💨 wind
- No table header row — emojis make fields self-describing
- Dotted separator `·  ·  ·  ·  ·` between every row
- Rating: label only, no number (POOR / POOR TO FAIR / FAIR / GOOD / EPIC)
- Only show daylight hours (sunrise to sunset) unless notable pre/post windows exist
- Add 🦈 to Power Plant header during shark season (Dec–May) — no dawn/dusk sessions
- Sunrise 🌅 and sunset 🌇 in header line only, not in rows
- End with verdict: best window or "no clean window today"

### Gap detection — completing spot profiles

When you encounter a favorite spot with an incomplete profile (or a newly added spot):
- **Proactively ask the user** to describe it: "I don't have local knowledge for Atlit Beach yet. Can you tell me: what type of break is it? What energy range works? What winds does it handle?"
- Once the user provides info, ask them to update the profile in this file or remember it for future reports
- Don't ask about all missing spots at once — ask about one at a time, when it's relevant (e.g., when reporting conditions for that spot)

### Scheduled surf reports

The user can ask you to set up recurring surf reports sent to any WhatsApp chat.

**Preferred approach — config file (persistent, version-controlled):**

Edit `/workspace/project/groups/main/scheduled-tasks.json` to add or modify tasks. Changes take effect on the next NanoClaw restart. This is the right approach for permanent recurring reports.

Example entry:
```json
{
  "name": "dawn-patrol-surf-report",
  "enabled": true,
  "schedule_type": "cron",
  "schedule_value": "0 5 * * *",
  "target_group_jid": "<group JID>",
  "context_mode": "group",
  "prompt": "Dawn patrol surf check. Run conditions for The Power Plant and The Sandbox. Give a go/no-go recommendation — which spot (if any) is worth surfing right now, and why. Include water temp. Keep it short and actionable.",
  "description": "Daily 5am surf report"
}
```

Keep prompts short — the skill has all the spot knowledge and analysis logic built in.

**Alternative — native scheduling tools (ephemeral, takes effect immediately):**

Use `mcp__nanoclaw__schedule_task` for one-off or temporary tasks. These are stored in the DB and survive restarts, but aren't tracked in the config file. Avoid using this for reports that are already defined in `scheduled-tasks.json` — it will create duplicates.

**Modifying a report:**
- Config file tasks: edit `scheduled-tasks.json` and restart NanoClaw
- Native tasks: use `mcp__nanoclaw__list_tasks` then `mcp__nanoclaw__update_task`

**Removing a report:**
- Config file tasks: set `"enabled": false` or remove the entry, then restart
