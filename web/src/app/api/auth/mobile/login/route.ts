import { NextResponse } from "next/server";
import { eq } from "drizzle-orm";

import { db } from "@/lib/db/client";
import { users } from "@/lib/db/schema";
import { verifyPassword } from "@/lib/auth/password";
import { generateMobileToken } from "@/lib/auth/tokens";
import { mobileLoginSchema } from "@/lib/validators/auth";

export const POST = async (request: Request) => {
  const body = await request.json();
  const parsed = mobileLoginSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json(parsed.error.flatten(), { status: 400 });
  }

  const { email, password } = parsed.data;

  const user = await db.query.users.findFirst({
    where: eq(users.email, email.toLowerCase()),
  });

  if (!user?.hashedPassword) {
    return NextResponse.json({ message: "Invalid credentials" }, { status: 401 });
  }

  const isValid = await verifyPassword(password, user.hashedPassword);
  if (!isValid) {
    return NextResponse.json({ message: "Invalid credentials" }, { status: 401 });
  }

  const token = await generateMobileToken(user.id);

  return NextResponse.json({
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
    },
  });
};










