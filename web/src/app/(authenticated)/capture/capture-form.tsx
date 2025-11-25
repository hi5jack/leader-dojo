"use client";

import { useState } from "react";

import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Input } from "@/components/ui/input";
import { CommitmentFields } from "@/components/capture/commitment-fields";
import { ReflectionFields } from "@/components/capture/reflection-fields";
import type { Project } from "@/lib/db/types";

type EntryKind = "meeting" | "update" | "decision" | "note" | "prep" | "reflection" | "commitment";

export const CaptureForm = ({ projects }: { projects: Project[] }) => {
  const [projectId, setProjectId] = useState(projects[0]?.id ?? "new");
  const [newProjectName, setNewProjectName] = useState("");
  const [entryKind, setEntryKind] = useState<EntryKind>("note");
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [status, setStatus] = useState<"idle" | "saving" | "success" | "error">("idle");

  // Commitment fields
  const [direction, setDirection] = useState<"i_owe" | "waiting_for">("i_owe");
  const [counterparty, setCounterparty] = useState("");
  const [dueDate, setDueDate] = useState("");
  const [importance, setImportance] = useState(3);
  const [urgency, setUrgency] = useState(3);
  const [notes, setNotes] = useState("");

  // Reflection fields
  const [questionsAndAnswers, setQuestionsAndAnswers] = useState<
    Array<{ question: string; answer: string }>
  >([]);

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    
    // Validate input based on selection
    if (projectId === "new" && !newProjectName.trim()) {
      toast.error("Please enter a project name");
      return;
    }
    if (projectId !== "new" && !projectId) {
      toast.error("Please select a project");
      return;
    }
    if (!title.trim() && !content.trim()) {
      toast.error("Please enter a title or content");
      return;
    }

    setStatus("saving");

    let targetProjectId = projectId;

    // Create new project if needed
    if (projectId === "new") {
      const createProjectResponse = await fetch("/api/secure/projects", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: newProjectName.trim(),
          type: "project",
          status: "active",
          priority: 3,
        }),
      });

      if (!createProjectResponse.ok) {
        setStatus("error");
        toast.error("Unable to create project. Try again.");
        return;
      }

      const newProject = await createProjectResponse.json();
      targetProjectId = newProject.id;
    }

    // Build the capture payload based on entry kind
    const basePayload = {
      projectId: targetProjectId,
      kind: entryKind,
      title: title.trim() || content.split(".")[0]?.slice(0, 60) || "Quick note",
      rawContent: content.trim() || undefined,
      occurredAt: new Date().toISOString(),
    };

    let payload: any = basePayload;

    if (entryKind === "commitment") {
      payload = {
        ...basePayload,
        direction,
        counterparty: counterparty.trim() || undefined,
        dueDate: dueDate ? new Date(dueDate).toISOString() : undefined,
        importance,
        urgency,
        notes: notes.trim() || undefined,
      };
    } else if (entryKind === "reflection") {
      payload = {
        ...basePayload,
        questionsAndAnswers: questionsAndAnswers.filter(
          (qa) => qa.question.trim() && qa.answer.trim(),
        ),
      };
    }

    const response = await fetch("/api/secure/capture", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      setStatus("error");
      toast.error("Unable to save entry. Try again.");
      return;
    }

    // Reset form
    setTitle("");
    setContent("");
    setNewProjectName("");
    setProjectId(projects[0]?.id ?? "new");
    setEntryKind("note");
    setDirection("i_owe");
    setCounterparty("");
    setDueDate("");
    setImportance(3);
    setUrgency(3);
    setNotes("");
    setQuestionsAndAnswers([]);
    setStatus("success");
    toast.success(`${entryKind.charAt(0).toUpperCase() + entryKind.slice(1)} captured!`);
    setTimeout(() => setStatus("idle"), 2000);
  };

  return (
    <Card variant="elevated" padding="mobile" className="shadow-none border-0 md:border md:shadow-elevation-md">
      <CardContent className="space-y-6 p-6">
        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <Label className="text-base font-semibold mb-2">Project</Label>
            <Select value={projectId} onValueChange={setProjectId}>
              <SelectTrigger className="w-full h-12 text-base">
                <SelectValue placeholder="Select project" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="new">+ Create new project</SelectItem>
                {projects.map((project) => (
                  <SelectItem value={project.id} key={project.id}>
                    {project.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          
          {projectId === "new" && (
            <div>
              <Label htmlFor="projectName" className="text-base font-semibold mb-2">
                New project name
              </Label>
              <Input
                id="projectName"
                value={newProjectName}
                onChange={(e) => setNewProjectName(e.target.value)}
                placeholder="Strategic account expansion"
                className="h-12 text-base"
              />
            </div>
          )}

          <div>
            <Label className="text-base font-semibold mb-2">Entry Type</Label>
            <Select value={entryKind} onValueChange={(v) => setEntryKind(v as EntryKind)}>
              <SelectTrigger className="w-full h-12 text-base">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="note">📝 Note</SelectItem>
                <SelectItem value="meeting">🤝 Meeting</SelectItem>
                <SelectItem value="update">📣 Update</SelectItem>
                <SelectItem value="decision">⚖️ Decision</SelectItem>
                <SelectItem value="commitment">✅ Commitment</SelectItem>
                <SelectItem value="reflection">💭 Reflection</SelectItem>
                <SelectItem value="prep">📋 Prep</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div>
            <Label htmlFor="title" className="text-base font-semibold mb-2">
              Title
            </Label>
            <Input
              id="title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Brief title for this entry"
              className="h-12 text-base"
            />
          </div>

          <div>
            <Label className="text-base font-semibold mb-2">
              {entryKind === "commitment" ? "Description" : "Content"}
            </Label>
            <Textarea
              value={content}
              onChange={(event) => setContent(event.target.value)}
              className="min-h-[160px] md:min-h-[140px] text-base resize-none"
              placeholder={
                entryKind === "meeting"
                  ? "Meeting notes and key takeaways..."
                  : entryKind === "commitment"
                  ? "Details about this commitment..."
                  : entryKind === "reflection"
                  ? "Your thoughts and reflections..."
                  : "Type or paste your notes here..."
              }
            />
            <p className="text-xs text-muted-foreground mt-2">
              {content.length > 0 && `${content.length} characters`}
            </p>
          </div>

          {entryKind === "commitment" && (
            <CommitmentFields
              direction={direction}
              onDirectionChange={setDirection}
              counterparty={counterparty}
              onCounterpartyChange={setCounterparty}
              dueDate={dueDate}
              onDueDateChange={setDueDate}
              importance={importance}
              onImportanceChange={setImportance}
              urgency={urgency}
              onUrgencyChange={setUrgency}
              notes={notes}
              onNotesChange={setNotes}
            />
          )}

          {entryKind === "reflection" && (
            <ReflectionFields
              questionsAndAnswers={questionsAndAnswers}
              onQuestionsAndAnswersChange={setQuestionsAndAnswers}
            />
          )}

          <Button 
            type="submit" 
            size="lg"
            className="w-full text-base font-semibold" 
            disabled={status === "saving"}
          >
            {status === "saving" 
              ? "Saving..." 
              : status === "success" 
              ? "Saved!" 
              : `Capture ${entryKind}`}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
};

