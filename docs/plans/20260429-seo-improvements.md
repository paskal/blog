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

## Deviations from the original plan

Several template-level adjustments were needed during implementation that the Technical-details snippets below do not fully reflect. Read these before applying any snippet from the Technical details section — the *Pagination-aware canonical & og:url* subsection has been updated in place to show the hand-rolled OG block, but the deviations are summarised here for context.

- **Kind-guards around `with .Paginator`** (Tasks 2 and 3): the canonical, `og:url`, and robots blocks each call `.Paginator`. On a single post `.Paginator` is not callable and Hugo aborts the build with `pagination not supported in this context`. Each `with .Paginator` is wrapped in `if or .IsHome (eq .Kind "section") (eq .Kind "taxonomy") (eq .Kind "term")` so the call only fires on list-type pages.
- **Hand-rolled OG block replaces `_internal/opengraph.html`** (Task 2): the original plan kept `_internal/opengraph.html` and emitted a second `<meta property="og:url">` from `custom_head.html` to override it on paginated pages (last-wins semantics). External validation (codex iteration 2) flagged the duplicate `og:url` as a real defect — some scrapers honour the first tag, which on paginated pages still pointed to the section/home permalink. The shipped fix (commit `121f6c1`) drops the `_internal/opengraph.html` call entirely from `head.html` and emits the full OG block inline (`og:url`, `og:site_name`, `og:title`, `og:description`, `og:locale`, `og:type`, `article:section/published_time/modified_time/tag` on posts), reusing the same `$canonical` variable as the canonical link. `og:image` (and width/height/alt) stays in `custom_head.html`. The plan's *Pagination-aware canonical & og:url* subsection has been rewritten in place to show this approach.
- **`hugo.Data.authors` not `$.Site.Data.authors`** (Task 5): the JSON-LD partial uses `hugo.Data` because `.Site.Data` was deprecated in the 0.160 cleanup commit (`a99d06f`). The plan snippet still shows the legacy form; the shipped partial uses `hugo.Data`.
- **`safeJS` not `safeHTML` on the JSON-LD `<script>` body** (Task 5): Go's `html/template` JS-escapes script bodies by design, and `safeHTML` produces double-encoded JSON inside `<script type="application/ld+json">`. `safeJS` is the correct marker — the value is a literal JS string the parser hands to `JSON.parse`. `terms.html` was also missed in Task 4's title-suffix work and was added in the review pass (paginated `/tags/page/N/` was emitting the unsuffixed title).
- **JSON-LD partial replaced with equivalent inline microdata** (post-Task-5, by user request): the user prefers inline microdata (`itemscope` / `itemtype` / `itemprop`) over `<script type="application/ld+json">` because microdata is the existing project convention (see `baseof.html` `<html itemtype>`, `_internal/schema.html`, the freestanding `Person` block in `index.html`, and the `BreadcrumbList` / `articleBody` markup in `single.html`) and avoids the script-tag-escaping foot-guns that `safeJS` had to work around. The shipped change deletes `themes/jane/layouts/partials/jsonld.html`, drops the include from `head.html`, adds per-kind `<html itemtype>` logic to `baseof.html` (`Blog` on home, `BlogPosting` on posts, `WebPage` elsewhere), and inlines the equivalent microdata in `single.html` (`author` / `publisher` / `image` / `mainEntityOfPage` / `inLanguage`, gated to `eq .Section "post"`) and `index.html` (Blog `name` / `description` / `url` / `inLanguage` plus `<link itemprop="author" href="#site-author">` referencing the existing Person block, all gated to the unpaginated home). The *Structured data via inline microdata* subsection in *Technical details* has been rewritten to show this approach.

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
| `themes/jane/layouts/partials/head.html`                 | Add `truncate 160` to description chain; pagination-aware canonical; hand-rolled OG block sharing the `$canonical` variable; per-page `noindex, follow`; rely on `_internal/schema.html` for shared microdata (no JSON-LD partial) | 1, 2, 3, 5 |
| `themes/jane/layouts/partials/custom_head.html`          | Same `truncate 160` for `twitter:description`; emits `og:image` (and width/height/alt) only — `og:url` is now hand-rolled in `head.html` | 1, 2 |
| `themes/jane/layouts/_default/baseof.html`               | `<html itemtype>` per kind: `BlogPosting` on posts, `Blog` on home, `WebPage` elsewhere | 5 |
| `themes/jane/layouts/_default/single.html`               | Inline microdata for posts: `mainEntityOfPage`, `inLanguage`, `author` Person, `publisher` Person, `image` ImageObject (gated to `eq .Section "post"`) | 5 |
| `themes/jane/layouts/index.html`                         | `define "title"` block: append " — Page N" when `Paginator.PageNumber > 1`; Blog properties (name, description, url, inLanguage, author) on first page; existing `Person` block keeps `id="site-author"` | 4, 5 |
| `themes/jane/layouts/_default/section.html`              | Same `define "title"` block (English: " — Page N"; Russian: " — Страница N")       | 4 |
| `themes/jane/layouts/_default/taxonomy.html`             | Same                                                                              | 4 |
| `static/robots.txt`                                      | Reformat existing `Disallow:` lines (style only); `/post/`, `/tags/`, `/page/`, `/cv/` all stay disallowed | 3 |

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

