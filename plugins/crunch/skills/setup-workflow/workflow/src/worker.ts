/**
 * Temporal Worker
 *
 * Workers poll task queues and execute workflows and activities.
 * You can run multiple workers for scalability and reliability.
 *
 * Usage:
 *   npx ts-node src/worker.ts
 *   # or
 *   npm run start:worker
 */

import { Worker, NativeConnection } from '@temporalio/worker';
import * as activities from './activities/greet';

const TASK_QUEUE = 'hello-world-queue';

async function run() {
  // Connect to Temporal server
  const connection = await NativeConnection.connect({
    address: process.env.TEMPORAL_ADDRESS || 'localhost:7233',
  });

  // Create worker
  const worker = await Worker.create({
    connection,
    namespace: process.env.TEMPORAL_NAMESPACE || 'default',
    taskQueue: TASK_QUEUE,
    workflowsPath: require.resolve('./workflows/hello-world'),
    activities,
  });

  console.log(`Worker started, listening on task queue: ${TASK_QUEUE}`);
  console.log('Press Ctrl+C to stop');

  // Start processing
  await worker.run();
}

run().catch((err) => {
  console.error('Worker failed:', err);
  process.exit(1);
});
