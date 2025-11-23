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
        kind: "self_note",
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
    <Card className="shadow-none border-0 sm:border">
      <CardContent className="space-y-4 pt-6">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label>Project</Label>
            <Select value={projectId} onValueChange={setProjectId}>
              <SelectTrigger className="w-full">
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
              <Label htmlFor="projectName">New project name</Label>
              <Input
                id="projectName"
                value={newProjectName}
                onChange={(e) => setNewProjectName(e.target.value)}
                placeholder="Strategic account expansion"
                className="text-lg"
              />
            </div>
          )}
          <div>
            <Label>What happened?</Label>
            <Textarea
              value={content}
              onChange={(event) => setContent(event.target.value)}
              className="min-h-[200px] text-lg"
              placeholder="Dictate or paste notes..."
            />
          </div>
          <Button type="submit" className="w-full py-6 text-lg" disabled={status === "saving"}>
            {status === "saving" ? "Saving..." : "Save note"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
};

