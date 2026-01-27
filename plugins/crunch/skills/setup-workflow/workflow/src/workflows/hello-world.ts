/**
 * Workflow: Hello World
 *
 * Workflows orchestrate activities and define the business logic.
 * They must be deterministic - no random values, Date.now(), or
 * direct API calls. All side effects go through activities.
 *
 * This workflow demonstrates:
 * - Calling activities with retry policies
 * - Sequential activity execution
 * - Returning structured results
 */

import { proxyActivities, sleep } from '@temporalio/workflow';
import type * as activities from '../activities/greet';

// Create activity proxies with retry configuration
const { greet, farewell } = proxyActivities<typeof activities>({
  startToCloseTimeout: '1 minute',
  retry: {
    initialInterval: '1s',
    backoffCoefficient: 2,
    maximumAttempts: 3,
  },
});

export interface HelloWorldInput {
  name: string;
  includeGoodbye?: boolean;
}

export interface HelloWorldOutput {
  greetingResult: activities.GreetOutput;
  farewellResult?: activities.GreetOutput;
  workflowCompleted: boolean;
}

/**
 * Main workflow function
 *
 * @param input - Workflow input parameters
 * @returns Workflow result with greeting and optional farewell
 */
export async function helloWorld(input: HelloWorldInput): Promise<HelloWorldOutput> {
  // Step 1: Greet the person
  const greetingResult = await greet({ name: input.name });

  // Step 2: Optionally say goodbye
  let farewellResult: activities.GreetOutput | undefined;
  if (input.includeGoodbye) {
    // Wait a bit before saying goodbye
    await sleep('1 second');
    farewellResult = await farewell({ name: input.name });
  }

  return {
    greetingResult,
    farewellResult,
    workflowCompleted: true,
  };
}
