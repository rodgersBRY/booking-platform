import { getStaffFromRequest } from "@/lib/staffAuth";
import { isBookableRole } from "@/lib/staff/roles";
import { shapeStaffNotification } from "@/lib/notifications/shapeStaffNotification";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

// Token-authed staff notification feed for the mobile barber app's
// Notifications tab. Staff parallel to GET /api/v1/account/notifications —
// same shape/ordering convention, reading from staff_notifications instead
// of notifications (see createStaffNotification.ts for why the tables and
// writers are kept separate).

export async function GET(request: NextRequest) {
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

  const admin = createAdminClient();
  const { data, error } = await admin
    .from("staff_notifications")
    .select("*")
    .eq("staff_id", staff.id)
    .order("created_at", { ascending: false })
    .limit(100);

  if (error) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  const notifications = (data ?? []).map(shapeStaffNotification);
  const unreadCount = notifications.filter((n) => n.readAt === null).length;

  return NextResponse.json({ notifications, unreadCount });
}
