import * as p from "@clack/prompts";
import type { InstallConfig } from "./types.js";

function cancelled<T>(answer: T | symbol): T {
  if (p.isCancel(answer)) {
    p.cancel("Installation cancelled. No changes were made.");
    process.exit(130);
  }
  return answer as T;
}

export async function askForInstallConfig(defaults: InstallConfig): Promise<InstallConfig> {
  p.intro("TYPO3 project installer");
  const projectName = cancelled(await p.text({ message: "DDEV project name", initialValue: defaults.project.name, validate: (value) => /^[a-z0-9][a-z0-9-]{2,62}$/.test(value) ? undefined : "Use at least three lowercase letters, numbers, or hyphens." }));
  const title = cancelled(await p.text({ message: "Project title", initialValue: defaults.project.title, validate: (value) => value.trim() ? undefined : "A title is required." }));
  const directory = cancelled(await p.text({ message: "Installation directory", initialValue: defaults.project.directory, validate: (value) => value.trim() ? undefined : "A directory is required." }));
  const vendor = cancelled(await p.text({ message: "Composer vendor", initialValue: defaults.sitepackage.vendor, validate: (value) => /^[a-z0-9][a-z0-9-]{2,62}$/.test(value) ? undefined : "Use a lowercase Composer vendor name." }));
  const sitepackageName = cancelled(await p.text({ message: "Sitepackage key", initialValue: defaults.sitepackage.name, validate: (value) => /^[a-z][a-z0-9_]{2,62}$/.test(value) ? undefined : "Use lowercase letters, numbers, and underscores." }));
  const username = cancelled(await p.text({ message: "Administrator username", initialValue: defaults.admin.username, validate: (value) => value.trim() ? undefined : "A username is required." }));
  const name = cancelled(await p.text({ message: "Administrator name", initialValue: defaults.admin.name, validate: (value) => value.trim() ? undefined : "A name is required." }));
  const email = cancelled(await p.text({ message: "Administrator email", initialValue: defaults.admin.email, validate: (value) => /^\S+@\S+\.\S+$/.test(value) ? undefined : "Enter a valid email address." }));
  const password = cancelled(await p.password({
    message: "Administrator password",
    validate: (value) => {
      if (value.length < 8) return "Use at least eight characters.";
      if (!/[A-Z]/.test(value) || !/[a-z]/.test(value) || !/[0-9]/.test(value) || !/[^a-zA-Z0-9]/.test(value)) {
        return "Include upper- and lowercase letters, a number, and a special character.";
      }
      return undefined;
    },
  }));
  const viteSidecar = cancelled(await p.confirm({ message: "Install the DDEV Vite sidecar?", initialValue: defaults.features.viteSidecar }));
  const rector = cancelled(await p.confirm({ message: "Install TYPO3 Rector?", initialValue: defaults.features.rector }));
  const playwright = cancelled(await p.confirm({ message: "Install Playwright?", initialValue: defaults.features.playwright }));

  return {
    ...defaults,
    project: { name: projectName, title, directory },
    admin: { ...defaults.admin, username, name, email, password },
    sitepackage: { vendor, name: sitepackageName },
    features: { viteSidecar, rector, playwright },
  };
}

export async function confirmInstall(): Promise<boolean> {
  return cancelled(await p.confirm({ message: "Execute this plan?", initialValue: true }));
}
