import { redirect } from "next/navigation";

import { ReflectionsList } from "./reflections-list";
import { ReflectionWizard } from "./reflection-wizard";
import { ReflectionsService } from "@/lib/services";
import { getCurrentSession } from "@/lib/auth/session";

const reflectionsService = new ReflectionsService();

export default async function ReflectionsPage() {
  const session = await getCurrentSession();
  if (!session?.user?.id) {
    redirect("/auth/signin");
  }

  const reflections = await reflectionsService.listReflections(session.user.id);

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-semibold">Reflections</h1>
        <p className="text-muted-foreground">
          Generate AI-assisted reflection questions and capture lessons.
        </p>
      </div>
      <ReflectionWizard />
      <ReflectionsList reflections={reflections} />
    </div>
  );
}

