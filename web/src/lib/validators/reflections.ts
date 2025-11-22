import { z } from "zod";

export const reflectionRequestSchema = z.object({
  periodType: z.enum(["week", "month", "quarter"]),
  periodStart: z.coerce.date(),
  periodEnd: z.coerce.date(),
  answers: z
    .array(
      z.object({
        question: z.string(),
        answer: z.string(),
      }),
    )
    .optional(),
});

