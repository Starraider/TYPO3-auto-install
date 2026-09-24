import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import { renderDirectory } from "../src/filesystem.js";
import { makeReplacements } from "../src/installer/planner.js";
import type { InstallConfig } from "../src/types.js";

const temporaryDirectories: string[] = [];

afterEach(async () => {
  await Promise.all(temporaryDirectories.splice(0).map((directory) => rm(directory, { recursive: true, force: true })));
});

describe("template rendering", () => {
  it("replaces placeholders in text while preserving binary assets", async () => {
    const directory = await mkdtemp(path.join(tmpdir(), "typo3-installer-"));
    temporaryDirectories.push(directory);
    const source = path.join(directory, "source");
    const destination = path.join(directory, "destination");
    await (await import("node:fs/promises")).mkdir(source);
    await writeFile(path.join(source, "extension.php"), "EXT:xxxx_sitepackage skom_sitepackage skom");
    await writeFile(path.join(source, "icon.ico"), Buffer.from([0, 1, 2, 3]));

    await renderDirectory(source, destination, {
      xxxx_sitepackage: "demo_sitepackage",
      skom_sitepackage: "demo_sitepackage",
      skom: "acme",
    });

    await expect(readFile(path.join(destination, "extension.php"), "utf8")).resolves.toBe("EXT:demo_sitepackage demo_sitepackage acme");
    await expect(readFile(path.join(destination, "icon.ico"))).resolves.toEqual(Buffer.from([0, 1, 2, 3]));
  });

  it("renders all customary TYPO3 sitepackage and vendor name forms", async () => {
    const directory = await mkdtemp(path.join(tmpdir(), "typo3-installer-"));
    temporaryDirectories.push(directory);
    const source = path.join(directory, "source");
    const destination = path.join(directory, "destination");
    await (await import("node:fs/promises")).mkdir(source);
    await writeFile(
      path.join(source, "placeholders.txt"),
      [
        "xxxx_sitepackage", "xxxx-sitepackage", "xxxx sitepackage", "XxxxSitepackage", "xxxxSitepackage",
        "XXXX_SITEPACKAGE", "XXXX-SITEPACKAGE", "XXXX SITEPACKAGE", "XXXXSitepackage", "xxxx", "Xxxx", "XXXX",
        "skom_sitepackage", "skom-sitepackage", "skom sitepackage", "SkomSitepackage", "skom", "Skom", "SKom", "SKOM",
      ].join("\n"),
    );
    const config: InstallConfig = {
      project: { name: "demo-site", title: "Demo site", directory },
      admin: { username: "admin", name: "Admin", email: "admin@example.test", password: "SecurePass1!" },
      ddev: { phpVersion: "8.3", serverType: "apache" },
      database: { driver: "mysqli", host: "db", port: 3306, name: "db", user: "db", password: "db" },
      sitepackage: { vendor: "acme-agency", name: "my_typo3_project_sitepackage" },
      developerStack: "bootstrap-vite",
      extensions: [],
      features: { rector: false, playwright: false },
    };

    await renderDirectory(source, destination, makeReplacements(config));

    await expect(readFile(path.join(destination, "placeholders.txt"), "utf8")).resolves.toBe([
      "my_typo3_project_sitepackage", "my-typo3-project-sitepackage", "my typo3 project sitepackage", "MyTypo3ProjectSitepackage", "myTypo3ProjectSitepackage",
      "MY_TYPO3_PROJECT_SITEPACKAGE", "MY-TYPO3-PROJECT-SITEPACKAGE", "MY TYPO3 PROJECT SITEPACKAGE", "MYTYPO3PROJECTSITEPACKAGE", "my typo3 project sitepackage", "My typo3 project sitepackage", "MY TYPO3 PROJECT SITEPACKAGE",
      "my_typo3_project_sitepackage", "my-typo3-project-sitepackage", "my typo3 project sitepackage", "MyTypo3ProjectSitepackage", "acme-agency", "AcmeAgency", "AcmeAgency", "ACME-AGENCY",
    ].join("\n"));
  });

  it("renders the Fluid Styled Content template placeholder family", async () => {
    const directory = await mkdtemp(path.join(tmpdir(), "typo3-installer-"));
    temporaryDirectories.push(directory);
    const source = path.join(directory, "source");
    const destination = path.join(directory, "destination");
    await (await import("node:fs/promises")).mkdir(source);
    await writeFile(
      path.join(source, "placeholders.txt"),
      ["yyy_sitepackage", "yyy-sitepackage", "YyySitepackage", "yyySitepackage", "YYY_SITEPACKAGE", "YYY-SITEPACKAGE", "YYY SITEPACKAGE", "YYY"].join("\n"),
    );
    const config: InstallConfig = {
      project: { name: "demo-site", title: "Demo site", directory },
      admin: { username: "admin", name: "Admin", email: "admin@example.test", password: "SecurePass1!" },
      ddev: { phpVersion: "8.3", serverType: "apache" },
      database: { driver: "mysqli", host: "db", port: 3306, name: "db", user: "db", password: "db" },
      sitepackage: { vendor: "acme-agency", name: "my_typo3_project_sitepackage" },
      developerStack: "fluid-styled-content",
      extensions: [],
      features: { rector: false, playwright: false },
    };

    await renderDirectory(source, destination, makeReplacements(config));

    await expect(readFile(path.join(destination, "placeholders.txt"), "utf8")).resolves.toBe([
      "my_typo3_project_sitepackage", "my-typo3-project-sitepackage", "MyTypo3ProjectSitepackage", "myTypo3ProjectSitepackage",
      "MY_TYPO3_PROJECT_SITEPACKAGE", "MY-TYPO3-PROJECT-SITEPACKAGE", "MY TYPO3 PROJECT SITEPACKAGE", "MY TYPO3 PROJECT SITEPACKAGE",
    ].join("\n"));
  });

  it("renders the Bootstrap Package-only template with the configured vendor and sitepackage name", async () => {
    const directory = await mkdtemp(path.join(tmpdir(), "typo3-installer-"));
    temporaryDirectories.push(directory);
    const destination = path.join(directory, "my_typo3_project_sitepackage");
    const config: InstallConfig = {
      project: { name: "demo-site", title: "Demo site", directory },
      admin: { username: "admin", name: "Admin", email: "admin@example.test", password: "SecurePass1!" },
      ddev: { phpVersion: "8.3", serverType: "apache" },
      database: { driver: "mysqli", host: "db", port: 3306, name: "db", user: "db", password: "db" },
      sitepackage: { vendor: "acme-agency", name: "my_typo3_project_sitepackage" },
      developerStack: "bootstrap-package",
      extensions: [],
      features: { rector: false, playwright: false },
    };

    await renderDirectory(path.resolve("install-src/bbb_sitepackage"), destination, makeReplacements(config));

    await expect(readFile(path.join(destination, "composer.json"), "utf8")).resolves.toContain('"name": "acme-agency/my-typo3-project-sitepackage"');
    await expect(readFile(path.join(destination, "composer.json"), "utf8")).resolves.toContain('"AcmeAgency\\\\MyTypo3ProjectSitepackage\\\\": "Classes/"');
    await expect(readFile(path.join(destination, "composer.json"), "utf8")).resolves.toContain('"extension-key": "my_typo3_project_sitepackage"');
    await expect(readFile(path.join(destination, "Configuration/Sets/SitePackage/config.yaml"), "utf8")).resolves.toContain("name: acme-agency/my-typo3-project-sitepackage");
    await expect(readFile(path.join(destination, "ext_localconf.php"), "utf8")).resolves.toContain("EXT:my_typo3_project_sitepackage/Configuration/RTE/Default.yaml");
  });
});
