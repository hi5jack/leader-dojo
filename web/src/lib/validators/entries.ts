import { z } from "zod";

export const createEntrySchema = z.object({
  title: z.string().min(2).max(200),
  kind: z.enum(["meeting", "update", "decision", "note", "prep", "reflection"]),
  occurredAt: z.coerce.date(),
  rawContent: z.string().optional(),
  decisions: z.string().optional(),
});

export const updateEntrySchema = z.object({
  title: z.string().min(2).max(200).optional(),
  kind: z.enum(["meeting", "update", "decision", "note", "prep", "reflection"]).optional(),
  occurredAt: z.coerce.date().optional(),
  rawContent: z.string().optional(),
  decisions: z.string().optional(),
});

