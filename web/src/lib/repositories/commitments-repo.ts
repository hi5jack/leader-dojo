import type { SQL } from "drizzle-orm";
import { and, desc, eq, gte, inArray, lte } from "drizzle-orm";

import { db } from "@/lib/db/client";
import type { DbClient } from "@/lib/db/client";
import { commitments } from "@/lib/db/schema";
import type { NewCommitment } from "@/lib/db/types";

type CommitmentFilters = {
  directions?: (typeof commitments.$inferSelect.direction)[];
  statuses?: (typeof commitments.$inferSelect.status)[];
  projectId?: string;
  dueBefore?: Date;
  dueAfter?: Date;
};

export class CommitmentsRepository {
  constructor(private readonly database: DbClient = db) {}

  private buildWhere(conditions: Array<SQL | undefined>) {
    const defined = conditions.filter(Boolean) as SQL[];
    return defined.length ? and(...defined) : undefined;
  }

  async createCommitment(input: NewCommitment) {
    const [created] = await this.database
      .insert(commitments)
      .values(input)
      .returning();
    return created;
  }

  async createMany(inputs: NewCommitment[]) {
    if (!inputs.length) return [];
    return this.database.insert(commitments).values(inputs).returning();
  }

  async listCommitments(userId: string, filters: CommitmentFilters = {}) {
    const where = this.buildWhere([
      eq(commitments.userId, userId),
      filters.projectId ? eq(commitments.projectId, filters.projectId) : undefined,
      filters.directions
        ? inArray(commitments.direction, filters.directions)
        : undefined,
      filters.statuses ? inArray(commitments.status, filters.statuses) : undefined,
      filters.dueAfter ? gte(commitments.dueDate, filters.dueAfter) : undefined,
      filters.dueBefore ? lte(commitments.dueDate, filters.dueBefore) : undefined,
    ]);

    return this.database.query.commitments.findMany({
      where,
      orderBy: desc(commitments.dueDate),
    });
  }

  async findById(userId: string, commitmentId: string) {
    return this.database.query.commitments.findFirst({
      where: and(eq(commitments.id, commitmentId), eq(commitments.userId, userId)),
    });
  }

  async updateCommitment(
    userId: string,
    commitmentId: string,
    input: Partial<NewCommitment>,
  ) {
    const [updated] = await this.database
      .update(commitments)
      .set({ ...input, updatedAt: new Date() })
      .where(and(eq(commitments.id, commitmentId), eq(commitments.userId, userId)))
      .returning();

    return updated ?? null;
  }
}

