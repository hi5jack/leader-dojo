import { redirect } from "next/navigation";
import { Plus } from "lucide-react";

import { ProjectsTable } from "./projects-table";
import { CreateProjectDialog } from "./create-project-dialog";
import { Fab } from "@/components/ui/fab";
import { Button } from "@/components/ui/button";
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
    <div className="section-gap">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1>Projects</h1>
          <p className="text-muted-foreground">
            Track active bets, relationships, and areas
          </p>
        </div>
        {/* Desktop Create Button */}
        <div className="hidden md:block">
          <CreateProjectDialog />
        </div>
      </div>
      
      <ProjectsTable projects={projects} />

      {/* Mobile FAB */}
      <div className="md:hidden">
        <CreateProjectDialog>
          <Fab icon={<Plus className="w-6 h-6" />} />
        </CreateProjectDialog>
      </div>
    </div>
  );
}

