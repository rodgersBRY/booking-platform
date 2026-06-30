import { assertAutomationKey } from "@/lib/auth/automation";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

export const dynamic = "force-dynamic";

const TZ = "Africa/Nairobi";

function eatTodayBounds(): { start: string; end: string } {
  const now = new Date();
  const eatDate = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
  return {
    start: new Date(`${eatDate}T00:00:00+03:00`).toISOString(),
    end: new Date(`${eatDate}T23:59:59+03:00`).toISOString(),
  };
}

function firstRel<T>(rel: unknown): T | null {
  if (rel == null) return null;
  if (Array.isArray(rel)) return (rel[0] as T) ?? null;
  return rel as T;
}

export async function GET(request: NextRequest) {
  const authError = assertAutomationKey(request);
  if (authError) return authError;

  const admin = createAdminClient();
  const { start, end } = eatTodayBounds();

  const { data: completedBookings, error } = await admin
    .from("bookings")
    .select(
      "id, client_id, clients(name, phone), staff!barber_id(name), services(name)",
    )
    .eq("status", "completed")
    .gte("updated_at", start)
    .lte("updated_at", end);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  const bookings = completedBookings ?? [];
  if (bookings.length === 0) {
    return NextResponse.json({ bookings: [] });
  }

  const bookingIds = bookings.map((b: { id: string }) => b.id);

  // Find which bookings already have a review_request in message_log
  const { data: logRows } = await admin
    .from("message_log")
    .select("booking_id")
    .eq("type", "review_request")
    .in("booking_id", bookingIds);

  const sentSet = new Set(
    (logRows ?? []).map((r: { booking_id: string }) => r.booking_id),
  );

  type BookingRow = {
    id: string;
    client_id: string;
    clients: unknown;
    staff: unknown;
    services: unknown;
  };

  const result = (bookings as BookingRow[]).map((b) => {
    const client = firstRel<{ name: string; phone: string }>(b.clients);
    const barber = firstRel<{ name: string }>(b.staff);
    const service = firstRel<{ name: string }>(b.services);
    return {
      bookingId: b.id,
      clientId: b.client_id,
      clientName: client?.name ?? "Unknown",
      clientPhone: client?.phone ?? null,
      barberName: barber?.name ?? null,
      serviceName: service?.name ?? null,
      followupSent: sentSet.has(b.id),
    };
  });

  return NextResponse.json({ bookings: result });
}
