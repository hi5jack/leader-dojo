import OpenAI from "openai";

import type {
  AiClient,
  PrepBriefingInput,
  PrepBriefingResult,
  ReflectionPromptInput,
  ReflectionPromptResult,
  SummarizeMeetingInput,
  SummarizeMeetingResult,
} from "@/lib/ai/types";

type CreateOpenAiClientOptions = {
  apiKey: string;
};

const model = "gpt-4.1-mini";

type JsonSchemaBody = {
  type: "object";
  properties: Record<string, unknown>;
  required?: string[];
  additionalProperties?: boolean;
};

type ResponseWithOutput = {
  output_text?: string[];
};

const parseJsonOutput = <T>(response: ResponseWithOutput) => {
  const [text] = response.output_text ?? [];
  if (!text) {
    throw new Error("AI response missing output_text");
  }
  return JSON.parse(text) as T;
};

const createJsonRequest = async <T>({
  client,
  prompt,
  schemaName,
  schemaBody,
}: {
  client: OpenAI;
  prompt: string;
  schemaName: string;
  schemaBody: JsonSchemaBody;
}) => {
  const response = await client.responses.create({
    model,
    input: prompt,
    temperature: 0.4,
    response_format: {
      type: "json_schema",
      json_schema: {
        name: schemaName,
        schema: schemaBody,
        strict: true,
      },
    },
  } as unknown as Parameters<typeof client.responses.create>[0]);

  return parseJsonOutput<T>(response as ResponseWithOutput);
};

export const createOpenAiClient = ({
  apiKey,
}: CreateOpenAiClientOptions): AiClient => {
  const client = new OpenAI({ apiKey });

  const summarizeMeeting = async (
    input: SummarizeMeetingInput,
  ): Promise<SummarizeMeetingResult> => {
    const prompt = [
      "You are Chief of Staff AI.",
      "Summarize the following meeting or update, capturing background, key takeaways, and decisions.",
      "Extract actionable commitments with direction (i_owe or waiting_for).",
      `Meeting transcript:\n${input.rawContent}`,
      input.projectContext ? `Project context: ${input.projectContext}` : "",
    ]
      .filter(Boolean)
      .join("\n\n");

    return createJsonRequest<SummarizeMeetingResult>({
      client,
      prompt,
      schemaName: "meeting_summary",
      schemaBody: {
        type: "object",
        properties: {
          summary: { type: "string" },
          keyDecisions: {
            type: "array",
            items: { type: "string" },
          },
          openQuestions: {
            type: "array",
            items: { type: "string" },
          },
          suggestedActions: {
            type: "array",
            items: {
              type: "object",
              properties: {
                title: { type: "string" },
                direction: { type: "string", enum: ["i_owe", "waiting_for"] },
                counterparty: { type: "string" },
                dueDate: { type: "string" },
                notes: { type: "string" },
                importance: { type: "integer" },
                urgency: { type: "integer" },
              },
              required: ["title", "direction"],
              additionalProperties: false,
            },
          },
        },
        required: ["summary", "keyDecisions", "openQuestions", "suggestedActions"],
        additionalProperties: false,
      },
    });
  };

  const generatePrepBriefing = async (
    input: PrepBriefingInput,
  ): Promise<PrepBriefingResult> => {
    const prompt = [
      `Project: ${input.projectName}`,
      `Recent entries:\n${JSON.stringify(input.entries)}`,
      `Outstanding commitments:\n${JSON.stringify(input.commitments)}`,
      "Generate a concise prep briefing and 3-5 bullet talking points.",
    ].join("\n\n");

    return createJsonRequest<PrepBriefingResult>({
      client,
      prompt,
      schemaName: "prep_briefing",
      schemaBody: {
        type: "object",
        properties: {
          briefing: { type: "string" },
          talkingPoints: {
            type: "array",
            items: { type: "string" },
          },
        },
        required: ["briefing", "talkingPoints"],
        additionalProperties: false,
      },
    });
  };

  const generateReflectionPrompts = async (
    input: ReflectionPromptInput,
  ): Promise<ReflectionPromptResult> => {
    const prompt = [
      `Timeframe: ${input.timeframe}`,
      `Stats snapshot:\n${JSON.stringify(input.stats)}`,
      "Create reflective questions and improvement suggestions tailored to a senior leader.",
    ].join("\n\n");

    return createJsonRequest<ReflectionPromptResult>({
      client,
      prompt,
      schemaName: "reflection_prompts",
      schemaBody: {
        type: "object",
        properties: {
          questions: {
            type: "array",
            items: { type: "string" },
          },
          suggestions: {
            type: "array",
            items: { type: "string" },
          },
        },
        required: ["questions", "suggestions"],
        additionalProperties: false,
      },
    });
  };

  return {
    summarizeMeeting,
    generatePrepBriefing,
    generateReflectionPrompts,
  };
};

