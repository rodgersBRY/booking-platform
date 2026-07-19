import { getStaffFromRequest } from "@/lib/staffAuth";
import { isBookableRole } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

// Token-authed mark-as-read for the mobile barber app's Notifications tab.
// A single endpoint handling both the "one notification" and "all unread"
// cases via the body, unlike the client-facing pair
// (/v1/account/notifications/[id]/read and .../read-all) — this is the
// shape this slice's spec calls for.

type Body = {
  id?: unknown;
  all?: unknown;
};

export async function POST(request: NextRequest) {
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

  let body: Body;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json(
      { error: "invalid_json", message: "Invalid JSON body." },
      { status: 400 },
    );
  }

  const hasId = typeof body.id === "string" && body.id.trim().length > 0;
  const hasAll = body.all === true;

  if (hasId === hasAll) {
    // Both provided or neither provided — exactly one is required.
    return NextResponse.json(
      {
        error: "invalid_body",
        message: "Provide exactly one of id or all:true.",
      },
      { status: 400 },
    );
  }

  const admin = createAdminClient();

  if (hasAll) {
    const { error } = await admin
      .from("staff_notifications")
      .update({ read_at: new Date().toISOString() })
      .eq("staff_id", staff.id)
      .is("read_at", null);

    if (error) {
      return NextResponse.json(
        { error: "Something went wrong. Please try again." },
        { status: 500 },
      );
    }

    return NextResponse.json({ ok: true });
  }

  const { data: updated, error } = await admin
    .from("staff_notifications")
    .update({ read_at: new Date().toISOString() })
    .eq("id", body.id as string)
    .eq("staff_id", staff.id)
    .select("id");

  if (error) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  // Not found or not this staff member's notification — same response
  // either way, so we never reveal whether a notification id belongs to
  // someone else (matching the account/bookings ownership-check convention).
  if (!updated || updated.length === 0) {
    return NextResponse.json(
      { error: "Notification not found" },
      { status: 404 },
    );
  }

  return NextResponse.json({ ok: true });
}
