import { mkdtemp, readFile, readdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import { renderDirectory } from "../src/filesystem.js";
import { buildInstallPlan, makeReplacements } from "../src/installer/planner.js";
import { readState, writeState } from "../src/state.js";
import { parse } from "yaml";
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

  it("overlays Vite assets onto the Fluid Styled Content sitepackage", async () => {
    const directory = await mkdtemp(path.join(tmpdir(), "typo3-installer-"));
    temporaryDirectories.push(directory);
    const destination = path.join(directory, "my_typo3_project_sitepackage");
    const config: InstallConfig = {
      project: { name: "demo-site", title: "Demo site", directory },
      admin: { username: "admin", name: "Admin", email: "admin@example.test", password: "SecurePass1!" },
      ddev: { phpVersion: "8.3", serverType: "apache" },
      database: { driver: "mysqli", host: "db", port: 3306, name: "db", user: "db", password: "db" },
      sitepackage: { vendor: "acme-agency", name: "my_typo3_project_sitepackage" },
      developerStack: "fluid-styled-content-vite",
      extensions: [],
      features: { rector: false, playwright: false },
    };

    await renderDirectory(path.resolve("install-src/yyy_sitepackage"), destination, makeReplacements(config));
    await renderDirectory(path.resolve("install-src/fluid-styled-content-vite"), destination, makeReplacements(config));

    await expect(readFile(path.join(destination, "Resources/Private/PageView/Layouts/PageLayout.html"), "utf8")).resolves.toContain('<vite:asset entry="EXT:my_typo3_project_sitepackage/Resources/Private/JavaScript/Main.entry.js" />');
    await expect(readFile(path.join(destination, "Resources/Private/PageView/Layouts/PageLayout.html"), "utf8")).resolves.not.toContain("Resources/Public/Css/main.css");
    await expect(readFile(path.join(destination, "Resources/Private/PageView/Layouts/PageLayout.html"), "utf8")).resolves.toContain('xmlns:vite="http://typo3.org/ns/Praetorius/ViteAssetCollector/ViewHelpers"');
    await expect(readFile(path.join(destination, "Resources/Private/PageView/Layouts/PageLayout.html"), "utf8")).resolves.not.toContain("<f:if condition=\"true\"");
    await expect(readFile(path.join(destination, "Configuration/ViteEntrypoints.json"), "utf8")).resolves.toContain("../Resources/Private/JavaScript/Main.entry.js");
    await expect(readFile(path.join(destination, "Resources/Private/JavaScript/Main.entry.js"), "utf8")).resolves.toContain('import "../Scss/main.scss"');
  });

  it.each(["fluid-styled-content-vite", "fluid-styled-content-vite-stylex"] as const)(
    "generates %s without Bootstrap assets or dependencies",
    async (developerStack) => {
      const directory = await mkdtemp(path.join(tmpdir(), "typo3-fsc-render-"));
      temporaryDirectories.push(directory);
      const config: InstallConfig = {
        project: { name: "demo-site", title: "Demo site", directory },
        admin: { username: "admin", name: "Admin", email: "admin@example.test", password: "SecurePass1!" },
        ddev: { phpVersion: "8.3", serverType: "apache" },
        database: { driver: "mysqli", host: "db", port: 3306, name: "db", user: "db", password: "db" },
        sitepackage: { vendor: "acme", name: "demo_sitepackage" },
        developerStack,
        extensions: [],
        features: { rector: false, playwright: false },
      };
      const plan = await buildInstallPlan(config, { dryRun: true, force: false, verbose: false });
      const renders = plan.filter(step => step.type === "render");
      expect(renders).toHaveLength(2);
      expect(renders[1].from).toMatch(new RegExp(`${developerStack}$`));
      expect(renders[1].from).not.toContain("fluid-styled-content-frontend");
      // Only the base sitepackage provides page layouts and templates.
      await expect(readdir(path.join(renders[1].from, "Resources/Private/PageView"))).rejects.toMatchObject({ code: "ENOENT" });
      for (const step of plan) {
        if (step.type === "render") await renderDirectory(step.from, step.to, step.replacements);
        if (step.type === "command") expect(step.args.join(" ")).not.toMatch(/bootstrap|@popperjs/i);
        if (step.type === "write") expect(step.contents).not.toMatch(/bootstrap/i);
      }
      const sitepackage = path.join(directory, "packages/demo_sitepackage");
      const settings = parse(await readFile(path.join(sitepackage, "Configuration/Sets/SitePackage/settings.yaml"), "utf8"));
      expect(settings).not.toHaveProperty(["styles.templates.layoutRootPath"]);
      expect(settings).not.toHaveProperty(["styles.templates.partialRootPath"]);
      expect(settings).not.toHaveProperty(["styles.templates.templateRootPath"]);
      const siteSet = parse(await readFile(path.join(sitepackage, "Configuration/Sets/SitePackage/config.yaml"), "utf8"));
      expect(siteSet.dependencies).toEqual(expect.arrayContaining([
        "typo3/fluid-styled-content", "typo3/fluid-styled-content-css",
      ]));
      async function checkFiles(folder: string): Promise<void> {
        for (const entry of await readdir(folder, { withFileTypes: true })) {
          const file = path.join(folder, entry.name);
          if (entry.isDirectory()) await checkFiles(file);
          else if (/\.(html|css|scss|js|json|yaml|php|xlf|md)$/.test(entry.name)) {
            expect(path.relative(sitepackage, file)).not.toMatch(/^Resources\/Private\/ContentElements\//);
            expect(await readFile(file, "utf8"), file).not.toMatch(/bootstrap|--bs-|data-bs-|\.bs\./i);
          }
        }
      }
      await checkFiles(sitepackage);
      const layout = await readFile(path.join(sitepackage, "Resources/Private/PageView/Layouts/PageLayout.html"), "utf8");
      expect(layout.match(/<vite:asset/g)).toHaveLength(1);
      const header = await readFile(path.join(sitepackage, "Resources/Private/PageView/Partials/Header.html"), "utf8");
      expect(header).toContain('<nav aria-label="Main navigation">');
      expect(header).not.toContain("<details");
      await expect(readdir(path.join(sitepackage, "ContentBlocks/ContentElements"))).rejects.toMatchObject({ code: "ENOENT" });
      expect(layout).not.toMatch(/FSC_[A-Z_]+/);
    },
  );

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
  it("keeps connector identifiers intact when rendering a custom StyleX sitepackage", async () => {
    const directory = await mkdtemp(path.join(tmpdir(), "typo3-stylex-render-"));
    temporaryDirectories.push(directory);
    const config: InstallConfig = {
      project: { name: "demo-site", title: "Demo site", directory },
      admin: { username: "admin", name: "Admin", email: "admin@example.test", password: "SecurePass1!" },
      ddev: { phpVersion: "8.3", serverType: "apache" },
      database: { driver: "mysqli", host: "db", port: 3306, name: "db", user: "db", password: "db" },
      sitepackage: { vendor: "acme-agency", name: "my_custom_sitepackage" },
      developerStack: "fluid-styled-content-vite-stylex",
      extensions: ["baschte/content-animations"],
      features: { rector: false, playwright: false },
    };
    const plan = await buildInstallPlan(config, { dryRun: true, force: false, verbose: false });
    for (const step of plan) {
      if (step.type === "render") await renderDirectory(step.from, step.to, step.replacements);
    }
    const sitepackage = path.join(directory, "packages/my_custom_sitepackage");
    const composer = JSON.parse(await readFile(path.join(sitepackage, "composer.json"), "utf8"));
    expect(composer.name).toBe("acme-agency/my-custom-sitepackage");
    expect(composer.require["skom/stylex-connector"]).toBe("dev-main");
    const set = parse(await readFile(path.join(sitepackage, "Configuration/Sets/SitePackage/config.yaml"), "utf8"));
    expect(set.dependencies).toEqual([
      "typo3/fluid-styled-content", "typo3/fluid-styled-content-css", "skom/stylex-connector",
      "baschte/content-animations-fluid-styles-content",
    ]);
    const registry = await readFile(path.join(sitepackage, "ext_localconf.php"), "utf8");
    expect(registry).toContain("Vendor\\StylexConnector\\Configuration\\StylexRegistry::registerManifest");
    expect(registry).toContain("EXT:my_custom_sitepackage/Resources/Public/StylexManifest/stylex-manifest.json");
    const layout = await readFile(path.join(sitepackage, "Resources/Private/PageView/Layouts/PageLayout.html"), "utf8");
    expect(layout.match(/<vite:asset/g)).toHaveLength(1);
    expect(layout).toContain("EXT:my_custom_sitepackage/Resources/Private/JavaScript/Main.entry.js");
    expect(layout).toContain("stylex:class(styles: 'Site.shell')");
    expect(layout).not.toContain("stylex_sitepackage");
    const entry = await readFile(path.join(sitepackage, "Resources/Private/JavaScript/Main.entry.js"), "utf8");
    expect(entry).toContain('import "./Stylex/Site.stylex.js"');
    expect(entry).toContain("/virtual:stylex.css");
    const development = await readFile(path.join(sitepackage, "Configuration/Sets/SitePackage/TypoScript/stylex.typoscript"), "utf8");
    expect(development).toContain('[applicationContext matches "/^Development/"]');
    expect(development).toContain("config.no_cache = 1");
    await writeState(directory, config, "1.0.0");
    expect((await readState(directory))?.generatedPaths).toEqual(expect.arrayContaining([
      "vite.config.js", "verify-stylex-build.mjs",
    ]));
    expect((await readState(directory))?.generatedPaths).not.toContain("vite-plugin-stylex-manifest.js");
  });

});
