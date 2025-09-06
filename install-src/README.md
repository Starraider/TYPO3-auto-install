# TYPO3 CMS v13 Base Distribution

Get going quickly with TYPO3 CMS v13.

## Prerequisites

* PHP 8.3
* [Composer](https://getcomposer.org/download/)
* [DDEV](https://ddev.readthedocs.io/en/stable/)
* [Node.js](https://nodejs.org/en/download/)
* [npm](https://www.npmjs.com/get-npm)
* [Docker](https://www.docker.com/get-started)

## Getting Started

This project was installed using Sven Kalbhenn’s TYPO3 installation script.
You can find the script [here](https://github.com/Starraider/TYPO3-auto-install.git).

### Installation

1. Clone the repository:

```bash
git clone https://github.com/Starraider/TYPO3-auto-install.git
```

2. Start the Installation:

```bash
./install-typo3.sh
```

3. Follow the instructions in the script.

4. Clean up:

```bash
rm -rf install-src
rm install-typo3.sh
```
### Post Installation

1. Import the Database:

```bash
ddev typo3 database:import install.sql
```

2. Clear Caches:

```bash
ddev typo3 cache:flush
```

## Development

### Development Server (DDEV + Vite)

This project uses DDEV for the local TYPO3 stack and Vite for the frontend development server.

Prerequisites:
- DDEV + Docker
- Node.js (LTS recommended) and your preferred package manager (npm/yarn/pnpm)

Start the backend (TYPO3) stack via DDEV:

```bash
ddev start
```

Run the Vite development server inside DDEV (proxied automatically):

```bash
ddev vite dev
```

DDEV proxies Vite to a project URL like:

- https://vite.<projectname>.ddev.site

Build assets for production:

```bash
ddev vite build
```

Preview a production build locally (also proxied by DDEV):

```bash
ddev vite preview
```

### TYPO3 Console via DDEV

You can run TYPO3 Console commands inside the DDEV web container.

Shorthand (if available in your environment):

```bash
ddev typo3 cache:flush
```

Canonical form (always works):

```bash
ddev exec vendor/bin/typo3 cache:flush
```

Other useful examples:

```bash
# Update database schema
ddev typo3 database:updateschema

# List available commands
ddev typo3 list

# Update reference index
ddev typo3 referenceindex:update

# Update language files
ddev typo3 language:update

# Warm up all caches
ddev typo3 cache:warmup

# Install extensions
ddev composer req vendor/extension-name
```

### Code Quality Tooling

Rector (ssch/typo3-rector):

```bash
# Dry run (recommended first)
ddev exec vendor/bin/rector process packages/kwe_sitepackage --dry-run
# Apply changes
ddev exec vendor/bin/rector process packages/kwe_sitepackage
```

Composer Normalize (ergebnis/composer-normalize):

```bash
ddev composer normalize
```

### Automated Testing (Mandatory: Playwright)

All automated browser/UI and end-to-end testing in this project must be implemented with Microsoft Playwright. Other browser testing frameworks are not permitted.

Setup inside DDEV:

```bash
ddev exec npm i -D @playwright/test
ddev exec npx playwright install --with-deps
```

Minimal configuration (playwright.config.ts at project root):

```ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: 'tests/e2e',
  timeout: 30_000,
  use: {
    baseURL: 'https://<projectname>.ddev.site',
    trace: 'on-first-retry',
    video: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  reporter: [['list'], ['html', { open: 'never' }]],
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],
});
```

Running tests (inside DDEV):

```bash
# Run all tests headless
ddev exec npx playwright test
# UI mode
ddev exec npx playwright test --ui
# Debug single file
ddev exec npx playwright test tests/e2e/example.spec.ts --debug
# Open last HTML report
ddev exec npx playwright show-report
```

Best practices:
- Use data-testid attributes for stable selectors.
- Avoid arbitrary timeouts; prefer locator-based waits and assertions.
- Reset state between tests; use fixtures and storage state sparingly.
- Capture traces/videos/screenshots on failures and keep them in CI artifacts.
- Consider basic accessibility checks (e.g., axe-core integration) for key pages.

##  Next steps

* [Getting Started with TYPO3](https://docs.typo3.org/permalink/t3start:start)
* [Create a Site Package](https://docs.typo3.org/permalink/t3sitepackage:start)

## License

GPL-2.0 or later
