import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { execa } from "execa";
import { afterEach, describe, expect, it } from "vitest";

const directories: string[] = [];
afterEach(async () => {
  await Promise.all(directories.splice(0).map(directory => rm(directory, { recursive: true, force: true })));
});

async function updateFixture(failValidation = false, dryRun = false) {
  const directory = await mkdtemp(path.join(tmpdir(), "stylex-update-check-"));
  directories.push(directory);
  const bin = path.join(directory, "bin");
  await mkdir(bin);
  await mkdir(path.join(directory, ".typo3-auto-install"));
  await writeFile(path.join(directory, ".typo3-auto-install/state.json"), JSON.stringify({
    schemaVersion: 1,
    developerStack: "fluid-styled-content-vite-stylex",
  }));
  await writeFile(path.join(directory, "package.json"), "{}");
  await writeFile(path.join(bin, "ddev"), `#!/usr/bin/env node
const fs = require("node:fs");
const args = process.argv.slice(2);
fs.appendFileSync(process.env.DDEV_TEST_LOG, JSON.stringify(args) + "\\n");
if (args.includes("stylex:validate") && process.env.DDEV_TEST_FAIL_VALIDATION === "1") process.exit(1);
`, { mode: 0o755 });
  const log = path.join(directory, "commands.jsonl");
  const result = await execa(process.execPath, [
    "--import", "tsx", "src/cli.ts", "update", "--directory", directory,
    ...(dryRun ? ["--dry-run"] : []),
  ], {
    reject: false,
    env: {
      PATH: `${bin}${path.delimiter}${process.env.PATH}`,
      DDEV_TEST_LOG: log,
      DDEV_TEST_FAIL_VALIDATION: failValidation ? "1" : "0",
    },
  });
  const commands: string[][] = dryRun ? [] : (await readFile(log, "utf8")).trim().split("\n").map(line => JSON.parse(line));
  return { result, commands, log };
}

describe("StyleX dependency updates", () => {
  it("validates the rebuilt manifests before flushing and warming caches", async () => {
    const { result, commands } = await updateFixture();
    expect(result.exitCode).toBe(0);
    const build = commands.findIndex(args => args.join(" ") === "npm run build");
    expect(build).toBeGreaterThan(-1);
    expect(commands[build + 1]).toEqual([
      "typo3", "stylex:validate", "--required-key", "Site.shell", "--required-key", "Site.content",
    ]);
    expect(commands[build + 2]).toEqual(["typo3", "cache:flush"]);
    expect(commands.at(-1)).toEqual(["typo3", "cache:warmup"]);
  });

  it("stops an update when strict manifest validation fails", async () => {
    const { result, commands } = await updateFixture(true);
    expect(result.exitCode).not.toBe(0);
    expect(commands.at(-1)?.[1]).toBe("stylex:validate");
    expect(commands.some(args => args.includes("cache:flush") || args.includes("cache:warmup"))).toBe(false);
  });

  it("includes validation in a dry run without executing commands", async () => {
    const { result, commands, log } = await updateFixture(false, true);
    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain('"stylex:validate" "--required-key" "Site.shell" "--required-key" "Site.content"');
    expect(commands).toEqual([]);
    await expect(readFile(log, "utf8")).rejects.toMatchObject({ code: "ENOENT" });
  });
});
