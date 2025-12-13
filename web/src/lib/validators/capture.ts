import { z } from "zod";

// Base capture schema with common fields
const baseCaptureSchema = z.object({
  projectId: z.string().uuid(),
  title: z.string().min(1).max(200),
  occurredAt: z.coerce.date().optional(),
  rawContent: z.string().optional(),
});

// Entry type specific fields
const commitmentFieldsSchema = z.object({
  kind: z.literal("commitment"),
  direction: z.enum(["i_owe", "waiting_for"]).default("i_owe"),
  counterparty: z.string().optional(),
  dueDate: z.coerce.date().optional(),
  importance: z.number().min(1).max(5).default(3),
  urgency: z.number().min(1).max(5).default(3),
  notes: z.string().optional(),
});

const reflectionFieldsSchema = z.object({
  kind: z.literal("reflection"),
  questionsAndAnswers: z
    .array(
      z.object({
        question: z.string(),
        answer: z.string(),
      }),
    )
    .optional(),
  // Period fields are optional for ad-hoc reflections
  periodType: z.enum(["week", "month", "quarter"]).optional(),
  periodStart: z.coerce.date().optional(),
  periodEnd: z.coerce.date().optional(),
});

const simpleEntryFieldsSchema = z.object({
  kind: z.enum(["meeting", "update", "decision", "note", "prep"]),
});

// Discriminated union for different entry types
export const captureInputSchema = z.discriminatedUnion("kind", [
  baseCaptureSchema.merge(commitmentFieldsSchema),
  baseCaptureSchema.merge(reflectionFieldsSchema),
  baseCaptureSchema.merge(simpleEntryFieldsSchema),
]);

export type CaptureInput = z.infer<typeof captureInputSchema>;

// Type guards for narrowing
export function isCommitmentCapture(
  input: CaptureInput,
): input is CaptureInput & { kind: "commitment" } {
  return input.kind === "commitment";
}

export function isReflectionCapture(
  input: CaptureInput,
): input is CaptureInput & { kind: "reflection" } {
  return input.kind === "reflection";
}














