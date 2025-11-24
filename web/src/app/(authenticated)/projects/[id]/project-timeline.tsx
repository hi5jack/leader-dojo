"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { FileText, Calendar, Lightbulb, FileCheck, StickyNote, MessageSquare, ChevronRight } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { EmptyState } from "@/components/ui/empty-state";
import {
  Timeline,
  TimelineItem,
  TimelineContent,
  TimelineHeader,
  TimelineTitle,
  TimelineDescription,
  TimelineTime,
} from "@/components/ui/timeline";
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
  projectId: string;
  onSummarize?: (entryId: string) => void;
};

const getKindIcon = (kind: string) => {
  switch (kind) {
    case "meeting":
      return <MessageSquare className="w-5 h-5" />;
    case "update":
      return <Calendar className="w-5 h-5" />;
    case "decision":
      return <FileCheck className="w-5 h-5" />;
    case "self_note":
      return <StickyNote className="w-5 h-5" />;
    case "note":
      return <Lightbulb className="w-5 h-5" />;
    default:
      return <FileText className="w-5 h-5" />;
  }
};

const formatDate = (date: Date | string) => {
  const d = new Date(date);
  const now = new Date();
  const diffMs = now.getTime() - d.getTime();
  const isFuture = diffMs < 0;
  const absMs = Math.abs(diffMs);
  const diffMins = Math.floor(absMs / 60000);
  const diffHours = Math.floor(absMs / 3600000);
  const diffDays = Math.floor(absMs / 86400000);

  // For future timestamps, show "in X" instead of negative "X minutes ago".
  if (diffMins < 60) {
    return isFuture ? `in ${diffMins} minutes` : `${diffMins} minutes ago`;
  }
  if (diffHours < 24) {
    return isFuture ? `in ${diffHours} hours` : `${diffHours} hours ago`;
  }
  if (diffDays < 7) {
    return isFuture ? `in ${diffDays} days` : `${diffDays} days ago`;
  }

  // For older/future entries, fall back to a calendar date with a fixed locale
  // so that server and client renders stay in sync.
  return d.toLocaleDateString("en-US");
};

export const ProjectTimeline = ({ entries, projectId }: Props) => {
  const [filter, setFilter] = useState<(typeof entryKinds)[number]["value"]>("all");

  const filteredEntries = useMemo(() => {
    if (filter === "all") return entries;
    return entries.filter((entry) => entry.kind === filter);
  }, [entries, filter]);

  return (
    <div className="space-y-4">
      <Tabs value={filter} onValueChange={(value) => setFilter(value as typeof filter)}>
        <TabsList className="w-full overflow-x-auto flex flex-nowrap justify-start md:justify-center">
          {entryKinds.map((kind) => (
            <TabsTrigger key={kind.value} value={kind.value} className="shrink-0">
              {kind.label}
            </TabsTrigger>
          ))}
        </TabsList>
      </Tabs>

      {filteredEntries.length === 0 ? (
        <EmptyState
          icon={<FileText className="w-8 h-8" />}
          title="No entries yet"
          description="Create your first entry to start tracking this project's timeline."
        />
      ) : (
        <Timeline>
          {filteredEntries.map((entry, index) => (
              <TimelineItem
                key={entry.id}
                icon={getKindIcon(entry.kind)}
                isLast={index === filteredEntries.length - 1}
              >
                <Link 
                  href={`/projects/${projectId}/entries/${entry.id}`}
                  className="block hover:opacity-80 transition-opacity"
                >
                  <TimelineContent>
                    <TimelineHeader>
                      <div className="flex-1">
                        <TimelineTitle>{entry.title || "Untitled"}</TimelineTitle>
                        <TimelineTime>
                          {entry.occurredAt ? formatDate(entry.occurredAt) : "No timestamp"}
                        </TimelineTime>
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge variant="outline">{entry.kind.replace("_", " ")}</Badge>
                        <ChevronRight className="w-4 h-4 text-muted-foreground" />
                      </div>
                    </TimelineHeader>
                    {entry.aiSummary ? (
                      <TimelineDescription>{entry.aiSummary}</TimelineDescription>
                    ) : entry.rawContent ? (
                      <TimelineDescription className="line-clamp-3">
                        {entry.rawContent}
                      </TimelineDescription>
                    ) : null}
                  </TimelineContent>
                </Link>
              </TimelineItem>
          ))}
        </Timeline>
      )}
    </div>
  );
};

