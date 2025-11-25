"use client";

import { useState, useMemo } from "react";
import Link from "next/link";
import { 
  MessageSquare, 
  FileText, 
  GitBranch, 
  StickyNote, 
  Sparkles, 
  BookOpen,
  CheckCircle2,
  Filter,
  X,
} from "lucide-react";
import { format, isToday, isYesterday, isThisWeek, startOfDay } from "date-fns";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { EmptyState } from "@/components/ui/empty-state";
import { cn } from "@/lib/utils";

type EntryKind = "meeting" | "update" | "decision" | "note" | "prep" | "reflection" | "commitment";

type Entry = {
  id: string;
  projectId: string;
  projectName: string;
  kind: EntryKind;
  title: string;
  occurredAt: Date;
  aiSummary?: string | null;
  rawContent?: string | null;
};

type Project = {
  id: string;
  name: string;
};

type Props = {
  initialEntries: Entry[];
  projects: Project[];
};

const kindConfig: Record<EntryKind, { icon: typeof MessageSquare; label: string; color: string }> = {
  meeting: { 
    icon: MessageSquare, 
    label: "Meeting", 
    color: "text-blue-500 bg-blue-100 dark:bg-blue-950/50" 
  },
  update: { 
    icon: FileText, 
    label: "Update", 
    color: "text-green-500 bg-green-100 dark:bg-green-950/50" 
  },
  decision: { 
    icon: GitBranch, 
    label: "Decision", 
    color: "text-purple-500 bg-purple-100 dark:bg-purple-950/50" 
  },
  note: { 
    icon: StickyNote, 
    label: "Note", 
    color: "text-amber-500 bg-amber-100 dark:bg-amber-950/50" 
  },
  prep: { 
    icon: Sparkles, 
    label: "Prep", 
    color: "text-cyan-500 bg-cyan-100 dark:bg-cyan-950/50" 
  },
  reflection: { 
    icon: BookOpen, 
    label: "Reflection", 
    color: "text-rose-500 bg-rose-100 dark:bg-rose-950/50" 
  },
  commitment: { 
    icon: CheckCircle2, 
    label: "Commitment", 
    color: "text-emerald-500 bg-emerald-100 dark:bg-emerald-950/50" 
  },
};

// Available filters in the UI (commitment entries are intentionally excluded)
const ENTRY_KINDS: EntryKind[] = ["meeting", "update", "decision", "note", "prep", "reflection"];

function getDateGroup(date: Date): string {
  if (isToday(date)) return "Today";
  if (isYesterday(date)) return "Yesterday";
  if (isThisWeek(date, { weekStartsOn: 1 })) return "This Week";
  return format(date, "MMMM d, yyyy");
}

function groupEntriesByDate(entries: Entry[]): Map<string, Entry[]> {
  const groups = new Map<string, Entry[]>();
  
  entries.forEach((entry) => {
    const date = new Date(entry.occurredAt);
    const group = getDateGroup(date);
    
    if (!groups.has(group)) {
      groups.set(group, []);
    }
    groups.get(group)!.push(entry);
  });

  return groups;
}

