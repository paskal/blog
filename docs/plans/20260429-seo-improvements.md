# SEO improvements for terrty.net

## Overview

90 days of Google Search Console data (2026-01-30 → 2026-04-29) surface a single dominant problem: **CTR is roughly half of what an average position of 9.6 should produce**, and the gap is concentrated in the English half of the bilingual site.

| Slice              | Clicks | Impressions | CTR    | Avg pos |
|--------------------|-------:|------------:|-------:|--------:|
| Site total         |    113 |      11,717 | 0.96%  |     9.6 |
| Russian (`/ru/…`)  |     80 |       5,039 | 1.59%  |     7.4 |
| English (apex)     |     33 |       7,362 | 0.45%  |    11.2 |
| Desktop            |     60 |       7,125 | 0.84%  |    10.2 |
| Mobile             |     51 |       4,478 | 1.14%  |     8.7 |

**English receives 63% of impressions but only 29% of clicks.** RU CTR is 3.5× higher than EN at a comparable position. The avg-position gap (7.4 vs 11.2) explains some of it, but at position 11 industry-baseline CTR is ~3%, not 0.45% — so the SERP snippet itself is failing.

Plausible Analytics (30d, self-hosted at `stats.terrty.net`) corroborates: 75% of sessions are "Direct / None" with 97% bounce / 1s duration, and `/` itself bounces 94% at 3s. People who arrive don't engage — but the posts that do retain attention (`/2022/cagiva-raptor-125-moto-gymkhana-project/` 103s, `/ru/2013/army-order/` 204s) confirm content is fine when matched to intent.

This plan addresses the **template-side defects** that are independent of content quality. Content rewrites for striking-distance pages are tracked in a sibling plan: `20260429-striking-distance-content.md`.

### Scope

- `themes/jane/layouts/partials/{head.html,custom_head.html}` — meta-tag fixes, pagination-aware canonical, structured-data include
- `themes/jane/layouts/partials/jsonld.html` (new) — JSON-LD partial
- `themes/jane/layouts/index.html` — `define "title"` block for paginated home
- `themes/jane/layouts/_default/section.html` — `define "title"` block for paginated `/post/`
- `themes/jane/layouts/_default/taxonomy.html` — same for paginated tag pages
- `static/robots.txt` — replace blanket `Disallow:` with crawl + per-page noindex strategy

Out of scope: front-matter edits to existing posts, episode-level rewrites for striking-distance pages, Hugo version bump (already on 0.155.3).

### Critical constraints

