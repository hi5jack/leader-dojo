import type { SQL } from "drizzle-orm";
import { and, desc, eq, gte, inArray, lte } from "drizzle-orm";

import { db } from "@/lib/db/client";
import type { DbClient } from "@/lib/db/client";
import { projectEntries } from "@/lib/db/schema";
import type { NewProjectEntry } from "@/lib/db/types";

type EntryFilters = {
  kinds?: (typeof projectEntries.$inferSelect.kind)[];
  occurredAfter?: Date;
  occurredBefore?: Date;
  projectId?: string;
};

export class EntriesRepository {
  constructor(private readonly database: DbClient = db) {}

  private buildWhere(conditions: Array<SQL | undefined>) {
    const defined = conditions.filter(Boolean) as SQL[];
    return defined.length ? and(...defined) : undefined;
  }

  async createEntry(input: NewProjectEntry) {
    const [created] = await this.database
      .insert(projectEntries)
      .values(input)
      .returning();

    return created;
  }

  async updateEntry(
    userId: string,
    entryId: string,
    input: Partial<NewProjectEntry>,
  ) {
    const [updated] = await this.database
      .update(projectEntries)
      .set({ ...input, updatedAt: new Date() })
      .where(and(eq(projectEntries.id, entryId), eq(projectEntries.userId, userId)))
      .returning();

    return updated ?? null;
  }

  async findById(userId: string, entryId: string) {
    return this.database.query.projectEntries.findFirst({
      where: and(eq(projectEntries.id, entryId), eq(projectEntries.userId, userId)),
    });
  }

  async listByProject(
    userId: string,
    projectId: string,
    filters: EntryFilters = {},
  ) {
    const where = this.buildWhere([
      eq(projectEntries.projectId, projectId),
      eq(projectEntries.userId, userId),
      filters.kinds ? inArray(projectEntries.kind, filters.kinds) : undefined,
      filters.occurredAfter
        ? gte(projectEntries.occurredAt, filters.occurredAfter)
        : undefined,
      filters.occurredBefore
        ? lte(projectEntries.occurredAt, filters.occurredBefore)
        : undefined,
    ]);

    return this.database.query.projectEntries.findMany({
      where,
      orderBy: desc(projectEntries.occurredAt),
    });
  }

  async listForUser(userId: string, filters: EntryFilters = {}) {
    const where = this.buildWhere([
      eq(projectEntries.userId, userId),
      filters.projectId ? eq(projectEntries.projectId, filters.projectId) : undefined,
      filters.kinds ? inArray(projectEntries.kind, filters.kinds) : undefined,
      filters.occurredAfter
        ? gte(projectEntries.occurredAt, filters.occurredAfter)
        : undefined,
      filters.occurredBefore
        ? lte(projectEntries.occurredAt, filters.occurredBefore)
        : undefined,
    ]);

    return this.database.query.projectEntries.findMany({
      where,
      orderBy: desc(projectEntries.occurredAt),
    });
  }

  async listByKind(userId: string, kind: typeof projectEntries.$inferSelect.kind) {
    return this.database.query.projectEntries.findMany({
      where: and(eq(projectEntries.userId, userId), eq(projectEntries.kind, kind)),
      orderBy: desc(projectEntries.occurredAt),
      limit: 20,
    });
  }
}

