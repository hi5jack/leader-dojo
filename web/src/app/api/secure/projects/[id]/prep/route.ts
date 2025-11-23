import { NextResponse } from "next/server";

import { PrepService } from "@/lib/services/prep-service";
import { withUser } from "@/lib/http/with-user";

const prepService = new PrepService();

type Params = {
  id: string;
};

export const GET = withUser<Params>(async ({ userId, params }) => {
  try {
    const result = await prepService.generateBriefing(userId, params.id);
    if (!result) {
      return NextResponse.json({ message: "Not found" }, { status: 404 });
    }

    return NextResponse.json(result);
  } catch (error) {
    console.error("Prep briefing generation failed:", error);
    return NextResponse.json(
      { 
        message: "Unable to generate prep briefing. The AI service may be unavailable.",
        error: error instanceof Error ? error.message : "Unknown error"
      }, 
      { status: 503 }
    );
  }
});

