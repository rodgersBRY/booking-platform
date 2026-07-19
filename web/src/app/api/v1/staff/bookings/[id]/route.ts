import { getStaffFromRequest } from "@/lib/staffAuth";
import { isBookableRole } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import type { BookingChannel, BookingStatus } from "@/lib/db/types";
import { NextRequest, NextResponse } from "next/server";

// Token-authed appointment-detail screen for the mobile barber app. Unlike
// /v1/staff/day and /v1/staff/schedule (shared dashboard/list views, PII-safe
// name-only), this is the barber's OWN confirmed appointment — phone is
// included here, matching the level of client detail the cookie-authed
// receptionist views (e.g. /api/clients/search) already expose to bookable
// staff. Ownership is absolute: a barber can never read or touch another
// barber's booking, and this token-auth surface has no owner/receptionist
// bypass (unlike the cookie-authed /api/bookings/[id]/* routes).

function firstRel<T>(rel: unknown): T | null {
  if (rel == null) return null;
  if (Array.isArray(rel)) return (rel[0] as T) ?? null;
  return rel as T;
}

type BookingDetailRow = {
  id: unknown;
  status: unknown;
  channel: unknown;
  scheduled_start: unknown;
  scheduled_end: unknown;
  staff_id: unknown;
  client_id: unknown;
  clients: unknown;
  services: unknown;
  booking_services: unknown;
};

async function loadOwnedBooking(
  admin: ReturnType<typeof createAdminClient>,
  bookingId: string,
  staffId: string,
) {
  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .select(
      "id, status, channel, scheduled_start, scheduled_end, staff_id, client_id, clients(name, phone, total_visits, customer_notes, staff_notes), services(name), booking_services(services(name))",
    )
    .eq("id", bookingId)
    .single();

  if (bookErr || !booking) {
    return { error: "not_found" as const };
  }

  const row = booking as BookingDetailRow;
  if ((row.staff_id as string | null) !== staffId) {
    return { error: "forbidden" as const };
  }

  return { row };
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
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

  const { id } = await params;
  const admin = createAdminClient();

  const result = await loadOwnedBooking(admin, id, staff.id);
  if (result.error === "not_found") {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }
  if (result.error === "forbidden") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const row = result.row;
  const client = firstRel<{
    name: string;
    phone: string;
    total_visits: number;
    customer_notes: string | null;
    staff_notes: string | null;
  }>(row.clients);
  const primaryService = firstRel<{ name: string }>(row.services);

  const joinedServices = Array.isArray(row.booking_services)
    ? (row.booking_services as unknown[])
        .map((bs) => firstRel<{ name: string }>((bs as { services: unknown }).services))
        .filter((s): s is { name: string } => s != null)
        .map((s) => s.name)
    : [];

  const services =
    joinedServices.length > 0
      ? joinedServices
      : primaryService
        ? [primaryService.name]
        : [];

  const scheduledStart = row.scheduled_start as string;
  const scheduledEnd = row.scheduled_end as string;
  const durationMinutes = Math.round(
    (new Date(scheduledEnd).getTime() - new Date(scheduledStart).getTime()) / 60000,
  );

  const status = row.status as BookingStatus;

  return NextResponse.json({
    bookingId: row.id as string,
    status,
    channel: row.channel as BookingChannel,
    scheduledStart,
    scheduledEnd,
    durationMinutes,
    services,
    client: {
      name: client?.name ?? "Unknown",
      phone: client?.phone ?? null,
      totalVisits: client?.total_visits ?? 0,
      customerNotes: client?.customer_notes ?? null,
    },
    staffNotes: client?.staff_notes ?? null,
    canStart: status === "booked" || status === "arrived",
    canComplete: status === "in_chair",
  });
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
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

  let body: { customerNotes?: unknown; staffNotes?: unknown };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json(
      { error: "invalid_json", message: "Invalid JSON body." },
      { status: 400 },
    );
  }

  const hasCustomerNotes = typeof body.customerNotes === "string";
  const hasStaffNotes = typeof body.staffNotes === "string";

  if (
    (body.customerNotes !== undefined && !hasCustomerNotes) ||
    (body.staffNotes !== undefined && !hasStaffNotes)
  ) {
    return NextResponse.json(
      {
        error: "invalid_body",
        message: "customerNotes and staffNotes must be strings.",
      },
      { status: 400 },
    );
  }

  if (!hasCustomerNotes && !hasStaffNotes) {
    return NextResponse.json(
      {
        error: "invalid_body",
        message: "Provide customerNotes and/or staffNotes.",
      },
      { status: 400 },
    );
  }

  const { id } = await params;
  const admin = createAdminClient();

  const result = await loadOwnedBooking(admin, id, staff.id);
  if (result.error === "not_found") {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }
  if (result.error === "forbidden") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const updatePayload: Record<string, string> = {};
  if (hasCustomerNotes) updatePayload.customer_notes = body.customerNotes as string;
  if (hasStaffNotes) updatePayload.staff_notes = body.staffNotes as string;

  const { data: updated, error: updateErr } = await admin
    .from("clients")
    .update(updatePayload)
    .eq("id", result.row.client_id as string)
    .select("customer_notes, staff_notes")
    .single();

  if (updateErr || !updated) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  return NextResponse.json({
    customerNotes: updated.customer_notes as string | null,
    staffNotes: updated.staff_notes as string | null,
  });
}
