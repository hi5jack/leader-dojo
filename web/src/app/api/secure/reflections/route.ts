import { NextResponse } from "next/server";

import { ReflectionsService } from "@/lib/services";
import { reflectionRequestSchema } from "@/lib/validators/reflections";
import { withUser } from "@/lib/http/with-user";

const reflectionsService = new ReflectionsService();

export const GET = withUser(async ({ userId }) => {
  const reflections = await reflectionsService.listReflections(userId);
  return NextResponse.json(reflections);
});

export const POST = withUser(async ({ request, userId }) => {
  const body = await request.json();
  const parsed = reflectionRequestSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(parsed.error.flatten(), { status: 400 });
  }

  try {
    const { periodType, periodStart, periodEnd, answers } = parsed.data;
    const reflection = await reflectionsService.generateReflection(
      userId,
      periodType,
      periodStart,
      periodEnd,
    );

    if (answers?.length) {
      await reflectionsService.saveReflection(userId, {
        periodType,
        periodStart,
        periodEnd,
        stats: reflection.stats,
        questionsAndAnswers: answers,
        aiQuestions: reflection.questions,
      });
    }

    return NextResponse.json(reflection);
  } catch (error) {
    console.error("Reflection generation failed:", error);
    return NextResponse.json(
      { 
        message: "Unable to generate reflection prompts. The AI service may be unavailable.",
        error: error instanceof Error ? error.message : "Unknown error"
      }, 
      { status: 503 }
    );
  }
});

