#!/bin/sh
# Builds the site into public/. Used by deploy.sh before rsync and by the build
# service in docker-compose.yml, which is what the terrty.net publish hook runs.
set -e

hugo --minify --cleanDestinationDir

# Remove empty taxonomy pages (tags/categories with no published posts)
find public/tags public/ru/tags -type d -mindepth 1 -maxdepth 1 2>/dev/null | while read -r dir; do
  if grep -q 'class="main bg-llight wallpaper"></main>' "$dir/index.html" 2>/dev/null; then
    rm -rf "$dir"
  fi
done
