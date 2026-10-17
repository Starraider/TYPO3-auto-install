import { describe, expect, it, vi } from "vitest";
import * as p from "@clack/prompts";
import { confirmEmptyDirectory, confirmInstall } from "../src/prompts.js";

vi.mock("@clack/prompts", () => ({
  confirm: vi.fn(),
  isCancel: vi.fn(),
  cancel: vi.fn(),
  intro: vi.fn(),
  outro: vi.fn(),
  text: vi.fn(),
  select: vi.fn(),
  password: vi.fn(),
  multiselect: vi.fn(),
}));

describe("prompts", () => {
  it("prompts user to empty non-empty target directory and returns confirmation", async () => {
    vi.mocked(p.confirm).mockResolvedValueOnce(true);
    vi.mocked(p.isCancel).mockReturnValue(false);

    const result = await confirmEmptyDirectory("/test/path");
    expect(result).toBe(true);
    expect(p.confirm).toHaveBeenCalledWith({
      message: "Target folder is not empty (/test/path). Empty folder (delete all contents) before proceeding with the installation?",
      initialValue: false,
    });
  });

  it("returns false when user declines to empty non-empty target directory", async () => {
    vi.mocked(p.confirm).mockResolvedValueOnce(false);
    vi.mocked(p.isCancel).mockReturnValue(false);

    const result = await confirmEmptyDirectory("/test/path");
    expect(result).toBe(false);
  });
});
