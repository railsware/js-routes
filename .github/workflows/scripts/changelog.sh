#!/bin/sh

set -e 

CHANGELOG="CHANGELOG.md"
OUTPUT="./release_changelog.md"
SCRIPT_DIR=$(dirname "$(realpath "$0")")
VERSION=$($SCRIPT_DIR/version.sh)

if [ -z "$VERSION" ]; then
  echo "VERSION is not specified"
  exit 1
fi

if [ ! -f "$CHANGELOG" ]; then
  echo "CHANGELOG.md file not found!"
  exit 1
fi

if ! grep -q "^## \[$VERSION\]" $CHANGELOG; then
  echo "No changelog found for version $VERSION in $CHANGELOG"
  exit 1
fi

echo "## Changes" > $OUTPUT
echo "" >> $OUTPUT
ruby  -e "puts File.read('$CHANGELOG').split('## [$VERSION]')[1]&.split('## ')&.first&.strip" >> $OUTPUT
echo "Release notes:"
echo ----------------------------------------
cat $OUTPUT
echo ----------------------------------------

