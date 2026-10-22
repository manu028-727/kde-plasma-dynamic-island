#!/usr/bin/env bash
#
# Build the installable Plasma widget archive. Release CI and local release
# checks use the same script so the artifact contents stay consistent.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

version="${1:-}"
if [ -z "$version" ]; then
    version="$(python3 -c 'import json; print(json.load(open("metadata.json"))["KPlugin"]["Version"])')"
fi

output="dynamic-island-${version}.plasmoid"
rm -f "$output"

zip -q -r "$output" \
    contents \
    metadata.json \
    LICENSE \
    README.md \
    assets/readme-banner.svg

echo "$output"
