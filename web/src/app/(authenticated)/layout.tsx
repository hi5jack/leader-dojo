import { redirect } from "next/navigation";

import { AppShell } from "@/components/common/app-shell";
import { getCurrentSession } from "@/lib/auth/session";

export default async function AuthenticatedLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await getCurrentSession();

  if (!session?.user) {
    redirect("/auth/signin");
  }

  return (
    <AppShell userName={session.user.name} userEmail={session.user.email}>
      {children}
    </AppShell>
  );
}