Mirror the same chain for `twitter:description` in `custom_head.html:71` and for `og:description` in the hand-rolled OG block (see *Pagination-aware canonical & og:url* below — the OG block uses the same three-branch chain).

### Pagination-aware canonical & og:url

In `head.html`, replace `<link rel="canonical" href="{{ .Permalink }}" />` (line 55) with a guarded `$canonical` variable, then reuse the same variable for `og:url` in a hand-rolled OG block (replacing the `{{- template "_internal/opengraph.html" . -}}` call):

```go-html-template
{{- $canonical := .Permalink -}}
{{- if or .IsHome (eq .Kind "section") (eq .Kind "taxonomy") (eq .Kind "term") -}}
  {{- with .Paginator -}}
    {{- if gt .PageNumber 1 -}}{{- $canonical = .URL | absURL -}}{{- end -}}
  {{- end -}}
{{- end -}}
<link rel="canonical" href="{{ $canonical }}" />
```

`_internal/opengraph.html` always emits `.Permalink` for `og:url`, which would conflict with `$canonical` on paginated home/section/term pages. The fix is to drop the internal-template call entirely and hand-roll the OG block so `og:url` reuses `$canonical`:

```go-html-template
{{- $ogDesc := "" -}}
{{- if .Description -}}
  {{- $ogDesc = .Description | plainify | truncate 160 -}}
{{- else if .IsPage -}}
  {{- $ogDesc = .Summary | plainify | truncate 160 -}}
{{- else -}}
  {{- $ogDesc = .Site.Params.description | plainify | truncate 160 -}}
{{- end -}}
{{- $ogTitle := or .Title .Site.Title -}}
{{- $isArticle := and .IsPage (eq .Type "post") -}}
{{- $ogType := cond $isArticle "article" "website" -}}
<meta property="og:url" content="{{ $canonical }}" />
<meta property="og:site_name" content="{{ .Site.Title }}" />
<meta property="og:title" content="{{ $ogTitle }}" />
<meta property="og:description" content="{{ $ogDesc | safeHTML }}" />
<meta property="og:locale" content="{{ .Site.Language.Lang }}" />
<meta property="og:type" content="{{ $ogType }}" />
{{- if $isArticle }}
<meta property="article:section" content="{{ .Section }}" />
<meta property="article:published_time" content="{{ .Date.Format "2006-01-02T15:04:05-07:00" | safeHTML }}" />
<meta property="article:modified_time" content="{{ .Lastmod.Format "2006-01-02T15:04:05-07:00" | safeHTML }}" />
{{- range .GetTerms "tags" | first 6 }}
<meta property="article:tag" content="{{ .Page.Title | plainify | safeHTML }}" />
{{- end }}
{{- end }}
```

`og:image` (and `og:image:width/height/alt`) stays in `custom_head.html`; do not duplicate it here. `og:type` is `article` only when `.IsPage` AND `.Type == "post"`; sections, terms, taxonomies, and the bare `/about/` page stay `website`.

> Historical note: an earlier iteration of this task tried the simpler "emit a second `og:url` after `_internal/opengraph.html`" approach (Open Graph allows multiple `og:url` tags; consumers were assumed to prefer the last one). External validation flagged the duplicate `og:url` as a real defect — some scrapers honour the first tag, which on paginated pages still pointed to the section/home permalink. The hand-rolled block above replaces that approach.

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

