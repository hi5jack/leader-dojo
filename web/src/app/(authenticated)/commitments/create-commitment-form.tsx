"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2 } from "lucide-react";
import { useForm } from "react-hook-form";
import { type z } from "zod";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { createCommitmentSchema } from "@/lib/validators/commitments";
import type { Project, Commitment } from "@/lib/db/types";

type FormValues = z.input<typeof createCommitmentSchema>;

interface CreateCommitmentFormProps {
  projects: Project[];
  onSuccess: (commitment: Commitment) => void;
  onCancel?: () => void;
  defaultDirection?: "i_owe" | "waiting_for";
}

export const CreateCommitmentForm = ({
  projects,
  onSuccess,
  onCancel,
  defaultDirection = "i_owe",
}: CreateCommitmentFormProps) => {
  const form = useForm<FormValues>({
    resolver: zodResolver(createCommitmentSchema),
    defaultValues: {
      projectId: projects[0]?.id ?? "",
      title: "",
      direction: defaultDirection,
      counterparty: "",
      importance: 3,
      urgency: 3,
      notes: "",
    },
  });

  const onSubmit = async (values: FormValues) => {
    try {
      const response = await fetch("/api/secure/commitments", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(values),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error?.message || "Failed to create commitment");
      }

      const commitment = await response.json();
      toast.success("Commitment created successfully");
      form.reset();
      onSuccess(commitment);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Failed to create commitment";
      toast.error(message);
      form.setError("title", { message });
    }
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-5">
        <FormField
          control={form.control}
          name="title"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Title *</FormLabel>
              <FormControl>
                <Input 
                  placeholder="What needs to be done?" 
                  className="h-12 text-base"
                  {...field} 
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="projectId"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Project *</FormLabel>
              <Select onValueChange={field.onChange} defaultValue={field.value}>
                <FormControl>
                  <SelectTrigger className="h-12 text-base">
                    <SelectValue placeholder="Select a project" />
                  </SelectTrigger>
                </FormControl>
                <SelectContent>
                  {projects.map((project) => (
                    <SelectItem value={project.id} key={project.id}>
                      {project.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="direction"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Direction *</FormLabel>
              <Select onValueChange={field.onChange} defaultValue={field.value}>
                <FormControl>
                  <SelectTrigger className="h-12 text-base">
                    <SelectValue />
                  </SelectTrigger>
                </FormControl>
                <SelectContent>
                  <SelectItem value="i_owe">I Owe</SelectItem>
                  <SelectItem value="waiting_for">Waiting For</SelectItem>
                </SelectContent>
              </Select>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="counterparty"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Counterparty</FormLabel>
              <FormControl>
                <Input 
                  placeholder="Who is involved?" 
                  className="h-12 text-base"
                  {...field} 
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="dueDate"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Due Date</FormLabel>
              <FormControl>
                <Input
                  type="date"
                  className="h-12 text-base"
                  name={field.name}
                  ref={field.ref}
                  onBlur={field.onBlur}
                  value={
                    field.value instanceof Date
                      ? field.value.toISOString().split("T")[0]
                      : (field.value as string | undefined) || ""
                  }
                  onChange={(e) => {
                    const value = e.target.value;
                    field.onChange(value ? new Date(value) : undefined);
                  }}
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <div className="grid gap-4 sm:grid-cols-2">
          <FormField
            control={form.control}
            name="importance"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Importance (1-5)</FormLabel>
                <FormControl>
                  <Input
                    type="number"
                    min={1}
                    max={5}
                    className="h-12 text-base"
                    {...field}
                    value={field.value ?? 3}
                    onChange={(event) => field.onChange(Number(event.target.value))}
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="urgency"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Urgency (1-5)</FormLabel>
                <FormControl>
                  <Input
                    type="number"
                    min={1}
                    max={5}
                    className="h-12 text-base"
                    {...field}
                    value={field.value ?? 3}
                    onChange={(event) => field.onChange(Number(event.target.value))}
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
        </div>

        <FormField
          control={form.control}
          name="notes"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Notes</FormLabel>
              <FormControl>
                <Textarea 
                  placeholder="Additional context or details" 
                  rows={3}
                  className="text-base resize-none"
                  {...field} 
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <div className="flex gap-3 pt-4">
          {onCancel && (
            <Button
              type="button"
              variant="outline"
              onClick={onCancel}
              disabled={form.formState.isSubmitting}
              className="flex-1 h-12 text-base touch-target"
            >
              Cancel
            </Button>
          )}
          <Button 
            type="submit" 
            disabled={form.formState.isSubmitting} 
            className="flex-1 h-12 text-base touch-target"
          >
            {form.formState.isSubmitting ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              "Create commitment"
            )}
          </Button>
        </div>
      </form>
    </Form>
  );
};

