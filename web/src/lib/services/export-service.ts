import {
  CommitmentsRepository,
  EntriesRepository,
  ProjectsRepository,
  ReflectionsRepository,
} from "@/lib/repositories";

// Export DTOs matching Mac app's DataImportService.swift WebAppExport types
type WebProject = {
  id: string;
  name: string;
  description: string | null;
  type: string | null;
  status: string | null;
  priority: number | null;
  ownerNotes: string | null;
  lastActiveAt: Date | null;
  createdAt: Date | null;
  updatedAt: Date | null;
};

type WebEntry = {
  id: string;
  projectId: string | null;
  kind: string | null;
  title: string;
  occurredAt: Date | null;
  rawContent: string | null;
  aiSummary: string | null;
  decisions: string | null;
  isDecision: boolean | null;
  createdAt: Date | null;
  updatedAt: Date | null;
};

type WebCommitment = {
  id: string;
  projectId: string | null;
  entryId: string | null;
  title: string;
  direction: string | null;
  status: string | null;
  counterparty: string | null;
  dueDate: Date | null;
  importance: number | null;
  urgency: number | null;
  notes: string | null;
  aiGenerated: boolean | null;
  createdAt: Date | null;
  updatedAt: Date | null;
};

type WebQA = {
  question: string;
  answer: string;
};

type WebReflection = {
  id: string;
  projectId: string | null;
  periodType: string | null;
  periodStart: Date | null;
  periodEnd: Date | null;
  questionsAnswers: WebQA[] | null;
  createdAt: Date | null;
};

export type WebAppExport = {
  projects: WebProject[];
  entries: WebEntry[];
  commitments: WebCommitment[];
  reflections: WebReflection[];
};

export class ExportService {
  constructor(
    private readonly projectsRepo = new ProjectsRepository(),
    private readonly entriesRepo = new EntriesRepository(),
    private readonly commitmentsRepo = new CommitmentsRepository(),
    private readonly reflectionsRepo = new ReflectionsRepository(),
  ) {}

  async exportAllUserData(userId: string): Promise<WebAppExport> {
    const [projects, entries, commitments, reflections] = await Promise.all([
      this.projectsRepo.listByUser(userId),
      this.entriesRepo.listForUser(userId),
      this.commitmentsRepo.listCommitments(userId),
      this.reflectionsRepo.listReflections(userId),
    ]);

    return {
      projects: projects.map((p) => ({
        id: p.id,
        name: p.name,
        description: p.description,
        type: p.type,
        status: p.status,
        priority: p.priority,
        ownerNotes: p.ownerNotes,
        lastActiveAt: p.lastActiveAt,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
      })),
      entries: entries.map((e) => ({
        id: e.id,
        projectId: e.projectId,
        kind: e.kind,
        title: e.title,
        occurredAt: e.occurredAt,
        rawContent: e.rawContent,
        aiSummary: e.aiSummary,
        decisions: e.decisions,
        isDecision: e.isDecision,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      })),
      commitments: commitments.map((c) => ({
        id: c.id,
        projectId: c.projectId,
        entryId: c.entryId,
        title: c.title,
        direction: c.direction,
        status: c.status,
        counterparty: c.counterparty,
        dueDate: c.dueDate,
        importance: c.importance,
        urgency: c.urgency,
        notes: c.notes,
        aiGenerated: c.aiGenerated,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      })),
      reflections: reflections.map((r) => ({
        id: r.id,
        projectId: r.projectId,
        periodType: r.periodType,
        periodStart: r.periodStart,
        periodEnd: r.periodEnd,
        questionsAnswers: r.questionsAndAnswers as WebQA[] | null,
        createdAt: r.createdAt,
      })),
    };
  }
}



