#!/bin/sh

set -e
SCRIPT_DIR=$(dirname "$(realpath "$0")")
VERSION=$($SCRIPT_DIR/version.sh)

git tag "v$VERSION" || echo "Tag already exists."
git push origin --force --tags
