import type { CommitmentDirection } from "@/lib/ai/types";
import { commitments } from "@/lib/db/schema";
import type { NewCommitment } from "@/lib/db/types";
import { CommitmentsRepository } from "@/lib/repositories";

type CreateCommitmentInput = Omit<
  NewCommitment,
  "id" | "userId" | "createdAt" | "updatedAt"
>;

type ListCommitmentsInput = {
  directions?: CommitmentDirection[];
  statuses?: Array<typeof commitments.$inferSelect.status>;
  projectId?: string;
};

export class CommitmentsService {
  constructor(private readonly commitmentsRepo = new CommitmentsRepository()) {}

  async createCommitment(userId: string, input: CreateCommitmentInput) {
    return this.commitmentsRepo.createCommitment({
      ...input,
      userId,
    });
  }

  async listCommitments(userId: string, filters: ListCommitmentsInput = {}) {
    return this.commitmentsRepo.listCommitments(userId, filters);
  }

  async updateStatus(
    userId: string,
    commitmentId: string,
    status: typeof commitments.$inferSelect.status,
  ) {
    return this.commitmentsRepo.updateCommitment(userId, commitmentId, {
      status,
      completedAt: status === "done" ? new Date() : null,
    });
  }

  async updateCommitment(
    userId: string,
    commitmentId: string,
    input: Partial<CreateCommitmentInput>,
  ) {
    return this.commitmentsRepo.updateCommitment(userId, commitmentId, input);
  }
}

