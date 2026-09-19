import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import { renderDirectory } from "../src/filesystem.js";

const temporaryDirectories: string[] = [];

afterEach(async () => {
  await Promise.all(temporaryDirectories.splice(0).map((directory) => rm(directory, { recursive: true, force: true })));
});

describe("template rendering", () => {
  it("replaces placeholders in text while preserving binary assets", async () => {
    const directory = await mkdtemp(path.join(tmpdir(), "typo3-installer-"));
    temporaryDirectories.push(directory);
    const source = path.join(directory, "source");
    const destination = path.join(directory, "destination");
    await (await import("node:fs/promises")).mkdir(source);
    await writeFile(path.join(source, "extension.php"), "EXT:xxxx_sitepackage skom_sitepackage skom");
    await writeFile(path.join(source, "icon.ico"), Buffer.from([0, 1, 2, 3]));

    await renderDirectory(source, destination, {
      xxxx_sitepackage: "demo_sitepackage",
      skom_sitepackage: "demo_sitepackage",
      skom: "acme",
    });

    await expect(readFile(path.join(destination, "extension.php"), "utf8")).resolves.toBe("EXT:demo_sitepackage demo_sitepackage acme");
    await expect(readFile(path.join(destination, "icon.ico"))).resolves.toEqual(Buffer.from([0, 1, 2, 3]));
  });
});
