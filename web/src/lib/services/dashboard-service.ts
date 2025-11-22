import { CommitmentsRepository, EntriesRepository, ProjectsRepository } from "@/lib/repositories";

export class DashboardService {
  constructor(
    private readonly commitmentsRepo = new CommitmentsRepository(),
    private readonly projectsRepo = new ProjectsRepository(),
    private readonly entriesRepo = new EntriesRepository(),
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

    return {
      decisionsNeedingReview,
      pendingReflections: 0,
    };
  }

  async getDashboardData(userId: string) {
    const [weeklyFocus, idleProjects, pending] = await Promise.all([
      this.getWeeklyFocus(userId),
      this.getIdleProjects(userId),
      this.getPendingReviews(userId),
    ]);

    return {
      weeklyFocus,
      idleProjects,
      pending,
    };
  }
}

