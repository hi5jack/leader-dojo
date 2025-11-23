import { redirect } from "next/navigation";
import { Mic } from "lucide-react";

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
    <div className="section-gap max-w-2xl mx-auto">
      <div className="text-center md:text-left">
        <h1>Quick Capture</h1>
        <p className="text-muted-foreground mt-1">
          Capture thoughts, conversations, and insights on the go
        </p>
        <div className="mt-2 flex items-center justify-center md:justify-start gap-2 text-sm text-muted-foreground">
          <Mic className="w-4 h-4" />
          <span>Voice input coming soon</span>
        </div>
      </div>
      <CaptureForm projects={projects} />
    </div>
  );
}

