import { describe, expect, it } from "vitest";
import { validateConfig } from "../src/config/loader.js";

describe("configuration validation", () => {
  it("rejects unsafe DDEV project names", () => {
    expect(() => validateConfig({
      project: { name: "Unsafe Name", title: "Demo", directory: "./demo" },
      admin: { username: "admin", name: "Admin", email: "admin@example.test" },
      ddev: { phpVersion: "8.3", serverType: "apache" },
      database: { driver: "mysqli", host: "db", port: 3306, name: "db", user: "db", password: "db" },
      sitepackage: { vendor: "acme", name: "demo_sitepackage" },
      features: { viteSidecar: true, rector: true, playwright: false },
    })).toThrow(/lowercase/);
  });

  it("rejects PHP versions other than 8.3", () => {
    expect(() => validateConfig({
      project: { name: "demo-site", title: "Demo", directory: "./demo" },
      admin: { username: "admin", name: "Admin", email: "admin@example.test" },
      ddev: { phpVersion: "8.4", serverType: "apache" },
      database: { driver: "mysqli", host: "db", port: 3306, name: "db", user: "db", password: "db" },
      sitepackage: { vendor: "acme", name: "demo_sitepackage" },
      features: { viteSidecar: true, rector: true, playwright: false },
    })).toThrow(/PHP 8\.3/);
  });
});
