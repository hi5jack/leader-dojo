import { getAiClient } from "@/lib/ai/client";
import {
  CommitmentsRepository,
  EntriesRepository,
  ProjectsRepository,
} from "@/lib/repositories";

export class PrepService {
  constructor(
    private readonly projectsRepo = new ProjectsRepository(),
    private readonly entriesRepo = new EntriesRepository(),
    private readonly commitmentsRepo = new CommitmentsRepository(),
  ) {}

  async generateBriefing(userId: string, projectId: string) {
    const project = await this.projectsRepo.findById(userId, projectId);
    if (!project) {
      return null;
    }

    const [entries, commitments] = await Promise.all([
      this.entriesRepo.listByProject(userId, projectId, {
        kinds: ["meeting", "update", "decision"],
      }),
      this.commitmentsRepo.listCommitments(userId, {
        projectId,
        statuses: ["open"],
      }),
    ]);

    const aiClient = getAiClient();
    const aiResult = await aiClient.generatePrepBriefing({
      projectName: project.name,
      entries: entries.slice(0, 10).map((entry) => ({
        occurredAt: entry.occurredAt?.toISOString() ?? "",
        kind: entry.kind,
        content: entry.aiSummary ?? entry.rawContent ?? entry.title,
      })),
      commitments: commitments.map((commitment) => ({
        title: commitment.title,
        direction: commitment.direction,
        dueDate: commitment.dueDate?.toISOString(),
        counterparty: commitment.counterparty ?? undefined,
        status: commitment.status,
      })),
    });

    return {
      project,
      entries,
      commitments,
      briefing: aiResult,
    };
  }
}

