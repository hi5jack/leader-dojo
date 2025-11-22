import { redirect } from "next/navigation";

import { ProjectsTable } from "./projects-table";
import { CreateProjectDialog } from "./create-project-dialog";
import { ProjectsService } from "@/lib/services";
import { getCurrentSession } from "@/lib/auth/session";

const projectsService = new ProjectsService();

export default async function ProjectsPage() {
  const session = await getCurrentSession();
  if (!session?.user?.id) {
    redirect("/auth/signin");
  }

  const projects = await projectsService.listProjects(session.user.id);

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-semibold tracking-tight">Projects</h1>
          <p className="text-muted-foreground">
            Track active bets, relationships, and areas.
          </p>
        </div>
        <CreateProjectDialog />
      </div>
      <ProjectsTable projects={projects} />
    </div>
  );
}

