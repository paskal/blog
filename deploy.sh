#!/bin/sh

# Parse arguments
SUBDIR=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      SUBDIR="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Build site
hugo --minify --cleanDestinationDir

# Remove empty taxonomy pages (tags/categories with no published posts)
find public/tags public/ru/tags -type d -mindepth 1 -maxdepth 1 2>/dev/null | while read -r dir; do
  if grep -q 'class="main bg-llight wallpaper"></main>' "$dir/index.html" 2>/dev/null; then
    rm -rf "$dir"
  fi
done

# Set target path
TARGET="terrty:~/blog/public/"
if [ -n "$SUBDIR" ]; then
  TARGET="terrty:~/blog/public/$SUBDIR/"
  # Create directory if it doesn't exist
  ssh terrty "mkdir -p ~/blog/public/$SUBDIR"
fi

# Deploy
rsync -azi --exclude cv/ --delete public/ "$TARGET" | grep -v "f..t...." | grep -v ".d..t...."
