import * as React from "react";
import { cn } from "@/lib/utils";

interface TimelineProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
}

export function Timeline({ children, className, ...props }: TimelineProps) {
  return (
    <div className={cn("relative space-y-4", className)} {...props}>
      {children}
    </div>
  );
}

interface TimelineItemProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  icon?: React.ReactNode;
  isLast?: boolean;
}

export function TimelineItem({ children, icon, isLast, className, ...props }: TimelineItemProps) {
  return (
    <div className={cn("relative flex gap-4", className)} {...props}>
      {/* Timeline line and icon */}
      <div className="flex flex-col items-center">
        <div
          className={cn(
            "flex h-10 w-10 shrink-0 items-center justify-center rounded-full border-2 bg-background shadow-elevation-sm",
            "border-primary text-primary"
          )}
        >
          {icon}
        </div>
        {!isLast && (
          <div className="h-full w-0.5 bg-border mt-2" />
        )}
      </div>

      {/* Content */}
      <div className="flex-1 pb-8">{children}</div>
    </div>
  );
}

interface TimelineContentProps extends React.HTMLAttributes<HTMLDivElement> {}

export function TimelineContent({ className, ...props }: TimelineContentProps) {
  return <div className={cn("space-y-2", className)} {...props} />;
}

interface TimelineHeaderProps extends React.HTMLAttributes<HTMLDivElement> {}

export function TimelineHeader({ className, ...props }: TimelineHeaderProps) {
  return <div className={cn("flex items-center justify-between gap-2", className)} {...props} />;
}

interface TimelineTitleProps extends React.HTMLAttributes<HTMLHeadingElement> {}

export function TimelineTitle({ className, ...props }: TimelineTitleProps) {
  return <h4 className={cn("text-base font-semibold", className)} {...props} />;
}

interface TimelineDescriptionProps extends React.HTMLAttributes<HTMLParagraphElement> {}

export function TimelineDescription({ className, ...props }: TimelineDescriptionProps) {
  return <p className={cn("text-sm text-muted-foreground", className)} {...props} />;
}

interface TimelineTimeProps extends React.HTMLAttributes<HTMLTimeElement> {}

export function TimelineTime({ className, ...props }: TimelineTimeProps) {
  return <time className={cn("text-xs text-muted-foreground", className)} {...props} />;
}