export function ActivityTimeline({ initialEntries, projects }: Props) {
  const [projectFilter, setProjectFilter] = useState<string>("all");
  const [kindFilter, setKindFilter] = useState<string>("all");

  const filteredEntries = useMemo(() => {
    return initialEntries.filter((entry) => {
      // Never show commitment entries in the activity timeline
      if (entry.kind === "commitment") {
        return false;
      }
      if (projectFilter !== "all" && entry.projectId !== projectFilter) {
        return false;
      }
      if (kindFilter !== "all" && entry.kind !== kindFilter) {
        return false;
      }
      return true;
    });
  }, [initialEntries, projectFilter, kindFilter]);

  const groupedEntries = useMemo(() => {
    return groupEntriesByDate(filteredEntries);
  }, [filteredEntries]);

  const hasFilters = projectFilter !== "all" || kindFilter !== "all";

  const clearFilters = () => {
    setProjectFilter("all");
    setKindFilter("all");
  };

  return (
    <div className="space-y-6">
      {/* Filters */}
      <Card variant="elevated" className="p-4">
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <Filter className="w-4 h-4" />
            <span>Filters:</span>
          </div>
          
          <Select value={projectFilter} onValueChange={setProjectFilter}>
            <SelectTrigger className="w-[180px]">
              <SelectValue placeholder="All Projects" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Projects</SelectItem>
              {projects.map((project) => (
                <SelectItem key={project.id} value={project.id}>
                  {project.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>

          <Select value={kindFilter} onValueChange={setKindFilter}>
            <SelectTrigger className="w-[150px]">
              <SelectValue placeholder="All Types" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Types</SelectItem>
              {ENTRY_KINDS.map((kind) => (
                <SelectItem key={kind} value={kind}>
                  {kindConfig[kind].label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>

          {hasFilters && (
            <Button 
              variant="ghost" 
              size="sm" 
              onClick={clearFilters}
              className="text-muted-foreground"
            >
              <X className="w-4 h-4 mr-1" />
              Clear
            </Button>
          )}

          <div className="ml-auto text-sm text-muted-foreground">
            {filteredEntries.length} entries
          </div>
        </div>
      </Card>

      {/* Timeline */}
      {filteredEntries.length === 0 ? (
        <EmptyState
          icon={<MessageSquare className="w-8 h-8" />}
          title={hasFilters ? "No entries match filters" : "No activity yet"}
          description={
            hasFilters 
              ? "Try adjusting your filters or clear them to see all entries."
              : "Start by creating a project and adding your first entry."
          }
          action={
            hasFilters ? (
              <Button variant="outline" onClick={clearFilters}>
                Clear filters
              </Button>
            ) : undefined
          }
        />
      ) : (
        <div className="space-y-8">
          {Array.from(groupedEntries.entries()).map(([dateGroup, entries]) => (
            <div key={dateGroup} className="space-y-4">
              {/* Date header */}
              <div className="sticky top-0 z-10 py-2 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
                <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider">
                  {dateGroup}
                </h2>
              </div>

              {/* Entries for this date */}
              <div className="space-y-3">
                {entries.map((entry) => {
                  const config = kindConfig[entry.kind] || kindConfig.note;
                  const Icon = config.icon;
                  const entryDate = new Date(entry.occurredAt);

                  return (
                    <Link 
                      key={entry.id} 
                      href={`/projects/${entry.projectId}?entry=${entry.id}`}
                      className="block group"
                    >
                      <Card 
                        variant="interactive" 
                        className="transition-all group-hover:shadow-md"
                      >
                        <CardContent className="p-4">
                          <div className="flex items-start gap-4">
                            {/* Timeline indicator */}
                            <div className="flex flex-col items-center">
                              <div className={cn(
                                "p-2.5 rounded-xl shrink-0 transition-transform group-hover:scale-105",
                                config.color
                              )}>
                                <Icon className="w-5 h-5" />
                              </div>
                              <div className="w-0.5 h-full bg-border mt-2 hidden md:block" />
                            </div>

                            {/* Content */}
                            <div className="flex-1 min-w-0 space-y-2">
                              <div className="flex items-start justify-between gap-3">
                                <div className="space-y-1">
                                  <h3 className="font-medium text-base line-clamp-2 group-hover:text-primary transition-colors">
                                    {entry.title}
                                  </h3>
                                  <div className="flex items-center gap-2 flex-wrap">
                                    <Badge variant="outline" className="text-xs">
                                      {entry.projectName}
                                    </Badge>
                                    <span className="text-xs text-muted-foreground">
                                      {config.label}
                                    </span>
                                  </div>
                                </div>
                                <time className="text-xs text-muted-foreground shrink-0">
                                  {format(entryDate, "h:mm a")}
                                </time>
                              </div>

                              {/* Summary or content preview */}
                              {(entry.aiSummary || entry.rawContent) && (
                                <p className="text-sm text-muted-foreground line-clamp-2">
                                  {entry.aiSummary || entry.rawContent}
                                </p>
                              )}
                            </div>
                          </div>
                        </CardContent>
                      </Card>
                    </Link>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

