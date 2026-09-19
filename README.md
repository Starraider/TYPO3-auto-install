# TYPO3 Auto-Install

A TypeScript CLI that creates a TYPO3 v14 project with DDEV, a custom
sitepackage, Bootstrap, Vite, and the usual development tooling. It replaces
the former all-in-one Bash installer with a planned, testable Node.js CLI.

The installer still has the same job. It creates a production-ready TYPO3
project, configures DDEV and the database, creates an administrator account,
generates a sitepackage, and installs Vite, Bootstrap, and optional tooling.

## Requirements

- Node.js 20 or later
- DDEV and a running Docker provider
- Internet access for Composer, npm, and DDEV add-ons

The generated project is fixed to PHP 8.3 in DDEV, Composer's platform
configuration, and the Rector template. The installer checks Node.js, DDEV,
and Docker before a real installation.

## Install

Install the CLI dependencies once:

```bash
npm install
```

Copy or edit [installer.config.yaml](installer.config.yaml). Keep the TYPO3
administrator password out of that file. The interactive installer asks for it
without echoing it. The default database password is DDEV's local `db` value;
do not commit the configuration if you change it to a real secret.
Administrator passwords need eight characters, upper- and lowercase letters,
a number, and a special character.

```bash
npm run dev -- install
```

For a repeatable CI or scripted run, supply the password through a secret-aware
mechanism in your shell and skip prompts:

```bash
npm run dev -- install \
  --config ./installer.config.yaml \
  --admin-password "$TYPO3_ADMIN_PASSWORD" \
  --yes
```

After building, the same CLI is available through `node dist/cli.js` or the
`typo3-auto-install` package binary.

## Commands

```bash
npm run dev -- install                 # interactive install
npm run dev -- install --dry-run       # show every file and command first
npm run dev -- doctor                  # check Node.js, DDEV, and Docker
npm run dev -- status --directory ./my-project
npm run dev -- update --directory ./my-project --dry-run
```

`uninstall` deliberately removes only paths recorded in
`.typo3-auto-install/state.json`. It does not delete TYPO3 core, the database,
or DDEV containers. It requires both confirmation and `--force` because a
managed file can have local edits.

## Configuration

`installer.config.yaml` has these sections:

- `project`: DDEV name, title, and installation directory
- `admin`: backend account details, except the password
- `ddev`: PHP version and TYPO3 server type
- `database`: the DDEV database connection
- `sitepackage`: Composer vendor and TYPO3 extension key
- `features`: Vite sidecar, TYPO3 Rector, and Playwright choices

CLI flags override YAML values. Run `npm run dev -- install --help` for all
available flags.

## What the installer creates

The project gets a DDEV TYPO3 v14.3 installation (currently resolving the
TYPO3 core to v14.3.7) plus:

- a generated copy of `install-src/xxxx_sitepackage` under `packages/`
- Bootstrap 5, Bootstrap Icons, Sass, and Vite with TYPO3 asset integration
- TYPO3 14.3-compatible releases of `b13/container`, `helhum/typo3-console`,
  `praetorius/vite-asset-collector`, `helhum/dotenv-connector`, and Bootstrap
  Package
- Vite scripts, an environment file, project README, editor settings, and
  optional Rector and Playwright tooling

The installer builds its complete plan before it makes changes. `--dry-run`
prints the plan and redacts administrator and database passwords. When
`--force` permits an overwrite, it copies the previous installer-managed file
to `.typo3-auto-install/backups/` first.

## Development

```bash
npm run build
npm run test:run
npm run check
```

The core is split by responsibility:

```text
src/config/       YAML loading and Zod validation
src/prompts.ts    interactive input only
src/installer/    plan construction and execution
src/filesystem.ts native Node filesystem operations
src/process.ts    safe, argument-based process execution with Execa
src/preflight.ts  environment checks
```

Installer behavior is covered by the Vitest suite in `test/`.
