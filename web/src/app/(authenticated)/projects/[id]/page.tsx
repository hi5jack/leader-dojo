import { notFound, redirect } from "next/navigation";
import Link from "next/link";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { CommitmentsService, EntriesService, ProjectsService } from "@/lib/services";
import { getCurrentSession } from "@/lib/auth/session";
import { ProjectTimeline } from "./project-timeline";
import { PrepDrawer } from "./prep-drawer";

type Params = {
  id: string;
};

const projectsService = new ProjectsService();
const entriesService = new EntriesService();
const commitmentsService = new CommitmentsService();

export default async function ProjectDetailPage({ params }: { params: Params }) {
  const session = await getCurrentSession();
  if (!session?.user?.id) {
    redirect("/auth/signin");
  }

  const [project, entries, commitments] = await Promise.all([
    projectsService.getProject(session.user.id, params.id),
    entriesService.getTimeline(session.user.id, params.id),
    commitmentsService.listCommitments(session.user.id, {
      projectId: params.id,
      statuses: ["open"],
    }),
  ]);

  if (!project) {
    notFound();
  }

  return (
    <div className="space-y-8">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <p className="text-sm text-muted-foreground">Project</p>
          <h1 className="text-3xl font-semibold">{project.name}</h1>
          <div className="mt-2 flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
            <Badge variant="secondary">{project.type}</Badge>
            <Badge variant="outline">{project.status}</Badge>
            <span>Priority {project.priority}</span>
          </div>
        </div>
        <div className="flex flex-wrap gap-3">
          <PrepDrawer projectId={project.id} />
          <Button asChild>
            <Link href={`/projects/${project.id}/entries/new`}>Add entry</Link>
          </Button>
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-[2fr_1fr]">
        <Card>
          <CardHeader>
            <CardTitle>Timeline</CardTitle>
          </CardHeader>
          <CardContent>
            <ProjectTimeline entries={entries} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Open commitments</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {commitments.length === 0 ? (
              <p className="text-sm text-muted-foreground">Nothing outstanding.</p>
            ) : (
              commitments.map((commitment) => (
                <div key={commitment.id} className="rounded-lg border p-3">
                  <div className="flex items-center justify-between">
                    <p className="font-medium">{commitment.title}</p>
                    <Badge variant="outline">
                      {commitment.direction === "i_owe" ? "I Owe" : "Waiting For"}
                    </Badge>
                  </div>
                  <p className="text-sm text-muted-foreground">
                    Due {commitment.dueDate ? new Date(commitment.dueDate).toLocaleDateString() : "TBD"}
                  </p>
                </div>
              ))
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

