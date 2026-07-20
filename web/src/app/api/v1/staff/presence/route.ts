import { getStaffFromRequest } from "@/lib/staffAuth";
import { isBookableRole } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import type { StaffPresence } from "@/lib/db/types";
import { NextRequest, NextResponse } from "next/server";

// Sets the caller's OWN live presence — a barber can never touch another
// staff member's row. Distinct from `staff_availability` (recurring weekly
// working hours): presence is live, in-the-moment status.

const PRESENCE_VALUES: StaffPresence[] = [
  "available",
  "busy",
  "on_break",
  "off_duty",
];

function isStaffPresence(value: unknown): value is StaffPresence {
  return (
    typeof value === "string" &&
    (PRESENCE_VALUES as string[]).includes(value)
  );
}

export async function PATCH(request: NextRequest) {
  const staff = await getStaffFromRequest(request);
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  if (!isBookableRole(staff.role)) {
    return NextResponse.json(
      {
        error: "not_bookable_role",
        message: "This account doesn't have access to the barber app.",
      },
      { status: 403 },
    );
  }

  let body: { presence?: unknown };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json(
      { error: "invalid_json", message: "Invalid JSON body." },
      { status: 400 },
    );
  }

  if (!isStaffPresence(body.presence)) {
    return NextResponse.json(
      {
        error: "invalid_presence",
        message:
          "presence must be one of: available, busy, on_break, off_duty.",
      },
      { status: 400 },
    );
  }

  const presence = body.presence;
  const presenceUpdatedAt = new Date().toISOString();

  const admin = createAdminClient();
  const { error } = await admin
    .from("staff")
    .update({ presence, presence_updated_at: presenceUpdatedAt })
    .eq("id", staff.id);

  if (error) {
    return NextResponse.json(
      { error: "server_error", message: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  return NextResponse.json({ presence, presenceUpdatedAt });
}
