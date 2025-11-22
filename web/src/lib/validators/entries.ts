import { z } from "zod";

export const createEntrySchema = z.object({
  title: z.string().min(2).max(200),
  kind: z.enum(["meeting", "update", "decision", "note", "prep", "reflection", "self_note"]),
  occurredAt: z.coerce.date(),
  rawContent: z.string().optional(),
  decisions: z.string().optional(),
});

