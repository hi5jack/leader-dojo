"use client";

import { useEffect } from "react";

import { Button } from "@/components/ui/button";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error("App error", error);
  }, [error]);

  return (
    <div className="grid min-h-screen place-items-center bg-muted/20 px-4">
      <div className="space-y-4 text-center">
        <h1 className="text-2xl font-semibold">Something went wrong</h1>
        <p className="text-muted-foreground">We were unable to load this view.</p>
        <Button onClick={reset}>Try again</Button>
      </div>
    </div>
  );
}

