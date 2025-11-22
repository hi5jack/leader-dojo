"use client";

import { useMemo, useState } from "react";

import { Badge } from "@/components/ui/badge";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import type { ProjectEntry } from "@/lib/db/types";

const entryKinds = [
  { label: "All", value: "all" },
  { label: "Meeting", value: "meeting" },
  { label: "Update", value: "update" },
  { label: "Decision", value: "decision" },
  { label: "Note", value: "note" },
  { label: "Self Note", value: "self_note" },
] as const;

type Props = {
  entries: ProjectEntry[];
  onSummarize?: (entryId: string) => void;
};

export const ProjectTimeline = ({ entries }: Props) => {
  const [filter, setFilter] = useState<(typeof entryKinds)[number]["value"]>("all");

  const filteredEntries = useMemo(() => {
    if (filter === "all") return entries;
    return entries.filter((entry) => entry.kind === filter);
  }, [entries, filter]);

  return (
    <div className="space-y-4">
      <Tabs value={filter} onValueChange={(value) => setFilter(value as typeof filter)}>
        <TabsList className="flex flex-wrap">
          {entryKinds.map((kind) => (
            <TabsTrigger key={kind.value} value={kind.value}>
              {kind.label}
            </TabsTrigger>
          ))}
        </TabsList>
      </Tabs>
      <div className="space-y-4">
        {filteredEntries.length === 0 ? (
          <p className="text-sm text-muted-foreground">No entries yet.</p>
        ) : (
          filteredEntries.map((entry) => (
            <div key={entry.id} className="rounded-lg border p-4">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <div>
                  <p className="font-medium">{entry.title}</p>
                  <p className="text-sm text-muted-foreground">
                    {entry.occurredAt ? new Date(entry.occurredAt).toLocaleString() : "No timestamp"}
                  </p>
                </div>
                <Badge variant="outline">{entry.kind}</Badge>
              </div>
              {entry.aiSummary ? (
                <p className="mt-3 text-sm text-muted-foreground">{entry.aiSummary}</p>
              ) : entry.rawContent ? (
                <p className="mt-3 text-sm text-muted-foreground line-clamp-3">{entry.rawContent}</p>
              ) : null}
            </div>
          ))
        )}
      </div>
    </div>
  );
};

