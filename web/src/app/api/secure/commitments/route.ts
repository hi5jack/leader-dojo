import { NextResponse } from "next/server";

import { CommitmentsService } from "@/lib/services";
import { createCommitmentSchema } from "@/lib/validators/commitments";
import { withUser } from "@/lib/http/with-user";

const commitmentsService = new CommitmentsService();

export const GET = withUser(async ({ request, userId }) => {
  const { searchParams } = new URL(request.url);
  const directions = searchParams.getAll("direction") as
    | ["i_owe" | "waiting_for"]
    | [];
  const statuses = searchParams.getAll("status") as
    | ["open" | "done" | "blocked" | "dropped"]
    | [];
  const projectId = searchParams.get("projectId") ?? undefined;

  const items = await commitmentsService.listCommitments(userId, {
    directions: directions.length ? directions : undefined,
    statuses: statuses.length ? statuses : undefined,
    projectId,
  });

  return NextResponse.json(items);
});

export const POST = withUser(async ({ request, userId }) => {
  const body = await request.json();
  const parsed = createCommitmentSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(parsed.error.flatten(), { status: 400 });
  }

  const commitment = await commitmentsService.createCommitment(userId, parsed.data);
  return NextResponse.json(commitment, { status: 201 });
});

