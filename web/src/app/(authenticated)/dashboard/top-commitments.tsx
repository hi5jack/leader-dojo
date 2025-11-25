"use client";

import { useTransition } from "react";
import { CheckCircle2 } from "lucide-react";

import { SwipeActions } from "@/components/ui/swipe-actions";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import type { Commitment } from "@/lib/db/types";

type Props = {
  items: Commitment[];
};

export function TopCommitments({ items }: Props) {
  const [isPending, startTransition] = useTransition();

  const markDone = (id: string) => {
    startTransition(async () => {
      try {
        await fetch(`/api/secure/commitments/${id}`, {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ status: "done" }),
        });
        // Let the next navigation/refresh pick up the updated status.
      } catch (error) {
        console.error("Failed to mark commitment done from dashboard:", error);
      }
    });
  };

  if (!items.length) return null;

  return (
    <>
      {items.slice(0, 3).map((item) => (
        <SwipeActions
          key={item.id}
          actions={[
            {
              label: "Done",
              icon: <CheckCircle2 className="w-5 h-5" />,
              onClick: () => markDone(item.id),
              variant: "success",
            },
          ]}
          disabled={isPending || item.status === "done"}
        >
          <Card
            variant="interactive"
            className="border-0 shadow-none hover:shadow-none active:shadow-none"
          >
            <CardContent className="px-3 py-2">
              <div className="flex items-start justify-between gap-3">
                <div className="flex-1 min-w-0 space-y-1">
                  <p className="font-medium text-sm leading-snug line-clamp-2">
                    {item.title}
                  </p>
                  <p className="text-xs text-muted-foreground leading-snug line-clamp-1">
                    {item.counterparty || "No counterparty"}
                  </p>
                </div>
                <Badge
                  variant={item.direction === "i_owe" ? "i-owe" : "waiting-for"}
                  size="default"
                  className="shrink-0 text-[10px] px-2 py-0.5"
                >
                  {item.direction === "i_owe" ? "I Owe" : "Waiting"}
                </Badge>
              </div>
            </CardContent>
          </Card>
        </SwipeActions>
      ))}
    </>
  );
}


