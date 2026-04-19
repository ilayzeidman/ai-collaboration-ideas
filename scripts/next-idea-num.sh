#!/usr/bin/env bash
# Prints the next idea number (one more than the highest existing ideas/idea-N/ directory).
# Prints 1 if no ideas exist yet. Run from the repo root.
set -euo pipefail

ideas_dir="$(dirname "$0")/../ideas"

max=0
for d in "$ideas_dir"/idea-*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  n=${name#idea-}
  if [[ "$n" =~ ^[0-9]+$ ]] && (( n > max )); then
    max=$n
  fi
done

echo $(( max + 1 ))
