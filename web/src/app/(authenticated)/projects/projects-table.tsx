"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { Search, SlidersHorizontal } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import type { Project } from "@/lib/db/types";
import { cn } from "@/lib/utils";

type FilterState = {
  status: string;
  type: string;
  priority: string;
  sort: string;
};

const statusOptions = ["all", "active", "on_hold", "completed", "archived"] as const;
const typeOptions = ["all", "project", "relationship", "area"] as const;
const priorityOptions = ["all", "5", "4", "3", "2", "1"] as const;
const sortOptions = [
  { value: "last_active_desc", label: "Last activity" },
  { value: "priority_desc", label: "Priority" },
  { value: "name_asc", label: "Name" },
] as const;

export const ProjectsTable = ({ projects }: { projects: Project[] }) => {
  const [filters, setFilters] = useState<FilterState>({
    status: "all",
    type: "all",
    priority: "all",
    sort: "last_active_desc",
  });
  const [searchQuery, setSearchQuery] = useState("");

  const filteredProjects = useMemo(() => {
    return projects.filter((project) => {
      const statusMatches = filters.status === "all" || project.status === filters.status;
      const typeMatches = filters.type === "all" || project.type === filters.type;
      const priorityMatches =
        filters.priority === "all" || project.priority === Number(filters.priority);
      const searchMatches =
        searchQuery === "" ||
        project.name.toLowerCase().includes(searchQuery.toLowerCase());
      return statusMatches && typeMatches && priorityMatches && searchMatches;
    });
  }, [filters, projects, searchQuery]);

  const sortedProjects = useMemo(() => {
    return [...filteredProjects].sort((a, b) => {
      if (filters.sort === "priority_desc") {
        return (b.priority ?? 0) - (a.priority ?? 0);
      }
      if (filters.sort === "name_asc") {
        return a.name.localeCompare(b.name);
      }
      const lastActiveA = a.lastActiveAt ? new Date(a.lastActiveAt).getTime() : 0;
      const lastActiveB = b.lastActiveAt ? new Date(b.lastActiveAt).getTime() : 0;
      return lastActiveB - lastActiveA;
    });
  }, [filteredProjects, filters.sort]);

  const getPriorityColor = (priority: number) => {
    if (priority >= 5) return "var(--destructive)";
    if (priority >= 4) return "var(--warning)";
    return "var(--muted-foreground)";
  };

  const getRelativeTime = (date: Date | string | null) => {
    if (!date) return "Never";
    const now = new Date();
    const past = new Date(date);
    const diffMs = now.getTime() - past.getTime();
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
    
    if (diffDays === 0) return "Today";
    if (diffDays === 1) return "Yesterday";
    if (diffDays < 7) return `${diffDays} days ago`;
    if (diffDays < 30) return `${Math.floor(diffDays / 7)} weeks ago`;
    return `${Math.floor(diffDays / 30)} months ago`;
  };

  return (
    <div className="space-y-4">
      {/* Search and Filter Bar */}
      <div className="flex gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            placeholder="Search projects..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-9"
          />
        </div>
        
        {/* Mobile Filter Sheet */}
        <Sheet>
          <SheetTrigger asChild>
            <Button variant="outline" size="icon">
              <SlidersHorizontal className="w-4 h-4" />
            </Button>
          </SheetTrigger>
          <SheetContent side="bottom">
            <SheetHeader>
              <SheetTitle>Filter Projects</SheetTitle>
            </SheetHeader>
            <div className="grid gap-4 py-4">
              <div>
                <label className="text-sm font-medium mb-2 block">Status</label>
                <Select
                  value={filters.status}
                  onValueChange={(value) => setFilters((prev) => ({ ...prev, status: value }))}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {statusOptions.map((option) => (
                      <SelectItem value={option} key={option}>
                        {option === "all" ? "All statuses" : option.replace("_", " ")}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="text-sm font-medium mb-2 block">Type</label>
                <Select
                  value={filters.type}
                  onValueChange={(value) => setFilters((prev) => ({ ...prev, type: value }))}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {typeOptions.map((option) => (
                      <SelectItem value={option} key={option}>
                        {option === "all" ? "All types" : option}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="text-sm font-medium mb-2 block">Priority</label>
                <Select
                  value={filters.priority}
                  onValueChange={(value) => setFilters((prev) => ({ ...prev, priority: value }))}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {priorityOptions.map((option) => (
                      <SelectItem value={option} key={option}>
                        {option === "all" ? "All priorities" : `Priority ${option}`}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="text-sm font-medium mb-2 block">Sort by</label>
                <Select
                  value={filters.sort}
                  onValueChange={(value) => setFilters((prev) => ({ ...prev, sort: value }))}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {sortOptions.map((option) => (
                      <SelectItem value={option.value} key={option.value}>
                        {option.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
          </SheetContent>
        </Sheet>
      </div>

      {/* Projects Grid - Mobile First */}
      {sortedProjects.length === 0 ? (
        <EmptyState
          title="No projects found"
          description="Try adjusting your search or filters, or create a new project to get started."
        />
      ) : (
        <div className="grid gap-3 md:gap-4 md:grid-cols-2 lg:grid-cols-3">
          {sortedProjects.map((project) => (
            <Link key={project.id} href={`/projects/${project.id}`}>
              <Card
                variant="interactive"
                accentColor={getPriorityColor(project.priority)}
                className="h-full"
              >
                <CardContent className="p-4 space-y-3">
                  {/* Header */}
                  <div className="flex items-start justify-between gap-2">
                    <h3 className="font-semibold text-base line-clamp-2 flex-1">
                      {project.name}
                    </h3>
                    <Badge variant="outline" size="lg" className="shrink-0">
                      P{project.priority}
                    </Badge>
                  </div>

                  {/* Badges */}
                  <div className="flex flex-wrap gap-2">
                    <Badge variant="secondary" size="lg">
                      {project.type}
                    </Badge>
                    <Badge
                      variant={
                        project.status === "active"
                          ? "success"
                          : project.status === "on_hold"
                          ? "warning"
                          : "outline"
                      }
                      size="lg"
                    >
                      {project.status.replace("_", " ")}
                    </Badge>
                  </div>

                  {/* Last Activity */}
                  <div className="text-sm text-muted-foreground">
                    Last active: {getRelativeTime(project.lastActiveAt)}
                  </div>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
};

