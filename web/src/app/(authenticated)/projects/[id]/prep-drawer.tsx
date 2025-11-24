"use client";

import { Loader2 } from "lucide-react";
import { useState } from "react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";

type PrepPayload = {
  project: {
    id: string;
    name: string;
  };
  entries: Array<{
    id: string;
    title: string;
    occurredAt: string | null;
    kind: string;
    aiSummary: string | null;
    rawContent: string | null;
  }>;
  commitments: Array<{
    id: string;
    title: string;
    direction: string;
    counterparty: string | null;
    dueDate: string | null;
  }>;
  briefing: {
    briefing: string;
    talkingPoints: string[];
  };
};

export const PrepDrawer = ({ projectId }: { projectId: string }) => {
  const [open, setOpen] = useState(false);
  const [data, setData] = useState<PrepPayload | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const loadPrep = async () => {
    if (data || isLoading) return;
    setIsLoading(true);
    const response = await fetch(`/api/secure/projects/${projectId}/prep`);
    setIsLoading(false);
    if (!response.ok) return;
    const payload = (await response.json()) as PrepPayload;
    setData(payload);
  };

  return (
    <Sheet
      open={open}
      onOpenChange={(next) => {
        setOpen(next);
        if (next) {
          void loadPrep();
        }
      }}
    >
      <SheetTrigger asChild>
        <Button variant="outline">Prep briefing</Button>
      </SheetTrigger>
      <SheetContent className="flex w-full flex-col gap-6 overflow-hidden sm:max-w-xl">
        <SheetHeader>
          <SheetTitle>Prep briefing</SheetTitle>
        </SheetHeader>
        {isLoading && (
          <div className="flex flex-1 items-center justify-center text-muted-foreground">
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            Generating briefing...
          </div>
        )}
        {!isLoading && data ? (
          <ScrollArea className="h-full pr-4">
            <div className="space-y-6">
              <section>
                <h3 className="text-sm font-semibold">Summary</h3>
                <p className="mt-2 whitespace-pre-line text-sm text-muted-foreground">
                  {data.briefing.briefing}
                </p>
              </section>
              <section>
                <h3 className="text-sm font-semibold">Talking points</h3>
                <ul className="mt-2 list-disc space-y-2 pl-5 text-sm text-muted-foreground">
                  {data.briefing.talkingPoints.map((point) => (
                    <li key={point}>{point}</li>
                  ))}
                </ul>
              </section>
              <section>
                <h3 className="text-sm font-semibold">Outstanding commitments</h3>
                <div className="mt-2 space-y-3">
                  {data.commitments.length === 0 ? (
                    <p className="text-sm text-muted-foreground">None outstanding.</p>
                  ) : (
                    data.commitments.map((commitment) => (
                      <div key={commitment.id} className="rounded-lg border p-3">
                        <div className="flex items-center justify-between">
                          <p className="font-medium">{commitment.title}</p>
                          <Badge variant="secondary">
                            {commitment.direction === "i_owe" ? "I Owe" : "Waiting For"}
                          </Badge>
                        </div>
                        <p className="text-sm text-muted-foreground">
                          {commitment.counterparty ?? "No counterparty"} ·{" "}
                          {commitment.dueDate
                            ? new Date(commitment.dueDate).toLocaleDateString("en-US")
                            : "No due date"}
                        </p>
                      </div>
                    ))
                  )}
                </div>
              </section>
              <section>
                <h3 className="text-sm font-semibold">Recent entries</h3>
                <div className="mt-2 space-y-3">
                  {data.entries.map((entry) => (
                    <div key={entry.id} className="rounded-lg border p-3">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="font-medium">{entry.title}</p>
                          <p className="text-xs text-muted-foreground">
                          {entry.occurredAt
                              ? new Date(entry.occurredAt).toLocaleString("en-US", {
                                  year: "numeric",
                                  month: "short",
                                  day: "numeric",
                                  hour: "2-digit",
                                  minute: "2-digit",
                                })
                              : "No timestamp"}
                          </p>
                        </div>
                        <Badge variant="outline">{entry.kind}</Badge>
                      </div>
                      <p className="mt-2 text-sm text-muted-foreground">
                        {entry.aiSummary ?? entry.rawContent ?? "No summary"}
                      </p>
                    </div>
                  ))}
                </div>
              </section>
            </div>
          </ScrollArea>
        ) : null}
      </SheetContent>
    </Sheet>
  );
};

