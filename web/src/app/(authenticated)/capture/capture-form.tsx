"use client";

import { useState } from "react";

import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Input } from "@/components/ui/input";
import type { Project } from "@/lib/db/types";

export const CaptureForm = ({ projects }: { projects: Project[] }) => {
  const [projectId, setProjectId] = useState(projects[0]?.id ?? "new");
  const [newProjectName, setNewProjectName] = useState("");
  const [content, setContent] = useState("");
  const [status, setStatus] = useState<"idle" | "saving" | "success" | "error">("idle");

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!content.trim()) return;
    
    // Validate input based on selection
    if (projectId === "new" && !newProjectName.trim()) {
      toast.error("Please enter a project name");
      return;
    }
    if (projectId !== "new" && !projectId) {
      toast.error("Please select a project");
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

    const response = await fetch(`/api/secure/projects/${targetProjectId}/entries`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        title: content.split(".")[0]?.slice(0, 60) || "Quick note",
        kind: "note",
        occurredAt: new Date().toISOString(),
        rawContent: content,
      }),
    });

    if (!response.ok) {
      setStatus("error");
      toast.error("Unable to save note. Try again.");
      return;
    }

    setContent("");
    setNewProjectName("");
    setProjectId(projects[0]?.id ?? "new");
    setStatus("success");
    toast.success("Captured to timeline");
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
            <Label className="text-base font-semibold mb-2">What happened?</Label>
            <Textarea
              value={content}
              onChange={(event) => setContent(event.target.value)}
              className="min-h-[240px] md:min-h-[200px] text-base resize-none"
              placeholder="Type or paste your notes here...

Examples:
• Meeting notes from conversation
• Quick thought or insight
• Action items from discussion
• Reflection on recent event"
            />
            <p className="text-xs text-muted-foreground mt-2">
              {content.length > 0 && `${content.length} characters`}
            </p>
          </div>
          <Button 
            type="submit" 
            size="lg"
            className="w-full text-base font-semibold" 
            disabled={status === "saving"}
          >
            {status === "saving" ? "Saving..." : status === "success" ? "Saved!" : "Save note"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
};

