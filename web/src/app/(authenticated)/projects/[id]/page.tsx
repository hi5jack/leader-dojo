import { unstable_noStore as noStore } from "next/cache";
import { headers } from "next/headers";
import { notFound, redirect } from "next/navigation";
import Link from "next/link";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Plus, CheckSquare } from "lucide-react";
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
    <div className="section-gap">
      {/* Project Header */}
      <div className="space-y-4">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div className="flex-1">
            <p className="text-sm text-muted-foreground">Project</p>
            <h1>{project.name}</h1>
            <div className="mt-2 flex flex-wrap items-center gap-2">
              <Badge variant="secondary" size="lg">{project.type}</Badge>
              <Badge
                variant={
                  project.status === "active"
                    ? "success"
                    : project.status === "on_hold"
                    ? "warning"
                    : "outline"
                }
                size="lg"
              >
                {project.status.replace("_", " ")}
              </Badge>
              <Badge variant="outline" size="lg">Priority {project.priority}</Badge>
            </div>
          </div>
          {/* Desktop Actions */}
          <div className="hidden md:flex gap-3">
            <PrepDrawer projectId={id} />
            <Button asChild>
              <Link href={`/projects/${id}/entries/new`}>
                <Plus className="w-4 h-4 mr-2" />
                Add entry
              </Link>
            </Button>
          </div>
        </div>

        {project.description && (
          <p className="text-sm text-muted-foreground">{project.description}</p>
        )}

        {project.ownerNotes && (
          <Card variant="elevated" padding="mobile">
            <CardContent className="p-4">
              <p className="text-xs font-medium text-muted-foreground mb-2">Owner notes</p>
              <p className="text-sm">{project.ownerNotes}</p>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Mobile Tabs / Desktop 2-Column */}
      <div className="md:hidden">
        <Tabs defaultValue="timeline" className="w-full">
          <TabsList className="w-full grid grid-cols-3">
            <TabsTrigger value="timeline">Timeline</TabsTrigger>
            <TabsTrigger value="commitments">
              Commits ({commitments.length})
            </TabsTrigger>
            <TabsTrigger value="overview">Overview</TabsTrigger>
          </TabsList>

          <TabsContent value="timeline" className="mt-6">
            <ProjectTimeline entries={entries} projectId={id} />
          </TabsContent>

          <TabsContent value="commitments" className="mt-6 space-y-3">
            {commitments.length === 0 ? (
              <p className="text-sm text-muted-foreground py-8 text-center">
                No outstanding commitments
              </p>
            ) : (
              commitments.map((commitment) => (
                <Card key={commitment.id} variant="interactive">
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex-1 min-w-0">
                        <p className="font-medium mb-1">{commitment.title}</p>
                        <p className="text-sm text-muted-foreground">
                          Due:{" "}
                          {commitment.dueDate
                            ? new Date(commitment.dueDate).toLocaleDateString()
                            : "TBD"}
                        </p>
                      </div>
                      <Badge
                        variant={commitment.direction === "i_owe" ? "i-owe" : "waiting-for"}
                        size="lg"
                      >
                        {commitment.direction === "i_owe" ? "I Owe" : "Waiting"}
                      </Badge>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </TabsContent>

          <TabsContent value="overview" className="mt-6">
            <Card>
              <CardContent className="p-4 space-y-4">
                <div>
                  <p className="text-sm font-medium text-muted-foreground mb-1">Type</p>
                  <p className="text-base">{project.type}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground mb-1">Status</p>
                  <p className="text-base">{project.status.replace("_", " ")}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground mb-1">Priority</p>
                  <p className="text-base">{project.priority}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground mb-1">Last Active</p>
                  <p className="text-base">
                    {project.lastActiveAt
                      ? new Date(project.lastActiveAt).toLocaleDateString()
                      : "Never"}
                  </p>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>

      {/* Desktop 2-Column Layout */}
      <div className="hidden md:grid gap-6 lg:grid-cols-[2fr_1fr]">
        <Card variant="elevated" padding="mobile">
          <CardHeader>
            <CardTitle>Timeline</CardTitle>
          </CardHeader>
          <CardContent>
            <ProjectTimeline entries={entries} projectId={id} />
          </CardContent>
        </Card>

        <Card variant="elevated" padding="mobile">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <CheckSquare className="w-5 h-5" />
              Open Commitments
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {commitments.length === 0 ? (
              <p className="text-sm text-muted-foreground">Nothing outstanding.</p>
            ) : (
              commitments.map((commitment) => (
                <Card key={commitment.id} variant="interactive" className="shadow-none">
                  <CardContent className="p-3">
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex-1">
                        <p className="font-medium text-sm">{commitment.title}</p>
                        <p className="text-xs text-muted-foreground">
                          Due:{" "}
                          {commitment.dueDate
                            ? new Date(commitment.dueDate).toLocaleDateString()
                            : "TBD"}
                        </p>
                      </div>
                      <Badge
                        variant={commitment.direction === "i_owe" ? "i-owe" : "waiting-for"}
                      >
                        {commitment.direction === "i_owe" ? "I Owe" : "Waiting"}
                      </Badge>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </CardContent>
        </Card>
      </div>

      {/* Mobile FAB-style CTA */}
      <div className="md:hidden">
        <Button
          size="icon-lg"
          className="fixed bottom-20 right-4 md:bottom-6 md:right-6 rounded-full shadow-elevation-lg"
          asChild
        >
          <Link href={`/projects/${id}/entries/new`}>
            <Plus className="w-6 h-6" />
            <span className="sr-only">Add entry</span>
          </Link>
        </Button>
      </div>
    </div>
  );
}

