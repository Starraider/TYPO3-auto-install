import path from "node:path";
import type { InstallConfig, InstallOptions, InstallStep } from "../types.js";
import { isDirectoryEmpty } from "../filesystem.js";
import { PlanExecutor } from "./executor.js";
import { buildInstallPlan, templateVersion } from "./planner.js";
import { printPlan } from "./plan-output.js";
import { readState, writeState } from "../state.js";

export async function install(config: InstallConfig, options: InstallOptions): Promise<InstallStep[]> {
  const projectDirectory = path.resolve(config.project.directory);
  const existingState = await readState(projectDirectory);
  if (existingState && !options.force) {
    throw new Error(`This directory already has installer state. Run status, update, or use --force to reinstall: ${projectDirectory}`);
  }
  if (!existingState && !(await isDirectoryEmpty(projectDirectory)) && !options.force) {
    throw new Error(`The installation directory is not empty: ${projectDirectory}. Choose an empty directory or pass --force.`);
  }

  const plan = await buildInstallPlan({ ...config, project: { ...config.project, directory: projectDirectory } }, options);
  printPlan(plan);
  if (options.dryRun) {
    console.log("\nDry run complete. No changes were made.");
    return plan;
  }

  const executor = new PlanExecutor(projectDirectory, options);
  try {
    await executor.execute(plan);
    await writeState(projectDirectory, config, await templateVersion());
  } catch (error) {
    throw new Error(`Installation stopped. Existing managed files were backed up under .typo3-auto-install/backups when needed. ${(error as Error).message}`);
  } finally {
    await executor.cleanupEmptyBackupDirectory();
  }
  return plan;
}
