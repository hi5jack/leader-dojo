import { NextResponse } from "next/server";
import { withUser } from "@/lib/http/with-user";
import { CaptureService } from "@/lib/services/capture-service";
import { captureInputSchema } from "@/lib/validators/capture";

const captureService = new CaptureService();

export const POST = withUser(async ({ request, userId }) => {
  try {
    const body = await request.json();
    const input = captureInputSchema.parse(body);

    const result = await captureService.capture(userId, input);

    return NextResponse.json(result, { status: 201 });
  } catch (error) {
    if (error instanceof Error && error.name === "ZodError") {
      return NextResponse.json(
        { error: "Invalid input", details: error },
        { status: 400 },
      );
    }

    console.error("Error capturing entry:", error);
    return NextResponse.json(
      { error: "Failed to capture entry" },
      { status: 500 },
    );
  }
});

// Optional: GET endpoint to retrieve captures
export const GET = withUser(async ({ request, userId }) => {
  try {
    const { searchParams } = new URL(request.url);
    const projectId = searchParams.get("projectId");

    if (!projectId) {
      return NextResponse.json(
        { error: "projectId is required" },
        { status: 400 },
      );
    }

    const captures = await captureService.listCaptures(userId, projectId);

    return NextResponse.json(captures);
  } catch (error) {
    console.error("Error fetching captures:", error);
    return NextResponse.json(
      { error: "Failed to fetch captures" },
      { status: 500 },
    );
  }
});

