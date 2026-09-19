import { z } from "zod";

const identifier = z
  .string()
  .trim()
  .min(3)
  .max(63)
  .regex(/^[a-z0-9][a-z0-9-]*$/, "Use lowercase letters, numbers, and hyphens.");

const packageName = z
  .string()
  .trim()
  .min(3)
  .max(63)
  .regex(/^[a-z][a-z0-9_]*$/, "Use lowercase letters, numbers, and underscores.");

export const InstallConfigSchema = z.object({
  project: z.object({
    name: identifier,
    title: z.string().trim().min(1).max(120),
    directory: z.string().trim().min(1),
  }),
  admin: z.object({
    username: z.string().trim().min(1).max(64),
    name: z.string().trim().min(1).max(120),
    email: z.email(),
    url: z.url().optional(),
    password: z
      .string()
      .min(8, "Use at least eight characters.")
      .regex(/[A-Z]/, "Include an uppercase letter.")
      .regex(/[a-z]/, "Include a lowercase letter.")
      .regex(/[0-9]/, "Include a number.")
      .regex(/[^a-zA-Z0-9]/, "Include a special character.")
      .optional(),
  }),
  ddev: z.object({
    phpVersion: z.string().regex(/^8\.[34]$/, "Use PHP 8.3 or 8.4."),
    serverType: z.enum(["apache", "nginx"]),
  }),
  database: z.object({
    driver: z.literal("mysqli"),
    host: z.string().trim().min(1),
    port: z.coerce.number().int().min(1).max(65535),
    name: z.string().trim().min(1),
    user: z.string().trim().min(1),
    password: z.string().min(1),
  }),
  sitepackage: z.object({
    vendor: identifier,
    name: packageName,
  }),
  features: z.object({
    viteSidecar: z.boolean(),
    rector: z.boolean(),
    playwright: z.boolean(),
  }),
});
