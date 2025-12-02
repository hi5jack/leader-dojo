"use client";

import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Plus, X } from "lucide-react";

type QA = {
  question: string;
  answer: string;
};

type ReflectionFieldsProps = {
  questionsAndAnswers: QA[];
  onQuestionsAndAnswersChange: (value: QA[]) => void;
};

export function ReflectionFields({
  questionsAndAnswers,
  onQuestionsAndAnswersChange,
}: ReflectionFieldsProps) {
  const addQuestion = () => {
    onQuestionsAndAnswersChange([
      ...questionsAndAnswers,
      { question: "", answer: "" },
    ]);
  };

  const removeQuestion = (index: number) => {
    onQuestionsAndAnswersChange(
      questionsAndAnswers.filter((_, i) => i !== index),
    );
  };

  const updateQuestion = (index: number, field: "question" | "answer", value: string) => {
    const updated = [...questionsAndAnswers];
    updated[index] = { ...updated[index], [field]: value };
    onQuestionsAndAnswersChange(updated);
  };

  return (
    <div className="space-y-4 border-t pt-4">
      <div className="flex items-center justify-between">
        <div className="text-sm font-semibold text-muted-foreground">
          Reflection Questions (Optional)
        </div>
        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={addQuestion}
          className="gap-2"
        >
          <Plus className="w-4 h-4" />
          Add Question
        </Button>
      </div>

      {questionsAndAnswers.length === 0 && (
        <p className="text-sm text-muted-foreground italic">
          Add guided reflection questions to structure your thoughts
        </p>
      )}

      <div className="space-y-4">
        {questionsAndAnswers.map((qa, index) => (
          <div key={index} className="space-y-2 p-4 border rounded-lg bg-muted/30">
            <div className="flex items-center justify-between">
              <Label className="text-sm font-semibold">
                Question {index + 1}
              </Label>
              <Button
                type="button"
                variant="ghost"
                size="sm"
                onClick={() => removeQuestion(index)}
                className="h-8 w-8 p-0"
              >
                <X className="w-4 h-4" />
              </Button>
            </div>
            <Input
              value={qa.question}
              onChange={(e) => updateQuestion(index, "question", e.target.value)}
              placeholder="e.g., What went well this week?"
              className="h-10 text-base"
            />
            <Textarea
              value={qa.answer}
              onChange={(e) => updateQuestion(index, "answer", e.target.value)}
              placeholder="Your reflection..."
              className="min-h-[80px] text-base resize-none"
            />
          </div>
        ))}
      </div>
    </div>
  );
}

// Missing Input import - add it
import { Input } from "@/components/ui/input";







