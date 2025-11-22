"use client";

import Link from "next/link";
import { useMemo, useState } from "react";

import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type { Project } from "@/lib/db/types";

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

  const filteredProjects = useMemo(() => {
    return projects.filter((project) => {
      const statusMatches = filters.status === "all" || project.status === filters.status;
      const typeMatches = filters.type === "all" || project.type === filters.type;
      const priorityMatches =
        filters.priority === "all" || project.priority === Number(filters.priority);
      return statusMatches && typeMatches && priorityMatches;
    });
  }, [filters, projects]);

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

  return (
    <Card className="p-4">
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <Select
          value={filters.status}
          onValueChange={(value) => setFilters((prev) => ({ ...prev, status: value }))}
        >
          <SelectTrigger className="w-full">
            <SelectValue placeholder="Status" />
          </SelectTrigger>
          <SelectContent>
            {statusOptions.map((option) => (
              <SelectItem value={option} key={option}>
                {option === "all" ? "All statuses" : option.replace("_", " ")}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select
          value={filters.type}
          onValueChange={(value) => setFilters((prev) => ({ ...prev, type: value }))}
        >
          <SelectTrigger className="w-full">
            <SelectValue placeholder="Type" />
          </SelectTrigger>
          <SelectContent>
            {typeOptions.map((option) => (
              <SelectItem value={option} key={option}>
                {option === "all" ? "All types" : option}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select
          value={filters.priority}
          onValueChange={(value) => setFilters((prev) => ({ ...prev, priority: value }))}
        >
          <SelectTrigger className="w-full">
            <SelectValue placeholder="Priority" />
          </SelectTrigger>
          <SelectContent>
            {priorityOptions.map((option) => (
              <SelectItem value={option} key={option}>
                {option === "all" ? "All priorities" : `Priority ${option}`}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select
          value={filters.sort}
          onValueChange={(value) => setFilters((prev) => ({ ...prev, sort: value }))}
        >
          <SelectTrigger className="w-full">
            <SelectValue placeholder="Sort by" />
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

      <Table className="mt-6">
        <TableHeader>
          <TableRow>
            <TableHead>Name</TableHead>
            <TableHead>Status</TableHead>
            <TableHead>Type</TableHead>
            <TableHead>Priority</TableHead>
            <TableHead>Last activity</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {sortedProjects.map((project) => (
            <TableRow key={project.id}>
              <TableCell className="font-medium">
                <Link href={`/projects/${project.id}`} className="hover:underline">
                  {project.name}
                </Link>
              </TableCell>
              <TableCell>
                <Badge variant="outline">{project.status}</Badge>
              </TableCell>
              <TableCell>{project.type}</TableCell>
              <TableCell>{project.priority}</TableCell>
              <TableCell>
                {project.lastActiveAt
                  ? new Date(project.lastActiveAt).toLocaleDateString()
                  : "—"}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      {sortedProjects.length === 0 ? (
        <p className="mt-4 text-sm text-muted-foreground">
          No projects match the current filters.
        </p>
      ) : null}
    </Card>
  );
};