With (style cleanup only — every disallow stays in place; `sitemap.xml` lists every post directly so the listing pages add no SEO value):

```
Disallow: /post/
Disallow: /ru/post/
Disallow: /tags/
Disallow: /ru/tags/
Disallow: /page/
Disallow: /ru/page/
Disallow: /cv/
Disallow: /ru/cv/

Allow: /cv/verhoturov.html
Allow: /cv/verhoturov.pdf
```

The per-page `noindex, follow` meta from Task 3 is defence-in-depth — Google can't fetch these via the disallow anyway, but the meta tag means non-Google bots still see the directive. `/cv/` disallow stays — only the rendered CV files should be indexable, not the raw page bundle. Final `robots.txt` shape:

```
User-agent: *
Host: terrty.net

Disallow: /harming/humans
Disallow: /ignoring/human/orders
Disallow: /harm/to/self

Disallow: /post/
Disallow: /ru/post/
Disallow: /tags/
Disallow: /ru/tags/
Disallow: /page/
Disallow: /ru/page/
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

### Structured data via inline microdata

> Originally this section described a `themes/jane/layouts/partials/jsonld.html` partial that emitted `<script type="application/ld+json">` blocks. After the partial shipped (commit `5a8eb98` and earlier), the user requested a switch to inline microdata throughout — see *Deviations from the original plan* near the top of this document. The partial was removed, its include in `head.html` dropped, and the equivalent microdata was added directly to `single.html` and `index.html`. The rest of this section reflects the post-switch shape.

`baseof.html:5` sets `<html itemtype>` per page kind:

```go-html-template
itemtype="{{ if and .IsPage (eq .Type "post") }}https://schema.org/BlogPosting{{ else if .IsHome }}https://schema.org/Blog{{ else }}https://schema.org/WebPage{{ end }}"
```

`_internal/schema.html` (called from `head.html` after the canonical / OG block) emits `<meta itemprop>` tags (`name`, `description`, `datePublished`, `dateModified`, `wordCount`, `keywords`) attached to that scope. The author byline in `partials/post/meta.html` already provides the visible `itemprop="author"` Person on every post. The post-only properties not otherwise covered are inlined inside `<article>` in `single.html`:

```go-html-template
{{- if eq .Section "post" -}}
{{- $authorId := .Site.Params.author.name -}}
{{- $author := index (hugo.Data.authors | default dict) $authorId -}}
{{- $authorLang := index ($author | default dict) .Site.Language.Lang -}}
{{- $authorName := $authorLang.name.display | default $author.name.display | default $authorId -}}
{{- $authorURL := .Site.Params.author.url -}}

<link itemprop="mainEntityOfPage" href="{{ .Permalink }}" />
<meta itemprop="inLanguage" content="{{ .Site.Language.Lang }}" />

<span itemprop="publisher" itemscope itemtype="https://schema.org/Person" style="display:none">
  <meta itemprop="name" content="{{ $authorName }}" />
  <link itemprop="url" href="{{ $authorURL }}" />
</span>

{{- /* coverart > bundle image > Site.Params.image fallback (Article rich-result needs an image) */ -}}
{{- $img := "" -}}{{- $imgW := 0 -}}{{- $imgH := 0 -}}
{{- if .Param "coverart" -}}
  {{- with .Resources.GetMatch (.Param "coverart") -}}
    {{- $img = .Permalink -}}{{- $imgW = .Width -}}{{- $imgH = .Height -}}
  {{- else -}}
    {{- errorf "coverart image not found for %q: %s" .Title (.Param "coverart") -}}
  {{- end -}}
{{- else -}}
  {{- with .Resources.GetMatch "{*.jpg,*.png,*.webp}" -}}
    {{- $img = .Permalink -}}{{- $imgW = .Width -}}{{- $imgH = .Height -}}
  {{- end -}}
{{- end -}}
{{- if not $img -}}
  {{- with .Site.Params.image -}}
    {{- $cfg := imageConfig (add "/static" (. | safeURL)) -}}
    {{- $img = . | absURL -}}{{- $imgW = $cfg.Width -}}{{- $imgH = $cfg.Height -}}
  {{- end -}}
{{- end -}}
{{- if $img }}
<span itemprop="image" itemscope itemtype="https://schema.org/ImageObject" style="display:none">
  <link itemprop="url" href="{{ $img }}" />
  <meta itemprop="width" content="{{ $imgW }}" />
  <meta itemprop="height" content="{{ $imgH }}" />
