export type CommitmentDirection = "i_owe" | "waiting_for";
export type CommitmentStatus = "open" | "done" | "blocked" | "dropped";

export type SuggestedAction = {
  title: string;
  direction: CommitmentDirection;
  counterparty?: string;
  dueDate?: string;
  notes?: string;
  importance?: number;
  urgency?: number;
};

export type SummarizeMeetingInput = {
  rawContent: string;
  projectContext?: string;
};

export type SummarizeMeetingResult = {
  summary: string;
  keyDecisions: string[];
  openQuestions: string[];
  suggestedActions: SuggestedAction[];
};

export type PrepBriefingInput = {
  projectName: string;
  entries: Array<{
    occurredAt: string;
    kind: string;
    content: string;
  }>;
  commitments: Array<{
    title: string;
    direction: CommitmentDirection;
    dueDate?: string;
    counterparty?: string;
    status: CommitmentStatus;
  }>;
};

export type PrepBriefingResult = {
  briefing: string;
  talkingPoints: string[];
};

export type ReflectionPromptInput = {
  timeframe: string;
  stats: Record<string, unknown>;
};

export type ReflectionPromptResult = {
  questions: string[];
  suggestions: string[];
};

export interface AiClient {
  summarizeMeeting(
    input: SummarizeMeetingInput,
  ): Promise<SummarizeMeetingResult>;
  generatePrepBriefing(input: PrepBriefingInput): Promise<PrepBriefingResult>;
  generateReflectionPrompts(
    input: ReflectionPromptInput,
  ): Promise<ReflectionPromptResult>;
}

