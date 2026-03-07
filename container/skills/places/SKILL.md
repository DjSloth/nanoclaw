---
name: places
description: Search for local businesses, restaurants, hotels, bars, and attractions using Google Places API. Returns ratings, addresses, hours, and map links. Use whenever someone asks about places to eat, stay, or visit near a location.
allowed-tools: Bash(places:*)
---

# Places — Local Business Search

## Quick start

```bash
places search "sushi restaurants" --location "Binyamina, Israel"
places search "bars" --near 32.5234,34.9415 --open-now --limit 5
places search "hotels" --location "Tel Aviv" --price 1-2 --rating 4+
places details <place_id>
```

## Commands

### Search

```bash
places search <query> [options]
```

Options:
- `--location <city>` — City or address to search near
- `--near <lat,lng>` — Coordinates (alternative to --location)
- `--radius <km>` — Search radius in km (default: 5)
- `--rating <n+>` — Minimum rating, e.g. `4+`
- `--price <level>` — Price level 1–4 or range `2-3` (1=cheap, 4=expensive)
- `--open-now` — Only show currently open places
- `--limit <n>` — Max results (default: 10)
- `--type <type>` — Business type: `restaurant`, `cafe`, `bar`, `hotel`, `lodging`, `tourist_attraction`

### Details

```bash
places details <place_id>
```

Returns full info: address, phone, website, hours, top reviews.

## Configuration

Requires at least one API key in `.env`:

```bash
GOOGLE_MAPS_API_KEY=AIza...   # Primary (recommended)
SERP_API_KEY=abc123...           # Fallback if Google quota exceeded
```

## Examples

```bash
# Find hummus near default location
places search "hummus" --location "Binyamina" --rating 4+ --limit 5

# Bars open now within 3km
places search "bars" --near 32.5234,34.9415 --radius 3 --open-now

# Hotels in Tel Aviv, budget options
places search "hotels" --location "Tel Aviv" --price 1-2 --limit 10

# Get full details for a place
places details ChIJN1t_tDeuEmsRUsoyG83frY4
```
