import {
  boolean,
  index,
  integer,
  jsonb,
  pgEnum,
  pgTable,
  primaryKey,
  text,
  timestamp,
  uniqueIndex,
  uuid,
  varchar,
} from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";

export const projectTypeEnum = pgEnum("project_type", [
  "project",
  "relationship",
  "area",
]);

export const projectStatusEnum = pgEnum("project_status", [
  "active",
  "on_hold",
  "completed",
  "archived",
]);

export const entryKindEnum = pgEnum("entry_kind", [
  "meeting",
  "update",
  "decision",
  "note",
  "prep",
  "reflection",
  "self_note",
]);

export const commitmentDirectionEnum = pgEnum("commitment_direction", [
  "i_owe",
  "waiting_for",
]);

export const commitmentStatusEnum = pgEnum("commitment_status", [
  "open",
  "done",
  "blocked",
  "dropped",
]);

export const reflectionPeriodEnum = pgEnum("reflection_period_type", [
  "week",
  "month",
  "quarter",
]);

export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 120 }),
  email: varchar("email", { length: 255 }).notNull().unique(),
  emailVerified: timestamp("email_verified", { withTimezone: true }),
  image: text("image"),
  hashedPassword: text("hashed_password"),
  timezone: varchar("timezone", { length: 60 }).default("UTC"),
  locale: varchar("locale", { length: 10 }).default("en-US"),
  role: varchar("role", { length: 20 }).default("member"),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
});

export const accounts = pgTable(
  "accounts",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id")
      .references(() => users.id, { onDelete: "cascade" })
      .notNull(),
    provider: varchar("provider", { length: 255 }).notNull(),
    providerAccountId: varchar("provider_account_id", {
      length: 255,
    }).notNull(),
    type: varchar("type", { length: 255 }).notNull(),
    refreshToken: text("refresh_token"),
    accessToken: text("access_token"),
    expiresAt: integer("expires_at"),
    tokenType: varchar("token_type", { length: 50 }),
    scope: text("scope"),
    idToken: text("id_token"),
    sessionState: text("session_state"),
  },
  (table) => ({
    providerIdx: uniqueIndex("accounts_provider_idx").on(
      table.provider,
      table.providerAccountId,
    ),
  }),
);

export const sessions = pgTable(
  "sessions",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id")
      .references(() => users.id, { onDelete: "cascade" })
      .notNull(),
    sessionToken: text("session_token").notNull(),
    expires: timestamp("expires", { withTimezone: true }).notNull(),
  },
  (table) => ({
    sessionTokenIdx: uniqueIndex("sessions_token_idx").on(table.sessionToken),
  }),
);

export const verificationTokens = pgTable(
  "verification_tokens",
  {
    identifier: varchar("identifier", { length: 255 }).notNull(),
    token: varchar("token", { length: 255 }).notNull(),
    expires: timestamp("expires", { withTimezone: true }).notNull(),
  },
  (table) => ({
    compositePk: primaryKey({
      columns: [table.identifier, table.token],
    }),
  }),
);

export const projects = pgTable(
  "projects",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id")
      .references(() => users.id, { onDelete: "cascade" })
      .notNull(),
    name: varchar("name", { length: 180 }).notNull(),
    description: text("description"),
    type: projectTypeEnum("type").default("project").notNull(),
    status: projectStatusEnum("status").default("active").notNull(),
    priority: integer("priority").default(3).notNull(),
    ownerNotes: text("owner_notes"),
    lastActiveAt: timestamp("last_active_at", { withTimezone: true }).defaultNow(),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    projectUserIdx: index("projects_user_idx").on(
      table.userId,
      table.lastActiveAt,
    ),
    projectStatusIdx: index("projects_status_idx").on(table.status),
  }),
);

