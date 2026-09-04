---
name: google-search-console
description: "Google Search Console API — query organic search performance for terrty.net (bilingual EN/RU blog): keyword rankings, impressions, CTR by query/page/device/country, indexing status via URL Inspection, sitemap management. Use when working on SEO, comparing EN vs RU performance, finding striking-distance queries (positions 11-20), diagnosing CTR gaps, or checking whether a post is indexed."
---

# Google Search Console API

Ground truth for Google organic data on **terrty.net**. The blog is bilingual (`/` for English, `/ru/` for Russian), so most analyses split by `page` regex or by `country` (`rus` vs everything else).

## Environment Variables

- `GOOGLE_CLIENT_ID` — OAuth 2.0 client ID
- `GOOGLE_CLIENT_SECRET` — OAuth 2.0 client secret
- `GOOGLE_REFRESH_TOKEN` — long-lived refresh token (does not expire unless revoked)
- The OAuth credentials above are set globally in shell rc and are shared across every property the user has verified — **but `GSC_SITE_URL` is set globally to a different site** (`sc-domain:favor-group.ru`). For this blog, **always pin the site explicitly** at the top of any session:

```bash
GSC_SITE_URL=sc-domain:terrty.net
```

The `sc-domain:` form covers `https://terrty.net/` and any subdomain.

## Getting Access Tokens

Access tokens expire after ~1 hour. Exchange the refresh token for a fresh one before each session:

```bash
ACCESS_TOKEN=$(curl -s -X POST "https://oauth2.googleapis.com/token" \
  -d "client_id=$GOOGLE_CLIENT_ID" \
  -d "client_secret=$GOOGLE_CLIENT_SECRET" \
  -d "refresh_token=$GOOGLE_REFRESH_TOKEN" \
  -d "grant_type=refresh_token" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
```

All API calls use `Authorization: Bearer $ACCESS_TOKEN`.

## API Basics

- **Search Console base:** `https://www.googleapis.com/webmasters/v3`
- **URL Inspection base:** `https://searchconsole.googleapis.com/v1`
- **Site URL encoding:** `{siteUrl}` path param must be URL-encoded.

```bash
GSC_SITE_URL=sc-domain:terrty.net
SITE_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$GSC_SITE_URL', safe=''))")
```

## Search Analytics (the main endpoint)

**Endpoint:** `POST /sites/{siteUrl}/searchAnalytics/query`

### Request body schema

```json
{
  "startDate": "2026-01-30",
  "endDate": "2026-04-29",
  "dimensions": ["query", "page", "device", "country", "date", "searchAppearance"],
  "type": "web",
  "dimensionFilterGroups": [
    {
      "groupType": "and",
      "filters": [
        {"dimension": "page", "operator": "includingRegex", "expression": "^https://terrty\\.net/ru/"}
      ]
    }
  ],
  "aggregationType": "auto",
  "rowLimit": 25000,
  "startRow": 0,
  "dataState": "all"
}
```

### Dimensions

| Dimension | Description |
|-----------|-------------|
| `query` | Search query text |
| `page` | Canonical URL of the landing page |
| `country` | ISO 3166-1 alpha-3 (`rus`, `usa`, `nld`, etc.) |
| `device` | `DESKTOP`, `MOBILE`, `TABLET` |
| `date` | YYYY-MM-DD — enables time series |
| `searchAppearance` | Rich result types (FAQ, Review, AMP, etc.). Mutually exclusive with most other dimensions; query separately. |
| `hour` | Hour of day — requires `dataState: "hourly_all"` |

### Search types (`type` parameter)

| Value | Use for |
|-------|---------|
| `web` | Main search (default — use this for standard SEO) |
| `image` | Image search |
| `video` | Video results |
| `news` | Google News |
| `discover` | Google Discover feed |

### Filter operators

| Operator | Behaviour |
|----------|-----------|
| `equals` | Exact match (case-sensitive for `page`/`query`) |
| `contains` | Partial match (case-insensitive) |
| `notEquals` | Exact non-match |
| `notContains` | Substring exclusion |
| `includingRegex` | RE2 regex (use to split EN vs RU by URL prefix) |
| `excludingRegex` | RE2 regex exclusion |

### Response metrics

Each row returns:
- `keys` — array matching your `dimensions` order
- `clicks`, `impressions`
- `ctr` (0.0–1.0)
- `position` — average position in search results

### Pagination

- `rowLimit`: 1–25000 (default 1000)
- `startRow`: offset for pagination (paginate with `startRow += rowLimit`)
- Empty results when `startRow` exceeds total

### Data freshness (`dataState`)

| Value | Description |
|-------|-------------|
| `final` (default) | Finalised data (~2-3 day lag) |
| `all` | Includes fresh data — use for recent dates |
| `hourly_all` | Hourly breakdown — pair with `hour` dimension |

## Example queries

### Site totals (last 90 days)
```bash
curl -s -X POST "https://www.googleapis.com/webmasters/v3/sites/$SITE_ENCODED/searchAnalytics/query" \
  -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" \
  -d '{"startDate":"2026-01-30","endDate":"2026-04-29","dataState":"all"}'
```

### Top organic queries
```bash
curl -s -X POST "https://www.googleapis.com/webmasters/v3/sites/$SITE_ENCODED/searchAnalytics/query" \
  -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" \
  -d '{
    "startDate":"2026-01-30","endDate":"2026-04-29",
    "dimensions":["query"],"rowLimit":100,"dataState":"all"
  }' | python3 -c "
import sys,json
rows = json.load(sys.stdin).get('rows', [])
print(f\"{'Query':<50} {'Clicks':>7} {'Impr':>8} {'CTR':>7} {'Pos':>6}\")
for r in rows:
    print(f\"{r['keys'][0][:48]:<50} {r['clicks']:>7.0f} {r['impressions']:>8.0f} {r['ctr']*100:>6.1f}% {r['position']:>6.1f}\")
"
```

