import Link from "next/link";
import { redirect } from "next/navigation";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { DashboardService } from "@/lib/services";
import { getCurrentSession } from "@/lib/auth/session";

const dashboardService = new DashboardService();

export default async function DashboardPage() {
  const session = await getCurrentSession();
  if (!session?.user?.id) {
    redirect("/auth/signin");
  }

  const data = await dashboardService.getDashboardData(session.user.id);

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-semibold tracking-tight">Weekly focus</h1>
        <p className="text-muted-foreground">
          AI-prioritized commitments and projects that need your attention this week.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Top commitments</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {data.weeklyFocus.length === 0 ? (
              <p className="text-sm text-muted-foreground">No open commitments right now.</p>
            ) : (
              data.weeklyFocus.map((item) => (
                <div key={item.id} className="rounded-lg border p-3">
                  <div className="flex items-center justify-between">
                    <p className="font-medium">{item.title}</p>
                    <Badge variant={item.direction === "i_owe" ? "default" : "secondary"}>
                      {item.direction === "i_owe" ? "I Owe" : "Waiting For"}
                    </Badge>
                  </div>
                  <p className="text-sm text-muted-foreground">
                    {item.counterparty ? `Counterparty: ${item.counterparty}` : "No counterparty"}
                  </p>
                </div>
              ))
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Idle projects</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {data.idleProjects.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                All priority projects have recent activity.
              </p>
            ) : (
              data.idleProjects.map((project) => (
                <div key={project.id} className="rounded-lg border p-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium">{project.name}</p>
                      <p className="text-sm text-muted-foreground">
                        Last update: {project.lastActiveAt?.toLocaleDateString() ?? "Unknown"}
                      </p>
                    </div>
                    <Badge variant="secondary">Priority {project.priority}</Badge>
                  </div>
                </div>
              ))
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Pending reviews</CardTitle>
        </CardHeader>
        <CardContent className="flex gap-8 text-sm">
          <div>
            <p className="text-3xl font-semibold">{data.pending.decisionsNeedingReview}</p>
            <p className="text-muted-foreground">Decisions awaiting summary</p>
          </div>
          <div>
            <p className="text-3xl font-semibold">{data.pending.pendingReflections}</p>
            <p className="text-muted-foreground">Reflections to capture</p>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Reflection & decisions</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div>
            <p className="text-sm text-muted-foreground">
              Capture lessons from this week and close the loop on open decisions.
            </p>
          </div>
          <div className="flex gap-3">
            <Button variant="outline" asChild>
              <Link href="/commitments">Review commitments</Link>
            </Button>
            <Button asChild>
              <Link href="/reflections">Start reflection</Link>
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

