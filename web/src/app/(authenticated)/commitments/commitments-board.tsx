"use client";

import { useCallback, useMemo, useState, useTransition } from "react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Textarea } from "@/components/ui/textarea";
import type { Commitment, Project } from "@/lib/db/types";

type Props = {
  initialIOwe: Commitment[];
  initialWaitingFor: Commitment[];
  projects: Project[];
};

const statusOptions = ["all", "open", "done", "blocked", "dropped"] as const;
const sortOptions = [
  { value: "due_date", label: "Due date" },
  { value: "importance", label: "Importance" },
  { value: "urgency", label: "Urgency" },
] as const;

export const CommitmentsBoard = ({
  initialIOwe,
  initialWaitingFor,
  projects,
}: Props) => {
  const [iOwe, setIOwe] = useState(initialIOwe);
  const [waitingFor, setWaitingFor] = useState(initialWaitingFor);
  const [isPending, startTransition] = useTransition();
  const [filters, setFilters] = useState({
    projectId: "all",
    status: "all",
    sort: "due_date",
  });
  const projectLookup = useMemo(
    () => new Map(projects.map((project) => [project.id, project.name])),
    [projects],
  );

  const updateLocalState = (updated: Commitment) => {
    const updateList = (list: Commitment[]) =>
      list.map((item) => (item.id === updated.id ? { ...item, ...updated } : item));
    setIOwe((prev) => updateList(prev));
    setWaitingFor((prev) => updateList(prev));
  };

  const updateCommitment = (id: string, payload: Record<string, unknown>) => {
    startTransition(async () => {
      const response = await fetch(`/api/secure/commitments/${id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        const updated = await response.json();
        updateLocalState(updated);
      }
    });
  };

  const applyFilters = useCallback(
    (items: Commitment[]) => {
      return items
        .filter((item) => {
          const matchesProject =
            filters.projectId === "all" || item.projectId === filters.projectId;
          const matchesStatus = filters.status === "all" || item.status === filters.status;
          return matchesProject && matchesStatus;
        })
        .sort((a, b) => {
          if (filters.sort === "importance") {
            return (b.importance ?? 0) - (a.importance ?? 0);
          }
          if (filters.sort === "urgency") {
            return (b.urgency ?? 0) - (a.urgency ?? 0);
          }
          const dueA = a.dueDate ? new Date(a.dueDate).getTime() : Infinity;
          const dueB = b.dueDate ? new Date(b.dueDate).getTime() : Infinity;
          return dueA - dueB;
        });
    },
    [filters],
  );

  const filteredIOwe = useMemo(() => applyFilters(iOwe), [applyFilters, iOwe]);
  const filteredWaitingFor = useMemo(
    () => applyFilters(waitingFor),
    [applyFilters, waitingFor],
  );

  const renderTable = (items: Commitment[]) => (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Title</TableHead>
          <TableHead>Project</TableHead>
          <TableHead>Counterparty</TableHead>
          <TableHead>Due date</TableHead>
          <TableHead>Status</TableHead>
          <TableHead>Notes</TableHead>
          <TableHead>Actions</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {items.map((item) => (
          <TableRow key={item.id}>
            <TableCell className="font-medium">{item.title}</TableCell>
            <TableCell>
              <Badge variant="secondary">{projectLookup.get(item.projectId) ?? "Project"}</Badge>
            </TableCell>
            <TableCell>{item.counterparty ?? "—"}</TableCell>
            <TableCell>
              <Input
                type="date"
                defaultValue={item.dueDate ? new Date(item.dueDate).toISOString().slice(0, 10) : ""}
                onBlur={(event) =>
                  updateCommitment(item.id, {
                    dueDate: event.target.value,
                  })
                }
              />
            </TableCell>
            <TableCell>
              <Select
                defaultValue={item.status}
                onValueChange={(value) =>
                  updateCommitment(item.id, {
                    status: value,
                  })
                }
              >
                <SelectTrigger className="w-[140px]">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {statusOptions.map((status) => (
                    <SelectItem value={status} key={status}>
                      {status}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </TableCell>
            <TableCell>
              <Textarea
                defaultValue={item.notes ?? ""}
                placeholder="Add notes"
                className="min-w-[200px]"
                onBlur={(event) =>
                  updateCommitment(item.id, {
                    notes: event.target.value,
                  })
                }
              />
            </TableCell>
            <TableCell>
              <Button
                variant="outline"
                size="sm"
                onClick={() => updateCommitment(item.id, { status: "done" })}
                disabled={item.status === "done" || isPending}
              >
                Mark done
              </Button>
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );

  return (
    <Card>
      <CardContent className="space-y-4 pt-6">
        <div className="grid gap-3 sm:grid-cols-3">
          <Select
            value={filters.projectId}
            onValueChange={(value) => setFilters((prev) => ({ ...prev, projectId: value }))}
          >
            <SelectTrigger>
              <SelectValue placeholder="Project" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All projects</SelectItem>
              {projects.map((project) => (
                <SelectItem value={project.id} key={project.id}>
                  {project.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Select
            value={filters.status}
            onValueChange={(value) => setFilters((prev) => ({ ...prev, status: value }))}
          >
            <SelectTrigger>
              <SelectValue placeholder="Status" />
            </SelectTrigger>
            <SelectContent>
              {statusOptions.map((status) => (
                <SelectItem value={status} key={status}>
                  {status === "all" ? "All statuses" : status}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Select
            value={filters.sort}
            onValueChange={(value) => setFilters((prev) => ({ ...prev, sort: value }))}
          >
            <SelectTrigger>
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
        <Tabs defaultValue="i_owe">
          <TabsList>
            <TabsTrigger value="i_owe">I Owe ({iOwe.length})</TabsTrigger>
            <TabsTrigger value="waiting_for">Waiting For ({waitingFor.length})</TabsTrigger>
          </TabsList>
          <TabsContent value="i_owe">{renderTable(filteredIOwe)}</TabsContent>
          <TabsContent value="waiting_for">{renderTable(filteredWaitingFor)}</TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  );
};

