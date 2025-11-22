import { redirect } from "next/navigation";

import { CommitmentsBoard } from "./commitments-board";
import { CommitmentsService, ProjectsService } from "@/lib/services";
import { getCurrentSession } from "@/lib/auth/session";

const commitmentsService = new CommitmentsService();
const projectsService = new ProjectsService();

export default async function CommitmentsPage() {
  const session = await getCurrentSession();
  if (!session?.user?.id) {
    redirect("/auth/signin");
  }

  const [iOwe, waitingFor, projects] = await Promise.all([
    commitmentsService.listCommitments(session.user.id, {
      directions: ["i_owe"],
    }),
    commitmentsService.listCommitments(session.user.id, {
      directions: ["waiting_for"],
    }),
    projectsService.listProjects(session.user.id),
  ]);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-semibold">Commitments</h1>
        <p className="text-muted-foreground">
          Triage what you owe and what you&apos;re waiting for.
        </p>
      </div>
      <CommitmentsBoard
        initialIOwe={iOwe}
        initialWaitingFor={waitingFor}
        projects={projects}
      />
    </div>
  );
}

