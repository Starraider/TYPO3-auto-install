import { readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import type { InstallConfig, InstallState } from "./types.js";
import { pathExists } from "./filesystem.js";

export function statePath(projectDirectory: string): string {
  return path.join(projectDirectory, ".typo3-auto-install", "state.json");
}

export async function readState(projectDirectory: string): Promise<InstallState | undefined> {
  const filePath = statePath(projectDirectory);
  if (!(await pathExists(filePath))) return undefined;
  return JSON.parse(await readFile(filePath, "utf8")) as InstallState;
}

export async function writeState(projectDirectory: string, config: InstallConfig, installerVersion: string): Promise<void> {
  const state: InstallState = {
    schemaVersion: 1,
    installerVersion,
    installedAt: new Date().toISOString(),
    project: { name: config.project.name, title: config.project.title },
    sitepackage: config.sitepackage,
    generatedPaths: [
      `packages/${config.sitepackage.name}`,
      "vite.config.js",
      ".env",
      "README.md",
      ".editorconfig",
      ".gitignore",
      ...(config.features.rector ? ["rector.php"] : []),
    ],
  };
  const filePath = statePath(projectDirectory);
  await (await import("node:fs/promises")).mkdir(path.dirname(filePath), { recursive: true });
  await writeFile(filePath, `${JSON.stringify(state, null, 2)}\n`, "utf8");
}

export async function removeState(projectDirectory: string): Promise<void> {
  await rm(path.join(projectDirectory, ".typo3-auto-install"), { recursive: true, force: true });
}
