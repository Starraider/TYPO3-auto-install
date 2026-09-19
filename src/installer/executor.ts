import { cp, mkdir, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import type { InstallOptions, InstallStep } from "../types.js";
import { copyDirectory, pathExists, renderDirectory } from "../filesystem.js";
import { runCommand } from "../process.js";

function timestamp(): string {
  return new Date().toISOString().replaceAll(/[:.]/g, "-");
}

export class PlanExecutor {
  private readonly backedUp = new Set<string>();
  private readonly backupDirectory: string;

  public constructor(
    private readonly projectDirectory: string,
    private readonly options: InstallOptions,
  ) {
    this.backupDirectory = path.join(projectDirectory, ".typo3-auto-install", "backups", timestamp());
  }

  public async execute(steps: InstallStep[]): Promise<void> {
    for (const step of steps) await this.executeStep(step);
  }

  private async executeStep(step: InstallStep): Promise<void> {
    if (this.options.verbose) console.log(`→ ${step.type}`);
    switch (step.type) {
      case "mkdir":
        await mkdir(step.path, { recursive: true });
        return;
      case "copy":
        await this.backup(step.to);
        await copyDirectory(step.from, step.to);
        return;
      case "render":
        await this.backup(step.to);
        await renderDirectory(step.from, step.to, step.replacements);
        return;
      case "write":
        await this.backup(step.path);
        await mkdir(path.dirname(step.path), { recursive: true });
        await writeFile(step.path, step.contents, "utf8");
        return;
      case "command":
        await runCommand(step.executable, step.args, {
          cwd: step.cwd,
          verbose: this.options.verbose,
          secretArguments: step.secretArguments,
        });
    }
  }

  private async backup(destination: string): Promise<void> {
    if (this.backedUp.has(destination) || !(await pathExists(destination))) return;
    const relativeDestination = path.relative(this.projectDirectory, destination);
    if (relativeDestination.startsWith("..") || path.isAbsolute(relativeDestination)) {
      throw new Error(`Refusing to back up a file outside the project: ${destination}`);
    }
    const backupPath = path.join(this.backupDirectory, relativeDestination);
    await mkdir(path.dirname(backupPath), { recursive: true });
    await cp(destination, backupPath, { recursive: true, preserveTimestamps: true });
    this.backedUp.add(destination);
  }

  public async cleanupEmptyBackupDirectory(): Promise<void> {
    if (!(await pathExists(this.backupDirectory))) return;
    const backupsRoot = path.join(this.projectDirectory, ".typo3-auto-install", "backups");
    const contents = await (await import("node:fs/promises")).readdir(this.backupDirectory);
    if (contents.length === 0) await rm(backupsRoot, { recursive: true, force: true });
  }
}
