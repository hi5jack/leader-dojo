import { env } from "@/lib/config/env";
import { createOpenAiClient } from "./providers/openai-client";
import type { AiClient } from "./types";

let aiClient: AiClient | null = null;

export const getAiClient = (): AiClient => {
  if (aiClient) {
    return aiClient;
  }

  if (env.AI_PROVIDER === "openai") {
    aiClient = createOpenAiClient({ apiKey: env.OPENAI_API_KEY });
    return aiClient;
  }

  throw new Error(`Unsupported AI provider: ${env.AI_PROVIDER}`);
};

