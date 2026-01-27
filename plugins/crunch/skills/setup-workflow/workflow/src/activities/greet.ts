/**
 * Activity: Greet a person
 *
 * Activities are the building blocks of workflows. They perform
 * the actual work (API calls, database operations, etc.).
 *
 * Activities can fail and will be automatically retried based on
 * the retry policy configured in the workflow.
 */

export interface GreetInput {
  name: string;
}

export interface GreetOutput {
  greeting: string;
  timestamp: string;
}

export async function greet(input: GreetInput): Promise<GreetOutput> {
  // Simulate some work (e.g., API call, database lookup)
  await new Promise(resolve => setTimeout(resolve, 100));

  return {
    greeting: `Hello, ${input.name}!`,
    timestamp: new Date().toISOString(),
  };
}

export async function farewell(input: GreetInput): Promise<GreetOutput> {
  await new Promise(resolve => setTimeout(resolve, 100));

  return {
    greeting: `Goodbye, ${input.name}!`,
    timestamp: new Date().toISOString(),
  };
}
