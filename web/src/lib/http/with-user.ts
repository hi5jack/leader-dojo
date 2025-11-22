import { NextResponse } from "next/server";

import { getCurrentSession } from "@/lib/auth/session";

const isPromise = <T>(value: T | Promise<T>): value is Promise<T> => {
  return (
    typeof value === "object" &&
    value !== null &&
    "then" in (value as Record<string, unknown>)
  );
};

type Handler<TParams = unknown> = (args: {
  request: Request;
  params: TParams;
  userId: string;
}) => Promise<Response> | Response;

export const withUser = <TParams>(handler: Handler<TParams>) => {
  return async (
    request: Request,
    context: { params: TParams | Promise<TParams> },
  ) => {
    const session = await getCurrentSession();

    if (!session?.user?.id) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    try {
      const params = isPromise(context.params)
        ? await context.params
        : context.params;

      return await handler({
        request,
        params,
        userId: session.user.id,
      });
    } catch (error) {
      console.error("API error", error);
      return NextResponse.json(
        { message: "Unexpected error" },
        { status: 500 },
      );
    }
  };
};

