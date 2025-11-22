import { NextResponse } from "next/server";

import { EntriesService } from "@/lib/services";
import { createEntrySchema } from "@/lib/validators/entries";
import { withUser } from "@/lib/http/with-user";

const entriesService = new EntriesService();

type Params = {
  id: string;
};

export const POST = withUser<Params>(async ({ request, userId, params }) => {
  const body = await request.json();
  const parsed = createEntrySchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json(parsed.error.flatten(), { status: 400 });
  }

  const entry = await entriesService.createEntry(userId, params.id, parsed.data);
  return NextResponse.json(entry, { status: 201 });
});

export const GET = withUser<Params>(async ({ userId, params }) => {
  const entries = await entriesService.getTimeline(userId, params.id);
  return NextResponse.json(entries);
});

