import * as React from "react";
import { cn } from "@/lib/utils";
import { Card } from "./card";

type StatStatus = "default" | "warning" | "danger" | "success";

interface StatCardProps extends React.HTMLAttributes<HTMLDivElement> {
  label: string;
  value: string | number;
  trend?: {
    value: number;
    isPositive?: boolean;
  };
  icon?: React.ReactNode;
  description?: string;
  variant?: "default" | "compact";
  status?: StatStatus;
}

const statusStyles: Record<StatStatus, { bg: string; text: string; iconBg: string }> = {
  default: {
    bg: "",
    text: "",
    iconBg: "bg-primary/10 text-primary",
  },
  warning: {
    bg: "bg-amber-50 dark:bg-amber-950/30 border-amber-200 dark:border-amber-800",
    text: "text-amber-700 dark:text-amber-400",
    iconBg: "bg-amber-100 dark:bg-amber-900/50 text-amber-600 dark:text-amber-400",
  },
  danger: {
    bg: "bg-red-50 dark:bg-red-950/30 border-red-200 dark:border-red-800",
    text: "text-red-700 dark:text-red-400",
    iconBg: "bg-red-100 dark:bg-red-900/50 text-red-600 dark:text-red-400",
  },
  success: {
    bg: "bg-emerald-50 dark:bg-emerald-950/30 border-emerald-200 dark:border-emerald-800",
    text: "text-emerald-700 dark:text-emerald-400",
    iconBg: "bg-emerald-100 dark:bg-emerald-900/50 text-emerald-600 dark:text-emerald-400",
  },
};

export function StatCard({
  label,
  value,
  trend,
  icon,
  description,
  variant = "default",
  status = "default",
  className,
  ...props
}: StatCardProps) {
  const styles = statusStyles[status];

  if (variant === "compact") {
    return (
      <Card 
        variant="elevated" 
        className={cn(
          "p-4 transition-colors",
          styles.bg,
          className
        )} 
        {...props}
      >
        <div className="flex items-center gap-3">
          {icon && (
            <div className={cn("rounded-lg p-2 shrink-0", styles.iconBg)}>
              {icon}
            </div>
          )}
          <div className="min-w-0 flex-1">
            <p className="text-xs font-medium text-muted-foreground truncate">{label}</p>
            <p className={cn(
              "text-2xl font-bold tracking-tight",
              status !== "default" && styles.text
            )}>
              {value}
            </p>
          </div>
        </div>
      </Card>
    );
  }

  return (
    <Card variant="elevated" padding="mobile" className={cn("", className)} {...props}>
      <div className="flex items-start justify-between px-6">
        <div className="space-y-2 flex-1">
          <p className="text-sm font-medium text-muted-foreground">{label}</p>
          <div className="flex items-baseline gap-2">
            <p className="text-3xl font-bold tracking-tight">{value}</p>
            {trend && (
              <span
                className={cn(
                  "text-sm font-medium",
                  trend.isPositive ? "text-success" : "text-destructive"
                )}
              >
                {trend.isPositive ? "+" : ""}
                {trend.value}%
              </span>
            )}
          </div>
          {description && (
            <p className="text-xs text-muted-foreground">{description}</p>
          )}
        </div>
        {icon && (
          <div className="rounded-lg bg-primary/10 p-2.5 text-primary">
            {icon}
          </div>
        )}
      </div>
    </Card>
  );
}



