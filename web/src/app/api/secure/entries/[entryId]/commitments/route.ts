import { NextResponse } from "next/server";

import { EntriesService } from "@/lib/services";
import { suggestedActionsSchema } from "@/lib/validators/suggestions";
import { withUser } from "@/lib/http/with-user";

const entriesService = new EntriesService();

type Params = {
  entryId: string;
};

export const POST = withUser<Params>(async ({ request, userId, params }) => {
  const body = await request.json();
  const parsed = suggestedActionsSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json(parsed.error.flatten(), { status: 400 });
  }

  const entry = await entriesService.getEntry(userId, params.entryId);
  if (!entry) {
    return NextResponse.json({ message: "Entry not found" }, { status: 404 });
  }

  const commitments = await entriesService.createCommitmentsFromSuggestions(
    userId,
    parsed.data.projectId,
    entry.id,
    parsed.data.actions,
  );

  return NextResponse.json(commitments, { status: 201 });
});

