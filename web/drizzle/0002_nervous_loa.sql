ALTER TABLE "project_entries" ALTER COLUMN "kind" SET DATA TYPE text;--> statement-breakpoint
ALTER TABLE "project_entries" ALTER COLUMN "kind" SET DEFAULT 'meeting'::text;--> statement-breakpoint
DROP TYPE "public"."entry_kind";--> statement-breakpoint
CREATE TYPE "public"."entry_kind" AS ENUM('meeting', 'update', 'decision', 'note', 'prep', 'reflection', 'commitment');--> statement-breakpoint
ALTER TABLE "project_entries" ALTER COLUMN "kind" SET DEFAULT 'meeting'::"public"."entry_kind";--> statement-breakpoint
ALTER TABLE "project_entries" ALTER COLUMN "kind" SET DATA TYPE "public"."entry_kind" USING "kind"::"public"."entry_kind";--> statement-breakpoint
ALTER TABLE "reflections" ALTER COLUMN "period_type" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "reflections" ALTER COLUMN "period_start" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "reflections" ALTER COLUMN "period_end" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "reflections" ALTER COLUMN "stats" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "reflections" ALTER COLUMN "ai_questions" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "reflections" ADD COLUMN "project_id" uuid;--> statement-breakpoint
ALTER TABLE "reflections" ADD COLUMN "entry_id" uuid;--> statement-breakpoint
ALTER TABLE "reflections" ADD CONSTRAINT "reflections_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "reflections" ADD CONSTRAINT "reflections_entry_id_project_entries_id_fk" FOREIGN KEY ("entry_id") REFERENCES "public"."project_entries"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "reflections_project_idx" ON "reflections" USING btree ("project_id","created_at");