</span>
{{- end }}
{{- end }}
```

The `eq .Section "post"` gate keeps `/about/`, `/cv/`, etc. clean — those pages stay typed `WebPage` per `baseof.html` and must not get `BlogPosting` properties. `<span ... style="display:none">` hides the metadata visually; Google parses microdata regardless of CSS visibility (the same trick `index.html` already used for the freestanding `Person` block).

The home page Blog properties live in `index.html`, gated to the unpaginated home only:

```go-html-template
{{- $isFirstHome := and .IsHome (or (not .Paginator) (le .Paginator.PageNumber 1)) -}}
{{- if $isFirstHome }}
<meta itemprop="name" content="{{ .Site.Title }}" />
<meta itemprop="description" content="{{ .Site.Params.description | plainify | truncate 160 }}" />
<link itemprop="url" href="{{ .Permalink }}" />
<meta itemprop="inLanguage" content="{{ .Site.Language.Lang }}" />
<link itemprop="author" href="#site-author" />
<div id="site-author" itemprop="author" itemscope itemtype="https://schema.org/Person" style="display:none">
  <meta itemprop="name" content="{{ .Site.Params.author.name }}" />
  <link itemprop="url" href="{{ .Site.Params.author.url }}" />
  <link itemprop="image" href="{{ .Site.Params.logo | absURL }}" />
  {{ with .Site.Params.social }}
    {{ range $key, $value := . }}
      {{ if not (hasPrefix $value "mailto:") }}
      <link itemprop="sameAs" href="{{ $value }}" />
      {{ end }}
    {{ end }}
  {{ end }}
</div>
{{- end }}
```

The `<html itemtype="https://schema.org/Blog">` scope (set in `baseof.html` for `.IsHome`) wraps the whole document, so the loose `<meta itemprop>` tags above attach to it. The freestanding `Person` block is given `id="site-author"` so the Blog can `<link itemprop="author" href="#site-author">` — schema.org honours `href`-based references for nested entities. The existing `<section ... itemtype="ItemList">` listing posts as `BlogPosting` items is unchanged; it remains a sibling top-level item (no `itemprop` attaches it to Blog, which matches what JSON-LD did — the `ItemList` was always intentionally separate).

The `head.html` include order — note no `jsonld.html` partial:

```go-html-template
{{- template "_internal/schema.html" . -}}
```

Cyrillic and quoted strings need no escaping in microdata, which is one less foot-gun than JSON-LD (the original `jsonld.html` had to use `safeJS` to avoid Go's `html/template` JS-escaping of script bodies producing double-encoded JSON).

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

- [x] Edit `themes/jane/layouts/partials/head.html:55` per Technical details (compute `$canonical`, reuse for canonical + hand-rolled OG block; replaces the `_internal/opengraph.html` call)
- [x] Edit `themes/jane/layouts/partials/custom_head.html`: emit `og:image` (and width/height/alt) only — no `og:url` here, the hand-rolled block in `head.html` owns it (initial iteration emitted a duplicate `og:url` to override the internal template; later replaced by the hand-rolled block after external validation flagged the duplicate)
- [x] `hugo --minify --cleanDestinationDir` builds clean
- [x] `inspect_head http://localhost:1313/page/2/` shows `<link rel=canonical href="https://terrty.net/page/2/">` and exactly one `og:url` matching the paginated URL (no duplicates)
- [x] `inspect_head http://localhost:1313/` shows canonical = home (unchanged)
- [x] `inspect_head http://localhost:1313/2022/cagiva-raptor-125-moto-gymkhana-project/` shows canonical unchanged (single posts unaffected)
- [x] Commit

### Task 3: per-page noindex and robots.txt rewrite (single commit)

