import { z } from "zod";

export const registerSchema = z.object({
  name: z.string().min(2).max(120),
  email: z.string().email(),
  password: z.string().min(8).max(64),
});

export type RegisterInput = z.infer<typeof registerSchema>;

export const mobileLoginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

export type MobileLoginInput = z.infer<typeof mobileLoginSchema>;

