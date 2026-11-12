set -euo pipefail

MOD="${MOD_DIR:-example_mods/Sonic the Hedgehog 3 (FNF Port)}"
OUT="html5_stage"
export CACHE=".audio_cache"

if [ ! -d "$MOD" ]; then
  echo "Mod folder not found: $MOD" >&2
  exit 1
fi

rm -rf "$OUT"
mkdir -p "$OUT/shared" "$OUT/songs" "$OUT/fonts" "$CACHE"

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

mkdir -p "$OUT/shared/weeks"
list="$OUT/shared/weeks/weekList.txt"
: > "$list"
for f in "$OUT"/shared/weeks/*.json; do
  [ -e "$f" ] || continue
  basename "$f" .json >> "$list"
done

find assets "$OUT" -type f -name '*.ogg' -print0 | xargs -0 -P "$(nproc 2>/dev/null || echo 2)" -I{} sh -c '
  f="$1"; out="${f%.ogg}.mp3"; cached="$CACHE/$out"
  [ -f "$out" ] && exit 0
  if [ ! -f "$cached" ]; then
    if ! command -v ffmpeg >/dev/null 2>&1; then
      echo "WARNING: ffmpeg not found, $f was not converted." >&2
      exit 0
    fi
    mkdir -p "$(dirname "$cached")"
    ffmpeg -y -loglevel error -i "$f" -codec:a libmp3lame -q:a 6 "$cached"
  fi
  cp "$cached" "$out"
' _ {}

missing=0
while IFS= read -r -d '' f; do
  if [ ! -f "${f%.ogg}.mp3" ]; then
    echo "ERROR: no .mp3 was generated for: $f" >&2
    missing=1
  fi
done < <(find assets "$OUT" -type f -name '*.ogg' -print0)
if [ "$missing" -ne 0 ]; then
  echo "ERROR: install ffmpeg (with libmp3lame) and run this script again." >&2
  exit 1
fi

echo "HTML5 assets staged in $OUT/"
