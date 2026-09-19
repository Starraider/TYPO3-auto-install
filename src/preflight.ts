import { execa } from "execa";

export interface CheckResult {
  label: string;
  ok: boolean;
  detail: string;
}

async function checkCommand(label: string, executable: string, args: string[]): Promise<CheckResult> {
  try {
    const result = await execa(executable, args, { reject: false });
    const detail = (result.stdout || result.stderr).split("\n")[0] || "available";
    return { label, ok: result.exitCode === 0, detail };
  } catch {
    return { label, ok: false, detail: "not found" };
  }
}

export async function runPreflightChecks(): Promise<CheckResult[]> {
  return Promise.all([
    checkCommand("Node.js", "node", ["--version"]),
    checkCommand("DDEV", "ddev", ["version"]),
    checkCommand("Docker", "docker", ["info", "--format", "{{.ServerVersion}}"]),
  ]);
}

export function assertPreflightChecks(results: CheckResult[]): void {
  const failed = results.filter((result) => !result.ok);
  if (failed.length > 0) {
    throw new Error(`Missing or unavailable requirements: ${failed.map((result) => result.label).join(", ")}.`);
  }
}
