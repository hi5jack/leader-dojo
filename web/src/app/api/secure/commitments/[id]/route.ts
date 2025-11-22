import { NextResponse } from "next/server";

import { CommitmentsService } from "@/lib/services";
import { updateCommitmentSchema } from "@/lib/validators/commitments";
import { withUser } from "@/lib/http/with-user";

const commitmentsService = new CommitmentsService();

type Params = {
  id: string;
};

export const PATCH = withUser<Params>(async ({ request, userId, params }) => {
  const body = await request.json();
  const parsed = updateCommitmentSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json(parsed.error.flatten(), { status: 400 });
  }

  if (parsed.data.status) {
    const updated = await commitmentsService.updateStatus(userId, params.id, parsed.data.status);
    if (!updated) {
      return NextResponse.json({ message: "Not found" }, { status: 404 });
    }
    return NextResponse.json(updated);
  }

  const updated = await commitmentsService.updateCommitment(userId, params.id, parsed.data);
  if (!updated) {
    return NextResponse.json({ message: "Not found" }, { status: 404 });
  }
  return NextResponse.json(updated);
});

