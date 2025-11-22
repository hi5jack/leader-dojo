import { redirect } from "next/navigation";

import { EntryComposer } from "./entry-composer";
import { ProjectsService } from "@/lib/services";
import { getCurrentSession } from "@/lib/auth/session";

type Params = {
  id: string;
};

const projectsService = new ProjectsService();

export default async function NewEntryPage({ params }: { params: Params }) {
  const session = await getCurrentSession();
  if (!session?.user?.id) {
    redirect("/auth/signin");
  }

  const project = await projectsService.getProject(session.user.id, params.id);
  if (!project) {
    redirect("/projects");
  }

  return (
    <div className="space-y-6">
      <div>
        <p className="text-sm text-muted-foreground">New entry</p>
        <h1 className="text-3xl font-semibold">{project.name}</h1>
      </div>
      <EntryComposer projectId={project.id} />
    </div>
  );
}

