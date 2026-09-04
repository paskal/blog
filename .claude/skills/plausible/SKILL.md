---
name: plausible
description: "Plausible Analytics API for terrty.net blog (self-hosted at stats.terrty.net) — query pageviews, visitors, bounce rate, session duration, top pages, sources, devices, countries. Use when measuring on-site engagement, finding which posts drive real time-on-page, comparing EN vs RU traffic, or pairing with GSC: GSC explains what brought a click, Plausible explains what happened next."
---

# Plausible Analytics API

Self-hosted instance at `https://stats.terrty.net`, site id `terrty.net`. Public dashboard at `https://stats.terrty.net/terrty.net` is read-only and link-shareable; the API gives programmatic access to the same data.

## Environment Variables

- `PLAUSIBLE_API_URL` — base URL, default `https://stats.terrty.net`
- `PLAUSIBLE_SITE_ID` — site id, default `terrty.net`
- `PLAUSIBLE_API_KEY` — Bearer token (generate at `https://stats.terrty.net/settings/api-keys`, scope: **Stats API**)

If the env var isn't set, generating a key takes ~30 seconds: log in to the dashboard → Account Settings → API Keys → "+ New API Key" → name it "claude-blog" → copy the token (shown once).

## Two API flavours

| API | Endpoint | When to use |
|-----|----------|-------------|
| **Query API v2** | `POST /api/v2/query` | Default. Multiple metrics, custom dimensions, rich filters, single round-trip. |
| **Stats API v1** | `GET /api/v1/stats/{aggregate,timeseries,breakdown,realtime/visitors}` | Quick one-liners, dashboards, when v2 is overkill. |

Both share the same Bearer token. Self-hosted instances expose both; v2 is the long-term direction.

## Common request setup

```bash
: "${PLAUSIBLE_API_URL:=https://stats.terrty.net}"
: "${PLAUSIBLE_SITE_ID:=terrty.net}"
AUTH=(-H "Authorization: Bearer $PLAUSIBLE_API_KEY")
```

## Query API v2 (preferred)

**Endpoint:** `POST $PLAUSIBLE_API_URL/api/v2/query`

### Request body schema

```json
{
  "site_id": "terrty.net",
  "metrics": ["visitors", "pageviews", "views_per_visit", "bounce_rate", "visit_duration"],
  "date_range": "30d",
  "dimensions": ["event:page"],
  "filters": [["is", "visit:country", ["RU"]]],
  "order_by": [["visitors", "desc"]],
  "pagination": {"limit": 100, "offset": 0}
}
```

### Metrics

| Metric | Description |
|--------|-------------|
| `visitors` | Unique visitors |
| `visits` | Total sessions |
| `pageviews` | Total page loads |
| `views_per_visit` | Pages per session |
| `bounce_rate` | Single-pageview sessions % |
| `visit_duration` | Average session length, seconds |
| `events` | All recorded events (custom + pageviews) |
| `percentage` | Share of dimension within total |
| `conversion_rate` | Goal conversion rate (requires goal filter) |
| `time_on_page` | Average time on a page |

### Dimensions

`event:page`, `event:hostname`, `event:goal`, `event:name`, `event:props:<custom_property>`,
`visit:source`, `visit:referrer`, `visit:utm_medium`, `visit:utm_source`, `visit:utm_campaign`, `visit:utm_term`, `visit:utm_content`,
`visit:device`, `visit:browser`, `visit:browser_version`, `visit:os`, `visit:os_version`,
`visit:country`, `visit:region`, `visit:city`, `visit:entry_page`, `visit:exit_page`,
`time`, `time:hour`, `time:day`, `time:week`, `time:month`.

### Date ranges (`date_range`)

| Value | Meaning |
|-------|---------|
| `"day"`, `"7d"`, `"30d"`, `"month"`, `"6mo"`, `"12mo"`, `"year"`, `"all"` | Predefined |
| `["2026-01-01", "2026-04-29"]` | Explicit range (ISO dates) |
| `["2026-01-01T00:00:00", "2026-04-29T23:59:59"]` | With times |

Add `"date_range_op": "previous"` (or `"comparison"`) to compare against the prior period.

### Filter operators

`["is", dim, [values]]`, `["is_not", dim, [values]]`, `["matches", dim, [regex]]`, `["does_not_match", dim, [regex]]`, `["contains", dim, [substr]]`, `["does_not_contain", dim, [substr]]`. Combine with `["and", [...]]` / `["or", [...]]`.

### Response shape

```json
{
  "results": [
    {"metrics": [123, 456, 1.2, 35.5, 67], "dimensions": ["/2024/some-post/"]}
  ],
  "meta": {"warnings": [], "total_rows": 100},
  "query": { ... echoes the request ... }
}
```

`metrics` and `dimensions` are arrays in the order requested.

## Examples (v2)

### Site totals (last 30 days, headline numbers)
```bash
curl -s -X POST "$PLAUSIBLE_API_URL/api/v2/query" "${AUTH[@]}" -H "Content-Type: application/json" \
  -d '{
    "site_id":"'"$PLAUSIBLE_SITE_ID"'",
    "metrics":["visitors","pageviews","views_per_visit","bounce_rate","visit_duration"],
    "date_range":"30d"
  }' | python3 -m json.tool
```

