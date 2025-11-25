import Link from "next/link";
import { redirect } from "next/navigation";
import { 
  CheckCircle2, 
  Clock, 
  FolderOpen, 
  BookOpen, 
  ArrowRight,
  ListTodo,
  Hourglass,
  Activity,
  AlertTriangle,
} from "lucide-react";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import { StatCard } from "@/components/ui/stat-card";
import { DashboardService } from "@/lib/services";
import { getCurrentSession } from "@/lib/auth/session";
import { TopCommitments } from "./top-commitments";
import { RecentActivity } from "./recent-activity";

const dashboardService = new DashboardService();

export default async function DashboardPage() {
  const session = await getCurrentSession();
  if (!session?.user?.id) {
    redirect("/auth/signin");
  }

  const data = await dashboardService.getDashboardData(session.user.id);
  const userName = session.user.name?.split(" ")[0] || "there";
  const greeting = getGreeting();

  // Calculate status levels for stats
  const iOweStatus = data.stats.openIOwe > 10 ? "danger" : data.stats.openIOwe > 5 ? "warning" : "default";
  const waitingStatus = data.stats.waitingFor > 5 ? "warning" : "default";
  const reflectionStatus = data.stats.daysSinceReflection === null 
    ? "warning" 
    : data.stats.daysSinceReflection > 7 
      ? "danger" 
      : data.stats.daysSinceReflection > 3 
        ? "warning" 
        : "success";

  // Count needs attention items
  const needsAttentionCount = data.idleProjects.length + 
    (data.pending.decisionsNeedingReview > 0 ? 1 : 0) + 
    (data.pending.pendingReflections > 0 ? 1 : 0);

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

      {/* Stats Row */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 md:gap-4">
        <StatCard
          variant="compact"
          label="Open I Owe"
          value={data.stats.openIOwe}
          icon={<ListTodo className="w-4 h-4" />}
          status={iOweStatus}
        />
        <StatCard
          variant="compact"
          label="Waiting For"
          value={data.stats.waitingFor}
          icon={<Hourglass className="w-4 h-4" />}
          status={waitingStatus}
        />
        <StatCard
          variant="compact"
          label="Active Projects"
          value={data.stats.activeProjects}
          icon={<FolderOpen className="w-4 h-4" />}
        />
        <StatCard
          variant="compact"
          label="Days Since Reflection"
          value={data.stats.daysSinceReflection ?? "Never"}
          icon={<BookOpen className="w-4 h-4" />}
          status={reflectionStatus}
        />
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
              <TopCommitments items={data.weeklyFocus} />
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

      {/* Recent Activity */}
      <Card variant="elevated" padding="mobile">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Activity className="w-5 h-5 text-primary" />
              Recent Activity
            </CardTitle>
            <Button variant="ghost" size="sm" asChild>
              <Link href="/activity" className="text-primary">
                View all <ArrowRight className="w-4 h-4 ml-1" />
              </Link>
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {data.recentEntries.length === 0 ? (
            <EmptyState
              icon={<Activity className="w-8 h-8" />}
              title="No activity yet"
              description="Start by creating a project and adding your first entry."
            />
          ) : (
            <RecentActivity entries={data.recentEntries} />
          )}
        </CardContent>
      </Card>

      {/* Needs Attention - Compact Section */}
      {needsAttentionCount > 0 && (
        <Card variant="elevated" padding="mobile">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <AlertTriangle className="w-5 h-5 text-warning" />
              Needs Attention
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Idle Projects */}
            {data.idleProjects.length > 0 && (
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <p className="text-sm font-medium text-muted-foreground flex items-center gap-2">
                    <Clock className="w-4 h-4" />
                    Idle Projects
                  </p>
                  <Badge variant="outline">{data.idleProjects.length}</Badge>
                </div>
                <div className="flex flex-wrap gap-2">
                  {data.idleProjects.slice(0, 3).map((project) => {
                    const daysIdle = project.lastActiveAt
                      ? Math.floor(
                          (Date.now() - new Date(project.lastActiveAt).getTime()) /
                            (1000 * 60 * 60 * 24)
                        )
                      : 0;

                    return (
                      <Link key={project.id} href={`/projects/${project.id}`}>
                        <Badge variant="outline" className="hover:bg-muted cursor-pointer">
                          {project.name} ({daysIdle}d)
                        </Badge>
                      </Link>
                    );
                  })}
                  {data.idleProjects.length > 3 && (
                    <Link href="/projects">
                      <Badge variant="secondary" className="hover:bg-secondary/80 cursor-pointer">
                        +{data.idleProjects.length - 3} more
                      </Badge>
                    </Link>
                  )}
                </div>
              </div>
            )}

            {/* Pending Reviews */}
            {(data.pending.decisionsNeedingReview > 0 || data.pending.pendingReflections > 0) && (
              <div className="flex flex-wrap gap-3">
                {data.pending.decisionsNeedingReview > 0 && (
                  <div className="flex items-center gap-2 text-sm">
                    <Badge variant="outline" className="bg-amber-50 dark:bg-amber-950/30 text-amber-700 dark:text-amber-400 border-amber-200 dark:border-amber-800">
                      {data.pending.decisionsNeedingReview} decisions awaiting review
                    </Badge>
                  </div>
                )}
                {data.pending.pendingReflections > 0 && (
                  <Link href="/reflections">
                    <Badge variant="outline" className="bg-blue-50 dark:bg-blue-950/30 text-blue-700 dark:text-blue-400 border-blue-200 dark:border-blue-800 hover:bg-blue-100 dark:hover:bg-blue-950/50 cursor-pointer">
                      {data.pending.pendingReflections} reflections to capture
                    </Badge>
                  </Link>
                )}
              </div>
            )}
          </CardContent>
        </Card>
      )}

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
