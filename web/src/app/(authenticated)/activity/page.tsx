import { redirect } from "next/navigation";
import { Activity } from "lucide-react";

import { getCurrentSession } from "@/lib/auth/session";
import { EntriesService, ProjectsService } from "@/lib/services";
import { ActivityTimeline } from "./activity-timeline";

const entriesService = new EntriesService();
const projectsService = new ProjectsService();

export default async function ActivityPage() {
  const session = await getCurrentSession();
  if (!session?.user?.id) {
    redirect("/auth/signin");
  }

  const [entries, projects] = await Promise.all([
    entriesService.getAllEntriesWithProjects(session.user.id, { limit: 50 }),
    projectsService.listProjects(session.user.id),
  ]);

  return (
    <div className="section-gap">
      {/* Header */}
      <div className="space-y-2">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-primary/10 text-primary">
            <Activity className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-2xl md:text-3xl font-bold">Activity</h1>
            <p className="text-muted-foreground">
              Review your recent entries across all projects
            </p>
          </div>
        </div>
      </div>

      {/* Timeline with filters */}
      <ActivityTimeline 
        initialEntries={entries} 
        projects={projects.map((p) => ({ id: p.id, name: p.name }))}
      />
    </div>
  );
}

