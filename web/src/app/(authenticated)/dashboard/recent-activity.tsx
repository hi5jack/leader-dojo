"use client";

import Link from "next/link";
import { 
  MessageSquare, 
  FileText, 
  GitBranch, 
  StickyNote, 
  Sparkles, 
  BookOpen,
  CheckCircle2,
} from "lucide-react";
import { formatDistanceToNow } from "date-fns";

import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

type EntryKind = "meeting" | "update" | "decision" | "note" | "prep" | "reflection" | "commitment";

type RecentEntry = {
  id: string;
  projectId: string;
  projectName: string;
  kind: EntryKind;
  title: string;
  occurredAt: Date;
  aiSummary?: string | null;
};

type Props = {
  entries: RecentEntry[];
};

const kindConfig: Record<EntryKind, { icon: typeof MessageSquare; label: string; color: string }> = {
  meeting: { 
    icon: MessageSquare, 
    label: "Meeting", 
    color: "text-blue-500 bg-blue-50 dark:bg-blue-950/50" 
  },
  update: { 
    icon: FileText, 
    label: "Update", 
    color: "text-green-500 bg-green-50 dark:bg-green-950/50" 
  },
  decision: { 
    icon: GitBranch, 
    label: "Decision", 
    color: "text-purple-500 bg-purple-50 dark:bg-purple-950/50" 
  },
  note: { 
    icon: StickyNote, 
    label: "Note", 
    color: "text-amber-500 bg-amber-50 dark:bg-amber-950/50" 
  },
  prep: { 
    icon: Sparkles, 
    label: "Prep", 
    color: "text-cyan-500 bg-cyan-50 dark:bg-cyan-950/50" 
  },
  reflection: { 
    icon: BookOpen, 
    label: "Reflection", 
    color: "text-rose-500 bg-rose-50 dark:bg-rose-950/50" 
  },
  commitment: { 
    icon: CheckCircle2, 
    label: "Commitment", 
    color: "text-emerald-500 bg-emerald-50 dark:bg-emerald-950/50" 
  },
};

export function RecentActivity({ entries }: Props) {
  return (
    <div className="space-y-3">
      {entries
        // Never show commitment entries in the dashboard recent activity list
        .filter((entry) => entry.kind !== "commitment")
        .map((entry, index) => {
        const config = kindConfig[entry.kind] || kindConfig.note;
        const Icon = config.icon;

        return (
          <Link 
            key={entry.id} 
            href={`/projects/${entry.projectId}?entry=${entry.id}`}
            className="block"
          >
            <div 
              className={cn(
                "flex items-start gap-3 p-3 rounded-lg transition-colors",
                "hover:bg-muted/50 cursor-pointer",
                "border border-transparent hover:border-border"
              )}
            >
              {/* Kind icon */}
              <div className={cn("p-2 rounded-lg shrink-0", config.color)}>
                <Icon className="w-4 h-4" />
              </div>

              {/* Content */}
              <div className="flex-1 min-w-0 space-y-1">
                <div className="flex items-start justify-between gap-2">
                  <p className="font-medium text-sm line-clamp-1">{entry.title}</p>
                  <time className="text-xs text-muted-foreground shrink-0">
                    {formatDistanceToNow(new Date(entry.occurredAt), { addSuffix: true })}
                  </time>
                </div>
                <div className="flex items-center gap-2">
                  <Badge variant="outline" className="text-xs px-1.5 py-0">
                    {entry.projectName}
                  </Badge>
                  <span className="text-xs text-muted-foreground">
                    {config.label}
                  </span>
                </div>
                {entry.aiSummary && (
                  <p className="text-xs text-muted-foreground line-clamp-1">
                    {entry.aiSummary}
                  </p>
                )}
              </div>
            </div>
          </Link>
        );
      })}
    </div>
  );
}

