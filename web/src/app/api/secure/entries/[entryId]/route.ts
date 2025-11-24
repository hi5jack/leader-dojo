import { NextRequest, NextResponse } from "next/server";
import { EntriesService } from "@/lib/services";
import { getCurrentSession } from "@/lib/auth/session";
import { updateEntrySchema } from "@/lib/validators/entries";

const entriesService = new EntriesService();

export const dynamic = "force-dynamic";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ entryId: string }> }
) {
  try {
    const session = await getCurrentSession();
    if (!session?.user?.id) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { entryId } = await params;
    const entry = await entriesService.getEntry(session.user.id, entryId);

    if (!entry) {
      return NextResponse.json({ error: "Entry not found" }, { status: 404 });
    }

    return NextResponse.json(entry);
  } catch (error) {
    console.error("Error fetching entry:", error);
    return NextResponse.json(
      { error: "Failed to fetch entry" },
      { status: 500 }
    );
  }
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ entryId: string }> }
) {
  try {
    const session = await getCurrentSession();
    if (!session?.user?.id) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { entryId } = await params;
    const body = await request.json();

    // Validate input
    const validationResult = updateEntrySchema.safeParse(body);
    if (!validationResult.success) {
      return NextResponse.json(
        { error: "Validation failed", details: validationResult.error.issues },
        { status: 400 }
      );
    }

    // Check if entry exists and user owns it
    const existingEntry = await entriesService.getEntry(session.user.id, entryId);
    if (!existingEntry) {
      return NextResponse.json({ error: "Entry not found" }, { status: 404 });
    }

    // Update entry
    const updatedEntry = await entriesService.updateEntry(
      session.user.id,
      entryId,
      validationResult.data
    );

    return NextResponse.json(updatedEntry);
  } catch (error) {
    console.error("Error updating entry:", error);
    return NextResponse.json(
      { error: "Failed to update entry" },
      { status: 500 }
    );
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ entryId: string }> }
) {
  try {
    const session = await getCurrentSession();
    if (!session?.user?.id) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { entryId } = await params;

    // Check if entry exists and user owns it
    const existingEntry = await entriesService.getEntry(session.user.id, entryId);
    if (!existingEntry) {
      return NextResponse.json({ error: "Entry not found" }, { status: 404 });
    }

    // Soft delete entry
    await entriesService.deleteEntry(session.user.id, entryId);

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Error deleting entry:", error);
    return NextResponse.json(
      { error: "Failed to delete entry" },
      { status: 500 }
    );
  }
}

