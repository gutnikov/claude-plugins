#!/bin/bash
# Start the Temporal worker
cd "$(dirname "$0")/.." || exit 1
npx ts-node src/worker.ts
