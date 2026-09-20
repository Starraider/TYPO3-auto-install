import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { TYPO3_EXTENSION_SITE_SETS, type InstallConfig, type InstallOptions, type InstallStep } from "../types.js";

const sourceRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../install-src");

export function sitepackageKebabName(name: string): string {
  return name.replaceAll("_", "-");
}

export function sitepackagePascalName(name: string): string {
  return name
    .split("_")
    .map((part) => `${part.slice(0, 1).toUpperCase()}${part.slice(1)}`)
    .join("");
}

export function makeReplacements(config: InstallConfig): Record<string, string> {
  return {
    xxxx_sitepackage: config.sitepackage.name,
    "xxxx-sitepackage": sitepackageKebabName(config.sitepackage.name),
    XxxxSitepackage: sitepackagePascalName(config.sitepackage.name),
    "Sven Kalbhenn": config.admin.name,
    "sven@skom.de": config.admin.email,
    "https://www.skom.de": config.admin.url ?? "",
    skom_sitepackage: config.sitepackage.name,
    SKom: `${config.sitepackage.vendor.slice(0, 1).toUpperCase()}${config.sitepackage.vendor.slice(1)}`,
    skom: config.sitepackage.vendor,
    Skom: `${config.sitepackage.vendor.slice(0, 1).toUpperCase()}${config.sitepackage.vendor.slice(1)}`,
    TYPO3_EXTENSION_SITE_SET_DEPENDENCIES: config.extensions
      .map((extension) => TYPO3_EXTENSION_SITE_SETS[extension])
      .filter((siteSet): siteSet is string => Boolean(siteSet))
      .map((siteSet) => `  - ${siteSet}`)
      .join("\n"),
  };
}

function projectReadme(config: InstallConfig): string {
  return `# ${config.project.title}

This TYPO3 v14 project was created with \`typo3-auto-install\`.

## Development

\`ddev start\` starts TYPO3 and its database. Use \`ddev vite dev\` for the Vite
development server and \`ddev vite build\` for a production asset build.

Useful TYPO3 commands:

\`ddev typo3 cache:flush\`

\`ddev typo3 database:updateschema\`
`;
}

function environmentFile(config: InstallConfig): string {
  const baseUrl = `https://${config.project.name}.ddev.site/`;
  return `TYPO3_CONTEXT='Development'
INSTANCE='local'

SITE_BASE='${baseUrl}'

TYPO3_UTF8_FILESYSTEM='1'
TYPO3_SYSTEM_LOCALE='de_DE.UTF-8'
TYPO3_TRUSTED_HOST_PATTERN='.*'
TYPO3_DISPLAY_ERRORS='1'
TYPO3_BE_DEBUG='1'
TYPO3_FE_DEBUG='1'

TYPO3__DB__Connections__Default__dbname='${config.database.name}'
TYPO3__DB__Connections__Default__host='${config.database.host}'
TYPO3__DB__Connections__Default__password='${config.database.password}'
TYPO3__DB__Connections__Default__port='${config.database.port}'
TYPO3__DB__Connections__Default__user='${config.database.user}'
`;
}

