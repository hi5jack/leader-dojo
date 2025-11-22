"use client";

import { useMemo, useState } from "react";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";

const periods = [
  { label: "Week", value: "week" },
  { label: "Month", value: "month" },
  { label: "Quarter", value: "quarter" },
];

const computeEndDate = (start: string, periodType: string) => {
  const startDate = new Date(start);
  if (Number.isNaN(startDate.getTime())) return null;
  const end = new Date(startDate);
  if (periodType === "week") {
    end.setDate(end.getDate() + 6);
  } else if (periodType === "month") {
    end.setMonth(end.getMonth() + 1);
    end.setDate(end.getDate() - 1);
  } else if (periodType === "quarter") {
    end.setMonth(end.getMonth() + 3);
    end.setDate(end.getDate() - 1);
  }
  return end;
};

export const ReflectionWizard = () => {
  const [periodType, setPeriodType] = useState("week");
  const [periodStart, setPeriodStart] = useState("");
  const [questions, setQuestions] = useState<string[]>([]);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const [status, setStatus] = useState<"idle" | "loading" | "saving">("idle");
  const [error, setError] = useState<string | null>(null);

  const periodEnd = useMemo(() => {
    if (!periodStart) return null;
    return computeEndDate(periodStart, periodType);
  }, [periodStart, periodType]);

  const fetchPrompts = async () => {
    if (!periodStart || !periodEnd) return;
    setStatus("loading");
    setError(null);
    setQuestions([]);
    const response = await fetch("/api/secure/reflections", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        periodType,
        periodStart,
        periodEnd: periodEnd.toISOString(),
      }),
    });

    if (!response.ok) {
      const data = await response.json().catch(() => ({}));
      setError(data.message ?? "Unable to generate prompts");
      setStatus("idle");
      return;
    }

    const data = await response.json();
    setQuestions(data.questions ?? []);
    setSuggestions(data.suggestions ?? []);
    setAnswers({});
    setStatus("idle");
  };

  const saveReflection = async () => {
    if (!periodStart || !periodEnd || !questions.length) return;
    setStatus("saving");
    setError(null);
    const response = await fetch("/api/secure/reflections", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        periodType,
        periodStart,
        periodEnd: periodEnd.toISOString(),
        answers: questions.map((question) => ({
          question,
          answer: answers[question] ?? "",
        })),
      }),
    });

    if (!response.ok) {
      const data = await response.json().catch(() => ({}));
      setError(data.message ?? "Unable to save reflection");
      setStatus("idle");
      return;
    }

    setStatus("idle");
    setQuestions([]);
    setSuggestions([]);
    setAnswers({});
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>New reflection</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <Label>Period type</Label>
            <Select value={periodType} onValueChange={setPeriodType}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {periods.map((period) => (
                  <SelectItem key={period.value} value={period.value}>
                    {period.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div>
            <Label>Start date</Label>
            <Input type="date" value={periodStart} onChange={(event) => setPeriodStart(event.target.value)} />
          </div>
        </div>
        <Button
          onClick={fetchPrompts}
          disabled={!periodStart || status === "loading"}
          variant="outline"
        >
          {status === "loading" ? "Generating..." : "Generate AI questions"}
        </Button>

        {error ? <p className="text-sm text-destructive">{error}</p> : null}

        {suggestions.length ? (
          <div className="rounded-lg border p-3 text-sm text-muted-foreground space-y-2">
            <p className="font-medium text-foreground">Suggestions</p>
            <ul className="list-disc pl-4">
              {suggestions.map((suggestion) => (
                <li key={suggestion}>{suggestion}</li>
              ))}
            </ul>
          </div>
        ) : null}

        {questions.length ? (
          <div className="space-y-4">
            {questions.map((question) => (
              <div key={question} className="space-y-2">
                <Label>{question}</Label>
                <Textarea
                  value={answers[question] ?? ""}
                  onChange={(event) =>
                    setAnswers((prev) => ({
                      ...prev,
                      [question]: event.target.value,
                    }))
                  }
                  className="min-h-[120px]"
                />
              </div>
            ))}
            <Button onClick={saveReflection} disabled={status === "saving"}>
              {status === "saving" ? "Saving..." : "Save reflection"}
            </Button>
          </div>
        ) : null}
      </CardContent>
    </Card>
  );
};

