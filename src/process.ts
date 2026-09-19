import { execa } from "execa";

export interface CommandOptions {
  cwd: string;
  verbose: boolean;
  secretArguments?: number[];
}

export function formatCommand(
  executable: string,
  args: string[],
  secretArguments: number[] = [],
): string {
  return [executable, ...args.map((arg, index) => (secretArguments.includes(index) ? "[secret]" : arg))]
    .map((part) => JSON.stringify(part))
    .join(" ");
}

export async function runCommand(
  executable: string,
  args: string[],
  options: CommandOptions,
): Promise<void> {
  if (options.verbose) console.log(`$ ${formatCommand(executable, args, options.secretArguments)}`);
  await execa(executable, args, { cwd: options.cwd, stdio: "inherit" });
}