### Top landing pages
```bash
curl -s -X POST "https://www.googleapis.com/webmasters/v3/sites/$SITE_ENCODED/searchAnalytics/query" \
  -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" \
  -d '{
    "startDate":"2026-01-30","endDate":"2026-04-29",
    "dimensions":["page"],"rowLimit":100,"dataState":"all"
  }'
```

### EN vs RU split (compare clicks, CTR, position)
```bash
for prefix in "^https://terrty\\.net/ru/" "^https://terrty\\.net/(?!ru/)"; do
  echo "== $prefix =="
  curl -s -X POST "https://www.googleapis.com/webmasters/v3/sites/$SITE_ENCODED/searchAnalytics/query" \
    -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" \
    -d "{
      \"startDate\":\"2026-01-30\",\"endDate\":\"2026-04-29\",
      \"dimensionFilterGroups\":[{\"filters\":[{\"dimension\":\"page\",\"operator\":\"includingRegex\",\"expression\":\"$prefix\"}]}],
      \"dataState\":\"all\"
    }"
done
```

### Desktop vs mobile CTR
```bash
curl -s -X POST "https://www.googleapis.com/webmasters/v3/sites/$SITE_ENCODED/searchAnalytics/query" \
  -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" \
  -d '{"startDate":"2026-01-30","endDate":"2026-04-29","dimensions":["device"],"dataState":"all"}'
```

### Striking-distance queries (positions 11-20 with real impressions)
Quick wins — content tweaks or internal links can push these onto page 1.
```bash
curl -s -X POST "https://www.googleapis.com/webmasters/v3/sites/$SITE_ENCODED/searchAnalytics/query" \
  -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" \
  -d '{
    "startDate":"2026-01-30","endDate":"2026-04-29",
    "dimensions":["query","page"],"rowLimit":25000,"dataState":"all"
  }' | python3 -c "
import sys,json
rows = json.load(sys.stdin).get('rows', [])
striking = [r for r in rows if 10 < r['position'] <= 20 and r['impressions'] >= 50]
striking.sort(key=lambda r: -r['impressions'])
for r in striking[:50]:
    print(f\"pos={r['position']:.1f} impr={r['impressions']:.0f} ctr={r['ctr']*100:.1f}% q={r['keys'][0]} url={r['keys'][1]}\")
"
```

### Daily trend
```bash
curl -s -X POST "https://www.googleapis.com/webmasters/v3/sites/$SITE_ENCODED/searchAnalytics/query" \
  -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" \
  -d '{
    "startDate":"2026-01-30","endDate":"2026-04-29",
    "dimensions":["date"],"rowLimit":1000,"dataState":"all"
  }'
```

## URL Inspection

Check indexing status, canonical, last crawl, structured data detection for a single URL:

```bash
curl -s -X POST "https://searchconsole.googleapis.com/v1/urlInspection/index:inspect" \
  -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" \
  -d '{
    "inspectionUrl": "https://terrty.net/2024/some-post/",
    "siteUrl": "sc-domain:terrty.net",
    "languageCode": "en"
  }'
```

Returns `inspectionResult.{indexStatusResult, mobileUsabilityResult, richResultsResult, ampResult}`. **Limit: 2000 URL inspections per day per property.**

## Sitemaps

### List
```bash
curl -s "https://www.googleapis.com/webmasters/v3/sites/$SITE_ENCODED/sitemaps" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

Returns `lastSubmitted`, `lastDownloaded`, `warnings`, `errors`, `isPending`, `contents` per type.

### Submit / resubmit
```bash
SITEMAP_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('https://terrty.net/sitemap.xml', safe=''))")
curl -s -X PUT "https://www.googleapis.com/webmasters/v3/sites/$SITE_ENCODED/sitemaps/$SITEMAP_ENCODED" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

### Delete
```bash
curl -s -X DELETE "https://www.googleapis.com/webmasters/v3/sites/$SITE_ENCODED/sitemaps/$SITEMAP_ENCODED" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

## Sites management

```bash
curl -s "https://www.googleapis.com/webmasters/v3/sites" -H "Authorization: Bearer $ACCESS_TOKEN"
```

## Date ranges

- Last **16 months** rolling
- ~2-3 day lag for finalised data; `dataState: "all"` includes fresh (unfinalised) data
- Pacific Time (UTC-7/8) is used for date boundaries

## Rate limits

- Search Analytics: **1200 queries / minute** per property
- URL Inspection: **2000 / day** per property, 600 / minute per project
- 429 → back off with exponential retry

## Important notes

- Results are capped — `query × page` queries hit internal limits at ~25000 rows. The API does not guarantee all data, just the top rows.
- Rare queries (<~10 impressions) are anonymised and won't appear.
- For full data export, paginate with `startRow`.
- For terrty.net specifically: the `sc-domain:` property covers any subdomain too. If a future analysis only cares about the apex, filter `page` with `includingRegex` of `^https://terrty\.net/`.

## Tips for terrty.net analyses

1. **Always split EN vs RU** — they're completely different audiences (US/EU vs RU/CIS) with different CTR baselines and snippet expectations
2. **Striking-distance queries** (position 11-20, ≥50 impressions) are the cheapest wins for a personal blog
3. **Desktop vs mobile CTR gap** — if desktop CTR is materially lower, the SERP snippet is the prime suspect (missing/duplicate `<meta description>`, no rich result, generic title)
4. **Cross-reference Plausible** — GSC tells you what brought a click; Plausible tells you what the visitor did after. Use them together when judging which posts deserve a refresh.
