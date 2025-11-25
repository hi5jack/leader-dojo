import { getAiClient } from "@/lib/ai/client";
import type { ReflectionPromptResult } from "@/lib/ai/types";
import { reflections } from "@/lib/db/schema";
import type { NewReflection } from "@/lib/db/types";
import {
  CommitmentsRepository,
  EntriesRepository,
  ReflectionsRepository,
} from "@/lib/repositories";

type ReflectionPeriod = NonNullable<typeof reflections.$inferSelect.periodType>;

type ReflectionQuestionAnswer = {
  question: string;
  answer: string;
};

export class ReflectionsService {
  constructor(
    private readonly reflectionsRepo = new ReflectionsRepository(),
    private readonly entriesRepo = new EntriesRepository(),
    private readonly commitmentsRepo = new CommitmentsRepository(),
  ) {}

  async listReflections(userId: string, periodType?: ReflectionPeriod) {
    return this.reflectionsRepo.listReflections(userId, { periodType });
  }

  async generateReflection(
    userId: string,
    periodType: ReflectionPeriod,
    periodStart: Date,
    periodEnd: Date,
  ): Promise<ReflectionPromptResult & { stats: Record<string, unknown> }> {
    const entries = await this.entriesRepo.listForUser(userId, {
      occurredAfter: periodStart,
      occurredBefore: periodEnd,
    });

    const commitmentsList = await this.commitmentsRepo.listCommitments(userId, {
      dueAfter: periodStart,
      dueBefore: periodEnd,
    });

    const stats = {
      meetingCount: entries.filter((entry) => entry.kind === "meeting").length,
      decisionCount: entries.filter((entry) => entry.isDecision).length,
      openCommitments: commitmentsList.filter((c) => c.status === "open").length,
      waitingFor: commitmentsList.filter((c) => c.direction === "waiting_for").length,
      iOwe: commitmentsList.filter((c) => c.direction === "i_owe").length,
    };

    const ai = getAiClient();
    const prompts = await ai.generateReflectionPrompts({
      timeframe: `${periodType} ${periodStart.toISOString()} - ${periodEnd.toISOString()}`,
      stats,
    });

    return { ...prompts, stats };
  }

  async saveReflection(
    userId: string,
    data: {
      periodType: ReflectionPeriod;
      periodStart: Date;
      periodEnd: Date;
      stats: Record<string, unknown>;
      questionsAndAnswers: ReflectionQuestionAnswer[];
      aiQuestions: string[];
    },
  ) {
    const payload: NewReflection = {
      userId,
      periodType: data.periodType,
      periodStart: data.periodStart,
      periodEnd: data.periodEnd,
      stats: data.stats,
      questionsAndAnswers: data.questionsAndAnswers,
      aiQuestions: data.aiQuestions,
    };

    return this.reflectionsRepo.createReflection(payload);
  }
}

