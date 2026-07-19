import { getStaffFromRequest } from "@/lib/staffAuth";
import { isBookableRole } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

// Quick client registration for the mobile barber app's create-booking flow
// (BARBER-APP.md: "Name, Phone Number. Nothing else is required."). This is
// a real create, not a find-or-create — a duplicate phone is a genuine
// conflict to surface (409), not something to silently resolve. The
// find-or-create-by-phone path lives separately in createBooking.ts for
// callers that pass client.{name,phone} directly.

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

  let body: { name?: unknown; phone?: unknown };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json(
      { error: "invalid_json", message: "Invalid JSON body." },
      { status: 400 },
    );
  }

  const name = typeof body.name === "string" ? body.name.trim() : "";
  const phone = typeof body.phone === "string" ? body.phone.trim() : "";

  if (!name || !phone) {
    return NextResponse.json(
      { error: "invalid_body", message: "name and phone are required." },
      { status: 400 },
    );
  }

  const admin = createAdminClient();
  const { data: created, error: insertErr } = await admin
    .from("clients")
    .insert({ name, phone })
    .select("id, name, phone, total_visits, last_visit_at")
    .single();

  if (insertErr) {
    if (insertErr.code === "23505") {
      return NextResponse.json(
        {
          error: "phone_taken",
          message: "A client with this phone number already exists.",
        },
        { status: 409 },
      );
    }
    return NextResponse.json(
      { error: "server_error", message: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  return NextResponse.json(
    {
      client: {
        id: created.id as string,
        name: created.name as string,
        phone: created.phone as string,
        totalVisits: (created.total_visits as number) ?? 0,
        lastVisitAt: created.last_visit_at as string | null,
      },
    },
    { status: 201 },
  );
}
