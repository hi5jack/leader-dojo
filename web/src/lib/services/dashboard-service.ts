import { CommitmentsRepository, EntriesRepository, ProjectsRepository, ReflectionsRepository } from "@/lib/repositories";

export type DashboardStats = {
  openIOwe: number;
  waitingFor: number;
  activeProjects: number;
  daysSinceReflection: number | null;
};

export class DashboardService {
  constructor(
    private readonly commitmentsRepo = new CommitmentsRepository(),
    private readonly projectsRepo = new ProjectsRepository(),
    private readonly entriesRepo = new EntriesRepository(),
    private readonly reflectionsRepo = new ReflectionsRepository(),
  ) {}

  async getWeeklyFocus(userId: string) {
    const commitments = await this.commitmentsRepo.listCommitments(userId, {
      directions: ["i_owe"],
      statuses: ["open"],
    });

    return commitments
      .sort((a, b) => {
        const importanceDiff = (b.importance ?? 0) - (a.importance ?? 0);
        if (importanceDiff !== 0) return importanceDiff;
        const urgencyDiff = (b.urgency ?? 0) - (a.urgency ?? 0);
        if (urgencyDiff !== 0) return urgencyDiff;
        const dueA = a.dueDate ? new Date(a.dueDate).getTime() : Infinity;
        const dueB = b.dueDate ? new Date(b.dueDate).getTime() : Infinity;
        return dueA - dueB;
      })
      .slice(0, 5);
  }

  async getIdleProjects(userId: string) {
    return this.projectsRepo.findIdleProjects({
      userId,
      lastActiveBefore: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000),
      minPriority: 3,
    });
  }

  async getPendingReviews(userId: string) {
    const entries = await this.entriesRepo.listForUser(userId, {
      kinds: ["decision"],
    });

    const decisionsNeedingReview = entries.filter((entry) => !entry.aiSummary).length;

    // Calculate last full week (Monday to Sunday)
    const now = new Date();
    const lastWeekStart = new Date(now);
    const dayOfWeek = now.getDay();
    const daysToLastMonday = dayOfWeek === 0 ? 7 : dayOfWeek; // If Sunday, go back 7 days
    lastWeekStart.setDate(now.getDate() - daysToLastMonday - 7);
    lastWeekStart.setHours(0, 0, 0, 0);

    // Calculate last full month
    const lastMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    lastMonthStart.setHours(0, 0, 0, 0);

    // Check for missing reflections
    let pendingReflections = 0;
    
    const lastWeekReflection = await this.reflectionsRepo.findByPeriod(
      userId,
      "week",
      lastWeekStart,
    );
    if (!lastWeekReflection) {
      pendingReflections++;
    }

    const lastMonthReflection = await this.reflectionsRepo.findByPeriod(
      userId,
      "month",
      lastMonthStart,
    );
    if (!lastMonthReflection) {
      pendingReflections++;
    }

    return {
      decisionsNeedingReview,
      pendingReflections,
    };
  }

  async getStats(userId: string): Promise<DashboardStats> {
    const [iOweCommitments, waitingForCommitments, activeProjects, reflections] = await Promise.all([
      this.commitmentsRepo.listCommitments(userId, {
        directions: ["i_owe"],
        statuses: ["open"],
      }),
      this.commitmentsRepo.listCommitments(userId, {
        directions: ["waiting_for"],
        statuses: ["open"],
      }),
      this.projectsRepo.listByUser(userId, { status: ["active"] }),
      this.reflectionsRepo.listReflections(userId, {}),
    ]);

    // Calculate days since last reflection
    let daysSinceReflection: number | null = null;
    if (reflections.length > 0) {
      const lastReflection = reflections[0]; // Already sorted by createdAt desc
      const daysDiff = Math.floor(
        (Date.now() - new Date(lastReflection.createdAt).getTime()) / (1000 * 60 * 60 * 24)
      );
      daysSinceReflection = daysDiff;
    }

    return {
      openIOwe: iOweCommitments.length,
      waitingFor: waitingForCommitments.length,
      activeProjects: activeProjects.length,
      daysSinceReflection,
    };
  }

  async getRecentEntries(userId: string, limit = 5) {
    // Exclude commitment entries from dashboard recent activity
    const entries = await this.entriesRepo.listForUser(userId, {
      kinds: ["meeting", "update", "decision", "note", "prep", "reflection"],
    });
    
    // Get project info for each entry
    const entriesWithProjects = await Promise.all(
      entries.slice(0, limit).map(async (entry) => {
        const project = await this.projectsRepo.findById(userId, entry.projectId);
        return {
          ...entry,
          projectName: project?.name ?? "Unknown Project",
        };
      })
    );

    return entriesWithProjects;
  }

  async getDashboardData(userId: string) {
    const [weeklyFocus, idleProjects, pending, stats, recentEntries] = await Promise.all([
      this.getWeeklyFocus(userId),
      this.getIdleProjects(userId),
      this.getPendingReviews(userId),
      this.getStats(userId),
      this.getRecentEntries(userId, 5),
    ]);

    return {
      weeklyFocus,
      idleProjects,
      pending,
      stats,
      recentEntries,
    };
  }
}

