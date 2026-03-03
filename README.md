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

## Configuration

Before running, set your API base URL at the top of `checkpoints.sh`:

```bash
API_BASE="https://your-api-node-here"
```

Point this at your own DeroGold node or any compatible block explorer API.

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

The script expects a node/explorer API with these endpoints:

- `GET {API_BASE}/height` — returns `{"height": N}`
- `GET {API_BASE}/block/headers/{height}/bulk` — returns an array of block headers up to the given height

## License

LGPL-3.0, following the upstream CryptoNote / Bytecoin codebase.
