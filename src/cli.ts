#!/usr/bin/env node
import { rm } from "node:fs/promises";
import path from "node:path";
import { Command } from "commander";
import * as p from "@clack/prompts";
import { loadConfig, validateConfig } from "./config/loader.js";
import { assertPreflightChecks, runPreflightChecks } from "./preflight.js";
import { install } from "./installer/install.js";
import { confirmInstall, askForInstallConfig } from "./prompts.js";
import { readState, removeState } from "./state.js";
import type { InstallConfig, InstallOptions } from "./types.js";
import { formatCommand, runCommand } from "./process.js";

interface CommandFlags {
  config: string;
  directory?: string;
  projectName?: string;
  projectTitle?: string;
  adminUsername?: string;
  adminName?: string;
  adminEmail?: string;
  adminUrl?: string;
  adminPassword?: string;
  vendor?: string;
  sitepackage?: string;
  phpVersion?: string;
  serverType?: "apache" | "nginx";
  dryRun?: boolean;
  verbose?: boolean;
  force?: boolean;
  yes?: boolean;
  viteSidecar?: boolean;
  rector?: boolean;
  playwright?: boolean;
}

function mergeFlags(config: InstallConfig, flags: CommandFlags): InstallConfig {
  return validateConfig({
    ...config,
    project: {
      ...config.project,
      ...(flags.directory ? { directory: flags.directory } : {}),
      ...(flags.projectName ? { name: flags.projectName } : {}),
      ...(flags.projectTitle ? { title: flags.projectTitle } : {}),
    },
    admin: {
      ...config.admin,
      ...(flags.adminUsername ? { username: flags.adminUsername } : {}),
      ...(flags.adminName ? { name: flags.adminName } : {}),
      ...(flags.adminEmail ? { email: flags.adminEmail } : {}),
      ...(flags.adminUrl ? { url: flags.adminUrl } : {}),
      ...(flags.adminPassword ? { password: flags.adminPassword } : {}),
    },
    sitepackage: {
      ...config.sitepackage,
      ...(flags.vendor ? { vendor: flags.vendor } : {}),
      ...(flags.sitepackage ? { name: flags.sitepackage } : {}),
    },
    ddev: {
      ...config.ddev,
      ...(flags.phpVersion ? { phpVersion: flags.phpVersion } : {}),
      ...(flags.serverType ? { serverType: flags.serverType } : {}),
    },
    features: {
      ...config.features,
      ...(flags.viteSidecar === undefined ? {} : { viteSidecar: flags.viteSidecar }),
      ...(flags.rector === undefined ? {} : { rector: flags.rector }),
      ...(flags.playwright === undefined ? {} : { playwright: flags.playwright }),
    },
  });
}

function installOptions(flags: CommandFlags): InstallOptions {
  return { dryRun: Boolean(flags.dryRun), verbose: Boolean(flags.verbose), force: Boolean(flags.force) };
}

async function preflight(required: boolean): Promise<void> {
  const checks = await runPreflightChecks();
  for (const check of checks) console.log(`${check.ok ? "✓" : "✗"} ${check.label}: ${check.detail}`);
  if (required) assertPreflightChecks(checks);
}

async function loadInstallConfig(flags: CommandFlags): Promise<InstallConfig> {
  const config = mergeFlags(await loadConfig(flags.config), flags);
  if (flags.yes) {
    if (!config.admin.password) throw new Error("Non-interactive installation needs --admin-password. It is never written to installer state.");
    return config;
  }
  return askForInstallConfig(config);
}

const program = new Command();
program
  .name("typo3-auto-install")
  .description("Plan and create TYPO3 v14 projects with DDEV, Vite, Bootstrap, and a sitepackage")
  .version("1.0.0")
  .showSuggestionAfterError();

function addInstallOptions(command: Command): Command {
  return command
    .option("-c, --config <path>", "YAML configuration file", "installer.config.yaml")
    .option("-d, --directory <path>", "target project directory")
    .option("--project-name <name>", "DDEV project name")
    .option("--project-title <title>", "human-readable project title")
    .option("--admin-username <name>", "TYPO3 administrator username")
    .option("--admin-name <name>", "TYPO3 administrator name")
    .option("--admin-email <email>", "TYPO3 administrator email")
    .option("--admin-url <url>", "TYPO3 administrator URL")
    .option("--admin-password <password>", "TYPO3 administrator password. Prefer a secret-aware shell mechanism.")
    .option("--vendor <name>", "Composer vendor for the sitepackage")
    .option("--sitepackage <name>", "sitepackage key, such as example_sitepackage")
    .option("--php-version <version>", "DDEV PHP version (must be 8.3)")
    .option("--server-type <type>", "TYPO3 server type: apache or nginx")
    .option("--dry-run", "show the plan without changing files or running commands")
    .option("--verbose", "show each command as it runs")
    .option("--force", "allow an existing project directory and back up managed files")
    .option("-y, --yes", "skip interactive questions and confirmation")
    .option("--no-vite-sidecar", "do not install the DDEV Vite sidecar")
    .option("--no-rector", "do not install TYPO3 Rector")
    .option("--playwright", "install Playwright and its browsers");
}

