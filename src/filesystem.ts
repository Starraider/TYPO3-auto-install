import { access, cp, mkdir, readFile, readdir, stat, writeFile } from "node:fs/promises";
import path from "node:path";

export async function pathExists(filePath: string): Promise<boolean> {
  try {
    await access(filePath);
    return true;
  } catch {
    return false;
  }
}

export async function isDirectoryEmpty(directory: string): Promise<boolean> {
  if (!(await pathExists(directory))) return true;
  return (await readdir(directory)).length === 0;
}

export async function copyDirectory(source: string, destination: string): Promise<void> {
  await mkdir(path.dirname(destination), { recursive: true });
  await cp(source, destination, {
    recursive: true,
    preserveTimestamps: true,
    force: true,
    filter: (filePath) => path.basename(filePath) !== ".DS_Store",
  });
}

export async function renderDirectory(
  source: string,
  destination: string,
  replacements: Record<string, string>,
): Promise<void> {
  await copyDirectory(source, destination);
  await replaceTextFiles(destination, replacements);
}

async function replaceTextFiles(directory: string, replacements: Record<string, string>): Promise<void> {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const filePath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      await replaceTextFiles(filePath, replacements);
      continue;
    }
    if (!entry.isFile()) continue;

    const contents = await readFile(filePath);
    if (contents.includes(0)) continue;
    const pattern = new RegExp(
      Object.keys(replacements)
        .sort((left, right) => right.length - left.length)
        .map((placeholder) => placeholder.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"))
        .join("|"),
      "g",
    );
    const rendered = contents.toString("utf8").replace(pattern, (placeholder) => replacements[placeholder]);
    await writeFile(filePath, rendered, { mode: (await stat(filePath)).mode });
  }
}
