import { z } from "zod";

export const createProjectSchema = z.object({
  name: z.string().min(2).max(180),
  description: z.string().optional(),
  type: z.enum(["project", "relationship", "area"]).default("project"),
  status: z.enum(["active", "on_hold", "completed", "archived"]).default("active"),
  priority: z.number().min(1).max(5).default(3),
  ownerNotes: z.string().optional(),
});

export const updateProjectSchema = createProjectSchema.partial();

