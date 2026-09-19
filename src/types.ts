export type ServerType = "apache" | "nginx";

export interface InstallConfig {
  project: {
    name: string;
    title: string;
    directory: string;
  };
  admin: {
    username: string;
    name: string;
    email: string;
    url?: string;
    password?: string;
  };
  ddev: {
    phpVersion: "8.3";
    serverType: ServerType;
  };
  database: {
    driver: "mysqli";
    host: string;
    port: number;
    name: string;
    user: string;
    password: string;
  };
  sitepackage: {
    vendor: string;
    name: string;
  };
  features: {
    viteSidecar: boolean;
    rector: boolean;
    playwright: boolean;
  };
}

export interface InstallOptions {
  dryRun: boolean;
  verbose: boolean;
  force: boolean;
}

export type InstallStep =
  | { type: "mkdir"; path: string }
  | { type: "copy"; from: string; to: string }
  | { type: "render"; from: string; to: string; replacements: Record<string, string> }
  | { type: "write"; path: string; contents: string }
  | {
      type: "command";
      executable: string;
      args: string[];
      cwd: string;
      secretArguments?: number[];
    };

export interface InstallState {
  schemaVersion: 1;
  installerVersion: string;
  installedAt: string;
  project: Pick<InstallConfig["project"], "name" | "title">;
  sitepackage: InstallConfig["sitepackage"];
  generatedPaths: string[];
}
