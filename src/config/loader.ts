import { readFile } from "node:fs/promises";
import path from "node:path";
import { parse } from "yaml";
import type { InstallConfig } from "../types.js";
import { InstallConfigSchema } from "./schema.js";

export async function loadConfig(configPath: string): Promise<InstallConfig> {
  const absolutePath = path.resolve(configPath);
  const raw = await readFile(absolutePath, "utf8");
  const parsed = parse(raw);
  return InstallConfigSchema.parse(parsed);
}

export function validateConfig(config: unknown): InstallConfig {
  return InstallConfigSchema.parse(config);
}
