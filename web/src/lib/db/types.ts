import {
  commitments,
  projectEntries,
  projects,
  reflections,
  users,
} from "@/lib/db/schema";

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;

export type Project = typeof projects.$inferSelect;
export type NewProject = typeof projects.$inferInsert;

export type ProjectEntry = typeof projectEntries.$inferSelect;
export type NewProjectEntry = typeof projectEntries.$inferInsert;

export type Commitment = typeof commitments.$inferSelect;
export type NewCommitment = typeof commitments.$inferInsert;

export type Reflection = typeof reflections.$inferSelect;
export type NewReflection = typeof reflections.$inferInsert;

// Unified capture response type
export type CaptureResult = {
  entryId: string;
  commitmentId?: string;
  reflectionId?: string;
};

