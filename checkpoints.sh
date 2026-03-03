#!/usr/bin/env bash

OUTPUT="CryptoNoteCheckpoints.h"

LATEST=$(curl -s https://api.derogold.online/height | jq '.height')

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
    curl -s "https://api.derogold.online/block/headers/$((start + 999))/bulk" | \
      jq -r --argjson from "$START_FROM" \
        '[.[] | select(.height % 5000 == 0 and .height >= $from)] | sort_by(.height)[] | "        {\(.height), \"\(.hash)\"},"' >> "$OUTPUT"
  done

else
  echo "No existing file. Generating from scratch..."

  cat > "$OUTPUT" << 'HEADER'
// Copyright (c) 2018-2021, The DeroGold Developers
// Copyright (c) 2012-2017, The CryptoNote developers, The Bytecoin developers
//
// This file is part of Bytecoin.
//
// Bytecoin is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Bytecoin is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with Bytecoin.  If not, see <http://www.gnu.org/licenses/>.

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
    curl -s "https://api.derogold.online/block/headers/$((start + 999))/bulk" | \
      jq -r '[.[] | select(.height % 5000 == 0)] | sort_by(.height)[] | "        {\(.height), \"\(.hash)\"},"' >> "$OUTPUT"
  done

fi

cat >> "$OUTPUT" << 'EOF'
    };
} // namespace CryptoNote
EOF

echo "Done: $OUTPUT"
