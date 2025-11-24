"use client";

import { useEffect, useState, use } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { toast } from "sonner";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { 
  ArrowLeft, 
  Calendar, 
  FileText, 
  Lightbulb, 
  Edit2, 
  Save, 
  X, 
  Trash2,
  Loader2 
} from "lucide-react";
import type { ProjectEntry } from "@/lib/db/types";

type Params = Promise<{
  id: string;
  entryId: string;
}>;

const getKindIcon = (kind: string) => {
  switch (kind) {
    case "meeting":
      return "👥";
    case "update":
      return "📝";
    case "decision":
      return "✅";
    case "note":
      return "💡";
    default:
      return "📄";
  }
};

const formatDate = (date: Date | string) => {
  const d = new Date(date);
  return d.toLocaleString("en-US", {
    weekday: "short",
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
};

const formatDateForInput = (date: Date | string) => {
  const d = new Date(date);
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  const hours = String(d.getHours()).padStart(2, "0");
  const minutes = String(d.getMinutes()).padStart(2, "0");

  // `datetime-local` expects a local time string without timezone information.
  // We intentionally use the local components here to avoid converting to UTC,
  // which was causing an offset between display and edit modes.
  return `${year}-${month}-${day}T${hours}:${minutes}`;
};

// Lightweight remark plugin to support ==highlight== syntax by converting it to <mark>.
// It scans text nodes for ==...== and wraps the contents in a "mark" node that
// ReactMarkdown renders as a <mark> element (styled in globals.css).
const remarkHighlight = () => {
  return (tree: any) => {
    const visit = (node: any) => {
      if (!node || !node.children) return;

      node.children = node.children.flatMap((child: any) => {
        if (child.type === "text" && typeof child.value === "string") {
          const value: string = child.value;
          const regex = /==([^=]+)==/g;
          const parts: any[] = [];
          let lastIndex = 0;
          let match: RegExpExecArray | null;

          while ((match = regex.exec(value)) !== null) {
            if (match.index > lastIndex) {
              parts.push({
                type: "text",
                value: value.slice(lastIndex, match.index),
              });
            }

            parts.push({
              type: "mark",
              data: { hName: "mark" },
              children: [{ type: "text", value: match[1] }],
            });

            lastIndex = match.index + match[0].length;
          }

          if (!parts.length) {
            return child;
          }

          if (lastIndex < value.length) {
            parts.push({
              type: "text",
              value: value.slice(lastIndex),
            });
          }

          return parts;
        }

        visit(child);
        return child;
      });
    };

    visit(tree);
  };
};

export default function EntryDetailPage({
  params,
}: {
  params: Params;
}) {
  const router = useRouter();
  const { id: projectId, entryId } = use(params);

  const [entry, setEntry] = useState<ProjectEntry | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  const [editedTitle, setEditedTitle] = useState("");
  const [editedKind, setEditedKind] = useState("");
  const [editedOccurredAt, setEditedOccurredAt] = useState("");
  const [editedRawContent, setEditedRawContent] = useState("");

  useEffect(() => {
    fetchEntry();
  }, [entryId]);

  const fetchEntry = async () => {
    try {
      setIsLoading(true);
      const response = await fetch(`/api/secure/entries/${entryId}`);
      
      if (response.status === 404) {
        router.push(`/projects/${projectId}`);
        return;
      }

      if (!response.ok) {
        throw new Error("Failed to load entry");
      }

      const data = await response.json();
      
      // Verify the entry belongs to the current project
      if (data.projectId !== projectId) {
        router.push(`/projects/${projectId}`);
        return;
      }

      setEntry(data);
      resetEditedFields(data);
    } catch (error) {
      console.error("Error fetching entry:", error);
      toast.error("Failed to load entry");
    } finally {
      setIsLoading(false);
    }
  };

  const resetEditedFields = (entryData: ProjectEntry) => {
    setEditedTitle(entryData.title || "");
    setEditedKind(entryData.kind || "meeting");
    setEditedOccurredAt(
      entryData.occurredAt ? formatDateForInput(entryData.occurredAt) : ""
    );
    setEditedRawContent(entryData.rawContent || "");
  };

  const handleEditToggle = () => {
    if (isEditing) {
      // Cancel edit
      if (entry) {
        resetEditedFields(entry);
      }
      setIsEditing(false);
    } else {
      // Enter edit mode
      setIsEditing(true);
    }
  };

  const handleSave = async () => {
    if (!entry) return;

    try {
      setIsSaving(true);

      const response = await fetch(`/api/secure/entries/${entryId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          title: editedTitle,
          kind: editedKind,
          occurredAt: new Date(editedOccurredAt).toISOString(),
          rawContent: editedRawContent,
        }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || "Failed to update entry");
      }

      const updatedEntry = await response.json();
      setEntry(updatedEntry);
      setIsEditing(false);
      toast.success("Entry updated successfully");
    } catch (error) {
      console.error("Error saving entry:", error);
      toast.error(error instanceof Error ? error.message : "Failed to save entry");
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async () => {
    try {
      setIsDeleting(true);

      const response = await fetch(`/api/secure/entries/${entryId}`, {
        method: "DELETE",
      });

      if (!response.ok) {
        throw new Error("Failed to delete entry");
      }

      toast.success("Entry deleted successfully");
      router.push(`/projects/${projectId}`);
    } catch (error) {
      console.error("Error deleting entry:", error);
      toast.error("Failed to delete entry");
      setIsDeleting(false);
      setShowDeleteConfirm(false);
    }
  };

  if (isLoading) {
    return (
      <div className="section-gap max-w-4xl mx-auto">
        <div className="flex items-center justify-center py-12">
          <Loader2 className="w-8 h-8 animate-spin text-muted-foreground" />
        </div>
      </div>
    );
  }

  if (!entry) {
    return (
      <div className="section-gap max-w-4xl mx-auto">
        <Card variant="elevated" padding="mobile">
          <CardContent className="py-12 text-center">
            <p className="text-muted-foreground">Entry not found</p>
            <Button asChild className="mt-4">
              <Link href={`/projects/${projectId}`}>Back to Project</Link>
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="section-gap max-w-4xl mx-auto">
      {/* Back Navigation */}
      <div className="mb-6 flex items-center justify-between">
        <Button variant="ghost" size="sm" asChild>
          <Link href={`/projects/${projectId}`}>
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to Project
          </Link>
        </Button>

        {/* Action Buttons */}
        <div className="flex items-center gap-2">
          {!isEditing ? (
            <>
              <Button
                variant="outline"
                size="sm"
                onClick={handleEditToggle}
              >
                <Edit2 className="w-4 h-4 mr-2" />
                Edit
              </Button>
              <Button
                variant="destructive"
                size="sm"
                onClick={() => setShowDeleteConfirm(true)}
              >
                <Trash2 className="w-4 h-4 mr-2" />
                Delete
              </Button>
            </>
          ) : (
            <>
              <Button
                variant="outline"
                size="sm"
                onClick={handleEditToggle}
                disabled={isSaving}
              >
                <X className="w-4 h-4 mr-2" />
                Cancel
              </Button>
              <Button
                size="sm"
                onClick={handleSave}
                disabled={isSaving}
              >
                {isSaving ? (
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                ) : (
                  <Save className="w-4 h-4 mr-2" />
                )}
                Save
              </Button>
            </>
          )}
        </div>
      </div>

      {/* Entry Header */}
      <div className="space-y-4 mb-8">
        <div className="flex items-start gap-3">
          <span className="text-4xl" aria-label={`${entry.kind} entry`}>
            {getKindIcon(isEditing ? editedKind : entry.kind)}
          </span>
          <div className="flex-1 space-y-4">
            {isEditing ? (
              <>
                <div className="space-y-2">
                  <Label htmlFor="title">Title</Label>
                  <Input
                    id="title"
                    value={editedTitle}
                    onChange={(e) => setEditedTitle(e.target.value)}
                    placeholder="Entry title"
                  />
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="kind">Type</Label>
                    <Select value={editedKind} onValueChange={setEditedKind}>
                      <SelectTrigger id="kind">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="meeting">Meeting</SelectItem>
                        <SelectItem value="update">Update</SelectItem>
                        <SelectItem value="decision">Decision</SelectItem>
                        <SelectItem value="note">Note</SelectItem>
                        <SelectItem value="prep">Prep</SelectItem>
                        <SelectItem value="reflection">Reflection</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="occurredAt">Date & Time</Label>
                    <Input
                      id="occurredAt"
                      type="datetime-local"
                      value={editedOccurredAt}
                      onChange={(e) => setEditedOccurredAt(e.target.value)}
                    />
                  </div>
                </div>
              </>
            ) : (
              <>
                <h1 className="mb-2">{entry.title || "Untitled Entry"}</h1>
                <div className="flex flex-wrap items-center gap-2">
                  <Badge variant="outline" size="lg">
                    {entry.kind.replace("_", " ")}
                  </Badge>
                  {entry.isDecision && (
                    <Badge variant="success" size="lg">
                      Decision
                    </Badge>
                  )}
                  <div className="flex items-center gap-1 text-sm text-muted-foreground">
                    <Calendar className="w-4 h-4" />
                    <span>
                      {entry.occurredAt
                        ? formatDate(entry.occurredAt)
                        : "No timestamp"}
                    </span>
                  </div>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Raw Content */}
      <Card variant="elevated" padding="mobile" className="mb-6">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileText className="w-5 h-5" />
            Content
          </CardTitle>
        </CardHeader>
        <CardContent>
          {isEditing ? (
            <div className="space-y-2">
              <Label htmlFor="rawContent">Content (Markdown supported)</Label>
              <Textarea
                id="rawContent"
                value={editedRawContent}
                onChange={(e) => setEditedRawContent(e.target.value)}
                placeholder="Write your entry content here... Markdown is supported."
                rows={12}
                className="font-mono text-sm"
              />
              <p className="text-xs text-muted-foreground">
                You can use Markdown formatting (headers, lists, bold, italic, links, etc.)
              </p>
            </div>
          ) : entry.rawContent ? (
            <div className="prose prose-sm md:prose-base dark:prose-invert max-w-none">
              <ReactMarkdown remarkPlugins={[remarkGfm, remarkHighlight]}>
                {entry.rawContent}
              </ReactMarkdown>
            </div>
          ) : (
            <p className="text-sm text-muted-foreground italic">No content</p>
          )}
        </CardContent>
      </Card>

      {/* AI Summary */}
      {!isEditing && entry.aiSummary && (
        <Card variant="elevated" padding="mobile" className="mb-6">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Lightbulb className="w-5 h-5" />
              AI Summary
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground leading-relaxed">
              {entry.aiSummary}
            </p>
          </CardContent>
        </Card>
      )}

      {/* Suggested Actions */}
      {!isEditing && entry.aiSuggestedActions && entry.aiSuggestedActions.length > 0 && (
        <Card variant="elevated" padding="mobile">
          <CardHeader>
            <CardTitle>Suggested Actions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {entry.aiSuggestedActions.map((action: any, index: number) => (
              <Card key={index} variant="interactive" className="shadow-none">
                <CardContent className="p-4">
                  <div className="space-y-2">
                    <div className="flex items-start justify-between gap-2">
                      <p className="font-medium">{action.title}</p>
                      {action.direction && (
                        <Badge
                          variant={
                            action.direction === "i_owe" ? "i-owe" : "waiting-for"
                          }
                        >
                          {action.direction === "i_owe" ? "I Owe" : "Waiting"}
                        </Badge>
                      )}
                    </div>
                    {action.counterparty && (
                      <p className="text-sm text-muted-foreground">
                        With: {action.counterparty}
                      </p>
                    )}
                    {action.dueDate && (
                      <p className="text-sm text-muted-foreground">
                        Due: {new Date(action.dueDate).toLocaleDateString("en-US")}
                      </p>
                    )}
                    {action.notes && (
                      <p className="text-sm text-muted-foreground italic">
                        {action.notes}
                      </p>
                    )}
                  </div>
                </CardContent>
              </Card>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Delete Confirmation Dialog */}
      <Dialog open={showDeleteConfirm} onOpenChange={setShowDeleteConfirm}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Entry</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete this entry? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <div className="py-4">
            <p className="text-sm font-medium">
              Entry: <span className="text-muted-foreground">{entry.title}</span>
            </p>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setShowDeleteConfirm(false)}
              disabled={isDeleting}
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleDelete}
              disabled={isDeleting}
            >
              {isDeleting ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  Deleting...
                </>
              ) : (
                <>
                  <Trash2 className="w-4 h-4 mr-2" />
                  Delete
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
