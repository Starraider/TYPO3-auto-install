import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { execa } from "execa";
import { createHash } from "node:crypto";
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
  const css = ".xShell{color:red}.xContent{padding:1rem}";
  await writeFile(path.join(output, "main.css"), css);
  await writeFile(path.join(styles, "stylex-manifest.json"), JSON.stringify({
    version: "2.0",
    capabilities: ["static-conflicts", "null-clearing"],
    artifacts: [{ path: path.relative(styles, path.join(output, "main.css")), sha256: createHash("sha256").update(css).digest("hex") }],
    styles: {
      "Site.shell": { kind: "compiled", className: "xShell", properties: { color: "xShell", padding: null } },
      "Site.content": { kind: "compiled", className: "xContent", properties: { padding: "xContent" } },
    },
  }));
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

  it("rejects stale CSS even when all Fluid selectors still exist", async () => {
    const directory = await buildFixture();
    await writeFile(path.join(directory, "public/_assets/vite/main.css"), ".xShell{color:blue}.xContent{padding:1rem}");
    const result = await execa(process.execPath, ["verify-stylex-build.mjs"], { cwd: directory, reject: false });
    expect(result.exitCode).not.toBe(0);
    expect(result.stderr).toContain("Mismatched paired CSS artifact");
  });

  it("rejects a missing paired CSS artifact", async () => {
    const directory = await buildFixture();
    await changeManifest(directory, manifest => { manifest.artifacts[0].path = "missing.css"; });
    const result = await execa(process.execPath, ["verify-stylex-build.mjs"], { cwd: directory, reject: false });
    expect(result.exitCode).not.toBe(0);
    expect(result.stderr).toContain("Missing paired CSS artifact: missing.css");
  });

  it("rejects manifests produced by the removed writer", async () => {
    const directory = await buildFixture();
    await changeManifest(directory, manifest => { delete manifest.version; });
    const result = await execa(process.execPath, ["verify-stylex-build.mjs"], { cwd: directory, reject: false });
    expect(result.exitCode).not.toBe(0);
    expect(result.stderr).toContain("maintained version 2 manifest adapter");
  });

  it("requires a checksum for every CSS file used by the entrypoint", async () => {
    const directory = await buildFixture();
    const file = path.join(directory, "public/_assets/vite/.vite/manifest.json");
    const manifest = JSON.parse(await readFile(file, "utf8"));
    manifest.main.css.push("extra.css");
    await writeFile(file, JSON.stringify(manifest));
    await writeFile(path.join(directory, "public/_assets/vite/extra.css"), ".extra{color:red}");
    const result = await execa(process.execPath, ["verify-stylex-build.mjs"], { cwd: directory, reject: false });
    expect(result.exitCode).not.toBe(0);
    expect(result.stderr).toContain("Entry CSS has no StyleX checksum: extra.css");
  });
});

async function changeManifest(directory: string, change: (manifest: any) => void): Promise<void> {
  const file = path.join(directory, "packages/custom_sitepackage/Resources/Public/StylexManifest/stylex-manifest.json");
  const manifest = JSON.parse(await readFile(file, "utf8"));
  change(manifest);
  await writeFile(file, JSON.stringify(manifest));
}
