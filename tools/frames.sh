#!/usr/bin/env bash
# Turn a folder of recorded clips into evenly-spaced frames Claude can look at.
#
#   bash tools/frames.sh ~/Desktop/footage 40
#
# Makes ~/Desktop/footage/frames/<clipname>/f01.jpg ... and prints a summary.
# Second argument is frames per clip (default 40).

set -u
SRC="${1:?usage: frames.sh <folder-of-videos> [frames-per-clip]}"
N="${2:-40}"
OUT="$SRC/frames"
mkdir -p "$OUT"

shopt -s nullglob nocaseglob
vids=( "$SRC"/*.{mp4,mov,m4v,avi,mkv} )
(( ${#vids[@]} )) || { echo "No videos found in $SRC"; exit 1; }

printf '%-38s %8s %7s %6s %s\n' CLIP DURATION FPS RES FRAMES
for v in "${vids[@]}"; do
  base=$(basename "$v"); name="${base%.*}"
  d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$v" 2>/dev/null | cut -d. -f1)
  fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$v" 2>/dev/null | awk -F/ '{if($2)printf "%.0f",$1/$2; else print $1}')
  res=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$v" 2>/dev/null)
  [ -z "${d:-}" ] && { echo "SKIP (unreadable): $base"; continue; }

  dir="$OUT/$name"; mkdir -p "$dir"
  # one frame every duration/N seconds, evenly spread across the whole clip
  rate=$(python3 -c "print(max($N/max($d,1),0.01))")
  ffmpeg -v error -i "$v" -vf "fps=$rate,scale=1280:-2" -frames:v "$N" -q:v 3 "$dir/f%02d.jpg" </dev/null
  got=$(ls "$dir"/*.jpg 2>/dev/null | wc -l | tr -d ' ')
  printf '%-38s %6ss %7s %6s %s\n' "$name" "$d" "$fps" "$res" "$got"
done

echo
echo "Frames are in: $OUT"
echo "Tell Claude that path. Also paste the Gemini index for each clip."
