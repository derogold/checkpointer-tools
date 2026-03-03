#!/usr/bin/env bash

OUTPUT="CryptoNoteCheckpoints.h"

# Set your DeroGold API base URL here (e.g. your own node or a public explorer)
API_BASE="https://your-api-node-here"

LATEST=$(curl -s "$API_BASE/height" | jq '.height')

if [ -f "$OUTPUT" ]; then
  LAST_HEIGHT=$(grep -oE '\{[0-9]+,' "$OUTPUT" | tail -1 | grep -oE '[0-9]+')
  START_FROM=$((LAST_HEIGHT + 5000))

  if [ "$START_FROM" -gt "$LATEST" ]; then
    echo "Already up to date. Last checkpoint: $LAST_HEIGHT, network tip: $LATEST"
    exit 0
  fi

  echo "Existing file found. Last checkpoint: $LAST_HEIGHT. Fetching $START_FROM to $LATEST..."

  # Strip the closing lines before appending
  head -n -2 "$OUTPUT" > "${OUTPUT}.tmp" && mv "${OUTPUT}.tmp" "$OUTPUT"

  CHUNK_START=$(( (START_FROM / 1000) * 1000 ))
  for start in $(seq $CHUNK_START 1000 $LATEST); do
    curl -s "$API_BASE/block/headers/$((start + 999))/bulk" | \
      jq -r --argjson from "$START_FROM" \
        '[.[] | select(.height % 5000 == 0 and .height >= $from)] | sort_by(.height)[] | "        {\(.height), \"\(.hash)\"},"' >> "$OUTPUT"
  done

else
  echo "No existing file. Generating from scratch..."

  cat > "$OUTPUT" << 'HEADER'
// Copyright (c) 2018-2026, The DeroGold Developers
// Copyright (c) 2012-2017, The CryptoNote developers, The Bytecoin developers
//

#pragma once

#include <cstdint>

namespace CryptoNote
{
    struct CheckpointData
    {
        uint32_t index;
        const char *blockId;
    };

    const CheckpointData CHECKPOINTS[] = {
HEADER

  for start in $(seq 0 1000 $LATEST); do
    curl -s "$API_BASE/block/headers/$((start + 999))/bulk" | \
      jq -r '[.[] | select(.height % 5000 == 0)] | sort_by(.height)[] | "        {\(.height), \"\(.hash)\"},"' >> "$OUTPUT"
  done

fi

cat >> "$OUTPUT" << 'EOF'
    };
} // namespace CryptoNote
EOF

echo "Done: $OUTPUT"
