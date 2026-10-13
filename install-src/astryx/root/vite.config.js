import fs from "node:fs";
import { defineConfig } from "vite";
import typo3 from "vite-plugin-typo3";
import liveReload from "vite-plugin-live-reload";
import stylexPlugin from "@stylexjs/unplugin";
import stylexManifestPlugin from "./vendor/skom/stylex-connector/Resources/Private/Build/stylex-manifest.mjs";

// PHP and release packaging need a complete manifest. Vite's lazy development
// transforms cannot provide one before the first frontend request renders.
const buildManifest = options => ({ ...stylexManifestPlugin(options), apply: "build" });

export default defineConfig({
    plugins: [
        typo3(),
        stylexPlugin.vite({
            useCSSLayers: true,
            unstable_moduleResolution: {
                type: "commonJS",
                rootDir: process.cwd(),
            },
        }),
        buildManifest({
            outputPath: "packages/astryx_sitepackage/Resources/Public/StylexManifest/stylex-manifest.json",
            root: process.cwd(),
            namespace: "astryx_sitepackage",
            legacyAliases: true,
            include: id => id.includes("/astryx_sitepackage/") && id.endsWith(".stylex.js"),
        }),
        ...(fs.existsSync("packages/typo3_astryx") ? [
            buildManifest({
                outputPath: "packages/typo3_astryx/Resources/Public/StylexManifest/stylex-manifest.json",
                root: process.cwd() + "/packages/typo3_astryx",
                namespace: "typo3_astryx",
                compilerVersion: "0.19.1",
                include: id => id.includes("/typo3_astryx/") && id.endsWith(".stylex.js"),
            }),
        ] : []),
        liveReload([
            "packages/**/*.php",
            "packages/**/*.html",
            "packages/**/*.typoscript",
            "packages/**/*.yaml",
        ]),
    ],
});
