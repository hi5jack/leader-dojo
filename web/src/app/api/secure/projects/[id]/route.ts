import { NextResponse } from "next/server";

import { ProjectsService } from "@/lib/services";
import { updateProjectSchema } from "@/lib/validators/projects";
import { withUser } from "@/lib/http/with-user";

const projectsService = new ProjectsService();

type Params = {
  id: string;
};

export const GET = withUser<Params>(async ({ userId, params }) => {
  const project = await projectsService.getProject(userId, params.id);
  if (!project) {
    return NextResponse.json({ message: "Not found" }, { status: 404 });
  }
  return NextResponse.json(project);
});

export const PATCH = withUser<Params>(async ({ request, userId, params }) => {
  const body = await request.json();
  const parsed = updateProjectSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(parsed.error.flatten(), { status: 400 });
  }

  const updated = await projectsService.updateProject(userId, params.id, parsed.data);
  if (!updated) {
    return NextResponse.json({ message: "Not found" }, { status: 404 });
  }
  return NextResponse.json(updated);
});

