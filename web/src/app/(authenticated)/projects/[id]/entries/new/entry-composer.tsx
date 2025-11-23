"use client";

import { useMemo, useState } from "react";

import { SuggestedAction } from "@/lib/ai/types";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";

type EntryState = {
  id: string;
  title: string;
};

type SuggestionState = SuggestedAction & {
  id: string;
  selected: boolean;
};

const entryKinds = [
  { label: "Meeting", value: "meeting" },
  { label: "Update", value: "update" },
  { label: "Decision", value: "decision" },
  { label: "Note", value: "note" },
  { label: "Self note", value: "self_note" },
];

export const EntryComposer = ({ projectId }: { projectId: string }) => {
  const [kind, setKind] = useState("meeting");
  const [status, setStatus] = useState<"idle" | "saving" | "ready" | "summarizing">("idle");
  const [entry, setEntry] = useState<EntryState | null>(null);
  const [summary, setSummary] = useState("");
  const [suggestions, setSuggestions] = useState<SuggestionState[]>([]);
  const [error, setError] = useState<string | null>(null);

  const selectedCount = useMemo(() => suggestions.filter((item) => item.selected).length, [suggestions]);

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);
    setStatus("saving");
    const formData = new FormData(event.currentTarget);

    const payload = {
      title: formData.get("title")?.toString() ?? "",
      kind,
      occurredAt: formData.get("occurredAt")?.toString() ?? new Date().toISOString(),
      rawContent: formData.get("rawContent")?.toString() ?? "",
    };

    const response = await fetch(`/api/secure/projects/${projectId}/entries`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const data = await response.json().catch(() => ({}));
      setError(data.message ?? "Unable to save entry");
      setStatus("idle");
      return;
    }

    const saved = await response.json();
    setEntry({ id: saved.id, title: saved.title });
    setStatus("ready");
  };

  const handleSummarize = async () => {
    if (!entry) return;
    setStatus("summarizing");
    setError(null);

    try {
      const response = await fetch(`/api/secure/entries/${entry.id}/summarize`, {
        method: "POST",
      });

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        setError(data.message ?? "AI summarization failed. Your entry was saved, but we couldn't generate a summary.");
        setStatus("ready");
        return;
      }

      const result = await response.json();
      setSummary(result.summary);
      setSuggestions(
        result.suggestedActions.map((action: SuggestedAction, index: number) => ({
          ...action,
          id: `${index}-${action.title}`,
          selected: true,
        })),
      );
      setStatus("ready");
    } catch (error) {
      console.error("Summarization request failed:", error);
      setError("Network error. Please check your connection and try again.");
      setStatus("ready");
    }
  };

  const toggleSuggestion = (id: string, updates?: Partial<SuggestionState>) => {
    setSuggestions((prev) =>
      prev.map((item) =>
        item.id === id
          ? {
              ...item,
              ...updates,
            }
          : item,
      ),
    );
  };

  const handleCreateCommitments = async () => {
    if (!entry) return;
    const actions = suggestions.filter((item) => item.selected);
    if (!actions.length) return;

    setStatus("summarizing");
    const response = await fetch(`/api/secure/entries/${entry.id}/commitments`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        projectId,
        actions: actions.map((action) => ({
          title: action.title,
          direction: action.direction,
          counterparty: action.counterparty,
          dueDate: action.dueDate,
          notes: action.notes,
          importance: action.importance,
          urgency: action.urgency,
        })),
      }),
    });

    if (!response.ok) {
      const data = await response.json().catch(() => ({}));
      setError(data.message ?? "Failed to create commitments");
      setStatus("ready");
      return;
    }

    setStatus("ready");
  };

  return (
    <div className="grid gap-6 lg:grid-cols-[1.5fr_1fr]">
      <Card>
        <CardHeader>
          <CardTitle>Entry details</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="flex gap-3">
              <div className="flex-1">
                <Label htmlFor="title">Title</Label>
                <Input id="title" name="title" placeholder="Weekly sync with product" required />
              </div>
              <div className="w-48">
                <Label htmlFor="kind">Kind</Label>
                <Select value={kind} onValueChange={setKind}>
                  <SelectTrigger id="kind">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {entryKinds.map((item) => (
                      <SelectItem key={item.value} value={item.value}>
                        {item.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div>
              <Label htmlFor="occurredAt">Occurred at</Label>
              <Input id="occurredAt" name="occurredAt" type="datetime-local" />
            </div>
            <div>
              <Label htmlFor="rawContent">Notes / transcript</Label>
              <Textarea
                id="rawContent"
                name="rawContent"
                className="min-h-[200px]"
                placeholder="Paste meeting notes or key points..."
              />
            </div>

            {error ? <p className="text-sm text-destructive">{error}</p> : null}

            <Button type="submit" disabled={status === "saving"}>
              {status === "saving" ? "Saving..." : "Save entry"}
            </Button>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>AI summary & actions</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <Button
            variant="outline"
            className="w-full"
            disabled={!entry || status === "summarizing"}
            onClick={handleSummarize}
          >
            {status === "summarizing" ? "Running AI..." : "Generate summary"}
          </Button>

          {summary ? (
            <div className="space-y-2 rounded-lg border p-3">
              <div className="flex items-center gap-2">
                <Badge variant="secondary">Summary</Badge>
                <span className="text-xs text-muted-foreground">
                  Saved automatically to the entry
                </span>
              </div>
              <p className="text-sm text-muted-foreground">{summary}</p>
            </div>
          ) : null}

          {suggestions.length ? (
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-medium">Suggested commitments</h3>
                <span className="text-xs text-muted-foreground">{selectedCount} selected</span>
              </div>
              <div className="space-y-3">
                {suggestions.map((suggestion) => (
                  <div key={suggestion.id} className="rounded-lg border p-3 space-y-3">
                    <div className="flex items-center gap-2">
                      <Checkbox
                        checked={suggestion.selected}
                        onCheckedChange={(checked) =>
                          toggleSuggestion(suggestion.id, { selected: Boolean(checked) })
                        }
                      />
                      <Input
                        value={suggestion.title}
                        onChange={(event) =>
                          toggleSuggestion(suggestion.id, { title: event.target.value })
                        }
                      />
                    </div>
                    <div className="grid gap-3 sm:grid-cols-2">
                      <div>
                        <Label>Direction</Label>
                        <Select
                          value={suggestion.direction}
                          onValueChange={(value) =>
                            toggleSuggestion(suggestion.id, {
                              direction: value as "i_owe" | "waiting_for",
                            })
                          }
                        >
                          <SelectTrigger>
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="i_owe">I Owe</SelectItem>
                            <SelectItem value="waiting_for">Waiting For</SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                      <div>
                        <Label>Counterparty</Label>
                        <Input
                          value={suggestion.counterparty ?? ""}
                          placeholder="Person or team"
                          onChange={(event) =>
                            toggleSuggestion(suggestion.id, { counterparty: event.target.value })
                          }
                        />
                      </div>
                      <div>
                        <Label>Due date</Label>
                        <Input
                          type="date"
                          value={suggestion.dueDate ?? ""}
                          onChange={(event) =>
                            toggleSuggestion(suggestion.id, { dueDate: event.target.value })
                          }
                        />
                      </div>
                      <div className="flex gap-3">
                        <div>
                          <Label>Importance</Label>
                          <Input
                            type="number"
                            min={1}
                            max={5}
                            value={suggestion.importance ?? 3}
                            onChange={(event) =>
                              toggleSuggestion(suggestion.id, {
                                importance: Number(event.target.value),
                              })
                            }
                          />
                        </div>
                        <div>
                          <Label>Urgency</Label>
                          <Input
                            type="number"
                            min={1}
                            max={5}
                            value={suggestion.urgency ?? 3}
                            onChange={(event) =>
                              toggleSuggestion(suggestion.id, {
                                urgency: Number(event.target.value),
                              })
                            }
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
              <Button
                className="w-full"
                variant="secondary"
                disabled={!selectedCount || status === "summarizing"}
                onClick={handleCreateCommitments}
              >
                Create commitments
              </Button>
            </div>
          ) : null}
        </CardContent>
      </Card>
    </div>
  );
};