export const projectEntries = pgTable(
  "project_entries",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id")
      .references(() => users.id, { onDelete: "cascade" })
      .notNull(),
    projectId: uuid("project_id")
      .references(() => projects.id, { onDelete: "cascade" })
      .notNull(),
    kind: entryKindEnum("kind").default("meeting").notNull(),
    title: varchar("title", { length: 200 }).notNull(),
    occurredAt: timestamp("occurred_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    rawContent: text("raw_content"),
    aiSummary: text("ai_summary"),
    decisions: text("decisions"),
    aiSuggestedActions: jsonb("ai_suggested_actions").$type<
      Record<string, unknown>[]
    >(),
    isDecision: boolean("is_decision").default(false).notNull(),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    deletedAt: timestamp("deleted_at", { withTimezone: true }),
  },
  (table) => ({
    entriesProjectIdx: index("entries_project_idx").on(
      table.projectId,
      table.occurredAt,
    ),
    entriesUserIdx: index("entries_user_idx").on(table.userId, table.kind),
  }),
);

export const commitments = pgTable(
  "commitments",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id")
      .references(() => users.id, { onDelete: "cascade" })
      .notNull(),
    projectId: uuid("project_id")
      .references(() => projects.id, { onDelete: "cascade" })
      .notNull(),
    entryId: uuid("entry_id").references(() => projectEntries.id, {
      onDelete: "set null",
    }),
    title: varchar("title", { length: 200 }).notNull(),
    direction: commitmentDirectionEnum("direction")
      .default("i_owe")
      .notNull(),
    status: commitmentStatusEnum("status").default("open").notNull(),
    counterparty: varchar("counterparty", { length: 180 }),
    dueDate: timestamp("due_date", { withTimezone: true }),
    importance: integer("importance").default(3).notNull(),
    urgency: integer("urgency").default(3).notNull(),
    notes: text("notes"),
    aiGenerated: boolean("ai_generated").default(false).notNull(),
    completedAt: timestamp("completed_at", { withTimezone: true }),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    commitmentsDirectionIdx: index("commitments_direction_idx").on(
      table.userId,
      table.direction,
      table.status,
    ),
    commitmentsDueDateIdx: index("commitments_due_idx").on(
      table.userId,
      table.dueDate,
    ),
  }),
);

export const reflections = pgTable(
  "reflections",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id")
      .references(() => users.id, { onDelete: "cascade" })
      .notNull(),
    periodType: reflectionPeriodEnum("period_type").notNull(),
    periodStart: timestamp("period_start", { withTimezone: true }).notNull(),
    periodEnd: timestamp("period_end", { withTimezone: true }).notNull(),
    stats: jsonb("stats").$type<Record<string, unknown>>().notNull(),
    questionsAndAnswers: jsonb("questions_answers")
      .$type<
        Array<{
          question: string;
          answer: string;
        }>
      >()
      .notNull(),
    aiQuestions: jsonb("ai_questions").$type<string[]>().notNull(),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    reflectionsPeriodIdx: index("reflections_period_idx").on(
      table.userId,
      table.periodType,
      table.periodStart,
    ),
  }),
);

export const userRelations = relations(users, ({ many }) => ({
  projects: many(projects),
  entries: many(projectEntries),
  commitments: many(commitments),
  reflections: many(reflections),
}));

export const projectRelations = relations(projects, ({ many }) => ({
  entries: many(projectEntries),
  commitments: many(commitments),
}));

export const entryRelations = relations(projectEntries, ({ one, many }) => ({
  project: one(projects, {
    fields: [projectEntries.projectId],
    references: [projects.id],
  }),
  commitments: many(commitments),
}));

export const commitmentRelations = relations(commitments, ({ one }) => ({
  project: one(projects, {
    fields: [commitments.projectId],
    references: [projects.id],
  }),
  entry: one(projectEntries, {
    fields: [commitments.entryId],
    references: [projectEntries.id],
  }),
}));

export const reflectionRelations = relations(reflections, ({ one }) => ({
  user: one(users, {
    fields: [reflections.userId],
    references: [users.id],
  }),
}));

