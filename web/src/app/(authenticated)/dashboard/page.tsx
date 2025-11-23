import Link from "next/link";
import { redirect } from "next/navigation";
import { CheckCircle2, Clock, FolderOpen, BookOpen, ArrowRight } from "lucide-react";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import { SwipeActions } from "@/components/ui/swipe-actions";
import { DashboardService } from "@/lib/services";
import { getCurrentSession } from "@/lib/auth/session";
import { cn } from "@/lib/utils";

const dashboardService = new DashboardService();

export default async function DashboardPage() {
  const session = await getCurrentSession();
  if (!session?.user?.id) {
    redirect("/auth/signin");
  }

  const data = await dashboardService.getDashboardData(session.user.id);
  const userName = session.user.name?.split(" ")[0] || "there";
  const greeting = getGreeting();

  return (
    <div className="section-gap">
      {/* Hero Section */}
      <div className="space-y-2">
        <h1 className="text-2xl md:text-3xl font-bold">
          {greeting}, {userName}
        </h1>
        <p className="text-muted-foreground">
          Here's what needs your attention this week
        </p>
      </div>

      {/* Weekly Focus - Top Priority */}
      <Card variant="elevated" padding="mobile">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <CheckCircle2 className="w-5 h-5 text-primary" />
              Top Commitments
            </CardTitle>
            <Button variant="ghost" size="sm" asChild>
              <Link href="/commitments" className="text-primary">
                View all <ArrowRight className="w-4 h-4 ml-1" />
              </Link>
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-3">
          {data.weeklyFocus.length === 0 ? (
            <EmptyState
              icon={<CheckCircle2 className="w-8 h-8" />}
              title="All clear!"
              description="No urgent commitments right now. Great work staying on top of things."
            />
          ) : (
            <>
              {data.weeklyFocus.slice(0, 3).map((item) => (
                <SwipeActions
                  key={item.id}
                  actions={[
                    {
                      label: "Done",
                      icon: <CheckCircle2 className="w-5 h-5" />,
                      onClick: () => {
                        // TODO: Mark as done
                        console.log("Mark done:", item.id);
                      },
                      variant: "success",
                    },
                  ]}
                >
                  <Card
                    variant="interactive"
                    className="border-0 shadow-none hover:shadow-none active:shadow-none"
                  >
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between gap-3">
                        <div className="flex-1 min-w-0">
                          <p className="font-medium mb-1 line-clamp-2">{item.title}</p>
                          <p className="text-sm text-muted-foreground">
                            {item.counterparty || "No counterparty"}
                          </p>
                        </div>
                        <Badge
                          variant={item.direction === "i_owe" ? "i-owe" : "waiting-for"}
                          size="lg"
                          className="shrink-0"
                        >
                          {item.direction === "i_owe" ? "I Owe" : "Waiting"}
                        </Badge>
                      </div>
                    </CardContent>
                  </Card>
                </SwipeActions>
              ))}
              {data.weeklyFocus.length > 3 && (
                <Button variant="outline" className="w-full" asChild>
                  <Link href="/commitments">
                    View {data.weeklyFocus.length - 3} more commitments
                  </Link>
                </Button>
              )}
            </>
          )}
        </CardContent>
      </Card>

      {/* Two Column Grid on Desktop */}
      <div className="grid gap-6 md:grid-cols-2">
        {/* Idle Projects */}
        <Card variant="elevated" padding="mobile">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Clock className="w-5 h-5 text-warning" />
              Idle Projects
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {data.idleProjects.length === 0 ? (
              <p className="text-sm text-muted-foreground py-4">
                All priority projects have recent activity 🎉
              </p>
            ) : (
              data.idleProjects.map((project) => {
                const daysIdle = project.lastActiveAt
                  ? Math.floor(
                      (Date.now() - new Date(project.lastActiveAt).getTime()) /
                        (1000 * 60 * 60 * 24)
                    )
                  : 0;

                return (
                  <Link key={project.id} href={`/projects/${project.id}`}>
                    <Card
                      variant="interactive"
                      accentColor={
                        daysIdle > 60 ? "var(--destructive)" : "var(--warning)"
                      }
                      className="border-l-4"
                    >
                      <CardContent className="p-4">
                        <div className="flex items-start justify-between gap-2">
                          <div className="flex-1 min-w-0">
                            <p className="font-medium mb-1">{project.name}</p>
                            <p className="text-sm text-muted-foreground">
                              {daysIdle} days idle
                            </p>
                          </div>
                          <Badge variant="outline" size="lg">
                            P{project.priority}
                          </Badge>
                        </div>
                      </CardContent>
                    </Card>
                  </Link>
                );
              })
            )}
          </CardContent>
        </Card>

        {/* Pending Reviews */}
        <Card variant="elevated" padding="mobile">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BookOpen className="w-5 h-5 text-primary" />
              Pending Reviews
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <p className="text-4xl font-bold text-primary">
                  {data.pending.decisionsNeedingReview}
                </p>
                <p className="text-sm text-muted-foreground">
                  Decisions awaiting review
                </p>
              </div>
              <div className="space-y-2">
                <p className="text-4xl font-bold text-accent">
                  {data.pending.pendingReflections}
                </p>
                <p className="text-sm text-muted-foreground">
                  Reflections to capture
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Action Card */}
      <Card className="gradient-primary text-white border-0" padding="mobile">
        <CardContent className="py-6 px-6">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
              <h3 className="text-lg font-semibold mb-1">Weekly Reflection</h3>
              <p className="text-white/90 text-sm">
                Capture lessons and close the loop on open decisions
              </p>
            </div>
            <div className="flex gap-3">
              <Button variant="outline" size="lg" asChild className="bg-white/10 border-white/20 text-white hover:bg-white/20">
                <Link href="/commitments">Review commitments</Link>
              </Button>
              <Button size="lg" asChild className="bg-white text-primary hover:bg-white/90">
                <Link href="/reflections">Start reflection</Link>
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function getGreeting() {
  const hour = new Date().getHours();
  if (hour < 12) return "Good morning";
  if (hour < 18) return "Good afternoon";
  return "Good evening";
}

