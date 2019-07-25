#!/bin/bash
for f in *.flac; do
  avconv -i "$f" -qscale:a 0 "${f[@]/%flac/mp3}"
done
