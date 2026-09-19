import { describe, expect, it } from "vitest";
import { buildInstallPlan, sitepackageKebabName, sitepackagePascalName } from "../src/installer/planner.js";
import type { InstallConfig } from "../src/types.js";

const config: InstallConfig = {
  project: { name: "demo-site", title: "Demo site", directory: "/tmp/demo-site" },
  admin: { username: "admin", name: "Admin", email: "admin@example.test", password: "SecurePass1!" },
  ddev: { phpVersion: "8.3", serverType: "apache" },
  database: { driver: "mysqli", host: "db", port: 3306, name: "db", user: "db", password: "db" },
  sitepackage: { vendor: "acme", name: "demo_sitepackage" },
  features: { viteSidecar: false, rector: false, playwright: false },
};

describe("installation planning", () => {
  it("derives valid Composer and PHP identifiers", () => {
    expect(sitepackageKebabName("demo_sitepackage")).toBe("demo-sitepackage");
    expect(sitepackagePascalName("demo_sitepackage")).toBe("DemoSitepackage");
  });

  it("plans commands without exposing the administrator password", async () => {
    const plan = await buildInstallPlan(config, { dryRun: true, force: false, verbose: false });
    const setup = plan.find((step) => step.type === "command" && step.args[1] === "setup");
    expect(setup).toMatchObject({ type: "command", secretArguments: [8, 10] });
    expect(plan.some((step) => step.type === "render" && step.to.endsWith("packages/demo_sitepackage"))).toBe(true);
  });
});
