"use client";

import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";

type CommitmentFieldsProps = {
  direction: "i_owe" | "waiting_for";
  onDirectionChange: (value: "i_owe" | "waiting_for") => void;
  counterparty: string;
  onCounterpartyChange: (value: string) => void;
  dueDate: string;
  onDueDateChange: (value: string) => void;
  importance: number;
  onImportanceChange: (value: number) => void;
  urgency: number;
  onUrgencyChange: (value: number) => void;
  notes: string;
  onNotesChange: (value: string) => void;
};

export function CommitmentFields({
  direction,
  onDirectionChange,
  counterparty,
  onCounterpartyChange,
  dueDate,
  onDueDateChange,
  importance,
  onImportanceChange,
  urgency,
  onUrgencyChange,
  notes,
  onNotesChange,
}: CommitmentFieldsProps) {
  return (
    <div className="space-y-4 border-t pt-4">
      <div className="text-sm font-semibold text-muted-foreground">
        Commitment Details
      </div>

      <div>
        <Label htmlFor="direction" className="text-base font-semibold mb-2">
          Direction
        </Label>
        <Select value={direction} onValueChange={onDirectionChange}>
          <SelectTrigger id="direction" className="w-full h-12 text-base">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="i_owe">I owe (my commitment)</SelectItem>
            <SelectItem value="waiting_for">Waiting for (their commitment)</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div>
        <Label htmlFor="counterparty" className="text-base font-semibold mb-2">
          Counterparty
        </Label>
        <Input
          id="counterparty"
          value={counterparty}
          onChange={(e) => onCounterpartyChange(e.target.value)}
          placeholder="Who is this commitment with?"
          className="h-12 text-base"
        />
      </div>

      <div>
        <Label htmlFor="dueDate" className="text-base font-semibold mb-2">
          Due date
        </Label>
        <Input
          id="dueDate"
          type="date"
          value={dueDate}
          onChange={(e) => onDueDateChange(e.target.value)}
          className="h-12 text-base"
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <Label htmlFor="importance" className="text-base font-semibold mb-2">
            Importance (1-5)
          </Label>
          <Select
            value={importance.toString()}
            onValueChange={(v) => onImportanceChange(parseInt(v))}
          >
            <SelectTrigger id="importance" className="w-full h-12 text-base">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {[1, 2, 3, 4, 5].map((i) => (
                <SelectItem key={i} value={i.toString()}>
                  {i}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div>
          <Label htmlFor="urgency" className="text-base font-semibold mb-2">
            Urgency (1-5)
          </Label>
          <Select
            value={urgency.toString()}
            onValueChange={(v) => onUrgencyChange(parseInt(v))}
          >
            <SelectTrigger id="urgency" className="w-full h-12 text-base">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {[1, 2, 3, 4, 5].map((i) => (
                <SelectItem key={i} value={i.toString()}>
                  {i}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>

      <div>
        <Label htmlFor="commitment-notes" className="text-base font-semibold mb-2">
          Additional notes
        </Label>
        <Textarea
          id="commitment-notes"
          value={notes}
          onChange={(e) => onNotesChange(e.target.value)}
          className="min-h-[80px] text-base resize-none"
          placeholder="Any additional context or notes..."
        />
      </div>
    </div>
  );
}




