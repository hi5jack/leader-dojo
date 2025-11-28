import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const fabVariants = cva(
  "fixed z-40 flex items-center justify-center rounded-full shadow-elevation-lg transition-all active:scale-95 touch-target font-medium",
  {
    variants: {
      variant: {
        default: "gradient-primary text-white hover:shadow-elevation-md",
        accent: "gradient-accent text-white hover:shadow-elevation-md",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
      },
      size: {
        default: "w-14 h-14",
        lg: "w-16 h-16",
      },
      position: {
        "bottom-right": "bottom-20 right-4 md:bottom-6 md:right-6",
        "bottom-center": "bottom-20 left-1/2 -translate-x-1/2 md:bottom-6",
        "bottom-left": "bottom-20 left-4 md:bottom-6 md:left-6",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
      position: "bottom-right",
    },
  }
);

export interface FabProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof fabVariants> {
  icon?: React.ReactNode;
  label?: string;
}

const Fab = React.forwardRef<HTMLButtonElement, FabProps>(
  ({ className, variant, size, position, icon, label, ...props }, ref) => {
    return (
      <button
        className={cn(fabVariants({ variant, size, position, className }))}
        ref={ref}
        {...props}
      >
        {icon}
        {label && <span className="ml-2 text-sm">{label}</span>}
      </button>
    );
  }
);
Fab.displayName = "Fab";

export { Fab, fabVariants };






