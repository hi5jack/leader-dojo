import type { SuggestedAction } from "@/lib/ai/types";
import { getAiClient } from "@/lib/ai/client";
import type { NewProjectEntry, ProjectEntry } from "@/lib/db/types";
import { CommitmentsRepository, EntriesRepository, ProjectsRepository } from "@/lib/repositories";

type CreateEntryInput = Omit<
  NewProjectEntry,
  "id" | "userId" | "projectId" | "createdAt" | "updatedAt"
>;

export class EntriesService {
  constructor(
    private readonly entriesRepo = new EntriesRepository(),
    private readonly projectsRepo = new ProjectsRepository(),
    private readonly commitmentsRepo = new CommitmentsRepository(),
  ) {}

  async createEntry(userId: string, projectId: string, input: CreateEntryInput) {
    const entry = await this.entriesRepo.createEntry({
      ...input,
      userId,
      projectId,
    });

    await this.projectsRepo.updateLastActive(userId, projectId, input.occurredAt ?? new Date());
    return entry;
  }

  async getTimeline(userId: string, projectId: string) {
    return this.entriesRepo.listByProject(userId, projectId);
  }

  async markAsDecision(userId: string, entryId: string) {
    return this.entriesRepo.updateEntry(userId, entryId, { isDecision: true });
  }

  async getEntry(userId: string, entryId: string) {
    return this.entriesRepo.findById(userId, entryId);
  }

  async updateEntry(
    userId: string,
    entryId: string,
    input: Partial<CreateEntryInput>
  ) {
    return this.entriesRepo.updateEntry(userId, entryId, input);
  }

  async deleteEntry(userId: string, entryId: string) {
    return this.entriesRepo.deleteEntry(userId, entryId);
  }

  async generateSummary(entry: ProjectEntry, projectContext?: string) {
    const ai = getAiClient();
    return ai.summarizeMeeting({
      rawContent: entry.rawContent ?? "",
      projectContext,
    });
  }

  async persistSummary(
    userId: string,
    entryId: string,
    summary: string,
    suggestedActions: SuggestedAction[],
  ) {
    await this.entriesRepo.updateEntry(userId, entryId, {
      aiSummary: summary,
      aiSuggestedActions: suggestedActions,
    });
  }

  async createCommitmentsFromSuggestions(
    userId: string,
    projectId: string,
    entryId: string,
    suggestions: SuggestedAction[],
  ) {
    const payload = suggestions.map((suggestion) => ({
      userId,
      projectId,
      entryId,
      title: suggestion.title,
      direction: suggestion.direction,
      counterparty: suggestion.counterparty,
      dueDate: suggestion.dueDate ? new Date(suggestion.dueDate) : null,
      importance: suggestion.importance ?? 3,
      urgency: suggestion.urgency ?? 3,
      notes: suggestion.notes,
      aiGenerated: true,
    }));

    return this.commitmentsRepo.createMany(payload);
  }

  /**
   * Get all entries for a user with their project information
   * Used for the cross-project activity timeline
   */
  async getAllEntriesWithProjects(
    userId: string,
    filters?: {
      projectId?: string;
      kinds?: ProjectEntry["kind"][];
      limit?: number;
    }
  ) {
    const entries = await this.entriesRepo.listForUser(userId, {
      projectId: filters?.projectId,
      kinds: filters?.kinds,
    });

    // Get unique project IDs
    const projectIds = [...new Set(entries.map((e) => e.projectId))];
    
    // Fetch all projects in parallel
    const projectsMap = new Map<string, { name: string; id: string }>();
    await Promise.all(
      projectIds.map(async (projectId) => {
        const project = await this.projectsRepo.findById(userId, projectId);
        if (project) {
          projectsMap.set(projectId, { name: project.name, id: project.id });
        }
      })
    );

    // Combine entries with project info
    const entriesWithProjects = entries
      .map((entry) => ({
        ...entry,
        projectName: projectsMap.get(entry.projectId)?.name ?? "Unknown Project",
      }))
      .slice(0, filters?.limit ?? 50);

    return entriesWithProjects;
  }
}

