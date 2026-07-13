import { getCurrentStaff } from "@/lib/auth";
import { isBookableRole } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

// TODO: AUTOMATION_API_KEY auth — n8n will authenticate via this header in production.

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  // Parse optional body first.
  let body: { amountCharged?: number; paymentMethod?: string } = {};
  try {
    body = await request.json();
  } catch {
    // Body is optional.
  }
  const amountCharged = body.amountCharged ?? 0;
  const paymentMethod = body.paymentMethod ?? null;

  // Base role gate — bookable-staff ownership checked after fetching booking.
  if (
    staff.role !== "owner" &&
    staff.role !== "receptionist" &&
    !isBookableRole(staff.role)
  ) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { id } = await params;
  const admin = createAdminClient();

  // Fetch booking.
  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .select("id, client_id, staff_id, service_id, status")
    .eq("id", id)
    .single();

  if (bookErr || !booking) {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }

  // Bookable staff may only complete their own bookings.
  if (isBookableRole(staff.role) && booking.staff_id !== staff.id) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  if (booking.status === "completed") {
    return NextResponse.json({ error: "Booking already completed" }, { status: 409 });
  }

  const now = new Date().toISOString();

  // Mark booking completed.
  const { error: updateErr } = await admin
    .from("bookings")
    .update({ status: "completed" })
    .eq("id", id);

  if (updateErr) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  // Insert visit row.
  const { data: visit, error: visitErr } = await admin
    .from("visits")
    .insert({
      booking_id: id,
      client_id: booking.client_id as string,
      staff_id: booking.staff_id as string | null,
      service_id: booking.service_id as string,
      completed_at: now,
      amount_charged: amountCharged,
      payment_method: paymentMethod,
    })
    .select()
    .single();

  if (visitErr) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  // Bump client total_visits and last_visit_at.
  const { data: client } = await admin
    .from("clients")
    .select("total_visits")
    .eq("id", booking.client_id as string)
    .single();

  await admin
    .from("clients")
    .update({
      total_visits: ((client?.total_visits as number | undefined) ?? 0) + 1,
      last_visit_at: now,
    })
    .eq("id", booking.client_id as string);

  return NextResponse.json({ visit });
}
