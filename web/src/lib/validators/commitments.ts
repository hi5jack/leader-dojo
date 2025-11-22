import { z } from "zod";

export const createCommitmentSchema = z.object({
  projectId: z.string().uuid(),
  entryId: z.string().uuid().optional(),
  title: z.string().min(2).max(200),
  direction: z.enum(["i_owe", "waiting_for"]).default("i_owe"),
  counterparty: z.string().optional(),
  dueDate: z.coerce.date().optional(),
  importance: z.number().min(1).max(5).default(3),
  urgency: z.number().min(1).max(5).default(3),
  notes: z.string().optional(),
});

export const updateCommitmentSchema = createCommitmentSchema
  .omit({ projectId: true })
  .partial()
  .extend({
    status: z.enum(["open", "done", "blocked", "dropped"]).optional(),
  });

