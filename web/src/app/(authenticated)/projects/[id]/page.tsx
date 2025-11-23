import { unstable_noStore as noStore } from "next/cache";
import { headers } from "next/headers";
import { notFound, redirect } from "next/navigation";
import Link from "next/link";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { CommitmentsService, EntriesService } from "@/lib/services";
import { getCurrentSession } from "@/lib/auth/session";
import { env } from "@/lib/config/env";
import type { Project } from "@/lib/db/types";
import { ProjectTimeline } from "./project-timeline";
import { PrepDrawer } from "./prep-drawer";

type Params = {
  id: string;
};

const entriesService = new EntriesService();
const commitmentsService = new CommitmentsService();

export const dynamic = "force-dynamic";

export default async function ProjectDetailPage({ params }: { params: Promise<Params> }) {
  noStore();
  const session = await getCurrentSession();
  if (!session?.user?.id) {
    redirect("/auth/signin");
  }

  const headersList = await headers();
  const cookieHeader = headersList.get("cookie") ?? "";
  const { id } = await params;
  const baseUrl = env.APP_BASE_URL ?? env.NEXTAUTH_URL ?? "http://localhost:3000";

  const projectResponse = await fetch(`${baseUrl}/api/secure/projects/${id}`, {
    cache: "no-store",
    headers: {
      cookie: cookieHeader,
    },
  });

  if (projectResponse.status === 404) {
    notFound();
  }

  if (!projectResponse.ok) {
    throw new Error("Failed to load project");
  }

  const project = (await projectResponse.json()) as Project;

  const [entries, commitments] = await Promise.all([
    entriesService.getTimeline(session.user.id, id),
    commitmentsService.listCommitments(session.user.id, {
      projectId: id,
      statuses: ["open"],
    }),
  ]);

  return (
    <div className="space-y-8">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex-1">
          <p className="text-sm text-muted-foreground">Project</p>
          <h1 className="text-3xl font-semibold">{project.name}</h1>
          <div className="mt-2 flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
            <Badge variant="secondary">{project.type}</Badge>
            <Badge variant="outline">{project.status}</Badge>
            <span>Priority {project.priority}</span>
          </div>
          {project.description && (
            <p className="mt-3 text-sm max-w-2xl">
              {project.description}
            </p>
          )}
          {project.ownerNotes && (
            <div className="mt-3 rounded-lg bg-muted p-3 max-w-2xl">
              <p className="text-xs font-medium text-muted-foreground mb-1">Owner notes</p>
              <p className="text-sm">{project.ownerNotes}</p>
            </div>
          )}
        </div>
        <div className="flex flex-wrap gap-3">
          <PrepDrawer projectId={id} />
          <Button asChild>
            <Link href={`/projects/${id}/entries/new`}>Add entry</Link>
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

