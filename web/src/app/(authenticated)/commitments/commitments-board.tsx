"use client";

import { useCallback, useMemo, useState, useTransition } from "react";
import { CheckCircle2, Clock, AlertCircle, SlidersHorizontal } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";
import { SwipeActions } from "@/components/ui/swipe-actions";
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import type { Commitment, Project } from "@/lib/db/types";
import { cn } from "@/lib/utils";

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

  const getDueDateColor = (dueDate: Date | string | null) => {
    if (!dueDate) return "text-muted-foreground";
    const date = new Date(dueDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const diffMs = date.getTime() - today.getTime();
    const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays < 0) return "text-destructive"; // Overdue
    if (diffDays <= 3) return "text-warning"; // Due soon
    return "text-muted-foreground";
  };

  const formatDueDate = (dueDate: Date | string | null) => {
    if (!dueDate) return "No due date";
    const date = new Date(dueDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const diffMs = date.getTime() - today.getTime();
    const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays < 0) return `Overdue by ${Math.abs(diffDays)} days`;
    if (diffDays === 0) return "Due today";
    if (diffDays === 1) return "Due tomorrow";
    if (diffDays <= 7) return `Due in ${diffDays} days`;
    return date.toLocaleDateString("en-US");
  };

  const renderCommitmentCard = (item: Commitment) => (
    <SwipeActions
      key={item.id}
      actions={[
        {
          label: "Done",
          icon: <CheckCircle2 className="w-5 h-5" />,
          onClick: () => updateCommitment(item.id, { status: "done" }),
          variant: "success",
        },
      ]}
      disabled={item.status === "done" || isPending}
    >
      <Card variant="interactive" className="border-0 shadow-none hover:shadow-none">
        <CardContent className="p-4">
          <div className="space-y-3">
            {/* Header */}
            <div className="flex items-start justify-between gap-2">
              <div className="flex-1 min-w-0">
                <h3 className="font-semibold line-clamp-2 mb-1">{item.title}</h3>
                <div className="flex items-center gap-2 text-sm">
                  <Badge variant="secondary" size="lg">
                    {projectLookup.get(item.projectId) ?? "Project"}
                  </Badge>
                  {item.counterparty && (
                    <span className="text-muted-foreground">• {item.counterparty}</span>
                  )}
                </div>
              </div>
              <Badge
                variant={item.status === "done" ? "success" : "outline"}
                size="lg"
                className="shrink-0"
              >
                {item.status}
              </Badge>
            </div>

            {/* Due Date */}
            <div className="flex items-center gap-2">
              {item.status !== "done" && (
                <>
                  <Clock className={cn("w-4 h-4", getDueDateColor(item.dueDate))} />
                  <span className={cn("text-sm font-medium", getDueDateColor(item.dueDate))}>
                    {formatDueDate(item.dueDate)}
                  </span>
                </>
              )}
              {item.importance && item.importance >= 4 && (
                <Badge variant="destructive" size="lg" className="ml-auto">
                  High priority
                </Badge>
              )}
            </div>

            {/* Notes */}
            {item.notes && (
              <p className="text-sm text-muted-foreground line-clamp-2">{item.notes}</p>
            )}

            {/* Desktop Actions */}
            <div className="hidden md:flex gap-2">
              {item.status !== "done" && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => updateCommitment(item.id, { status: "done" })}
                  disabled={isPending}
                >
                  <CheckCircle2 className="w-4 h-4 mr-2" />
                  Mark done
                </Button>
              )}
            </div>
          </div>
        </CardContent>
      </Card>
    </SwipeActions>
  );

  const renderCommitmentsList = (items: Commitment[], emptyMessage: string) => {
    if (items.length === 0) {
      return (
        <EmptyState
          icon={<CheckCircle2 className="w-8 h-8" />}
          title={emptyMessage}
          description="Adjust your filters or add new commitments to get started."
        />
      );
    }

    return (
      <div className="space-y-3">
        {items.map((item) => renderCommitmentCard(item))}
      </div>
    );
  };

  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="flex gap-2">
        <Sheet>
          <SheetTrigger asChild>
            <Button variant="outline" size="icon" className="shrink-0">
              <SlidersHorizontal className="w-4 h-4" />
            </Button>
          </SheetTrigger>
          <SheetContent side="bottom">
            <SheetHeader>
              <SheetTitle>Filter & Sort</SheetTitle>
            </SheetHeader>
            <div className="grid gap-4 py-4">
              <div>
                <label className="text-sm font-medium mb-2 block">Project</label>
                <Select
                  value={filters.projectId}
                  onValueChange={(value) => setFilters((prev) => ({ ...prev, projectId: value }))}
                >
                  <SelectTrigger>
                    <SelectValue />
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
              </div>
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
                    {statusOptions.map((status) => (
                      <SelectItem value={status} key={status}>
                        {status === "all" ? "All statuses" : status}
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

        <div className="flex-1 overflow-hidden">
          <p className="text-sm text-muted-foreground truncate">
            {filters.projectId !== "all" && `Project: ${projectLookup.get(filters.projectId)} • `}
            {filters.status !== "all" && `Status: ${filters.status} • `}
            Sorted by {sortOptions.find((o) => o.value === filters.sort)?.label.toLowerCase()}
          </p>
        </div>
      </div>

      {/* Tabs */}
      <Tabs defaultValue="i_owe" className="w-full">
        <TabsList className="w-full grid grid-cols-2">
          <TabsTrigger value="i_owe" className="gap-2">
            <AlertCircle className="w-4 h-4" />
            I Owe ({filteredIOwe.length})
          </TabsTrigger>
          <TabsTrigger value="waiting_for" className="gap-2">
            <Clock className="w-4 h-4" />
            Waiting ({filteredWaitingFor.length})
          </TabsTrigger>
        </TabsList>

        <TabsContent value="i_owe" className="mt-6">
          {renderCommitmentsList(filteredIOwe, "No commitments you owe")}
        </TabsContent>

        <TabsContent value="waiting_for" className="mt-6">
          {renderCommitmentsList(filteredWaitingFor, "Nothing you're waiting for")}
        </TabsContent>
      </Tabs>
    </div>
  );
};
