export interface Workflow {
  name: string;
  logMessage: string;
  status: "in-progress" | "completed" | "cancelled";
}

export interface Project {
  owner: string;
  name: string;
  branch: string;
  sha?: string;
  runId?: string;
}

export interface BuildInfo {
  projectPath: string;
  packageVersion: string;
  vivadoVersion: string;
  vivadoToolchainPath: string;
  vivadoSettings: string;
  crossCompile: string;
}
