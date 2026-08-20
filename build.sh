#!/bin/sh
# Builds the site into public/. Used by deploy.sh before rsync and by the build
# service in docker-compose.yml, which is what the terrty.net publish hook runs.
set -e

# On the server public/ is the directory nginx serves, so build into a staging
# directory and swap it in only once Hugo has succeeded. A failed build then
# leaves the live site as it was.
rm -rf public.new public.old
hugo --minify --cleanDestinationDir -d public.new

# Remove empty taxonomy pages (tags/categories with no published posts)
find public.new/tags public.new/ru/tags -type d -mindepth 1 -maxdepth 1 2>/dev/null | while read -r dir; do
  if grep -q 'class="main bg-llight wallpaper"></main>' "$dir/index.html" 2>/dev/null; then
    rm -rf "$dir"
  fi
done

# terrty.net/cv/ is served out of public/cv but is built by the resume repository:
# Hugo only creates the directory, from static/cv. Carry whatever is already there
# into the new tree, or the swap below would drop the CV. deploy.sh keeps the same
# directory out of its rsync for the same reason.
if [ -d public/cv ]; then
  mkdir -p public.new/cv
  cp -R public/cv/. public.new/cv/
fi

# Two renames rather than a delete followed by a rename, so the served directory
# is missing for as short a time as possible.
if [ -d public ]; then
  mv public public.old
fi
mv public.new public
rm -rf public.old
