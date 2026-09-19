import path from "node:path";
import type { InstallStep } from "../types.js";
import { formatCommand } from "../process.js";

export function describeStep(step: InstallStep): string {
  const displayPath = (filePath: string): string => {
    const relative = path.relative(process.cwd(), filePath);
    return relative.startsWith("..") ? filePath : relative || ".";
  };
  switch (step.type) {
    case "mkdir": return `Create directory ${displayPath(step.path)}`;
    case "copy": return `Copy ${path.basename(step.from)} to ${displayPath(step.to)}`;
    case "render": return `Create sitepackage at ${displayPath(step.to)}`;
    case "write": return `Write ${displayPath(step.path)}`;
    case "command": return `Run ${formatCommand(step.executable, step.args, step.secretArguments)}`;
  }
}

export function printPlan(steps: InstallStep[]): void {
  console.log("\nInstallation plan\n");
  for (const step of steps) console.log(`  ${describeStep(step)}`);
}
