#!/bin/bash
# Test workflow execution end-to-end
set -e

cd "$(dirname "$0")/.." || exit 1

echo "=== Temporal Workflow Test ==="

# Check if server is running
if ! curl -s http://localhost:7233/health > /dev/null 2>&1; then
    echo "ERROR: Temporal server not running on localhost:7233"
    echo "Start it with: temporal server start-dev"
    exit 1
fi

echo "1. Server is healthy"

# Start worker in background
echo "2. Starting worker..."
npx ts-node src/worker.ts &
WORKER_PID=$!

# Wait for worker to initialize
sleep 3

# Run workflow
echo "3. Executing workflow..."
RESULT=$(npx ts-node src/client.ts "TestUser" 2>&1)

# Check result
if echo "$RESULT" | grep -q "workflowCompleted.*true"; then
    echo "4. Workflow completed successfully!"
    echo "$RESULT"
    EXITCODE=0
else
    echo "4. ERROR: Workflow failed"
    echo "$RESULT"
    EXITCODE=1
fi

# Cleanup
echo "5. Stopping worker..."
kill $WORKER_PID 2>/dev/null || true

exit $EXITCODE
