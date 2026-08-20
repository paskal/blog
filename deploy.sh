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
		# A single path component only. An empty value would silently deploy the
		# whole site, and anything with a slash or a leading dot can move the
		# rsync destination out of public/, where --delete would then apply.
		case "$SUBDIR" in
		"" | .* | *[!A-Za-z0-9._-]*)
			echo "Error: --path must be one component of letters, digits, dot, underscore or hyphen" >&2
			exit 1
			;;
		esac
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

# Deploy. rsync writes into the live directory with --delete, so on failure keep
# the itemised output: it is the only record of what was already replaced or
# removed there. Run it as an if condition so errexit does not exit before that.
CHANGES=$(mktemp "${TMPDIR:-/tmp}/deploy.XXXXXX")
if rsync -azi --exclude cv/ --delete public/ "$TARGET" >"$CHANGES"; then
	# Tolerate grep's "no matches" (exit 1) but let real errors (exit 2) abort
	grep -Ev '[fd]\.\.t\.\.\.\.' "$CHANGES" || [ "$?" -eq 1 ]
	rm -f "$CHANGES"
else
	STATUS="$?"
	echo "rsync failed with status $STATUS, transfer may be partial" >&2
	echo "itemised output kept at $CHANGES" >&2
	cat "$CHANGES" >&2
	exit "$STATUS"
fi
