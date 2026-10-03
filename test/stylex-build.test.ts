import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { execa } from "execa";
import { afterEach, describe, expect, it } from "vitest";

const directories: string[] = [];
afterEach(async () => {
  await Promise.all(directories.splice(0).map(directory => rm(directory, { recursive: true, force: true })));
});

async function buildFixture(): Promise<string> {
  const directory = await mkdtemp(path.join(tmpdir(), "stylex-build-check-"));
  directories.push(directory);
  const output = path.join(directory, "public/_assets/vite");
  const styles = path.join(directory, "packages/custom_sitepackage/Resources/Public/StylexManifest");
  await mkdir(path.join(output, ".vite"), { recursive: true });
  await mkdir(styles, { recursive: true });
  await writeFile(path.join(output, ".vite/manifest.json"), JSON.stringify({
    main: {
      isEntry: true,
      src: "packages/custom_sitepackage/Resources/Private/JavaScript/Main.entry.js",
      file: "main.js", css: ["main.css"],
    },
  }));
  await writeFile(path.join(output, "main.js"), "export {};");
  await writeFile(path.join(output, "main.css"), ".xShell{color:red}.xContent{padding:1rem}");
  await writeFile(path.join(styles, "stylex-manifest.json"), JSON.stringify({ styles: {
    "Site.shell": { className: "xShell" },
    "Site.content": { className: "xContent" },
  } }));
  const verifier = await readFile(path.resolve("install-src/stylex/verify-stylex-build.mjs"), "utf8");
  await writeFile(path.join(directory, "verify-stylex-build.mjs"), verifier.replaceAll("yyy_sitepackage", "custom_sitepackage"));
  return directory;
}

describe("generated StyleX build verification", () => {
  it("accepts built CSS that includes the Fluid classes", async () => {
    const directory = await buildFixture();
    const result = await execa(process.execPath, ["verify-stylex-build.mjs"], { cwd: directory });
    expect(result.stdout).toContain("StyleX build verified");
  });

  it("rejects a successful Vite build that omits StyleX CSS", async () => {
    const directory = await buildFixture();
    await writeFile(path.join(directory, "public/_assets/vite/main.css"), ".ce-bodytext{color:red}");
    const result = await execa(process.execPath, ["verify-stylex-build.mjs"], { cwd: directory, reject: false });
    expect(result.exitCode).not.toBe(0);
    expect(result.stderr).toContain("Built CSS has no selector for Site.shell");
  });

  it("rejects a manifest that references a missing asset", async () => {
    const directory = await buildFixture();
    await rm(path.join(directory, "public/_assets/vite/main.js"));
    const result = await execa(process.execPath, ["verify-stylex-build.mjs"], { cwd: directory, reject: false });
    expect(result.exitCode).not.toBe(0);
    expect(result.stderr).toContain("Missing built asset: main.js");
  });
});
