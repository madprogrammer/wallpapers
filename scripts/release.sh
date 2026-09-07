#!/usr/bin/env bash
# Publish rendered wallpapers as GitHub release assets and record their
# download URLs and hashes in wallpapers/list.json.
#
#   scripts/release.sh <tag> <out-dir>
#
# <out-dir> is what scripts/generate.sh produced. The release is created if
# the tag does not exist yet; otherwise the assets are (re)uploaded to it.
# Needs gh (authenticated), jq and nix.
set -euo pipefail

tag=${1:?release tag}
out_dir=${2:?rendered wallpapers dir}
here=$(cd "$(dirname "$0")" && pwd)
list=$here/../wallpapers/list.json

repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
base="https://github.com/$repo/releases/download/$tag"

if gh release view "$tag" >/dev/null 2>&1; then
  gh release upload --clobber "$tag" "$out_dir"/*.png
else
  gh release create "$tag" --title "$tag" \
    --notes "Rendered with scripts/generate.sh; see wallpapers/list.json for hashes." \
    "$out_dir"/*.png
fi

for name in $(jq -r '.[].name' "$list"); do
  for variant in ultrawide:5120x2160 widescreen:3840x2160; do
    key=${variant%%:*}
    file=$name-${variant##*:}.png
    hash=$(nix hash file --sri --type sha256 "$out_dir/$file")
    jq --indent 2 --arg n "$name" --arg k "$key" --arg url "$base/$file" --arg h "$hash" \
      '(.[] | select(.name == $n)).variants[$k] = {url: $url, hash: $h}' "$list" >"$list.tmp"
    mv "$list.tmp" "$list"
    echo "$file $hash"
  done
done
