#!/usr/bin/env bash
# Render the wallpaper variants from full-resolution originals.
#
#   scripts/generate.sh <originals-dir> <out-dir>
#
# <originals-dir> holds one file per wallpaper named wallhaven-<id>.<ext>,
# where <id> is the wallhaven id taken from "source" in wallpapers/list.json.
#
# For every entry two lossless PNGs are written to <out-dir>:
#   <name>-5120x2160.png  ultrawide 21:9 (5K2K): Lanczos scale-to-fill + centre crop
#   <name>-3840x2160.png  widescreen 16:9 (4K UHD): crop of the ultrawide frame,
#                         starting at column "widescreen_x" (default 640 = centred)
#
# Needs ImageMagick 7 (magick) and jq.
set -euo pipefail

src_dir=${1:?originals dir}
out_dir=${2:?output dir}
here=$(cd "$(dirname "$0")" && pwd)
list=$here/../wallpapers/list.json

mkdir -p "$out_dir"

png_opts=(
  -strip -depth 8 -type TrueColor
  -define png:compression-level=9
  -define png:compression-filter=5
  -define png:compression-strategy=1
  -define png:exclude-chunk=all
)

render() {
  local name=$1 id=$2 wide_x=$3
  local src
  src=$(ls "$src_dir"/wallhaven-"$id".* 2>/dev/null | head -n1)
  [[ -n $src ]] || { echo "missing original for $name (wallhaven-$id.*)" >&2; return 1; }

  local uw=$out_dir/$name-5120x2160.png
  local ws=$out_dir/$name-3840x2160.png

  magick "$src" -alpha off -filter Lanczos -resize 5120x2160^ \
    -gravity center -extent 5120x2160 +repage "${png_opts[@]}" "$uw"
  magick "$uw" -gravity NorthWest -crop "3840x2160+${wide_x}+0" +repage "${png_opts[@]}" "$ws"

  echo "$name: $(magick identify -format '%wx%h' "$uw") / $(magick identify -format '%wx%h' "$ws")"
}
export -f render
export src_dir out_dir

jq -r '.[] | [.name, (.source | sub(".*/"; "")), (.widescreen_x // 640)] | @tsv' "$list" \
  | xargs -P "$(nproc 2>/dev/null || sysctl -n hw.ncpu)" -L1 bash -c 'render "$0" "$1" "$2"'
