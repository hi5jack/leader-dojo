 "use client";
 
import { useEffect, useState } from "react";
 
import { MobileNav } from "./mobile-nav";
import { DesktopSidebar } from "./desktop-sidebar";

export const AppShell = ({
  children,
  userName,
  userEmail,
}: {
  children: React.ReactNode;
  userName?: string | null;
  userEmail?: string | null;
}) => {
  const [todayLabel, setTodayLabel] = useState<string | null>(null);

  // Compute the date only on the client after hydration to avoid SSR mismatches.
  useEffect(() => {
    const label = new Date().toLocaleDateString("en-US", {
      weekday: "long",
      month: "long",
      day: "numeric",
    });
    setTodayLabel(label);
  }, []);

  return (
    <div className="flex min-h-screen bg-background">
      {/* Desktop Sidebar */}
      <DesktopSidebar userName={userName} userEmail={userEmail} />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Simplified Header - Desktop Only */}
        <header className="hidden md:block border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/80">
          <div className="flex items-center justify-between px-6 py-4">
            {todayLabel && (
              <div className="text-sm text-muted-foreground" suppressHydrationWarning>
                {todayLabel}
              </div>
            )}
          </div>
        </header>

        {/* Main Content */}
        <main className="flex-1 mobile-spacing md:px-8 md:py-8 overflow-auto">
          <div className="mx-auto max-w-6xl">{children}</div>
        </main>

        {/* Mobile Bottom Navigation */}
        <MobileNav />
      </div>
    </div>
  );
};

