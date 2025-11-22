"use client";

import type { Route } from "next";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { signOut } from "next-auth/react";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const navItems = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/projects", label: "Projects" },
  { href: "/commitments", label: "Commitments" },
  { href: "/reflections", label: "Reflections" },
  { href: "/capture", label: "Capture" },
] satisfies Array<{ href: Route; label: string }>;

export const AppShell = ({
  children,
  userName,
}: {
  children: React.ReactNode;
  userName?: string | null;
}) => {
  const pathname = usePathname();

  return (
    <div className="flex min-h-screen flex-col bg-muted/30">
      <header className="border-b bg-background">
        <div className="mx-auto flex w-full max-w-6xl items-center justify-between px-6 py-4">
          <Link href="/dashboard" className="text-lg font-semibold">
            Leader Dojo
          </Link>
          <nav className="flex items-center gap-4 text-sm font-medium text-muted-foreground">
            {navItems.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "rounded-md px-3 py-2 transition",
                  pathname?.startsWith(item.href)
                    ? "bg-primary/10 text-primary"
                    : "hover:text-foreground",
                )}
              >
                {item.label}
              </Link>
            ))}
          </nav>
          <div className="flex items-center gap-3 text-sm">
            <span className="text-muted-foreground">
              {userName ? `Hi, ${userName}` : ""}
            </span>
            <Button
              variant="outline"
              size="sm"
              onClick={() => signOut({ callbackUrl: "/auth/signin" })}
            >
              Sign out
            </Button>
          </div>
        </div>
      </header>
      <main className="mx-auto w-full max-w-6xl flex-1 px-6 py-10">{children}</main>
    </div>
  );
};

