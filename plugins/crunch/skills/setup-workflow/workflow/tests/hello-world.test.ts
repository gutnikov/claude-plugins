/**
 * Workflow Tests
 *
 * Uses Temporal's testing framework to run workflows in isolation.
 * Tests execute without a real server, making them fast and reliable.
 */

import { TestWorkflowEnvironment } from '@temporalio/testing';
import { Worker } from '@temporalio/worker';
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { helloWorld } from '../src/workflows/hello-world';
import * as activities from '../src/activities/greet';

describe('Hello World Workflow', () => {
  let testEnv: TestWorkflowEnvironment;

  beforeAll(async () => {
    testEnv = await TestWorkflowEnvironment.createLocal();
  });

  afterAll(async () => {
    await testEnv?.teardown();
  });

  it('should greet a person', async () => {
    const { client, nativeConnection } = testEnv;

    const worker = await Worker.create({
      connection: nativeConnection,
      taskQueue: 'test-queue',
      workflowsPath: require.resolve('../src/workflows/hello-world'),
      activities,
    });

    const result = await worker.runUntil(
      client.workflow.execute(helloWorld, {
        taskQueue: 'test-queue',
        workflowId: 'test-hello-world',
        args: [{ name: 'Alice' }],
      })
    );

    expect(result.workflowCompleted).toBe(true);
    expect(result.greetingResult.greeting).toBe('Hello, Alice!');
    expect(result.farewellResult).toBeUndefined();
  });

  it('should include goodbye when requested', async () => {
    const { client, nativeConnection } = testEnv;

    const worker = await Worker.create({
      connection: nativeConnection,
      taskQueue: 'test-queue',
      workflowsPath: require.resolve('../src/workflows/hello-world'),
      activities,
    });

    const result = await worker.runUntil(
      client.workflow.execute(helloWorld, {
        taskQueue: 'test-queue',
        workflowId: 'test-hello-goodbye',
        args: [{ name: 'Bob', includeGoodbye: true }],
      })
    );

    expect(result.workflowCompleted).toBe(true);
    expect(result.greetingResult.greeting).toBe('Hello, Bob!');
    expect(result.farewellResult?.greeting).toBe('Goodbye, Bob!');
  });
});