export async function buildInstallPlan(config: InstallConfig, _options: InstallOptions): Promise<InstallStep[]> {
  const projectDirectory = path.resolve(config.project.directory);
  const templates = {
    sitepackage: path.join(sourceRoot, "xxxx_sitepackage"),
    viteConfig: path.join(sourceRoot, "vite.config.js"),
    editorConfig: path.join(sourceRoot, ".editorconfig"),
    gitignore: path.join(sourceRoot, ".gitignore"),
    rector: path.join(sourceRoot, "rector.php"),
  };
  const adminPassword = config.admin.password;
  if (!adminPassword) throw new Error("An administrator password is required to build an installation plan.");

  const composerPackages = [
    "helhum/typo3-console:^9.0",
    "praetorius/vite-asset-collector:^1.18",
    "helhum/dotenv-connector:^3.2",
    "b13/container:^4.1",
    ...config.extensions,
    `${config.sitepackage.vendor}/${sitepackageKebabName(config.sitepackage.name)}:@dev`,
  ];

  const steps: InstallStep[] = [
    { type: "mkdir", path: projectDirectory },
    {
      type: "command",
      executable: "ddev",
      args: ["config", `--project-name=${config.project.name}`, "--project-type=typo3", "--docroot=public", `--php-version=${config.ddev.phpVersion}`],
      cwd: projectDirectory,
    },
    { type: "command", executable: "ddev", args: ["start"], cwd: projectDirectory },
    {
      type: "command",
      executable: "ddev",
      args: ["composer", "create-project", "typo3/cms-base-distribution:^14.3", "--no-interaction"],
      cwd: projectDirectory,
    },
    {
      type: "command",
      executable: "ddev",
      args: [
        "typo3", "setup", "--force", `--driver=${config.database.driver}`,
        `--host=${config.database.host}`, `--port=${config.database.port}`, `--dbname=${config.database.name}`,
        `--username=${config.database.user}`, `--password=${config.database.password}`,
        `--admin-username=${config.admin.username}`, `--admin-user-password=${adminPassword}`,
        `--server-type=${config.ddev.serverType}`, "--no-interaction",
      ],
      cwd: projectDirectory,
      secretArguments: [8, 10],
    },
    { type: "command", executable: "ddev", args: ["composer", "config", "allow-plugins.helhum/dotenv-connector", "true"], cwd: projectDirectory },
    { type: "command", executable: "ddev", args: ["composer", "config", "repositories.typo3", "composer", "https://composer.typo3.org"], cwd: projectDirectory },
    { type: "command", executable: "ddev", args: ["composer", "config", "repositories.sitepackage", "path", "packages/*"], cwd: projectDirectory },
    { type: "command", executable: "ddev", args: ["composer", "config", "platform.php", `${config.ddev.phpVersion}.0`], cwd: projectDirectory },
    { type: "mkdir", path: path.join(projectDirectory, "packages") },
    {
      type: "render",
      from: templates.sitepackage,
      to: path.join(projectDirectory, "packages", config.sitepackage.name),
      replacements: makeReplacements(config),
    },
    { type: "command", executable: "ddev", args: ["composer", "require", ...composerPackages, "--no-interaction"], cwd: projectDirectory },
    { type: "command", executable: "ddev", args: ["composer", "update", "--with-all-dependencies", "--no-interaction"], cwd: projectDirectory },
    { type: "command", executable: "ddev", args: ["typo3", "database:updateschema"], cwd: projectDirectory },
    { type: "command", executable: "ddev", args: ["typo3", "cache:flush"], cwd: projectDirectory },
    { type: "command", executable: "ddev", args: ["npm", "init", "--yes"], cwd: projectDirectory },
    { type: "command", executable: "ddev", args: ["npm", "install", "--save-dev", "vite@^7.0.0", "vite-plugin-typo3@^3.0.0", "vite-plugin-live-reload", "sass", "bootstrap", "bootstrap-icons", "@popperjs/core"], cwd: projectDirectory },
    { type: "command", executable: "ddev", args: ["npm", "pkg", "set", "scripts.dev=vite", "scripts.build=vite build", "scripts.watch=vite build --watch"], cwd: projectDirectory },
    { type: "copy", from: templates.viteConfig, to: path.join(projectDirectory, "vite.config.js") },
    { type: "copy", from: templates.editorConfig, to: path.join(projectDirectory, ".editorconfig") },
    { type: "copy", from: templates.gitignore, to: path.join(projectDirectory, ".gitignore") },
    { type: "write", path: path.join(projectDirectory, ".env"), contents: environmentFile(config) },
    { type: "write", path: path.join(projectDirectory, "README.md"), contents: projectReadme(config) },
  ];

  if (config.features.viteSidecar) {
    steps.push({ type: "command", executable: "ddev", args: ["get", "s2b/ddev-vite-sidecar"], cwd: projectDirectory });
  }
  if (config.features.rector) {
    steps.push({ type: "command", executable: "ddev", args: ["composer", "require", "ssch/typo3-rector:^3.16", "--dev", "--no-interaction"], cwd: projectDirectory });
    steps.push({ type: "copy", from: templates.rector, to: path.join(projectDirectory, "rector.php") });
  }
  if (config.features.playwright) {
    steps.push({ type: "command", executable: "ddev", args: ["npm", "install", "--save-dev", "@playwright/test"], cwd: projectDirectory });
    steps.push({ type: "command", executable: "ddev", args: ["exec", "npx", "playwright", "install", "--with-deps"], cwd: projectDirectory });
  }
  steps.push({ type: "command", executable: "ddev", args: ["typo3", "cache:warmup"], cwd: projectDirectory });
  return steps;
}

export async function templateVersion(): Promise<string> {
  const packageJson = JSON.parse(await readFile(path.resolve(sourceRoot, "../package.json"), "utf8")) as { version: string };
  return packageJson.version;
}
