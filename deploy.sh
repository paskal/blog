#!/bin/sh
set -e

# Parse arguments
SUBDIR=""
while [ "$#" -gt 0 ]; do
	case "$1" in
	--path)
		if [ "$#" -lt 2 ]; then
			echo "Error: --path requires a value" >&2
			exit 1
		fi
		SUBDIR="$2"
		shift 2
		;;
	*)
		echo "Unknown option: $1" >&2
		exit 1
		;;
	esac
done

# Build site
./build.sh

# Set target path
TARGET="terrty:~/blog/public/"
if [ -n "$SUBDIR" ]; then
	TARGET="terrty:~/blog/public/$SUBDIR/"
	# Create directory if it doesn't exist
	ssh terrty "mkdir -p ~/blog/public/$SUBDIR"
fi

# Deploy; run rsync as a simple command so errexit aborts on a failed transfer,
# writing the itemised output to a temp file before filtering (a pipeline would
# swallow rsync's exit status)
CHANGES=$(mktemp "${TMPDIR:-/tmp}/deploy.XXXXXX")
trap 'rm -f "$CHANGES"' EXIT
rsync -azi --exclude cv/ --delete public/ "$TARGET" >"$CHANGES"
# Tolerate grep's "no matches" (exit 1) but let real errors (exit 2) abort
grep -Ev '[fd]\.\.t\.\.\.\.' "$CHANGES" || [ "$?" -eq 1 ]
