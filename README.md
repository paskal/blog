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
# Build site with minification
hugo --minify --cleanDestinationDir

# Build and deploy to production
./deploy.sh

# Deploy to a subdirectory
./deploy.sh --path <subdirectory>
```

## Site Structure

- `content/`: Blog posts and pages (separate directories for en/ru languages)
- `layouts/`: Custom layout templates that override theme defaults
- `static/`: Static files (CSS, images, etc.)
- `hugo.json`: Site configuration

## Theme Management

The blog uses a vendored copy of the [Jane theme](https://github.com/xianmin/hugo-theme-jane), checked into `themes/jane/` and selected via `"theme": "jane"` in `hugo.json`. It is NOT pulled in as a Hugo module. Editing files under `themes/jane/` is the project's established pattern; customisations live alongside the theme and are never overwritten by upstream updates.

## Deployment

The blog is deployed in two ways:
1. Manually using `deploy.sh` script which uses rsync to upload to the server
2. Automatically via GitHub Actions when pushing to master branch

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
- **Pagination-aware canonical / og:url**: `head.html` computes a `$canonical` variable that resolves to `.Permalink` on single posts and unpaginated home, but to `.Paginator.URL | absURL` on paginated home/section/taxonomy/term (pages 2+). Both `<link rel="canonical">` and `<meta property="og:url">` use this same variable. The `with .Paginator` block must be guarded by a kind check (`IsHome` / `section` / `taxonomy` / `term`) — calling `.Paginator` on a single post raises a build error.
- **Hand-rolled Open Graph block**: `head.html` emits the full OG block inline (`og:url`, `og:site_name`, `og:title`, `og:description`, `og:locale`, `og:type`, plus `article:section` / `article:published_time` / `article:modified_time` / `article:tag` on single posts) instead of calling `_internal/opengraph.html`. This is required so `og:url` reflects the paginated `$canonical` — `_internal/opengraph.html` always emits `.Permalink` and would conflict on paginated pages. `og:type` is `article` only when `.IsPage` AND `.Type == "post"`; sections/terms/about stay `website`. `og:image` (and `og:image:width/height/alt`) is emitted separately by `custom_head.html`; do not duplicate it in `head.html`.
- **Pagination title suffix**: every list template that renders paginated URLs (`index.html`, `_default/section.html`, `_default/taxonomy.html`, `_default/terms.html`) has a `define "title"` block that appends ` — Page N` (en) / ` — Страница N` (ru) when `Paginator.PageNumber > 1`.
- **Structured data via inline microdata** (no `<script type="application/ld+json">` anywhere): the project uses inline microdata throughout. `baseof.html` sets `<html itemtype>` per kind — `BlogPosting` for `.IsPage && .Type == "post"`, `Blog` for `.IsHome`, `WebPage` everywhere else. `_internal/schema.html` (called from `head.html`) emits the shared `<meta itemprop>` tags (`name`, `description`, `datePublished`, `dateModified`, `wordCount`, `keywords`) attached to that scope. `single.html` adds `mainEntityOfPage`, `inLanguage`, `publisher` (Person), and `image` (ImageObject with `url` / `width` / `height`) inside `<article>` — gated to `eq .Section "post"` so non-post `.IsPage` templates (about/cv) stay clean. The visible `itemprop="author"` Person is already provided by `partials/post/meta.html` (the byline), so it isn't duplicated in `single.html`. `index.html` adds the Blog properties (`name`, `description`, `url`, `inLanguage`, `author` reference) plus the Person block (kept with `id="site-author"` so the Blog `<link itemprop="author" href="#site-author">` resolves) on the unpaginated home only — paginated `/page/N/` skips these. `index.html` also keeps the `ItemList` of `BlogPosting` summaries it has always had.
- **Microdata construction notes**: hidden microdata (author, publisher, image with dimensions) is wrapped in `<span ... style="display:none">` — Google parses microdata regardless of CSS visibility. Cyrillic and special characters are safe in microdata without any escaping (a notable advantage over JSON-LD, which would need `safeJS` to avoid Go's `html/template` JS-escaping of script bodies).
- **robots.txt**: `static/robots.txt` no longer disallows `/page/` — the per-page `noindex` from `head.html` covers those, and removing the disallow lets Google crawl pagination links to discover deeper-archive posts. `/post/`, `/tags/` stay disallowed (sitemap.xml lists posts directly, so `/post/` and `/tags/` listing pages add no SEO value); `/cv/` stays disallowed (only the rendered HTML/PDF files are allowed).
- Run `hugo --minify --cleanDestinationDir` after any template change; the build must finish with zero warnings or errors.

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
