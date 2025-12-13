"use client";

import * as React from "react";
import { cn } from "@/lib/utils";

interface SwipeAction {
  label: string;
  icon?: React.ReactNode;
  onClick: () => void;
  variant?: "default" | "success" | "destructive";
}

interface SwipeActionsProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  actions: SwipeAction[];
  disabled?: boolean;
}

export function SwipeActions({
  children,
  actions,
  disabled,
  className,
  ...props
}: SwipeActionsProps) {
  const [swipeOffset, setSwipeOffset] = React.useState(0);
  const [isSwiping, setIsSwiping] = React.useState(false);
  const startX = React.useRef(0);
  const currentX = React.useRef(0);

  const handleTouchStart = (e: React.TouchEvent) => {
    if (disabled) return;
    startX.current = e.touches[0].clientX;
    setIsSwiping(true);
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    if (disabled || !isSwiping) return;
    currentX.current = e.touches[0].clientX;
    const diff = startX.current - currentX.current;
    // Only allow left swipe (positive diff)
    if (diff > 0) {
      setSwipeOffset(Math.min(diff, 120));
    }
  };

  const handleTouchEnd = () => {
    if (disabled) return;
    setIsSwiping(false);
    // If swiped more than halfway, lock open
    if (swipeOffset > 60) {
      setSwipeOffset(120);
    } else {
      setSwipeOffset(0);
    }
  };

  const resetSwipe = () => {
    setSwipeOffset(0);
  };

  return (
    <div className={cn("relative overflow-hidden", className)} {...props}>
      {/* Actions Background */}
      <div className="absolute right-0 top-0 bottom-0 flex items-stretch gap-0">
        {actions.map((action, index) => (
          <button
            key={index}
            onClick={() => {
              action.onClick();
              resetSwipe();
            }}
            className={cn(
              "flex items-center justify-center w-[60px] text-white font-medium text-sm transition-colors",
              action.variant === "destructive" && "bg-destructive hover:bg-destructive/90",
              action.variant === "success" && "bg-success hover:bg-success/90",
              !action.variant && "bg-primary hover:bg-primary-hover"
            )}
          >
            {action.icon || action.label}
          </button>
        ))}
      </div>

      {/* Content */}
      <div
        className={cn(
          "relative bg-background transition-transform",
          isSwiping ? "duration-0" : "duration-300"
        )}
        style={{
          transform: `translateX(-${swipeOffset}px)`,
        }}
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
      >
        {children}
      </div>
    </div>
  );
}
















