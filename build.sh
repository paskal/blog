#!/bin/sh
# Builds the site into public/. Used by deploy.sh before rsync and by the build
# service in docker-compose.yml, which is what the terrty.net publish hook runs.
set -e

# On the server public/ is the live directory nginx serves, so build into a
# staging directory first and only touch public/ once Hugo has succeeded; a
# failed build then leaves the served tree as it was.
rm -rf public.new
hugo --minify --cleanDestinationDir -d public.new

# Remove empty taxonomy pages (tags/categories with no published posts)
find public.new/tags public.new/ru/tags -type d -mindepth 1 -maxdepth 1 2>/dev/null | while read -r dir; do
	if grep -q 'class="main bg-llight wallpaper"></main>' "$dir/index.html" 2>/dev/null; then
		rm -rf "$dir"
	fi
done

# Replace the contents of public/ rather than the directory itself: nginx bind
# mounts /home/opc/blog/public, so swapping the directory would leave the server
# pointing at the old inode and serving 403s until it is restarted.
#
# public/cv is kept. terrty.net/cv/ is served from there but is built by the
# resume repository; Hugo only creates the directory, from static/cv. deploy.sh
# keeps the same directory out of its rsync for the same reason.
mkdir -p public
find public -mindepth 1 -maxdepth 1 ! -name cv -exec rm -rf {} \;
find public.new -mindepth 1 -maxdepth 1 ! -name cv -exec mv {} public/ \;
if [ -d public.new/cv ]; then
	mkdir -p public/cv
	cp -R public.new/cv/. public/cv/
fi
rm -rf public.new
