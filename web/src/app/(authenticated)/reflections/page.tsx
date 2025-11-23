import { redirect } from "next/navigation";
import { Sparkles } from "lucide-react";

import { ReflectionsList } from "./reflections-list";
import { ReflectionWizard } from "./reflection-wizard";
import { Card } from "@/components/ui/card";
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
    <div className="section-gap max-w-4xl mx-auto">
      <div className="text-center md:text-left">
        <h1 className="flex items-center justify-center md:justify-start gap-2">
          <Sparkles className="w-7 h-7 text-primary" />
          Reflections
        </h1>
        <p className="text-muted-foreground mt-2">
          AI-powered reflection questions to help you learn from your experiences
        </p>
      </div>
      
      <Card variant="elevated" padding="mobile" className="gradient-primary text-white border-0">
        <ReflectionWizard />
      </Card>
      
      <div>
        <h2 className="mb-4">Past Reflections</h2>
        <ReflectionsList reflections={reflections} />
      </div>
    </div>
  );
}

