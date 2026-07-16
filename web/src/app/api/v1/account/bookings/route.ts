import { getClientFromRequest } from "@/lib/clientAuth";
import { shapeBooking } from "@/lib/booking/shapeBooking";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

const UPCOMING_STATUSES = ["booked", "arrived", "in_chair", "late"];
const CANCELLED_STATUSES = ["cancelled", "no_show"];

export async function GET(request: NextRequest) {
  const client = await getClientFromRequest(request);
  if (!client) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const admin = createAdminClient();
  const { data, error } = await admin
    .from("bookings")
    .select(
      "*, staff:staff_id(id,name,role,avatar_url), services:service_id(id,name,category,duration_minutes,price)",
    )
    .eq("client_id", client.id);

  if (error) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  const bookings = (data ?? []).map(shapeBooking);

  const upcoming = bookings
    .filter((b) => UPCOMING_STATUSES.includes(b.status))
    .sort((a, b) => a.scheduledStart.localeCompare(b.scheduledStart));

  const completed = bookings
    .filter((b) => b.status === "completed")
    .sort((a, b) => b.scheduledStart.localeCompare(a.scheduledStart));

  const cancelled = bookings
    .filter((b) => CANCELLED_STATUSES.includes(b.status))
    .sort((a, b) => b.scheduledStart.localeCompare(a.scheduledStart));

  return NextResponse.json({ upcoming, completed, cancelled });
}
