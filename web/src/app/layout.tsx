import type { Metadata } from "next";

import { env } from "@/lib/config/env";
import { cn } from "@/lib/utils";
import { Toaster } from "@/components/ui/sonner";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(env.APP_BASE_URL ?? "http://localhost:3000"),
  title: {
    default: "Leader Dojo",
    template: "%s · Leader Dojo",
  },
  description:
    "Leader Dojo helps executives turn meetings into commitments, dashboards, and reflections powered by AI.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className={cn(
          "min-h-screen bg-background font-sans text-foreground antialiased",
        )}
      >
        {children}
        <Toaster />
      </body>
    </html>
  );
}
