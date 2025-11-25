"use client";

import { useState } from "react";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import type { Reflection } from "@/lib/db/types";

export const ReflectionsList = ({ reflections }: { reflections: Reflection[] }) => {
  const [selected, setSelected] = useState<Reflection | null>(null);

  const formatPeriod = (reflection: Reflection) => {
    if (reflection.periodType && reflection.periodStart && reflection.periodEnd) {
      return `${reflection.periodType} – ${new Date(
        reflection.periodStart,
      ).toLocaleDateString("en-US")} - ${new Date(
        reflection.periodEnd,
      ).toLocaleDateString("en-US")}`;
    }

    if (reflection.periodStart && reflection.periodEnd) {
      return `${new Date(reflection.periodStart).toLocaleDateString(
        "en-US",
      )} - ${new Date(reflection.periodEnd).toLocaleDateString("en-US")}`;
    }

    return "Ad-hoc reflection";
  };

  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle>Past reflections</CardTitle>
        </CardHeader>
        <CardContent>
          {reflections.length === 0 ? (
            <p className="text-sm text-muted-foreground">No reflections yet.</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Period</TableHead>
                  <TableHead>Created</TableHead>
                  <TableHead>Answered</TableHead>
                  <TableHead />
                </TableRow>
              </TableHeader>
              <TableBody>
                {reflections.map((reflection) => (
                  <TableRow key={reflection.id}>
                    <TableCell>
                      {formatPeriod(reflection)}
                    </TableCell>
                    <TableCell>{new Date(reflection.createdAt).toLocaleDateString("en-US")}</TableCell>
                    <TableCell>{reflection.questionsAndAnswers.length}</TableCell>
                    <TableCell className="text-right">
                      <Button variant="outline" size="sm" onClick={() => setSelected(reflection)}>
                        View
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
      <Dialog open={Boolean(selected)} onOpenChange={() => setSelected(null)}>
        <DialogContent className="max-w-xl">
          <DialogHeader>
            <DialogTitle>
              {selected
                ? formatPeriod(selected)
                : "Reflection"}
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            {selected?.questionsAndAnswers.map((pair, index) => (
              <div key={`${pair.question}-${index}`} className="rounded-lg border p-3">
                <p className="text-sm font-medium">{pair.question}</p>
                <p className="mt-2 text-sm text-muted-foreground whitespace-pre-line">{pair.answer}</p>
              </div>
            ))}
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
};

