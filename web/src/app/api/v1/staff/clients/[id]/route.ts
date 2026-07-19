import { getStaffFromRequest } from "@/lib/staffAuth";
import { isBookableRole } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

// Token-authed "My Customers" profile for the mobile barber app. Ownership
// here is NOT a foreign key on `clients` (there's no staff_id on that
// table) — it's derived: a barber may view a client only if they have at
// least one `visits` row with them. This mirrors the ownership pattern in
// /v1/staff/bookings/[id]: 404 when the underlying row genuinely doesn't
// exist (no client with this id), 403 when it exists but doesn't belong to
// this staff member (client exists, but this staff never served them — not
// a general client lookup).
//
// The visit timeline is scoped to THIS staff member's own visits with the
// client, not the client's shop-wide visit history — same per-relationship
// distinction as the GET on /v1/staff/clients.
//
// Per-visit services: completeBooking.ts only ever copies the booking's
// PRIMARY service onto visits.service_id, never the full booking_services
// list, so a multi-service appointment would silently lose its secondary
// services if we read visits.service_id alone. When the visit has a
// booking_id, join through to booking_services for the full list (same
// join idiom as /v1/staff/bookings/[id]); fall back to the visit's own
// service_id for walk-ins with no booking (or the rare case
// booking_services is empty).

function firstRel<T>(rel: unknown): T | null {
  if (rel == null) return null;
  if (Array.isArray(rel)) return (rel[0] as T) ?? null;
  return rel as T;
}

type VisitRow = {
  completed_at: unknown;
  service_id: unknown;
  services: unknown;
  booking_id: unknown;
  bookings: unknown;
};

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

  const { data: client, error: clientErr } = await admin
    .from("clients")
    .select("id, name, phone, customer_notes, staff_notes")
    .eq("id", id)
    .single();

  if (clientErr || !client) {
    return NextResponse.json({ error: "Client not found" }, { status: 404 });
  }

  const { data: visitRows, error: visitErr } = await admin
    .from("visits")
    .select(
      "completed_at, service_id, services(name), booking_id, bookings(booking_services(services(name)))",
    )
    .eq("staff_id", staff.id)
    .eq("client_id", id)
    .order("completed_at", { ascending: false });

  if (visitErr) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  // No visits rows for this staff+client pair: either this staff member has
  // never served this client, or this client belongs entirely to other
  // staff. Either way, this is not this barber's customer to view.
  if (!visitRows || visitRows.length === 0) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const visits = visitRows.map((raw: unknown) => {
    const row = raw as VisitRow;
    const primaryService = firstRel<{ name: string }>(row.services);

    const booking = firstRel<{ booking_services: unknown }>(row.bookings);
    const joinedServices = Array.isArray(booking?.booking_services)
      ? (booking!.booking_services as unknown[])
          .map((bs) =>
            firstRel<{ name: string }>((bs as { services: unknown }).services),
          )
          .filter((s): s is { name: string } => s != null)
          .map((s) => s.name)
      : [];

    const services =
      joinedServices.length > 0
        ? joinedServices
        : primaryService
          ? [primaryService.name]
          : [];

    return {
      date: row.completed_at as string,
      services,
    };
  });

  return NextResponse.json({
    id: client.id as string,
    name: client.name as string,
    phone: client.phone as string,
    visitCount: visits.length,
    customerNotes: client.customer_notes as string | null,
    staffNotes: client.staff_notes as string | null,
    visits,
  });
}
