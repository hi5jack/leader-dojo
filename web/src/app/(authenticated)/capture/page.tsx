import { redirect } from "next/navigation";

import { CaptureForm } from "./capture-form";
import { ProjectsService } from "@/lib/services";
import { getCurrentSession } from "@/lib/auth/session";

const projectsService = new ProjectsService();

export default async function CapturePage() {
  const session = await getCurrentSession();
  if (!session?.user?.id) {
    redirect("/auth/signin");
  }

  const projects = await projectsService.listProjects(session.user.id);

  return (
    <div className="space-y-4 sm:space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Quick capture</h1>
        <p className="text-sm text-muted-foreground">
          Fast mobile-friendly capture for thoughts and conversations.
        </p>
      </div>
      <CaptureForm projects={projects} />
    </div>
  );
}

