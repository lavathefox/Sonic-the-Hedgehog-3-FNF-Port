#!/usr/bin/env bash
# Prepares everything the HTML5 build needs. Run it from the repository root before:
#   haxelib run lime build html5 -release
#
# 1) Browsers have no mods/ folder, so the mod is copied into html5_stage/ using the layout of a
#    normal (non-mods) Psych Engine assets folder. Project.xml bundles that folder when targeting html5.
# 2) Paths.SOUND_EXT is "mp3" on web builds, so every .ogg is converted to .mp3 (needs ffmpeg).
#    The .ogg files themselves are left untouched and are not bundled (see Project.xml).
set -euo pipefail

MOD="${MOD_DIR:-example_mods/Sonic the Hedgehog 3 (FNF Port)}"
OUT="html5_stage"

if [ ! -d "$MOD" ]; then
  echo "Mod folder not found: $MOD" >&2
  exit 1
fi

rm -rf "$OUT"
mkdir -p "$OUT/shared" "$OUT/songs" "$OUT/fonts"

# stage <mod subfolder> <destination inside html5_stage>
stage() {
  if [ -d "$MOD/$1" ]; then
    mkdir -p "$OUT/$2"
    cp -a "$MOD/$1/." "$OUT/$2/"
  fi
}

stage images shared/images
stage data shared/data
stage characters shared/characters
stage stages shared/stages
stage weeks shared/weeks
stage sounds shared/sounds
stage music shared/music
stage fonts fonts
stage songs songs

# Without the mods folder the game reads the week list from weeks/weekList.txt.
mkdir -p "$OUT/shared/weeks"
list="$OUT/shared/weeks/weekList.txt"
: > "$list"
for f in "$OUT"/shared/weeks/*.json; do
  [ -e "$f" ] || continue
  basename "$f" .json >> "$list"
done

if command -v ffmpeg >/dev/null 2>&1; then
  echo "Converting .ogg to .mp3 ..."
  find assets "$OUT" -type f -name '*.ogg' -print0 | xargs -0 -P "$(nproc 2>/dev/null || echo 2)" -I{} sh -c '
    f="$1"; out="${f%.ogg}.mp3"
    [ -f "$out" ] || ffmpeg -y -loglevel error -i "$f" -codec:a libmp3lame -q:a 4 "$out"
  ' _ {}
else
  echo "WARNING: ffmpeg not found, .ogg files were not converted and the game will have no sound." >&2
fi

echo "HTML5 assets staged in $OUT/"
