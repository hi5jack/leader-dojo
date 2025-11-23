import { headers } from "next/headers";
import { notFound, redirect } from "next/navigation";

import { EntryComposer } from "./entry-composer";
import { getCurrentSession } from "@/lib/auth/session";
import { env } from "@/lib/config/env";
import type { Project } from "@/lib/db/types";

type Params = {
  id: string;
};

export default async function NewEntryPage({ params }: { params: Promise<Params> }) {
  const session = await getCurrentSession();
  if (!session?.user?.id) {
    redirect("/auth/signin");
  }

  const headersList = await headers();
  const cookieHeader = headersList.get("cookie") ?? "";
  const baseUrl = env.APP_BASE_URL ?? env.NEXTAUTH_URL ?? "http://localhost:3000";
  const { id } = await params;

  let project: Project | null = null;

  try {
    const projectResponse = await fetch(`${baseUrl}/api/secure/projects/${id}`, {
      cache: "no-store",
      headers: {
        cookie: cookieHeader,
      },
    });

    if (projectResponse.status === 404) {
      notFound();
    }

    if (projectResponse.ok) {
      project = (await projectResponse.json()) as Project;
    } else {
      console.error("Failed to load project for new entry:", projectResponse.statusText);
    }
  } catch (error) {
    console.error("Error loading project for new entry:", error);
  }

  return (
    <div className="space-y-6">
      <div>
        <p className="text-sm text-muted-foreground">New entry</p>
        <h1 className="text-3xl font-semibold">{project?.name ?? "Untitled project"}</h1>
      </div>
      <EntryComposer projectId={id} />
    </div>
  );
}

