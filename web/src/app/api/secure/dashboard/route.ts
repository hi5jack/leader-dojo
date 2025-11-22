import { NextResponse } from "next/server";

import { DashboardService } from "@/lib/services";
import { withUser } from "@/lib/http/with-user";

const dashboardService = new DashboardService();

export const GET = withUser(async ({ userId }) => {
  const data = await dashboardService.getDashboardData(userId);
  return NextResponse.json(data);
});

