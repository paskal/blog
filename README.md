# terrty.net blog source [![Publish Status](https://github.com/paskal/blog/workflows/publish/badge.svg)](https://github.com/paskal/blog/actions/workflows/ci-publish.yml)

This repository contains the source for a personal blog (terrty.net) built with [Hugo](https://gohugo.io/) and uses the [Jane theme](https://github.com/xianmin/hugo-theme-jane). It's proxied by the nginx configuration in [paskal/terrty](https://github.com/paskal/terrty).

## Development

### Requirements

- [Hugo](https://gohugo.io/installation/) (Extended version recommended)

### Local Development

Run the site locally:

```bash
# Start development server with drafts enabled
hugo server -D
```

### Build Commands

```bash
# Build site into public/
./build.sh

# Build and deploy to production
./deploy.sh

# Deploy to a subdirectory of the site, one path component, and not "cv"
./deploy.sh --path <subdirectory>
```

`build.sh` is the only build path in use. It stages into `public.new`, applies
`--panicOnWarning`, keeps `public/cv` (published by the resume repository) and replaces
the contents of `public/` instead of the directory, which nginx bind mounts on the
server. Calling Hugo directly skips all of that, so use the script.

## Site Structure

- `content/`: Blog posts and pages (separate directories for en/ru languages)
- `layouts/`: Custom layout templates that override theme defaults
- `static/`: Static files (CSS, images, etc.)
- `hugo.json`: Site configuration

## Theme Management

The blog uses a vendored copy of the [Jane theme](https://github.com/xianmin/hugo-theme-jane), checked into `themes/jane/` and selected via `"theme": "jane"` in `hugo.json`. It is NOT pulled in as a Hugo module. Editing files under `themes/jane/` is the project's established pattern; customisations live alongside the theme and are never overwritten by upstream updates.

## Deployment

The blog is deployed in two ways:
1. Manually using `deploy.sh` script, which runs `build.sh` and then uploads `public/` with rsync
2. Automatically on a push to master: GitHub Actions builds the site, then calls a webhook that makes the server pull and run `build.sh` in the pinned Hugo container from `docker-compose.yml`

## Multilingual Setup

The blog is bilingual with content in both English and Russian:
- English content is served from the root URL (e.g., `https://terrty.net/post/...`)
- Russian content is served with the `/ru/` prefix (e.g., `https://terrty.net/ru/post/...`)

Content is organized in the directory structure:
- `content/en/` - English content
- `content/ru/` - Russian content

When a post is available in both languages, they share the same slug but different language paths.

## Comments System

The blog uses [Remark42](https://github.com/umputun/remark42) for comments, configured in hugo.json with:
- `remark42Url`: "https://remark42.terrty.net"
- `remark42SiteId`: "terrty"

The comment system is configured to use canonical URLs without the `/ru/` prefix for bilingual pages. This ensures that comments are shared between the English and Russian versions of the same article, rather than having separate comment threads.

## SEO conventions

- **Per-page noindex** (`themes/jane/layouts/partials/head.html`): sections, taxonomies, and terms always emit `noindex, follow, max-image-preview:large`; the home and singles emit `max-image-preview:large` only; paginated home (`/page/N>1/`) also gets `noindex, follow`.
- **All pagination goes through `partials/list_paginator.html`**: Hugo fixes a page's pager on the first `.Paginate` / `.Paginator` call and returns that same pager for every later call, ignoring the arguments. The title block and `head.html` both render before the `content` block, so a caller passing different arguments there silently overrides what the list template asks for. `list_paginator.html` is the one place that decides which pages each kind lists and how many per pager, and every caller (`head.html`, `page_suffix.html`, `index.html`, `_default/section.html`, `_default/taxonomy.html`, `partials/pagination.html`) goes through it. Never call `.Paginate` or `.Paginator` directly in a template.
- **Kinds that paginate**: home (`mainSections` posts, default pager size) and `section` / `term` (`Type == "post"`, `archive-paginate` or 10). The `taxonomy` kind (`/tags/`, rendered by `_default/terms.html`) lists every term on one page and does not paginate, so `list_paginator.html` returns `false` for it and no `/tags/page/N/` is generated. It returns `false` for single pages too, which is what keeps `.Paginate` from aborting the build there.
- **Pagination-aware canonical / og:url**: `head.html` computes a `$canonical` variable that resolves to `.Permalink` on single posts and unpaginated home, but to the pager `.URL | absURL` on paginated pages (2+). Both `<link rel="canonical">` and `<meta property="og:url">` use this same variable.
- **Hand-rolled Open Graph block**: `head.html` emits the full OG block inline (`og:url`, `og:site_name`, `og:title`, `og:description`, `og:locale`, `og:type`, plus `article:section` / `article:published_time` / `article:modified_time` / `article:tag` on single posts) instead of calling `_internal/opengraph.html`. This is required so `og:url` reflects the paginated `$canonical` — `_internal/opengraph.html` always emits `.Permalink` and would conflict on paginated pages. `og:type` is `article` only when `.IsPage` AND `.Type == "post"`; sections/terms/about stay `website`. `og:image` (and `og:image:width/height/alt`) is emitted separately by `custom_head.html`; do not duplicate it in `head.html`.
- **Pagination title suffix**: every list template (`index.html`, `_default/section.html`, `_default/taxonomy.html`, `_default/terms.html`) has a `define "title"` block calling `partials/page_suffix.html`, which appends ` — Page N` (en) / ` — Страница N` (ru) when the pager is past page 1 and an empty string otherwise.
- **Structured data via inline microdata** (no `<script type="application/ld+json">` anywhere): the project uses inline microdata throughout. `baseof.html` sets `<html itemtype>` per kind — `BlogPosting` for `.IsPage && .Type == "post"`, `Blog` for `.IsHome`, `WebPage` everywhere else. `_internal/schema.html` (called from `head.html`) emits the shared `<meta itemprop>` tags (`name`, `description`, `datePublished`, `dateModified`, `wordCount`, `keywords`) attached to that scope. `single.html` adds `mainEntityOfPage`, `inLanguage`, `publisher` (Person), and `image` (ImageObject with `url` / `width` / `height`) inside `<article>` — gated to `eq .Section "post"` so non-post `.IsPage` templates (about/cv) stay clean. The visible `itemprop="author"` Person is already provided by `partials/post/meta.html` (the byline), so it isn't duplicated in `single.html`. `index.html` adds the Blog properties (`name`, `description`, `url`, `inLanguage`, `author` reference) plus the Person block (kept with `id="site-author"` so the Blog `<link itemprop="author" href="#site-author">` resolves) on the unpaginated home only — paginated `/page/N/` skips these. `index.html` also keeps the `ItemList` of `BlogPosting` summaries it has always had.
- **Microdata construction notes**: hidden microdata (author, publisher, image with dimensions) is wrapped in `<span ... style="display:none">` — Google parses microdata regardless of CSS visibility. Cyrillic and special characters are safe in microdata without any escaping (a notable advantage over JSON-LD, which would need `safeJS` to avoid Go's `html/template` JS-escaping of script bodies).
- **robots.txt**: `static/robots.txt` keeps `/post/`, `/tags/`, `/page/` (and their `/ru/` mirrors) disallowed; `sitemap.xml` lists every post directly, so listing pages add no SEO value. The per-page `noindex, follow` from `head.html` is defence-in-depth — Google can't fetch these via the disallow anyway, but the meta tag means non-Google bots still see the directive. `/cv/` stays disallowed (only the rendered HTML/PDF files are allowed).
- Run `./build.sh` after any template change; the build must finish with zero warnings or errors, which `--panicOnWarning` inside the script enforces.

## Hugo template conventions (Hugo 0.160+)

- Use `hugo.Data.<key>` instead of `.Site.Data.<key>` (deprecated).
- Use `.Site.Language.Lang` instead of `.Site.LanguageCode` (deprecated).
- Use `.Site.Params.author.name` only — `.Site.Author.name` is deprecated and not configured.
- For image attribution use `$image.Meta.IPTC.Credit` and `$image.Meta.Exif.Tags.Artist` (Hugo 0.155+); `$image.Exif` is deprecated. The default Hugo whitelist excludes `Artist` from `.Meta.Exif.Tags` for many JPEGs — IPTC `Credit` is the more reliable path on Hugo 0.161 and matches schema.org `creditText` semantics. Both must be guarded with `with` because `Meta`, `Meta.IPTC`, and `Meta.Exif` can each be nil.
- In `hugo.json`, languages use `label` and `locale` per-language; do NOT set top-level `languageCode` or per-language `languageName`.

## Image attribution and licensing

Images use schema.org `ImageObject` metadata via the custom render hook in `themes/jane/layouts/_default/_markup/render-image.html`. By default, all images are credited to the site author with a CC BY 4.0 license.

### EXIF/IPTC metadata (preferred for custom credit)

The render hook reads image metadata from local JPEG/PNG files to determine the credit, preferring IPTC `Credit` (schema.org `creditText` semantics) over EXIF `Artist`. To attribute an image to someone other than the site author, embed both fields with exiftool — IPTC for the schema-aligned credit, EXIF as a fallback for tools that don't read IPTC:

    exiftool -IPTC:Credit="Name Here" -IPTC:CopyrightNotice="© Name Here" -XMP:Credit="Name Here" -EXIF:Artist="Name Here" image.jpg

The render hook reads `$image.Meta.IPTC.Credit` first and `$image.Meta.Exif.Tags.Artist` second; whichever is present and non-empty wins, with IPTC overriding EXIF when both are set.

### URL query parameters (fallback)

For images where embedding metadata isn't practical (e.g. PNGs, external images, or YouTube thumbnails), use query parameters in the image URL:

- **Custom credit**: `![alt](image.jpg?credit=Name+Here#center "title")` — sets `creditText` and `creator` to the specified name (use `+` for spaces)
- **No license**: `![alt](image.png?nolicense#center)` — suppresses `license`, `acquireLicensePage`, and `copyrightNotice` tags
- **Both**: `![alt](image.png?nolicense&credit=Someone#center)`

This works for both standalone images and images wrapped in links (e.g. YouTube thumbnails):

    [![alt](thumbnail.png?nolicense#center)](https://www.youtube.com/watch?v=ID)

### Priority order

Credit is resolved in this order: URL `?credit=` parameter > IPTC `Credit` field > EXIF `Artist` field > site author (default).

## YouTube thumbnails

YouTube's thumbnails with play button generated by [this service](https://addplaybuttontoimage.way4info.net). Example original thumbnails URLs:

    https://img.youtube.com/vi/SFIEA_sAPhc/maxresdefault.jpg
    https://img.youtube.com/vi/SFIEA_sAPhc/hqdefault.jpg

## Images in avif

In order to make copies of images in a modern format to serve alongside with usual ones:

    find ./static/images -type f -name '*.png' -exec sh -c 'avifenc --min 10 --max 30 $1 "${1%.png}.avif"' _ {} \;

Easier alternative than harden-than-I-thought task of getting avifenc working is converting images to avif using https://avif.io/.

## Reduce PNG and JPG image size before publishing

It's easy to reduce the images size without altering their content:

    find . -type f -iname "*.png" -exec optipng -o7 -preserve {} \;
    find . -type f -iname "*.png" -exec advpng -z4 {} \;
    find . -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) -exec jpegoptim --strip-none {} \;
