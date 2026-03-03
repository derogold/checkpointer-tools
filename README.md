# DeroGold Checkpointer

A shell script that automatically generates and updates `CryptoNoteCheckpoints.h` for the [DeroGold](https://derogold.online) blockchain node, using the public block explorer API.

## What it does

Checkpoints are known-good block height/hash pairs embedded directly into the node source code. They allow new nodes to skip re-validating old blocks, speeding up initial sync significantly.

This script:

1. Queries the DeroGold public API for the current chain height
2. Fetches block headers in bulk (1000 at a time)
3. Selects every 5000th block as a checkpoint
4. Writes (or incrementally updates) `CryptoNoteCheckpoints.h` with the correct C++ structure

## Requirements

- `bash`
- `curl`
- `jq`

## Usage

```bash
./checkpoints.sh
```

### First run

If `CryptoNoteCheckpoints.h` does not exist, the script generates it from scratch — fetching all blocks from genesis to the current tip and writing the full C++ header file.

### Subsequent runs

If `CryptoNoteCheckpoints.h` already exists, the script reads the last checkpoint height, resumes from there, and appends only the new checkpoints. It will exit early if the file is already up to date.

```
Already up to date. Last checkpoint: 1500000, network tip: 1502341
```

## Output

The script produces `CryptoNoteCheckpoints.h`, a C++ header ready to drop into the DeroGold node source tree:

```cpp
namespace CryptoNote
{
    struct CheckpointData
    {
        uint32_t index;
        const char *blockId;
    };

    const CheckpointData CHECKPOINTS[] = {
        {0, "..."},
        {5000, "..."},
        // ...
    };
} // namespace CryptoNote
```

## API

Block data is fetched from the DeroGold public API:

- `GET https://api.derogold.online/height` — current chain height
- `GET https://api.derogold.online/block/headers/{height}/bulk` — bulk block headers up to the given height

## License

LGPL-3.0, following the upstream CryptoNote / Bytecoin codebase.
