import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import fs from "node:fs";
import path from "node:path";

const output = "public/_assets/vite";
const manifest = JSON.parse(fs.readFileSync(`${output}/.vite/manifest.json`, "utf8"));
const stylexManifestPath = "packages/yyy_sitepackage/Resources/Public/StylexManifest/stylex-manifest.json";
const stylex = JSON.parse(fs.readFileSync(stylexManifestPath, "utf8"));
assert.equal(stylex.version, "2.0", "Rebuild with the connector's maintained version 2 manifest adapter");
const entry = Object.values(manifest).find(item =>
    item.isEntry && item.src?.endsWith("/Resources/Private/JavaScript/Main.entry.js"),
);
assert(entry, "Vite did not build the sitepackage entrypoint");
const cssFiles = new Set();
const visited = new Set();
function collect(item) {
    if (visited.has(item)) return;
    visited.add(item);
    assert(fs.existsSync(path.join(output, item.file)), `Missing built asset: ${item.file}`);
    for (const css of item.css ?? []) cssFiles.add(css);
    for (const asset of item.assets ?? []) {
        assert(fs.existsSync(path.join(output, asset)), `Missing built asset: ${asset}`);
    }
    for (const imported of item.imports ?? []) {
        assert(manifest[imported], `Missing Vite manifest import: ${imported}`);
        collect(manifest[imported]);
    }
}
collect(entry);
assert(cssFiles.size > 0, "Vite emitted no CSS for the entrypoint");
const css = [...cssFiles].map(file => fs.readFileSync(path.join(output, file), "utf8")).join("\n");
for (const key of ["Site.shell", "Site.content"]) {
    const classes = stylex.styles?.[key]?.className;
    assert(classes?.trim(), `Missing StyleX classes for ${key}`);
    for (const className of classes.split(/\s+/)) {
        assert(css.includes(`.${className}`), `Built CSS has no selector for ${key}: ${className}`);
    }
}
assert(Array.isArray(stylex.artifacts) && stylex.artifacts.length > 0, "StyleX manifest declares no paired CSS artifacts");
const pairedCss = new Set();
for (const artifact of stylex.artifacts) {
    assert(typeof artifact.path === "string" && typeof artifact.sha256 === "string", "Invalid paired CSS artifact");
    const file = path.resolve(path.dirname(stylexManifestPath), artifact.path);
    assert(fs.existsSync(file), `Missing paired CSS artifact: ${artifact.path}`);
    const hash = createHash("sha256").update(fs.readFileSync(file)).digest("hex");
    assert.equal(hash, artifact.sha256, `Mismatched paired CSS artifact: ${artifact.path}`);
    pairedCss.add(file);
}
for (const file of cssFiles) {
    assert(pairedCss.has(path.resolve(output, file)), `Entry CSS has no StyleX checksum: ${file}`);
}
console.log("StyleX build verified: Fluid classes, CSS selectors, Vite assets, and paired CSS checksums match.");
