import { describe, expect, it } from "vitest";
import { buildInstallPlan, makeReplacements, sitepackageKebabName, sitepackagePascalName } from "../src/installer/planner.js";
import { DEVELOPER_STACKS, type InstallConfig } from "../src/types.js";

const config: InstallConfig = {
  project: { name: "demo-site", title: "Demo site", directory: "/tmp/demo-site" },
  admin: { username: "admin", name: "Admin", email: "admin@example.test", password: "SecurePass1!" },
  ddev: { phpVersion: "8.3", serverType: "apache" },
  database: { driver: "mysqli", host: "db", port: 3306, name: "db", user: "db", password: "db" },
  sitepackage: { vendor: "acme", name: "demo_sitepackage" },
  developerStack: "bootstrap-vite",
  extensions: [],
  features: { rector: false, playwright: false },
};

describe("installation planning", () => {
  it("derives valid Composer and PHP identifiers", () => {
    expect(sitepackageKebabName("demo_sitepackage")).toBe("demo-sitepackage");
    expect(sitepackagePascalName("demo_sitepackage")).toBe("DemoSitepackage");
  });

  it("replaces customary TYPO3 sitepackage and vendor placeholder variants", () => {
    expect(makeReplacements({
      ...config,
      sitepackage: { vendor: "acme-agency", name: "my_typo3_project_sitepackage" },
    })).toMatchObject({
      xxxx_sitepackage: "my_typo3_project_sitepackage",
      "xxxx-sitepackage": "my-typo3-project-sitepackage",
      "xxxx sitepackage": "my typo3 project sitepackage",
      XxxxSitepackage: "MyTypo3ProjectSitepackage",
      xxxxSitepackage: "myTypo3ProjectSitepackage",
      XXXX_SITEPACKAGE: "MY_TYPO3_PROJECT_SITEPACKAGE",
      "XXXX-SITEPACKAGE": "MY-TYPO3-PROJECT-SITEPACKAGE",
      "XXXX SITEPACKAGE": "MY TYPO3 PROJECT SITEPACKAGE",
      skom_sitepackage: "my_typo3_project_sitepackage",
      "skom-sitepackage": "my-typo3-project-sitepackage",
      SkomSitepackage: "MyTypo3ProjectSitepackage",
      skom: "acme-agency",
      Skom: "AcmeAgency",
      SKom: "AcmeAgency",
      SKOM: "ACME-AGENCY",
    });
  });

  it("plans commands without exposing the administrator password", async () => {
    const plan = await buildInstallPlan(config, { dryRun: true, force: false, verbose: false });
    const setup = plan.find((step) => step.type === "command" && step.args[1] === "setup");
    const createProject = plan.find((step) => step.type === "command" && step.args[1] === "create-project");
    const configureDdev = plan.find((step) => step.type === "command" && step.executable === "ddev" && step.args[0] === "config");
    const configureComposer = plan.find((step) => step.type === "command" && step.executable === "ddev" && step.args[0] === "composer" && step.args[2] === "platform.php");
    expect(setup).toMatchObject({ type: "command", secretArguments: [8, 10] });
    expect(createProject).toMatchObject({ type: "command", args: ["composer", "create-project", "typo3/cms-base-distribution:^14.3", "--no-interaction"] });
    expect(configureDdev).toMatchObject({ type: "command", args: expect.arrayContaining(["--php-version=8.3"]) });
    expect(configureComposer).toMatchObject({ type: "command", args: ["composer", "config", "platform.php", "8.3.0"] });
    expect(plan.some((step) => step.type === "command" && step.args.includes("helhum/typo3-console:^9.0"))).toBe(true);
    expect(plan.some((step) => step.type === "render" && step.to.endsWith("packages/demo_sitepackage"))).toBe(true);
  });

  it("installs the Vite sidecar for the Bootstrap and Vite stack", async () => {
    const plan = await buildInstallPlan(config, { dryRun: true, force: false, verbose: false });
    const viteSidecar = plan.find((step) => step.type === "command" && step.args[0] === "get");

    expect(viteSidecar).toMatchObject({
      type: "command",
      executable: "ddev",
      args: ["get", "s2b/ddev-vite-sidecar"],
    });
  });

  it("runs TYPO3 extension setup for every developer stack", async () => {
    for (const developerStack of DEVELOPER_STACKS) {
      const plan = await buildInstallPlan(
        { ...config, developerStack },
        { dryRun: true, force: false, verbose: false },
      );
      const extensionSetup = plan.find(
        (step) => step.type === "command" && step.executable === "ddev" && step.args[0] === "typo3" && step.args[1] === "extension:setup",
      );

      expect(extensionSetup).toMatchObject({ type: "command", args: ["typo3", "extension:setup"] });
      expect(plan.at(-1)).toMatchObject({ type: "command", executable: "ddev", args: ["typo3", "extension:setup"] });
    }
  });

  it("installs compatible Vite and TYPO3 plugin versions", async () => {
    const plan = await buildInstallPlan(config, { dryRun: true, force: false, verbose: false });
    const npmInstall = plan.find(
      (step) => step.type === "command" && step.args[0] === "npm" && step.args[1] === "install",
    );

    expect(npmInstall).toMatchObject({
      type: "command",
      args: expect.arrayContaining(["vite@^7.0.0", "vite-plugin-typo3@^3.0.0"]),
    });
  });

  it("installs selected extensions and adds their available site sets to the sitepackage", async () => {
    const extensions = [
      "CodingFreaks/cf-cookiemanager",
      "friendsoftypo3/content-blocks",
      "baschte/content-animations",
      "t3g/blog",
      "georgringer/news",
    ] as const;
    const plan = await buildInstallPlan(
      { ...config, extensions: [...extensions] },
      { dryRun: true, force: false, verbose: false },
    );
    const composerRequire = plan.find((step) => step.type === "command" && step.args[0] === "composer" && step.args[1] === "require");
    const sitepackageRender = plan.find((step) => step.type === "render");

    expect(composerRequire).toMatchObject({ type: "command", args: expect.arrayContaining(extensions) });
    expect(sitepackageRender).toMatchObject({
      type: "render",
      replacements: {
        TYPO3_EXTENSION_SITE_SET_DEPENDENCIES: [
          "  - CodingFreaks/cf-cookiemanager",
          "  - baschte/content-animations-bootstrap-package",
          "  - blog/integration",
          "  - georgringer/news",
        ].join("\n"),
      },
    });
  });

  it("uses the Fluid Styled Content template without Vite-only dependencies", async () => {
    const plan = await buildInstallPlan(
      { ...config, developerStack: "fluid-styled-content", extensions: ["baschte/content-animations"] },
      { dryRun: true, force: false, verbose: false },
    );
    const composerRequire = plan.find((step) => step.type === "command" && step.args[0] === "composer" && step.args[1] === "require");
    const sitepackageRender = plan.find((step) => step.type === "render");

    expect(composerRequire).toMatchObject({
      type: "command",
      args: expect.not.arrayContaining(["praetorius/vite-asset-collector:^1.18"]),
    });
    expect(plan.some((step) => step.type === "command" && step.args[0] === "npm")).toBe(false);
    expect(plan.some((step) => step.type === "command" && step.args[0] === "get")).toBe(false);
    expect(plan.some((step) => step.type === "copy" && step.to.endsWith("vite.config.js"))).toBe(false);
    expect(sitepackageRender).toMatchObject({
      type: "render",
      from: expect.stringMatching(/fluid-styled-content\/sitepackage$/),
      replacements: { TYPO3_EXTENSION_SITE_SET_DEPENDENCIES: "  - baschte/content-animations-fluid-styles-content" },
    });
  });

  it("renders the self-contained Vite sitepackage of the Fluid Styled Content stack", async () => {
    const plan = await buildInstallPlan(
      { ...config, developerStack: "fluid-styled-content-vite", extensions: ["baschte/content-animations"] },
      { dryRun: true, force: false, verbose: false },
    );
    const composerRequire = plan.find((step) => step.type === "command" && step.args[0] === "composer" && step.args[1] === "require");
    const renders = plan.filter((step) => step.type === "render");
    const npmInstall = plan.find((step) => step.type === "command" && step.args[0] === "npm" && step.args[1] === "install");
    const viteSidecar = plan.find((step) => step.type === "command" && step.args[0] === "get");

    expect(composerRequire).toMatchObject({
      type: "command",
      args: expect.arrayContaining(["praetorius/vite-asset-collector:^1.18"]),
    });
    expect(renders).toHaveLength(1);
    expect(renders[0]).toMatchObject({ type: "render", from: expect.stringMatching(/fluid-styled-content-vite\/sitepackage$/) });
    expect(renders[0]).toMatchObject({
      replacements: {
        FSC_SITE_ASSETS: '<vite:asset entry="EXT:demo_sitepackage/Resources/Private/JavaScript/Main.entry.js" />',
        TYPO3_EXTENSION_SITE_SET_DEPENDENCIES: "  - baschte/content-animations-fluid-styles-content",
      },
    });
    expect(npmInstall).toMatchObject({
      type: "command",
      args: expect.arrayContaining(["vite@^7.0.0", "vite-plugin-typo3@^3.0.0", "sass-embedded"]),
    });
    expect(viteSidecar).toMatchObject({ type: "command", args: ["get", "s2b/ddev-vite-sidecar"] });
    const sidecarIndex = plan.indexOf(viteSidecar!);
    expect(plan[sidecarIndex + 1]).toMatchObject({ type: "command", executable: "ddev", args: ["restart"] });
  });

  it("uses and fully renders the Bootstrap Package-only template without Vite dependencies", async () => {
    const plan = await buildInstallPlan(
      { ...config, developerStack: "bootstrap-package", extensions: ["baschte/content-animations", "georgringer/news"] },
      { dryRun: true, force: false, verbose: false },
    );
    const composerRequire = plan.find((step) => step.type === "command" && step.args[0] === "composer" && step.args[1] === "require");
    const sitepackageRender = plan.find((step) => step.type === "render");

    expect(composerRequire).toMatchObject({
      type: "command",
      args: expect.not.arrayContaining(["praetorius/vite-asset-collector:^1.18"]),
    });
    expect(plan.some((step) => step.type === "command" && step.args[0] === "npm")).toBe(false);
    expect(plan.some((step) => step.type === "command" && step.args[0] === "get")).toBe(false);
    expect(plan.some((step) => step.type === "copy" && step.to.endsWith("vite.config.js"))).toBe(false);
    expect(sitepackageRender).toMatchObject({
      type: "render",
      from: expect.stringMatching(/bootstrap-package\/sitepackage$/),
      replacements: {
        "skom/bbb": "acme/demo-sitepackage",
        bbb: "demo_sitepackage",
        Bbb: "DemoSitepackage",
        TYPO3_EXTENSION_SITE_SET_DEPENDENCIES: [
          "  - baschte/content-animations-bootstrap-package",
          "  - georgringer/news",
        ].join("\n"),
      },
    });
  });
  it("installs and builds StyleX after configuring the sidecar", async () => {
    const plan = await buildInstallPlan(
      { ...config, developerStack: "fluid-styled-content-vite-stylex", extensions: ["baschte/content-animations"] },
      { dryRun: true, force: false, verbose: false },
    );
    const commands = plan.filter(step => step.type === "command");
    expect(commands.find(step => step.args[0] === "config")?.args).toContain("--nodejs-version=22");
    expect(commands.find(step => step.args[1] === "require")?.args).toEqual(expect.arrayContaining([
      "skom/stylex-connector:dev-main#701d870b9ae55e8c434af24532b95c10f7e54ef2", "praetorius/vite-asset-collector:^1.18",
    ]));
    const npmDependencies = commands.filter(step => step.args[0] === "npm" && step.args[1] === "install").flatMap(step => step.args);
    expect(npmDependencies).toEqual(expect.arrayContaining([
      "@stylexjs/stylex@^0.19.1", "@stylexjs/unplugin@^0.19.1", "@babel/parser@^7.29.0",
    ]));
    expect(npmDependencies).not.toContain("sass-embedded");
    expect(npmDependencies).not.toContain("bootstrap");
    const stylexSitepackage = plan.find(step => step.type === "render" && step.from.endsWith("fluid-styled-content-vite-stylex/sitepackage"));
    expect(stylexSitepackage).toMatchObject({ replacements: {
      STYLEX_CONNECTOR_PACKAGE: "skom/stylex-connector",
      STYLEX_CONNECTOR_VERSION: "dev-main",
      TYPO3_EXTENSION_SITE_SET_DEPENDENCIES: "  - baschte/content-animations-fluid-styles-content",
    } });
    const sidecar = commands.findIndex(step => step.executable === "env");
    const restart = commands.findIndex(step => step.args[0] === "restart");
    const build = commands.findIndex(step => step.args.join(" ") === "npm run build");
    expect(sidecar).toBeGreaterThan(-1);
    expect(restart).toBeGreaterThan(sidecar);
    expect(build).toBeGreaterThan(restart);
    expect(commands[build + 1].args).toEqual([
      "typo3", "stylex:validate", "--required-key", "Site.shell", "--required-key", "Site.content",
    ]);
    expect(commands[build + 2].args).toEqual(["typo3", "cache:flush"]);
    const vite = plan.find(step => step.type === "write" && step.path.endsWith("vite.config.js"));
    expect(vite).toMatchObject({ contents: expect.stringContaining("packages/demo_sitepackage/Resources/Public/StylexManifest/stylex-manifest.json") });
    expect(vite).toMatchObject({ contents: expect.stringContaining('from "./vendor/skom/stylex-connector/Resources/Private/Build/stylex-manifest.mjs"') });
    expect(vite).toMatchObject({ contents: expect.stringContaining('namespace: "demo_sitepackage"') });
    expect(vite).toMatchObject({ contents: expect.stringContaining("legacyAliases: true") });
    expect(plan.some(step => step.type === "copy" && step.to.endsWith("vite-plugin-stylex-manifest.js"))).toBe(false);
    expect(plan.find(step => step.type === "write" && step.path.endsWith("verify-stylex-build.mjs"))).toBeDefined();
  });

});
