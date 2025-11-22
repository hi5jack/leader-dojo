import { z } from "zod";

const envSchema = z.object({
  DATABASE_URL: z
    .string()
    .url()
    .default("postgres://user:pass@localhost:5432/leaderdojo"),
  NEXTAUTH_SECRET: z
    .string()
    .min(20)
    .default("dev-secret-change-me-1234567890"),
  NEXTAUTH_URL: z.string().url().optional(),
  OPENAI_API_KEY: z.string().min(1).default("sk-test-1234567890"),
  AI_PROVIDER: z.enum(["openai"]).default("openai"),
  APP_BASE_URL: z.string().url().optional(),
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
});

export type Env = z.infer<typeof envSchema>;

export const env: Env = envSchema.parse({
  DATABASE_URL: process.env.DATABASE_URL,
  NEXTAUTH_SECRET: process.env.NEXTAUTH_SECRET ?? process.env.AUTH_SECRET,
  NEXTAUTH_URL: process.env.NEXTAUTH_URL ?? process.env.APP_BASE_URL,
  OPENAI_API_KEY: process.env.OPENAI_API_KEY,
  AI_PROVIDER: process.env.AI_PROVIDER ?? "openai",
  APP_BASE_URL: process.env.APP_BASE_URL ?? process.env.NEXTAUTH_URL,
  NODE_ENV: process.env.NODE_ENV,
});

