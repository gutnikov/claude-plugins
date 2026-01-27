/**
 * Temporal Client
 *
 * The client is used to start workflows, query their status,
 * and retrieve results. This file demonstrates starting
 * the hello-world workflow.
 *
 * Usage:
 *   npx ts-node src/client.ts [name]
 *   # or
 *   npm run start:workflow
 */

import { Client, Connection } from '@temporalio/client';
import { helloWorld } from './workflows/hello-world';

const TASK_QUEUE = 'hello-world-queue';

async function run() {
  // Get name from command line or use default
  const name = process.argv[2] || 'World';

  // Connect to Temporal server
  const connection = await Connection.connect({
    address: process.env.TEMPORAL_ADDRESS || 'localhost:7233',
  });

  const client = new Client({
    connection,
    namespace: process.env.TEMPORAL_NAMESPACE || 'default',
  });

  // Generate unique workflow ID
  const workflowId = `hello-world-${Date.now()}`;

  console.log(`Starting workflow: ${workflowId}`);

  // Start workflow execution
  const handle = await client.workflow.start(helloWorld, {
    taskQueue: TASK_QUEUE,
    workflowId,
    args: [{ name, includeGoodbye: true }],
  });

  console.log(`Workflow started: ${handle.workflowId}`);
  console.log(`Run ID: ${handle.firstExecutionRunId}`);

  // Wait for result
  const result = await handle.result();

  console.log('\nWorkflow completed!');
  console.log('Result:', JSON.stringify(result, null, 2));

  await connection.close();
}

run().catch((err) => {
  console.error('Client failed:', err);
  process.exit(1);
});
