import { defineConfig } from "vite";
import typo3 from "vite-plugin-typo3";
import liveReload from "vite-plugin-live-reload";
import stylexPlugin from "@stylexjs/unplugin";
import stylexManifestPlugin from "./vite-plugin-stylex-manifest.js";

export default defineConfig({
    plugins: [
        typo3(),
        stylexPlugin.vite({
            useCSSLayers: false,
            unstable_moduleResolution: {
                type: "commonJS",
                rootDir: process.cwd(),
            },
        }),
        stylexManifestPlugin({
            outputPath: "packages/yyy_sitepackage/Resources/Public/StylexManifest/stylex-manifest.json",
        }),
        liveReload([
            "packages/**/*.php",
            "packages/**/*.html",
            "packages/**/*.typoscript",
            "packages/**/*.yaml",
        ]),
    ],
});
