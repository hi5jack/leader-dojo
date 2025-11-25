"use client";

import type { Route } from "next";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, FolderOpen, Plus, CheckSquare, Activity } from "lucide-react";
import { cn } from "@/lib/utils";

const navItems = [
  { href: "/dashboard", label: "Home", icon: Home },
  { href: "/activity", label: "Activity", icon: Activity },
  { href: "/capture", label: "Capture", icon: Plus, isCenter: true },
  { href: "/projects", label: "Projects", icon: FolderOpen },
  { href: "/commitments", label: "Tasks", icon: CheckSquare },
] satisfies Array<{
  href: Route;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  isCenter?: boolean;
}>;

export const MobileNav = () => {
  const pathname = usePathname();

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 md:hidden border-t bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/80 safe-area-bottom">
      <div className="flex items-center justify-around h-[60px]">
        {navItems.map((item) => {
          const isActive = pathname?.startsWith(item.href);
          const Icon = item.icon;

          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex flex-col items-center justify-center gap-1 px-3 py-2 transition-all touch-target relative",
                isActive && !item.isCenter && "text-primary",
                !isActive && !item.isCenter && "text-muted-foreground hover:text-foreground",
                item.isCenter && "mt-[-20px]"
              )}
            >
              {item.isCenter ? (
                <div
                  className={cn(
                    "flex items-center justify-center rounded-full w-14 h-14 transition-all shadow-elevation-md",
                    isActive
                      ? "gradient-primary text-white scale-110"
                      : "bg-primary text-primary-foreground hover:scale-105"
                  )}
                >
                  <Icon className="w-6 h-6" />
                </div>
              ) : (
                <>
                  <Icon className={cn("w-5 h-5", isActive && "animate-bounce-in")} />
                  <span
                    className={cn(
                      "text-[10px] font-medium transition-opacity",
                      isActive ? "opacity-100" : "opacity-70"
                    )}
                  >
                    {item.label}
                  </span>
                  {isActive && (
                    <span className="absolute top-0 left-1/2 -translate-x-1/2 w-8 h-0.5 bg-primary rounded-full" />
                  )}
                </>
              )}
            </Link>
          );
        })}
      </div>
    </nav>
  );
};



