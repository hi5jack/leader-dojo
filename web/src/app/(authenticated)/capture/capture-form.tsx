"use client";

import { useState } from "react";

import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import type { Project } from "@/lib/db/types";

export const CaptureForm = ({ projects }: { projects: Project[] }) => {
  const [projectId, setProjectId] = useState(projects[0]?.id ?? "");
  const [content, setContent] = useState("");
  const [status, setStatus] = useState<"idle" | "saving" | "success" | "error">("idle");

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!projectId || !content.trim()) return;
    setStatus("saving");

    const response = await fetch(`/api/secure/projects/${projectId}/entries`, {
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
    setStatus("success");
    toast.success("Captured to timeline");
    setTimeout(() => setStatus("idle"), 2000);
  };

  if (!projects.length) {
    return (
      <Card className="shadow-none border-0 sm:border">
        <CardContent className="pt-6">
          <p className="text-sm text-muted-foreground">
            Create a project before capturing notes.
          </p>
        </CardContent>
      </Card>
    );
  }

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
                {projects.map((project) => (
                  <SelectItem value={project.id} key={project.id}>
                    {project.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
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

