import { NextResponse } from "next/server";
import { eq } from "drizzle-orm";

import { db } from "@/lib/db/client";
import { users } from "@/lib/db/schema";
import { hashPassword } from "@/lib/auth/password";
import { registerSchema } from "@/lib/validators/auth";

export async function POST(request: Request) {
  const body = await request.json();
  const validated = registerSchema.safeParse(body);

  if (!validated.success) {
    return NextResponse.json(
      { message: "Invalid payload", errors: validated.error.flatten() },
      { status: 400 },
    );
  }

  const { name, email, password } = validated.data;
  const normalizedEmail = email.toLowerCase();

  const existingUser = await db.query.users.findFirst({
    where: eq(users.email, normalizedEmail),
  });

  if (existingUser) {
    return NextResponse.json(
      { message: "Email already registered" },
      { status: 409 },
    );
  }

  const hashedPassword = await hashPassword(password);

  const [created] = await db
    .insert(users)
    .values({
      name,
      email: normalizedEmail,
      hashedPassword,
    })
    .returning();

  return NextResponse.json(
    {
      id: created.id,
      email: created.email,
      name: created.name,
    },
    { status: 201 },
  );
}