### Top pages by visitors
```bash
curl -s -X POST "$PLAUSIBLE_API_URL/api/v2/query" "${AUTH[@]}" -H "Content-Type: application/json" \
  -d '{
    "site_id":"'"$PLAUSIBLE_SITE_ID"'",
    "metrics":["visitors","pageviews","bounce_rate","visit_duration"],
    "date_range":"30d",
    "dimensions":["event:page"],
    "order_by":[["visitors","desc"]],
    "pagination":{"limit":50}
  }' | python3 -c "
import sys,json
res = json.load(sys.stdin)['results']
print(f\"{'Page':<60} {'Visitors':>9} {'PVs':>7} {'Bounce':>7} {'Duration':>9}\")
for r in res:
    p = r['dimensions'][0][:58]
    v,pv,br,d = r['metrics']
    print(f\"{p:<60} {v:>9} {pv:>7} {br:>6.1f}% {d:>8.0f}s\")
"
```

### EN vs RU split
```bash
for prefix in '/ru/' '!/ru/'; do
  echo "== $prefix =="
  case $prefix in
    /ru/) FILT='[["matches","event:page",["^/ru/"]]]' ;;
    *)    FILT='[["does_not_match","event:page",["^/ru/"]]]' ;;
  esac
  curl -s -X POST "$PLAUSIBLE_API_URL/api/v2/query" "${AUTH[@]}" -H "Content-Type: application/json" \
    -d '{
      "site_id":"'"$PLAUSIBLE_SITE_ID"'",
      "metrics":["visitors","pageviews","bounce_rate","visit_duration"],
      "date_range":"30d",
      "filters":'"$FILT"'
    }'
done
```

### Top sources / referrers
```bash
curl -s -X POST "$PLAUSIBLE_API_URL/api/v2/query" "${AUTH[@]}" -H "Content-Type: application/json" \
  -d '{
    "site_id":"'"$PLAUSIBLE_SITE_ID"'",
    "metrics":["visitors","bounce_rate"],
    "date_range":"30d",
    "dimensions":["visit:source"],
    "order_by":[["visitors","desc"]],
    "pagination":{"limit":20}
  }'
```

### Country breakdown
```bash
curl -s -X POST "$PLAUSIBLE_API_URL/api/v2/query" "${AUTH[@]}" -H "Content-Type: application/json" \
  -d '{
    "site_id":"'"$PLAUSIBLE_SITE_ID"'",
    "metrics":["visitors","percentage"],
    "date_range":"30d",
    "dimensions":["visit:country"],
    "order_by":[["visitors","desc"]],
    "pagination":{"limit":15}
  }'
```

### Device split
```bash
curl -s -X POST "$PLAUSIBLE_API_URL/api/v2/query" "${AUTH[@]}" -H "Content-Type: application/json" \
  -d '{
    "site_id":"'"$PLAUSIBLE_SITE_ID"'",
    "metrics":["visitors","bounce_rate","visit_duration"],
    "date_range":"30d",
    "dimensions":["visit:device"]
  }'
```

### Daily trend
```bash
curl -s -X POST "$PLAUSIBLE_API_URL/api/v2/query" "${AUTH[@]}" -H "Content-Type: application/json" \
  -d '{
    "site_id":"'"$PLAUSIBLE_SITE_ID"'",
    "metrics":["visitors","pageviews"],
    "date_range":"90d",
    "dimensions":["time:day"]
  }'
```

### Compare current 30d vs previous 30d
```bash
curl -s -X POST "$PLAUSIBLE_API_URL/api/v2/query" "${AUTH[@]}" -H "Content-Type: application/json" \
  -d '{
    "site_id":"'"$PLAUSIBLE_SITE_ID"'",
    "metrics":["visitors","pageviews"],
    "date_range":"30d",
    "include":{"comparisons":{"mode":"previous_period"}}
  }'
```

## Stats API v1 (legacy, simpler)

### Realtime visitors
```bash
curl -s "$PLAUSIBLE_API_URL/api/v1/stats/realtime/visitors?site_id=$PLAUSIBLE_SITE_ID" "${AUTH[@]}"
```

### Aggregate
```bash
curl -s "$PLAUSIBLE_API_URL/api/v1/stats/aggregate?site_id=$PLAUSIBLE_SITE_ID&period=30d&metrics=visitors,pageviews,bounce_rate,visit_duration" "${AUTH[@]}"
```

### Timeseries
```bash
curl -s "$PLAUSIBLE_API_URL/api/v1/stats/timeseries?site_id=$PLAUSIBLE_SITE_ID&period=30d&metrics=visitors" "${AUTH[@]}"
```

### Breakdown (by page, source, country, etc.)
```bash
curl -s "$PLAUSIBLE_API_URL/api/v1/stats/breakdown?site_id=$PLAUSIBLE_SITE_ID&period=30d&property=event:page&metrics=visitors,pageviews,bounce_rate&limit=50" "${AUTH[@]}"
```

`property` accepts the same dimension names as v2.

## Periods (v1)

`day`, `7d`, `30d`, `month`, `6mo`, `12mo`, `custom`. With `custom`, also pass `date=YYYY-MM-DD,YYYY-MM-DD`.

## Filters (v1)

Pass `&filters=event:page==/post/foo;visit:country==RU` — `;` separates filters, `==` is exact match, `!=` is negation, `|` is OR within a property.

## Rate limits

Self-hosted Plausible has no enforced rate limit by default but treat the instance gently (this is a single VM). Cap concurrent requests at ~5 and add a 100ms sleep between iterations of a long loop.

## Notes specific to terrty.net

- Plausible doesn't track sessions across the EN/RU language switch by default — a click on "на русском" starts a new session because the path changes. Compare languages with separate filtered queries, not `dimensions` alone.
- The dashboard at `stats.terrty.net/terrty.net` is set to public (no auth needed for viewing). API still needs the Bearer token.
- For pairing with GSC: GSC's `page` is the full URL (`https://terrty.net/...`), Plausible's `event:page` is path-only (`/...`). Strip the origin before joining the two datasets.
- Goals/funnels are not currently configured on this site — `metrics: ["conversion_rate"]` will return nothing useful until a goal exists.
