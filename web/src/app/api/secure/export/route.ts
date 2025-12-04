import { NextResponse } from "next/server";

import { ExportService } from "@/lib/services";
import { withUser } from "@/lib/http/with-user";

const exportService = new ExportService();

export const GET = withUser(async ({ userId }) => {
  const data = await exportService.exportAllUserData(userId);
  return NextResponse.json(data);
});