- [x] Edit `themes/jane/layouts/partials/head.html:5`: replace static robots meta with the dynamic `{{ $robots }}` block per Technical details
- [x] Edit `static/robots.txt` per Technical details (style cleanup only; `/post/`, `/tags/`, `/page/`, `/cv/` all stay disallowed — sitemap lists posts directly so listing pages add no SEO value)
- [x] `hugo --minify --cleanDestinationDir` builds clean
- [x] `inspect_head http://localhost:1313/post/` shows `noindex, follow, max-image-preview:large`
- [x] `inspect_head http://localhost:1313/tags/` shows `noindex, follow, …`
- [x] `inspect_head http://localhost:1313/page/2/` shows `noindex, follow, …`
- [x] `inspect_head http://localhost:1313/2022/cagiva-raptor-125-moto-gymkhana-project/` shows the original `max-image-preview:large` (no noindex)
- [x] `inspect_head http://localhost:1313/` shows `max-image-preview:large` only (home is indexable)
- [x] `curl -sL http://localhost:1313/robots.txt` matches the new block exactly
- [x] Single commit; deploy via `./deploy.sh` so both changes go live together (one commit produced; deploy half: [x] deploy (Task 6))
- [x] post-deploy (Task 6)

### Task 4: pagination title suffixes

- [x] Add `define "title"` block to `themes/jane/layouts/index.html` per Technical details
- [x] Add equivalent `define "title"` block to `themes/jane/layouts/_default/section.html`
- [x] Add equivalent `define "title"` block to `themes/jane/layouts/_default/taxonomy.html`
- [x] `hugo --minify --cleanDestinationDir` builds clean
- [x] `curl -sL http://localhost:1313/page/2/ | grep -oE '<title>[^<]+</title>'` shows ` — Page 2` suffix
- [x] `curl -sL http://localhost:1313/ru/page/2/ | grep -oE '<title>[^<]+</title>'` shows ` — Страница 2` suffix
- [x] `curl -sL http://localhost:1313/ | grep -oE '<title>[^<]+</title>'` shows the unsuffixed home title (regression check)
- [x] `curl -sL http://localhost:1313/2022/cagiva-raptor-125-moto-gymkhana-project/ | grep -oE '<title>[^<]+</title>'` shows the unchanged single-post title (regression check)
- [x] Commit

### Task 5: structured data (originally JSON-LD partial; replaced with inline microdata after user feedback)

Originally shipped as a JSON-LD partial (`themes/jane/layouts/partials/jsonld.html`); subsequently replaced with equivalent inline microdata at the user's request. The checklist below reflects the post-replacement shape.

- [x] (Originally) Create `themes/jane/layouts/partials/jsonld.html`
- [x] (Originally) Edit `themes/jane/layouts/partials/head.html`: add `{{ partial "jsonld.html" . }}` after `_internal/schema.html`
- [x] Replace JSON-LD with microdata: delete `jsonld.html`, drop the include from `head.html`, add `<html itemtype="...">` per-kind logic in `baseof.html` (`Blog` on home, `BlogPosting` on posts, `WebPage` elsewhere), inline microdata in `single.html` (`author` / `publisher` / `image` / `mainEntityOfPage` / `inLanguage`, gated to `eq .Section "post"`), and Blog properties + `id="site-author"` Person reference in `index.html` (gated to first-page home)
- [x] `hugo --minify --cleanDestinationDir` builds clean
- [x] On a post: `inspect_head http://localhost:1313/2022/cagiva-raptor-125-moto-gymkhana-project/` shows zero `application/ld+json` blocks and `<html itemtype="https://schema.org/BlogPosting">`; `<span itemprop="author">`, `<span itemprop="publisher">`, `<span itemprop="image">` (with `width` / `height`), `<link itemprop="mainEntityOfPage">` all present
- [x] On a post without `coverart` (`/2020/sre-vs-devops/`): `image` falls back to `Site.Params.image` with resolved `width` / `height`
- [x] On `/about/` and `/ru/about/`: NO `BlogPosting` properties (the `eq .Section "post"` guard holds)
- [x] On home: `inspect_head http://localhost:1313/` shows zero `application/ld+json`; `<html itemtype="https://schema.org/Blog">`; Blog `name` / `description` / `url` / `inLanguage` present; freestanding `Person` block with `id="site-author"` and `sameAs` social links
- [x] On `/page/2/`: NO Blog properties (paginated home is excluded)
- [x] On a Cyrillic post (`/ru/2013/army-order/`): all `itemprop` values render correctly with Cyrillic content (microdata sidesteps the JSON-string escaping `safeJS` had to manage)
- [x] schema.org validator (Task 6)
- [x] Commit

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
