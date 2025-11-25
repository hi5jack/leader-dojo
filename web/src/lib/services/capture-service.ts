import type { CaptureInput } from "@/lib/validators/capture";
import { isCommitmentCapture, isReflectionCapture } from "@/lib/validators/capture";
import type { CaptureResult, NewCommitment } from "@/lib/db/types";
import {
  EntriesRepository,
  CommitmentsRepository,
  ReflectionsRepository,
  ProjectsRepository,
} from "@/lib/repositories";

export class CaptureService {
  constructor(
    private readonly entriesRepo = new EntriesRepository(),
    private readonly commitmentsRepo = new CommitmentsRepository(),
    private readonly reflectionsRepo = new ReflectionsRepository(),
    private readonly projectsRepo = new ProjectsRepository(),
  ) {}

  async capture(userId: string, input: CaptureInput): Promise<CaptureResult> {
    const result: CaptureResult = {
      entryId: "",
    };

    // Always create an entry for timeline/audit trail
    const entry = await this.entriesRepo.createEntry({
      userId,
      projectId: input.projectId,
      kind: input.kind,
      title: input.title,
      occurredAt: input.occurredAt ?? new Date(),
      rawContent: input.rawContent,
    });

    result.entryId = entry.id;

    // Update project last active timestamp
    await this.projectsRepo.updateLastActive(
      userId,
      input.projectId,
      entry.occurredAt,
    );

    // Handle commitment-specific creation
    if (isCommitmentCapture(input)) {
      const commitmentInput: NewCommitment = {
        userId,
        projectId: input.projectId,
        entryId: entry.id,
        title: input.title,
        direction: input.direction,
        counterparty: input.counterparty ?? null,
        dueDate: input.dueDate ?? null,
        importance: input.importance,
        urgency: input.urgency,
        notes: input.notes ?? null,
        status: "open",
        aiGenerated: false,
      };

      const commitment = await this.commitmentsRepo.createCommitment(
        commitmentInput,
      );

      result.commitmentId = commitment.id;
    }

    // Handle reflection-specific creation
    if (isReflectionCapture(input)) {
      // Only create a reflection record if we have questions/answers
      // or if it's a structured period reflection
      if (input.questionsAndAnswers || input.periodType) {
        const reflection = await this.reflectionsRepo.createAdHocReflection({
          userId,
          projectId: input.projectId,
          entryId: entry.id,
          periodType: input.periodType,
          periodStart: input.periodStart,
          periodEnd: input.periodEnd,
          questionsAndAnswers: input.questionsAndAnswers ?? [],
          stats: input.periodType ? {} : undefined,
          aiQuestions: [],
        });

        result.reflectionId = reflection.id;
      }
    }

    return result;
  }

  async getCapture(userId: string, entryId: string) {
    return this.entriesRepo.findById(userId, entryId);
  }

  async listCaptures(userId: string, projectId?: string) {
    if (projectId) {
      return this.entriesRepo.listByProject(userId, projectId);
    }
    // Could implement a global list across all projects if needed
    throw new Error("Global capture list not yet implemented");
  }
}

