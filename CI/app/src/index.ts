import process from "process";
import * as exec from "@actions/exec";
import { Octokit } from "@octokit/rest";

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const delay = (ms: number) => new Promise((res) => setTimeout(res, ms));

const [REPO_OWNER, REPO_NAME] = process.env.GITHUB_REPOSITORY!.split("/");
const GITHUB_RUN_ID = process.env.GITHUB_RUN_ID!;
const HDL_PROJECT_NAME = process.env.HDL_PROJECT_NAME!;
const GH_OS_TOKEN = process.env.GH_OS_TOKEN!;

// Method to search for a workflow by name an return the id
const searchForWorkflowRun = async (workflowId: string, searchName: string) => {
  let runId: number | null = null;

  console.log(`Searching for ${searchName}`);

  while (!runId) {
    const runs = await octokit.actions.listWorkflowRuns({
      owner: REPO_OWNER,
      repo: REPO_NAME,
      workflow_id: workflowId,
      event: "workflow_dispatch",
      headers: {
        authorization: `token ${GH_OS_TOKEN}`,
      },
    });

    const run = runs.data.workflow_runs.find((r) => r.name === searchName);
    if (run) {
      runId = run.id;
      break;
    }

    console.log("Run not found yet, retrying...");
    await delay(2000); // Wait before retrying
  }

  if (!runId) {
    throw new Error(
      "Failed to find triggered workflow run ID after multiple attempts.",
    );
  }

  console.log(`Triggered workflow run ID: ${runId}`);

  return runId;
};

// Method to monitor testing status - TO BE IMPLEMENTED

// Method to monitor build workflow and log its status
const monitorResponseWorkflow = async (searchName: string) => {
  // Search for triggered workflow run by name
  const runId = await searchForWorkflowRun("get-response.yml", searchName);

  // Monitor the workflow run status until it completes
  let status;
  while (status !== "completed") {
    const { data: runData } = await octokit.actions.getWorkflowRun({
      owner: REPO_OWNER,
      repo: REPO_NAME,
      run_id: runId,
      headers: {
        authorization: `token ${GH_OS_TOKEN}`,
      },
    });

    status = runData.status!;
    console.log(`Workflow run status for ${searchName}: ${status}`);

    await delay(5000); // Wait before checking again
  }
  console.log(`Workflow run completed with conclusion: ${status}`);
};

// Method to get data of log build workflow
const monitorLogWorkflow = async (searchName: string) => {
  // Search for triggered workflow run by name
  const runId = await searchForWorkflowRun("get-log.yml", searchName);

  // Fetch the logs for the workflow run
  const logsResponse = await octokit.actions.downloadWorkflowRunLogs({
    owner: REPO_OWNER,
    repo: REPO_NAME,
    run_id: runId,
    headers: {
      authorization: `token ${GH_OS_TOKEN}`,
    },
  });

  console.log(`Logs URL: ${logsResponse.url}`);

  // Download log zip file
  await exec.exec("mkdir", [searchName]);
  await exec.exec("wget", [
    "-v",
    "-O",
    `${searchName}/logs.zip`,
    logsResponse.url,
  ]);

  // Unzip and read log file content
  await exec.exec("unzip", [`${searchName}/logs.zip`, "-d", searchName]);
  await exec.exec("cat", [`${searchName}/get-log/2_Get log.txt`]);
};

// Main starting point
(async () => {
  try {
    // Check workflow run for build
    await monitorResponseWorkflow(
      `HDL-Build-for-${HDL_PROJECT_NAME}_${GITHUB_RUN_ID}`,
    );
    await monitorLogWorkflow(
      `Output-for-HDL-Build-for-${HDL_PROJECT_NAME}_${GITHUB_RUN_ID}`,
    );

    // Check workflow run for publish
    await monitorResponseWorkflow(
      `HDL-Publish-for-${HDL_PROJECT_NAME}_${GITHUB_RUN_ID}`,
    );
    await monitorLogWorkflow(
      `Output-for-HDL-Publish-for-${HDL_PROJECT_NAME}_${GITHUB_RUN_ID}`,
    );
  } catch (error) {
    console.error("Error monitoring workflows status:", error);
    process.exit(1);
  }
})();
