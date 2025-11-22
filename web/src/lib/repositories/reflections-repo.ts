import type { SQL } from "drizzle-orm";
import { and, desc, eq } from "drizzle-orm";

import { db } from "@/lib/db/client";
import type { DbClient } from "@/lib/db/client";
import { reflections } from "@/lib/db/schema";
import type { NewReflection } from "@/lib/db/types";

type ReflectionFilters = {
  periodType?: typeof reflections.$inferSelect.periodType;
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
    const where = this.buildWhere([
      eq(reflections.userId, userId),
      filters.periodType ? eq(reflections.periodType, filters.periodType) : undefined,
    ]);

    return this.database.query.reflections.findMany({
      where,
      orderBy: desc(reflections.periodStart),
    });
  }

  async findByPeriod(
    userId: string,
    periodType: typeof reflections.$inferSelect.periodType,
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
}

