#!/bin/bash
# Run the hello-world workflow
cd "$(dirname "$0")/.." || exit 1
NAME="${1:-World}"
npx ts-node src/client.ts "$NAME"
