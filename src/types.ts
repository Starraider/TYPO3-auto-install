export type ServerType = "apache" | "nginx";

export const DEVELOPER_STACKS = ["bootstrap-vite", "fluid-styled-content"] as const;

export type DeveloperStack = (typeof DEVELOPER_STACKS)[number];

export const TYPO3_EXTENSION_PACKAGES = [
  "CodingFreaks/cf-cookiemanager",
  "friendsoftypo3/content-blocks",
  "baschte/content-animations",
  "t3g/blog",
  "georgringer/news",
] as const;

export type Typo3ExtensionPackage = (typeof TYPO3_EXTENSION_PACKAGES)[number];

export const TYPO3_EXTENSION_SITE_SETS: Partial<Record<Typo3ExtensionPackage, string>> = {
  "CodingFreaks/cf-cookiemanager": "CodingFreaks/cf-cookiemanager",
  "t3g/blog": "blog/integration",
  "georgringer/news": "georgringer/news",
};

export const TYPO3_STACK_EXTENSION_SITE_SETS: Record<DeveloperStack, Partial<Record<Typo3ExtensionPackage, string>>> = {
  "bootstrap-vite": {
    "baschte/content-animations": "baschte/content-animations-bootstrap-package",
  },
  "fluid-styled-content": {
    "baschte/content-animations": "baschte/content-animations-fluid-styles-content",
  },
};

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
  developerStack: DeveloperStack;
  extensions: Typo3ExtensionPackage[];
  features: {
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
  developerStack: DeveloperStack;
  generatedPaths: string[];
}
