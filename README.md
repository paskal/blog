# terrty.net blog source [![Publish Status](https://github.com/paskal/blog/workflows/publish/badge.svg)](https://github.com/paskal/blog/actions/workflows/ci-publish.yml)

This repository contains the source for a personal blog (terrty.net) built with [Hugo](https://gohugo.io/) and uses the [Jane theme](https://github.com/xianmin/hugo-theme-jane). It's proxied by the nginx configuration in [paskal/terrty](https://github.com/paskal/terrty).

## Development

### Requirements

- [Hugo](https://gohugo.io/installation/) (Extended version recommended)
- Go 1.23+ (for theme modules)

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
- `config.json`: Site configuration

## Theme Management

The blog uses the [Jane theme](https://github.com/xianmin/hugo-theme-jane) managed via Go modules instead of the traditional themes directory:

- Theme is specified in config.json: `"theme": "github.com/xianmin/hugo-theme-jane"`
- Get the theme: `hugo mod get`
- Update the theme: `hugo mod get -u`
- Theme files are stored in `$GOPATH/pkg/mod/github.com/xianmin/hugo-theme-jane@version`

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

The blog uses [Remark42](https://github.com/umputun/remark42) for comments, configured in config.json with:
- `remark42Url`: "https://remark42.terrty.net"
- `remark42SiteId`: "terrty"

The comment system is configured to use canonical URLs without the `/ru/` prefix for bilingual pages. This ensures that comments are shared between the English and Russian versions of the same article, rather than having separate comment threads.

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