addInstallOptions(program.command("install").description("create a TYPO3 project"))
  .action(async (flags: CommandFlags) => {
    const config = await loadInstallConfig(flags);
    await preflight(!flags.dryRun);
    const options = installOptions(flags);
    if (!flags.yes && !options.dryRun && !(await confirmInstall())) {
      p.cancel("Installation cancelled. No changes were made.");
      return;
    }
    await install(config, options);
    if (!options.dryRun) p.outro(`TYPO3 is ready at https://${config.project.name}.ddev.site`);
  });

program.command("doctor")
  .description("check Node.js, DDEV, and Docker")
  .action(async () => {
    p.intro("TYPO3 installer doctor");
    await preflight(false);
    p.outro("Run install after all required checks pass.");
  });

program.command("status")
  .description("show installer state for a project")
  .option("-d, --directory <path>", "project directory", ".")
  .action(async ({ directory }: { directory: string }) => {
    const projectDirectory = path.resolve(directory);
    const state = await readState(projectDirectory);
    if (!state) {
      console.log(`No installer state found in ${projectDirectory}.`);
      process.exitCode = 1;
      return;
    }
    console.log(`Project: ${state.project.title} (${state.project.name})`);
    console.log(`Installed: ${state.installedAt}`);
    console.log(`Installer version: ${state.installerVersion}`);
    console.log(`Sitepackage: ${state.sitepackage.vendor}/${state.sitepackage.name.replaceAll("_", "-")}`);
    console.log("Managed paths:");
    for (const generatedPath of state.generatedPaths) console.log(`  ${generatedPath}`);
  });

program.command("update")
  .description("update Composer and npm dependencies in an installed project")
  .option("-d, --directory <path>", "project directory", ".")
  .option("--dry-run", "show commands without running them")
  .option("--verbose", "show each command as it runs")
  .action(async ({ directory, dryRun, verbose }: { directory: string; dryRun?: boolean; verbose?: boolean }) => {
    const projectDirectory = path.resolve(directory);
    if (!(await readState(projectDirectory))) throw new Error("No installer state found. Refusing to update an unmanaged project.");
    const commands = [
      ["ddev", ["composer", "update", "--with-all-dependencies", "--no-interaction"]],
      ["ddev", ["npm", "update"]],
      ["ddev", ["typo3", "database:updateschema"]],
      ["ddev", ["typo3", "cache:warmup"]],
    ] as const;
    for (const [executable, args] of commands) {
      console.log(`${dryRun ? "Would run" : "Running"} ${formatCommand(executable, [...args])}`);
      if (!dryRun) await runCommand(executable, [...args], { cwd: projectDirectory, verbose: Boolean(verbose) });
    }
  });

program.command("uninstall")
  .description("remove only files tracked by the installer, never DDEV containers or TYPO3 core")
  .option("-d, --directory <path>", "project directory", ".")
  .option("-y, --yes", "skip confirmation")
  .option("--force", "acknowledge that tracked paths may contain local changes")
  .action(async ({ directory, yes, force }: { directory: string; yes?: boolean; force?: boolean }) => {
    const projectDirectory = path.resolve(directory);
    const state = await readState(projectDirectory);
    if (!state) throw new Error("No installer state found. Refusing to remove files from an unmanaged project.");
    if (!force) throw new Error("Uninstall requires --force because tracked files may have local changes.");
    if (!yes) {
      const accepted = await p.confirm({ message: `Remove ${state.generatedPaths.length} managed paths from ${projectDirectory}?`, initialValue: false });
      if (p.isCancel(accepted) || !accepted) return;
    }
    for (const generatedPath of state.generatedPaths) {
      const target = path.resolve(projectDirectory, generatedPath);
      if (path.relative(projectDirectory, target).startsWith("..")) throw new Error("Invalid generated path in state file.");
      await rm(target, { recursive: true, force: true });
    }
    await removeState(projectDirectory);
    console.log("Removed installer-managed files. DDEV containers and TYPO3 core remain in place.");
  });

program.parseAsync().catch((error: Error) => {
  p.log.error(error.message);
  process.exitCode = 1;
});
