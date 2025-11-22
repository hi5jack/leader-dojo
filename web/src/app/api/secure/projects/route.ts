import { NextResponse } from "next/server";

import { ProjectsService } from "@/lib/services";
import { createProjectSchema } from "@/lib/validators/projects";
import { withUser } from "@/lib/http/with-user";

const projectsService = new ProjectsService();

export const GET = withUser(async ({ userId }) => {
  const data = await projectsService.listProjects(userId);
  return NextResponse.json(data);
});

export const POST = withUser(async ({ request, userId }) => {
  const body = await request.json();
  const parsed = createProjectSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json(parsed.error.flatten(), { status: 400 });
  }

  const project = await projectsService.createProject(userId, parsed.data);
  return NextResponse.json(project, { status: 201 });
});

