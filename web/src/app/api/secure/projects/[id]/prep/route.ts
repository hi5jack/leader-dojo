import { NextResponse } from "next/server";

import { PrepService } from "@/lib/services/prep-service";
import { withUser } from "@/lib/http/with-user";

const prepService = new PrepService();

type Params = {
  id: string;
};

export const GET = withUser<Params>(async ({ userId, params }) => {
  const result = await prepService.generateBriefing(userId, params.id);
  if (!result) {
    return NextResponse.json({ message: "Not found" }, { status: 404 });
  }

  return NextResponse.json(result);
});

