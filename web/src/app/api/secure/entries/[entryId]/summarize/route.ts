import { NextResponse } from "next/server";

import { EntriesService } from "@/lib/services";
import { ProjectsService } from "@/lib/services/projects-service";
import { withUser } from "@/lib/http/with-user";

const entriesService = new EntriesService();
const projectsService = new ProjectsService();

type Params = {
  entryId: string;
};

export const POST = withUser<Params>(async ({ userId, params }) => {
  const entry = await entriesService.getEntry(userId, params.entryId);

  if (!entry) {
    return NextResponse.json({ message: "Not found" }, { status: 404 });
  }

  const project = await projectsService.getProject(userId, entry.projectId);
  const aiResult = await entriesService.generateSummary(entry, project?.description ?? project?.name);

  await entriesService.persistSummary(userId, entry.id, aiResult.summary, aiResult.suggestedActions);

  return NextResponse.json(aiResult);
});

