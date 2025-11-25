import type { SQL } from "drizzle-orm";
import { and, desc, eq, isNull } from "drizzle-orm";

import { db } from "@/lib/db/client";
import type { DbClient } from "@/lib/db/client";
import { reflections } from "@/lib/db/schema";
import type { NewReflection } from "@/lib/db/types";

type ReflectionFilters = {
  periodType?: NonNullable<typeof reflections.$inferSelect.periodType>;
  projectId?: string;
  isAdHoc?: boolean; // Filter for ad-hoc (no period) reflections
};

export class ReflectionsRepository {
  constructor(private readonly database: DbClient = db) {}

  private buildWhere(conditions: Array<SQL | undefined>) {
    const defined = conditions.filter(Boolean) as SQL[];
    return defined.length ? and(...defined) : undefined;
  }

  async createReflection(input: NewReflection) {
    const [created] = await this.database
      .insert(reflections)
      .values(input)
      .returning();
    return created;
  }

  async listReflections(userId: string, filters: ReflectionFilters = {}) {
    const conditions: Array<SQL | undefined> = [
      eq(reflections.userId, userId),
      filters.periodType ? eq(reflections.periodType, filters.periodType) : undefined,
      filters.projectId ? eq(reflections.projectId, filters.projectId) : undefined,
    ];

    // If filtering for ad-hoc reflections, include those without period data
    if (filters.isAdHoc) {
      conditions.push(isNull(reflections.periodType));
    }

    const where = this.buildWhere(conditions);

    return this.database.query.reflections.findMany({
      where,
      orderBy: desc(reflections.createdAt),
    });
  }

  async findByPeriod(
    userId: string,
    periodType: NonNullable<typeof reflections.$inferSelect.periodType>,
    periodStart: Date,
  ) {
    return this.database.query.reflections.findFirst({
      where: and(
        eq(reflections.userId, userId),
        eq(reflections.periodType, periodType),
        eq(reflections.periodStart, periodStart),
      ),
    });
  }

  // Create an ad-hoc reflection (no period constraints)
  async createAdHocReflection(input: Omit<NewReflection, "periodType" | "periodStart" | "periodEnd" | "stats" | "aiQuestions"> & {
    periodType?: NewReflection["periodType"];
    periodStart?: NewReflection["periodStart"];
    periodEnd?: NewReflection["periodEnd"];
    stats?: NewReflection["stats"];
    aiQuestions?: NewReflection["aiQuestions"];
  }) {
    const [created] = await this.database
      .insert(reflections)
      .values({
        ...input,
        stats: input.stats ?? null,
        aiQuestions: input.aiQuestions ?? null,
      })
      .returning();
    return created;
  }

  // Get reflections by project
  async listByProject(userId: string, projectId: string) {
    return this.database.query.reflections.findMany({
      where: and(
        eq(reflections.userId, userId),
        eq(reflections.projectId, projectId),
      ),
      orderBy: desc(reflections.createdAt),
    });
  }

  // Get reflection by entry ID
  async findByEntryId(userId: string, entryId: string) {
    return this.database.query.reflections.findFirst({
      where: and(
        eq(reflections.userId, userId),
        eq(reflections.entryId, entryId),
      ),
    });
  }
}

