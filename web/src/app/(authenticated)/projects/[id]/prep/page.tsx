import { notFound, redirect } from "next/navigation";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { PrepService } from "@/lib/services/prep-service";
import { getCurrentSession } from "@/lib/auth/session";

type Params = {
  id: string;
};

const prepService = new PrepService();

export default async function PrepPage({ params }: { params: Promise<Params> }) {
  const session = await getCurrentSession();
  if (!session?.user?.id) {
    redirect("/auth/signin");
  }

  const { id } = await params;
  const data = await prepService.generateBriefing(session.user.id, id);

  if (!data) {
    notFound();
  }

  return (
    <div className="space-y-6">
      <div>
        <p className="text-sm text-muted-foreground">Prep</p>
        <h1 className="text-3xl font-semibold">{data.project.name}</h1>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Briefing</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="whitespace-pre-line text-sm text-muted-foreground">{data.briefing.briefing}</p>
          <ul className="mt-4 list-disc pl-4 text-sm">
            {data.briefing.talkingPoints.map((point) => (
              <li key={point}>{point}</li>
            ))}
          </ul>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Outstanding commitments</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {data.commitments.length === 0 ? (
            <p className="text-sm text-muted-foreground">No open commitments.</p>
          ) : (
            data.commitments.map((commitment) => (
              <div key={commitment.id} className="rounded-lg border p-3">
                <p className="font-medium">{commitment.title}</p>
                <p className="text-sm text-muted-foreground">
                  {commitment.direction === "i_owe" ? "You owe" : "Waiting for"} ·{" "}
                  {commitment.counterparty ?? "Unassigned"}
                </p>
              </div>
            ))
          )}
        </CardContent>
      </Card>
    </div>
  );
}