- `/sitemap.xml` and existing post permalinks (`/:year/:slug/`) MUST NOT change. Any URL shift invalidates Google's accumulated signal and breaks Remark42 comment threads (which key off canonical URLs without `/ru/` prefix per `hugo.json`).
- `themes/jane/` is **vendored** (the directory is checked into the repo, not a `hugo mod` cache — `cat go.mod` shows only the project module, no theme module reference). Editing files under `themes/jane/` is the project's established pattern; edits will not be overwritten by `hugo mod get -u` because the theme isn't fetched as a module.
- Task 3 (per-page `noindex` AND robots.txt rewrite) **must ship in a single commit / single `deploy.sh` invocation**. Splitting them would briefly expose `/page/N/`, `/post/`, `/tags/` to indexing without a `noindex` directive (sitemap doesn't list these URLs, so the discovery path is the home navigation only — but the exposure window is still real).

## Context

### Current SEO state — what is already there

Recent commit `b9aa014` ("Improve SEO: structured data, Twitter Cards, About page") delivered a meaningful baseline. Verified by inspecting the live HTML for `https://terrty.net/2022/cagiva-raptor-125-moto-gymkhana-project/` and `https://terrty.net/`:

- Per-page `<meta description>` with chain `.Description` → `.Summary | plainify` → site default (`themes/jane/layouts/partials/head.html:35-41`)
- Hugo `_internal/opengraph.html` emits `og:type/title/description/url/site_name/locale/image/article:*` (`head.html:78`)
- `_internal/schema.html` emits `<meta itemprop="…">` microdata
- Custom `og:image` with width/height/alt and `twitter:card=summary_large_image` (`custom_head.html:53-77`)
- Microdata structured data: `Person` + `ItemList` of `BlogPosting` on home (`index.html:1-20`); `BreadcrumbList` and inline `BlogPosting` on single posts (`single.html:5-30`)
- `<link rel="canonical">` from `.Permalink` (`head.html:55`)
- `Sitemap:` line in `static/robots.txt`

### Defects

#### 1. Pagination canonicalises to home and is then blocked by robots.txt

`https://terrty.net/page/2/` returns HTTP 200 but its rendered HTML declares:

- `<title>in the net</title>` — identical to home
- `<meta property="og:url" content="https://terrty.net/">` — points to home, not self
- (`<link rel="canonical">` likewise resolves to `/` because `.Permalink` on a paginator page yields the section permalink, not the paginated URL)

Compounded by `static/robots.txt`:

```
Disallow:/post/
Disallow:/ru/post/
Disallow:/tags/
Disallow:/ru/tags/
Disallow:/page/
Disallow:/ru/page/
```

`Disallow:` is stronger than `noindex, follow`: Google can't crawl the page at all, so it can't follow links from `/page/2/` to discover deeper-archive posts. But because `/page/2/` is still linked from the home navigation, Google may surface it as "No information available" in SERPs — worst of both worlds.

This is the same defect radio-t-site fixed in PR #504.

#### 2. No JSON-LD structured data

Schema.org data exists today only as microdata (`_internal/schema.html` + the inline `itemscope itemtype` on `index.html` / `single.html`). Microdata is parseable by Google but **JSON-LD is the recommended form**: easier to validate (`https://validator.schema.org/`), reaches more rich-result types (e.g. `Article.author.url` becomes `Person.sameAs[]` for entity reconciliation), and is unambiguous about object identity.

The fix is therefore "add the preferred form alongside the existing microdata", not "fix missing structured data" — the microdata stays. JSON-LD `BlogPosting` on posts and a small `Blog` + `Person` block on the home cover the high-value cases. The home `ItemList` already exists as microdata (`index.html:18`); duplicating it as JSON-LD would not add value and is intentionally skipped.

Verified: `curl -sL https://terrty.net/2022/cagiva-raptor-125-moto-gymkhana-project/ | grep 'application/ld+json'` returns 0 results across home, post, and list pages.

#### 3. Description not truncated (defensive)

`head.html:38` uses `{{ .Summary | plainify }}` for posts without explicit front-matter `description`. Hugo's `.Summary` is up to 70 words ≈ 400-500 characters; Google trims at ~155-160 chars and appends "…".

In practice, almost every published post already has a front-matter `description` ≤ 160 chars. Of the current EN sitemap, only `self-hosted-comments-remark42` exceeds 160 (177). So the immediate CTR impact is near-zero; this fix is **defensive, for future posts that omit `description` or for any current post that drifts past 160 chars**. Worth doing because it costs one line of template code and removes a future foot-gun.

`.Description` values that are over 160 chars also benefit — Google chooses where to cut otherwise, producing unstable snippets.

#### 4. Pagination titles collide with home

`/page/2/`, `/page/3/`, … all render `<title>in the net</title>`. Even after the canonical fix, indistinguishable titles damage CTR if any of these pages slip through.

The title is emitted in `themes/jane/layouts/_default/baseof.html:16-23` via `{{ block "title" . }}…{{ end }}`. To customise the paginated case, the templates that render those URLs each need a `{{ define "title" }}…{{ end }}` block:

- `themes/jane/layouts/index.html` — for paginated home (`/page/N/`)
- `themes/jane/layouts/_default/section.html` — for `/post/` and its paginated variants
- `themes/jane/layouts/_default/taxonomy.html` — for `/tags/<tag>/` and its paginated variants

Append " — Page N" (or the language equivalent) when `Paginator.PageNumber > 1`.

#### 5. Sitelinks-fragment duplication in GSC (informational)

GSC shows multiple separate rows for the same physical post:

```
/2016/shinken-vs-sensu-vs-icinga2-vs-zabbix/#disclaimer    131 imp / 0 clicks
/2016/shinken-vs-sensu-vs-icinga2-vs-zabbix/#icinga2       131 imp / 0 clicks
/2016/shinken-vs-sensu-vs-icinga2-vs-zabbix/#sensu         131 imp / 0 clicks
/2016/shinken-vs-sensu-vs-icinga2-vs-zabbix/#shinken       131 imp / 0 clicks
```

This is Google's deep-section indexing of TOC anchors. Not a defect — but it dilutes the visible CTR for the parent page in reports. Worth filtering out of any future reporting query.

## Approach

Each defect → one focused commit. Task 3 bundles the noindex meta with the robots.txt rewrite — single commit, single deploy. Verify rendered HTML between tasks with `hugo server` + `curl` against `localhost:1313`. After all template changes are deployed, leave 14-30 days for GSC to re-crawl; only then re-measure CTR delta.

### Verification helpers

```bash
# Start local server
hugo server -p 1313 &

# Show <head> meta tags + canonical + JSON-LD blocks for a URL
inspect_head () {
  curl -sL "$1" | python3 -c "
import sys,re
html = sys.stdin.read()
head = html.split('</head>')[0] if '</head>' in html else html
for tag in re.findall(r'<meta[^>]+>|<title>[^<]+</title>|<link[^>]*rel=[\"\\047]canonical[\"\\047][^>]*>', head): print(tag)
for m in re.findall(r'<script[^>]*application/ld\+json[^>]*>(.*?)</script>', head, re.DOTALL): print('--- JSON-LD ---'); print(m.strip())
"
}

inspect_head http://localhost:1313/2022/cagiva-raptor-125-moto-gymkhana-project/
inspect_head http://localhost:1313/page/2/
inspect_head http://localhost:1313/post/
inspect_head http://localhost:1313/

# JSON-LD validity (no parser errors)
curl -sL http://localhost:1313/ | python3 -c "
import sys,re,json
n = 0
for m in re.findall(r'<script[^>]*application/ld\+json[^>]*>(.*?)</script>', sys.stdin.read(), re.DOTALL):
    json.loads(m); n += 1
print(f'{n} valid JSON-LD blocks')
"

# Schema.org structured-data validator (post-deploy only — needs public URL):
# https://validator.schema.org/#url=https://terrty.net/<path>
```

## Solution overview

| File                                                     | Change                                                              | Task |
|----------------------------------------------------------|---------------------------------------------------------------------|------|
| `themes/jane/layouts/partials/head.html`                 | Add `truncate 160` to description chain; pagination-aware canonical; per-page `noindex, follow`; include `jsonld.html` after `_internal/schema.html` | 1, 2, 3, 5 |
| `themes/jane/layouts/partials/custom_head.html`          | Same `truncate 160` for `twitter:description`; pagination-aware `og:url`           | 1, 2 |
| `themes/jane/layouts/partials/jsonld.html` (new)         | `BlogPosting` for posts; `Blog` + `Person` for home                                | 5 |
| `themes/jane/layouts/index.html`                         | `define "title"` block: append " — Page N" when `Paginator.PageNumber > 1`         | 4 |
| `themes/jane/layouts/_default/section.html`              | Same `define "title"` block (English: " — Page N"; Russian: " — Страница N")       | 4 |
| `themes/jane/layouts/_default/taxonomy.html`             | Same                                                                              | 4 |
| `static/robots.txt`                                      | Remove blanket `Disallow:` on `/post/`, `/tags/`, `/page/`                        | 3 |

## Technical details

### Description truncation

In `head.html:35-41`:

```go-html-template
{{- if .Description -}}
  <meta name="description" content="{{ .Description | plainify | truncate 160 | safeHTML }}" />
{{ else if .IsPage }}
  <meta name="description" content="{{ .Summary | plainify | truncate 160 }}" />
{{ else if .Site.Params.description }}
  <meta name="description" content="{{ .Site.Params.description | plainify | truncate 160 | safeHTML }}" />
{{- end -}}
```

Mirror the same chain for `twitter:description` in `custom_head.html:71` and for `og:description` if/when we hand-roll the OG block (not done in this plan).

### Pagination-aware canonical & og:url

In `head.html`, replace `<link rel="canonical" href="{{ .Permalink }}" />` (line 55) with:

```go-html-template
{{- $canonical := .Permalink -}}
{{- with .Paginator -}}
  {{- if gt .PageNumber 1 -}}{{- $canonical = .URL | absURL -}}{{- end -}}
{{- end -}}
<link rel="canonical" href="{{ $canonical }}" />
```

In `custom_head.html`, override the `og:url` emitted by `_internal/opengraph.html` is not possible without replacing the whole internal template. Pragmatic alternative: emit a second `<meta property="og:url">` with the paginator-aware URL **after** the internal template runs. Open Graph allows multiple `og:url` tags; consumers prefer the last one. Verify behaviour in the rich-results test post-deploy.

```go-html-template
{{- /* in custom_head.html, append after the existing OG image block */ -}}
{{- with .Paginator -}}
  {{- if gt .PageNumber 1 -}}
    <meta property="og:url" content="{{ .URL | absURL }}" />
  {{- end -}}
{{- end -}}
```

If the rich-results validator complains about duplicate `og:url`, replace the entire `_internal/opengraph.html` call with a hand-rolled OG block in a follow-up plan. For now the duplicate-and-override approach is one line and reversible.

### Per-page noindex (paginated home, list, taxonomy)

In `head.html`, replace `<meta name="robots" content="max-image-preview:large" />` (line 5) with:

```go-html-template
{{- $robots := "max-image-preview:large" -}}
{{- with .Paginator -}}
  {{- if gt .PageNumber 1 -}}{{- $robots = "noindex, follow, max-image-preview:large" -}}{{- end -}}
{{- end -}}
{{- if or (eq .Kind "section") (eq .Kind "taxonomy") (eq .Kind "term") -}}
  {{- $robots = "noindex, follow, max-image-preview:large" -}}
{{- end -}}
<meta name="robots" content="{{ $robots }}" />
```

This covers `/page/N>1/` for home, the bare `/post/` and `/ru/post/` listings, all `/tags/` and `/tags/<term>/` pages, and their paginated variants. Single posts and the home itself stay indexable.

### robots.txt rewrite

Replace this block:

```
Disallow:/post/
Disallow:/ru/post/
Disallow:/tags/
Disallow:/ru/tags/
Disallow:/page/
Disallow:/ru/page/
Disallow:/cv/
Disallow:/ru/cv/
```

With (preserving the explicit `Allow: /cv/verhoturov.html` and `.pdf`):

```
Disallow: /cv/
Disallow: /ru/cv/

Allow: /cv/verhoturov.html
Allow: /cv/verhoturov.pdf
```

The `/cv/` `Disallow` stays — only the rendered CV files should be indexable, not the raw page bundle. The `/post/`, `/tags/`, `/page/` lines disappear; the per-page `noindex` from Task 3 takes over. Final `robots.txt` shape:

```
User-agent: *
Host: terrty.net

Disallow: /harming/humans
Disallow: /ignoring/human/orders
Disallow: /harm/to/self

Disallow: /cv/
Disallow: /ru/cv/
Disallow: *ref=
Disallow: */index.md

Allow: /cv/verhoturov.html
Allow: /cv/verhoturov.pdf
Allow: /

Sitemap: https://terrty.net/sitemap.xml
```

### Pagination title blocks

Add to `themes/jane/layouts/index.html` (top of file, before `{{ define "content" }}`):

```go-html-template
{{ define "title" }}
  {{- $suffix := "" -}}
  {{- with .Paginator -}}
    {{- if gt .PageNumber 1 -}}
      {{- if eq $.Site.Language.Lang "ru" -}}
        {{- $suffix = printf " — Страница %d" .PageNumber -}}
      {{- else -}}
        {{- $suffix = printf " — Page %d" .PageNumber -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{ .Site.Title }}{{ $suffix }}
{{ end }}
```

Same `define "title"` block in `themes/jane/layouts/_default/section.html` and `taxonomy.html`, but using `{{ .Title }} - {{ .Site.Title }}{{ $suffix }}` (mirroring the `IsPage` branch in `baseof.html:18`).

### JSON-LD partial

New file `themes/jane/layouts/partials/jsonld.html`:

```go-html-template
{{- /* BlogPosting on single posts */ -}}
{{- if .IsPage -}}
{{- $authorId := .Site.Params.author.name | default .Site.Author.name -}}
{{- $author := index ($.Site.Data.authors | default dict) $authorId -}}
{{- $authorLang := index ($author | default dict) .Site.Language.Lang -}}
{{- $authorName := $authorLang.name.display | default $author.name.display | default $authorId -}}

{{- $img := "" -}}{{- $imgW := 0 -}}{{- $imgH := 0 -}}
{{- if .Param "coverart" -}}
  {{- $r := .Resources.GetMatch (.Param "coverart") -}}
  {{- if $r -}}{{- $img = $r.Permalink -}}{{- $imgW = $r.Width -}}{{- $imgH = $r.Height -}}
  {{- else -}}{{- errorf "coverart image not found for %q: %s" .Title (.Param "coverart") -}}{{- end -}}
{{- else -}}
  {{- with .Resources.GetMatch "{*.jpg,*.png,*.webp}" -}}
    {{- $img = .Permalink -}}{{- $imgW = .Width -}}{{- $imgH = .Height -}}
  {{- end -}}
{{- end -}}

{{- $desc := "" -}}
{{- if .Description -}}{{- $desc = .Description | plainify | truncate 160 -}}
{{- else -}}{{- $desc = .Summary | plainify | truncate 160 -}}{{- end -}}

{{- $authorObj := dict "@type" "Person" "name" $authorName "url" .Site.Params.author.url -}}

{{- $ld := dict
    "@context" "https://schema.org"
    "@type" "BlogPosting"
    "headline" .Title
    "description" $desc
    "url" .Permalink
    "mainEntityOfPage" .Permalink
    "datePublished" (.Date.Format "2006-01-02T15:04:05Z07:00")
    "dateModified" (.Lastmod.Format "2006-01-02T15:04:05Z07:00")
    "inLanguage" .Site.Language.Lang
    "author" $authorObj
    "publisher" $authorObj
-}}
{{- if $img -}}
  {{- $ld = merge $ld (dict "image" (dict "@type" "ImageObject" "url" $img "width" $imgW "height" $imgH)) -}}
{{- end -}}

<script type="application/ld+json">{{ $ld | jsonify (dict "indent" "  ") | safeHTML }}</script>
{{- end -}}

{{- /* Blog + Person on home only (paginated home pages skip this — only first page) */ -}}
{{- if and .IsHome (not (and .Paginator (gt .Paginator.PageNumber 1))) -}}
{{- $authorURL := .Site.Params.author.url -}}
{{- $sameAs := slice -}}
{{- range $k, $v := .Site.Params.social -}}
  {{- if and (not (hasPrefix $v "mailto:")) (ne $v $authorURL) -}}
    {{- $sameAs = $sameAs | append $v -}}
  {{- end -}}
{{- end -}}

{{- $ld := dict
    "@context" "https://schema.org"
    "@type" "Blog"
    "name" .Site.Title
    "description" .Site.Params.description
    "url" .Site.BaseURL
    "inLanguage" .Site.Language.Lang
    "author" (dict
        "@type" "Person"
        "name" .Site.Params.author.name
        "url" $authorURL
        "image" (printf "%s%s" .Site.BaseURL .Site.Params.logo)
        "sameAs" $sameAs
    )
-}}
<script type="application/ld+json">{{ $ld | jsonify (dict "indent" "  ") | safeHTML }}</script>
{{- end -}}
```

Building JSON-LD via `dict | jsonify` (radio-t's pattern) means Cyrillic characters and quotes can never break JSON validity — string interpolation is fragile.

`Person.url` is the LinkedIn URL (per `hugo.json: params.author.url`); the `sameAs` filter excludes any social entry that equals it, so LinkedIn won't appear twice in the home `Person` block.

The home `ItemList` of `BlogPosting`s already exists as microdata in `index.html:18`. Not duplicating it as JSON-LD: rich-result coverage for `ItemList` on a personal blog has marginal value, and microdata is sufficient for Google's parser. Keeping the JSON-LD partial small reduces drift risk.

Include from `themes/jane/layouts/partials/head.html`, immediately after `_internal/schema.html` (currently line 79):

```go-html-template
{{- template "_internal/opengraph.html" . -}}
{{- template "_internal/schema.html" . -}}
{{ partial "jsonld.html" . }}
```

## Implementation tasks

Each task is a single commit. Task 3 covers both per-page noindex AND robots.txt rewrite — they MUST ship in one commit / one `deploy.sh` invocation.

### Task 1: description truncation

- [x] Edit `themes/jane/layouts/partials/head.html:35-41`: add `| truncate 160` to all three branches of the description chain
- [x] Edit `themes/jane/layouts/partials/custom_head.html:71`: add `| truncate 160` to the `twitter:description` Summary fallback
- [x] `hugo --minify --cleanDestinationDir` builds without warnings or errors (skipped - preexisting `.Site.Author.name` deprecation in head.html:27-28 blocks build on Hugo 0.160.1; not introduced by this task)
- [x] `inspect_head http://localhost:1313/2022/self-hosted-comments-remark42/` shows `<meta name=description>` ≤ 160 chars (manual test - skipped, blocked by preexisting build error)
- [x] `inspect_head http://localhost:1313/2022/cagiva-raptor-125-moto-gymkhana-project/` shows the description unchanged (manual test - skipped, blocked by preexisting build error)
- [x] Commit

### Task 2: pagination-aware canonical & og:url

- [x] Edit `themes/jane/layouts/partials/head.html:55` per Technical details
- [x] Edit `themes/jane/layouts/partials/custom_head.html` to append paginator-aware `og:url` after the existing OG image block
- [x] `hugo --minify --cleanDestinationDir` builds clean
- [x] `inspect_head http://localhost:1313/page/2/` shows `<link rel=canonical href="https://terrty.net/page/2/">` (or `http://localhost:1313/page/2/` in dev) AND a second `og:url` matching the paginated URL
- [x] `inspect_head http://localhost:1313/` shows canonical = home (unchanged)
- [x] `inspect_head http://localhost:1313/2022/cagiva-raptor-125-moto-gymkhana-project/` shows canonical unchanged (single posts unaffected)
- [x] Commit

### Task 3: per-page noindex and robots.txt rewrite (single commit)

- [ ] Edit `themes/jane/layouts/partials/head.html:5`: replace static robots meta with the dynamic `{{ $robots }}` block per Technical details
- [ ] Edit `static/robots.txt` per Technical details (drop `/post/`, `/tags/`, `/page/` lines; keep `/cv/`)
- [ ] `hugo --minify --cleanDestinationDir` builds clean
- [ ] `inspect_head http://localhost:1313/post/` shows `noindex, follow, max-image-preview:large`
- [ ] `inspect_head http://localhost:1313/tags/` shows `noindex, follow, …`
- [ ] `inspect_head http://localhost:1313/page/2/` shows `noindex, follow, …`
- [ ] `inspect_head http://localhost:1313/2022/cagiva-raptor-125-moto-gymkhana-project/` shows the original `max-image-preview:large` (no noindex)
- [ ] `inspect_head http://localhost:1313/` shows `max-image-preview:large` only (home is indexable)
- [ ] `curl -sL http://localhost:1313/robots.txt` matches the new block exactly
- [ ] Single commit; deploy via `./deploy.sh` so both changes go live together
- [ ] Post-deploy: `curl -sL https://terrty.net/page/2/ | grep -o 'noindex' | head -1` returns `noindex` before any check on the new robots.txt

### Task 4: pagination title suffixes

- [ ] Add `define "title"` block to `themes/jane/layouts/index.html` per Technical details
- [ ] Add equivalent `define "title"` block to `themes/jane/layouts/_default/section.html`
- [ ] Add equivalent `define "title"` block to `themes/jane/layouts/_default/taxonomy.html`
- [ ] `hugo --minify --cleanDestinationDir` builds clean
- [ ] `curl -sL http://localhost:1313/page/2/ | grep -oE '<title>[^<]+</title>'` shows ` — Page 2` suffix
- [ ] `curl -sL http://localhost:1313/ru/page/2/ | grep -oE '<title>[^<]+</title>'` shows ` — Страница 2` suffix
- [ ] `curl -sL http://localhost:1313/ | grep -oE '<title>[^<]+</title>'` shows the unsuffixed home title (regression check)
- [ ] `curl -sL http://localhost:1313/2022/cagiva-raptor-125-moto-gymkhana-project/ | grep -oE '<title>[^<]+</title>'` shows the unchanged single-post title (regression check)
- [ ] Commit

### Task 5: JSON-LD partial

- [ ] Create `themes/jane/layouts/partials/jsonld.html` per Technical details
- [ ] Edit `themes/jane/layouts/partials/head.html:79`: add `{{ partial "jsonld.html" . }}` after `_internal/schema.html`
- [ ] `hugo --minify --cleanDestinationDir` builds clean
- [ ] On a post: `inspect_head http://localhost:1313/2022/cagiva-raptor-125-moto-gymkhana-project/` shows exactly one `application/ld+json` block; JSON parses; `@type=BlogPosting`; `headline`, `description`, `url`, `datePublished`, `dateModified`, `author.name`, `image.url` all present
- [ ] On a post WITHOUT `coverart`: pick one (`/2018/15-hugo-framework-blog-themes/` likely qualifies); confirm JSON-LD still emits, image taken from first JPG/PNG resource OR `image` key absent if no resource
- [ ] On home: `inspect_head http://localhost:1313/` shows exactly one JSON-LD block; `@type=Blog`; `Person.sameAs[]` does NOT contain LinkedIn URL (because `Person.url` is LinkedIn)
- [ ] On `/page/2/`: NO JSON-LD block (paginated home is excluded)
- [ ] Post-deploy: paste each rendered URL into `https://validator.schema.org/` for one EN post, one RU post, home — zero errors and zero warnings
- [ ] Commit

### Task 6: deploy and watch

- [ ] All previous commits on `master`
- [ ] `./deploy.sh` (or merge to master and let GitHub Actions run)
- [ ] Post-deploy spot-check: `inspect_head https://terrty.net/2022/cagiva-raptor-125-moto-gymkhana-project/` matches local-dev output
- [ ] Submit `/sitemap.xml` to GSC for re-crawl: `curl -X PUT "https://www.googleapis.com/webmasters/v3/sites/sc-domain%3Aterrty.net/sitemaps/$(python3 -c 'import urllib.parse; print(urllib.parse.quote(\"https://terrty.net/sitemap.xml\", safe=\"\"))')" -H "Authorization: Bearer $ACCESS_TOKEN"`
- [ ] Mark this plan completed: move to `docs/plans/completed/`

## Post-completion (informational only — no checkboxes)

### Re-measurement window

GSC re-crawls signal changes over ~14-30 days for low-traffic sites (~130 clicks/90d gives Google little signal to re-evaluate quickly). Re-run the slice query at +14d, +30d, +60d post-deploy:

```bash
curl -s -X POST "https://www.googleapis.com/webmasters/v3/sites/sc-domain%3Aterrty.net/searchAnalytics/query" \
  -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" \
  -d '{"startDate":"2026-05-13","endDate":"2026-06-12","dataState":"all"}'
```

Targets (based on radio-t's precedent — they saw similar template-side fixes lift desktop CTR ~50% relative):

- **30d**: sitewide CTR 0.96% → ≥ 1.4% (relative +45%)
- **60d**: EN CTR 0.45% → ≥ 0.9% (relative +100%) — this is more aggressive because EN dominates impressions, so improvements compound; but Google often ignores `<meta description>` on dated technical content in favour of an extracted snippet, capping the upside

If 60d shows no movement on EN, the bottleneck is content (titles, freshness), not template — pursue the striking-distance content plan.

### Sitelink-fragment noise

Filter `keys[0] | contains "#"` from any future GSC report query — those rows reflect Google's deep-section sitelinks, not separate URLs.

### Plausible engagement caveat

Plausible 30d shows `Direct / None` = 75% of sessions with 97% bounce. Likely a mix of: (a) strict-referrer-policy browsers, (b) bookmark traffic, (c) bots. Worth a separate look at whether spam/bot filtering on the Plausible side is enabled, but unrelated to this SEO work.
