import { describe, expect, it } from "vitest";
import { validateConfig } from "../src/config/loader.js";

describe("configuration validation", () => {
  const validConfig = {
    project: { name: "demo-site", title: "Demo", directory: "./demo" },
    admin: { username: "admin", name: "Admin", email: "admin@example.test" },
    ddev: { phpVersion: "8.3", serverType: "apache" },
    database: { driver: "mysqli", host: "db", port: 3306, name: "db", user: "db", password: "db" },
    sitepackage: { vendor: "acme", name: "demo_sitepackage" },
    developerStack: "bootstrap-vite",
    features: { rector: true, playwright: false },
  };

  it("rejects unsafe DDEV project names", () => {
    expect(() => validateConfig({
      project: { name: "Unsafe Name", title: "Demo", directory: "./demo" },
      admin: { username: "admin", name: "Admin", email: "admin@example.test" },
      ddev: { phpVersion: "8.3", serverType: "apache" },
      database: { driver: "mysqli", host: "db", port: 3306, name: "db", user: "db", password: "db" },
      sitepackage: { vendor: "acme", name: "demo_sitepackage" },
      developerStack: "bootstrap-vite",
      features: { rector: true, playwright: false },
    })).toThrow(/lowercase/);
  });

  it("rejects PHP versions other than 8.3", () => {
    expect(() => validateConfig({
      project: { name: "demo-site", title: "Demo", directory: "./demo" },
      admin: { username: "admin", name: "Admin", email: "admin@example.test" },
      ddev: { phpVersion: "8.4", serverType: "apache" },
      database: { driver: "mysqli", host: "db", port: 3306, name: "db", user: "db", password: "db" },
      sitepackage: { vendor: "acme", name: "demo_sitepackage" },
      developerStack: "bootstrap-vite",
      features: { rector: true, playwright: false },
    })).toThrow(/PHP 8\.3/);
  });

  it("accepts configured TYPO3 extensions and defaults to no selections", () => {
    expect(validateConfig(validConfig).extensions).toEqual([]);
    expect(validateConfig({
      ...validConfig,
      extensions: ["friendsoftypo3/content-blocks", "georgringer/news"],
    }).extensions).toEqual(["friendsoftypo3/content-blocks", "georgringer/news"]);
  });

  it("accepts all developer stacks and keeps the legacy default", () => {
    const { developerStack: _developerStack, ...legacyConfig } = validConfig;
    expect(validateConfig(legacyConfig).developerStack).toBe("bootstrap-vite");
    expect(validateConfig({ ...validConfig, developerStack: "bootstrap-package" }).developerStack).toBe("bootstrap-package");
    expect(validateConfig({ ...validConfig, developerStack: "fluid-styled-content" }).developerStack).toBe("fluid-styled-content");
  });

  it("rejects unsupported or duplicate TYPO3 extensions", () => {
    expect(() => validateConfig({ ...validConfig, extensions: ["vendor/not-supported"] })).toThrow();
    expect(() => validateConfig({ ...validConfig, extensions: ["georgringer/news", "georgringer/news"] })).toThrow(/only once/);
  });
});
