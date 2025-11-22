import type { SQL } from "drizzle-orm";
import { and, desc, eq, gte, inArray, lte } from "drizzle-orm";

import { db } from "@/lib/db/client";
import type { DbClient } from "@/lib/db/client";
import { projects } from "@/lib/db/schema";
import type { NewProject } from "@/lib/db/types";

type ListProjectsFilters = {
  status?: (typeof projects.$inferSelect.status)[];
  type?: (typeof projects.$inferSelect.type)[];
  priority?: number[];
};

type IdleProjectsFilter = {
  userId: string;
  minPriority?: number;
  lastActiveBefore: Date;
};

export class ProjectsRepository {
  constructor(private readonly database: DbClient = db) {}

  private buildWhere(
    conditions: Array<SQL | undefined>,
  ): SQL | undefined {
    const defined = conditions.filter(Boolean) as SQL[];
    return defined.length ? and(...defined) : undefined;
  }

  async createProject(input: NewProject) {
    const [created] = await this.database
      .insert(projects)
      .values(input)
      .returning();

    return created;
  }

  async updateProject(userId: string, projectId: string, input: Partial<NewProject>) {
    const [updated] = await this.database
      .update(projects)
      .set({
        ...input,
        updatedAt: new Date(),
      })
      .where(and(eq(projects.id, projectId), eq(projects.userId, userId)))
      .returning();

    return updated ?? null;
  }

  async findById(userId: string, projectId: string) {
    return this.database.query.projects.findFirst({
      where: and(eq(projects.id, projectId), eq(projects.userId, userId)),
    });
  }

  async listByUser(userId: string, filters: ListProjectsFilters = {}) {
    const where = this.buildWhere([
      eq(projects.userId, userId),
      filters.status ? inArray(projects.status, filters.status) : undefined,
      filters.type ? inArray(projects.type, filters.type) : undefined,
      filters.priority ? inArray(projects.priority, filters.priority) : undefined,
    ]);

    return this.database.query.projects.findMany({
      where,
      orderBy: desc(projects.lastActiveAt),
    });
  }

  async findIdleProjects(filter: IdleProjectsFilter) {
    const where = this.buildWhere([
      eq(projects.userId, filter.userId),
      filter.minPriority ? gte(projects.priority, filter.minPriority) : undefined,
      lte(projects.lastActiveAt, filter.lastActiveBefore),
      eq(projects.status, "active"),
    ]);

    return this.database.query.projects.findMany({
      where,
      orderBy: desc(projects.priority),
      limit: 5,
    });
  }

  async updateLastActive(userId: string, projectId: string, lastActiveAt: Date) {
    await this.database
      .update(projects)
      .set({ lastActiveAt, updatedAt: new Date() })
      .where(
        and(eq(projects.id, projectId), eq(projects.userId, userId)),
      );
  }
}

