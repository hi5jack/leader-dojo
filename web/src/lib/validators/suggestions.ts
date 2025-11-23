import { z } from "zod";

export const suggestedActionSchema = z.object({
  title: z.string().min(2),
  direction: z.enum(["i_owe", "waiting_for"]),
  counterparty: z.string().optional(),
  dueDate: z.string().optional(),
  notes: z.string().optional(),
  importance: z.coerce.number().min(1).max(5).optional(),
  urgency: z.coerce.number().min(1).max(5).optional(),
});

export const suggestedActionsSchema = z.object({
  projectId: z.string().uuid(),
  actions: z.array(suggestedActionSchema),
});

