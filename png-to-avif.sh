#!/usr/bin/env bash
# png-to-avif.sh — encode PNG screenshots to AVIF with the blog default recipe.
#
# Output sits next to each input, same basename:
#   foo.png → foo.avif
#
# Usage:
#   ./png-to-avif.sh img.png img2.png
#   ./png-to-avif.sh path/to/dir          # all *.png / *.PNG in dir (non-recursive)
#   ./png-to-avif.sh                      # all *.png in cwd
#   ./png-to-avif.sh -f img.png           # overwrite existing .avif
#   QUALITY=60 ./png-to-avif.sh img.png   # override quality (cq-level derived)
#   SPEED=1 YUV=444 ./png-to-avif.sh img.png
#
# Defaults (see README.md): q55, speed 3, yuv 420 — matches Squoosh q70 e7 size
# on stdlib blog DevTools screenshots without the GUI grind.

set -euo pipefail

QUALITY="${QUALITY:-55}"
SPEED="${SPEED:-3}"
YUV="${YUV:-420}"
FORCE=0

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    -f|--force) FORCE=1; shift ;;
    --) shift; break ;;
    -*)
      echo "unknown option: $1" >&2
      usage 2
      ;;
    *) break ;;
  esac
done

if ! command -v avifenc >/dev/null 2>&1; then
  echo "avifenc not found (brew install libavif)" >&2
  exit 1
fi

# cq-level ≈ (100 - q) * 63 / 100  (AOM CQ paired with end-usage=q)
CQ_LEVEL=$(( (100 - QUALITY) * 63 / 100 ))

collect_inputs() {
  if [[ $# -eq 0 ]]; then
    set -- .
  fi
  local arg
  for arg in "$@"; do
    if [[ -d "$arg" ]]; then
      # non-recursive; null-safe
      find "$arg" -maxdepth 1 -type f \( -name '*.png' -o -name '*.PNG' \) -print
    elif [[ -f "$arg" ]]; then
      printf '%s\n' "$arg"
    else
      echo "skip (not found): $arg" >&2
    fi
  done
}

encode_one() {
  local src="$1"
  local base ext out
  base="${src%.*}"
  ext="${src##*.}"
  case "${ext}" in
    png|PNG) ;;
    *)
      echo "skip (not png): $src" >&2
      return 0
      ;;
  esac
  out="${base}.avif"

  if [[ -e "$out" && "$FORCE" -ne 1 ]]; then
    echo "skip (exists, use -f): $out"
    return 0
  fi

  echo "encode  $src  →  $out  (q=${QUALITY} s=${SPEED} yuv=${YUV} cq=${CQ_LEVEL})"
  avifenc \
    -q "${QUALITY}" \
    -s "${SPEED}" \
    --yuv "${YUV}" \
    -a end-usage=q \
    -a "cq-level=${CQ_LEVEL}" \
    -a tune=ssim \
    -a sharpness=2 \
    "$src" \
    "$out" >/dev/null

  # size line for quick sanity
  local isz osz
  isz=$(stat -f%z "$src" 2>/dev/null || stat -c%s "$src")
  osz=$(stat -f%z "$out" 2>/dev/null || stat -c%s "$out")
  awk -v i="$isz" -v o="$osz" 'BEGIN {
    printf "        %d → %d bytes  (%.1fx smaller)\n", i, o, i/o
  }'
}

count=0
while IFS= read -r src; do
  [[ -z "$src" ]] && continue
  encode_one "$src"
  count=$((count + 1))
done < <(collect_inputs "$@" | sort -u)

if [[ "$count" -eq 0 ]]; then
  echo "no PNG inputs" >&2
  exit 1
fi

echo "done ($count file(s))."
