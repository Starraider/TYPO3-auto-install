import { defineConfig } from "vite";
import typo3 from "vite-plugin-typo3";
import liveReload from 'vite-plugin-live-reload'

export default defineConfig({
    plugins: [typo3(), liveReload('packages/**/*.php', 'packages/**/*.html')],
    // Optional: Silence Sass deprecation warnings. See note below.
    css: {
        preprocessorOptions: {
            scss: {
                silenceDeprecations: [
                    'import',
                    'mixed-decls',
                    'color-functions',
                    'global-builtin',
                ],
            },
        },
    },
});
