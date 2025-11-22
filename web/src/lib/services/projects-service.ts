import type { NewProject, Project } from "@/lib/db/types";
import { ProjectsRepository } from "@/lib/repositories";

type CreateProjectInput = Omit<
  NewProject,
  "id" | "userId" | "createdAt" | "updatedAt" | "lastActiveAt"
>;

type UpdateProjectInput = Partial<CreateProjectInput>;

export class ProjectsService {
  constructor(private readonly projectsRepo = new ProjectsRepository()) {}

  async createProject(userId: string, input: CreateProjectInput): Promise<Project> {
    return this.projectsRepo.createProject({
      ...input,
      userId,
    });
  }

  async updateProject(userId: string, projectId: string, input: UpdateProjectInput) {
    return this.projectsRepo.updateProject(userId, projectId, input);
  }

  async getProject(userId: string, projectId: string) {
    return this.projectsRepo.findById(userId, projectId);
  }

  async listProjects(userId: string) {
    return this.projectsRepo.listByUser(userId);
  }

  async markProjectActive(userId: string, projectId: string) {
    await this.projectsRepo.updateLastActive(userId, projectId, new Date());
  }

  async findIdleProjects(userId: string, daysIdle = 45) {
    const lastActiveBefore = new Date();
    lastActiveBefore.setDate(lastActiveBefore.getDate() - daysIdle);
    return this.projectsRepo.findIdleProjects({
      userId,
      lastActiveBefore,
      minPriority: 3,
    });
  }
}

