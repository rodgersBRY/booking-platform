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
//
// GET below is a different population than /v1/staff/clients/search: search
// (searchClients()) looks across ALL clients shop-wide. This is "My
// Customers" — clients THIS staff member has personally served — derived
// from `visits.staff_id`, not searchClients(). Visit count and last-visit
// date are per-relationship (this staff member's own visits with the
// client), not the shop-wide `clients.total_visits` / `last_visit_at`
// columns those other views read.

type VisitStatsRow = { client_id: unknown; completed_at: unknown };

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

  // Every visit this staff member has ever completed, newest first — the
  // source of truth for "who is my customer" (distinct client_id) and their
  // per-relationship visit count / last-visit date. No pagination: a single
  // barber's served-client set is bounded in practice, matching the
  // no-group-by, aggregate-in-JS style already used by /v1/staff/day.
  const { data: visitRows, error: visitErr } = await admin
    .from("visits")
    .select("client_id, completed_at")
    .eq("staff_id", staff.id)
    .order("completed_at", { ascending: false });

  if (visitErr) {
    return NextResponse.json(
      { error: "server_error", message: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  const stats = new Map<string, { count: number; lastVisitAt: string }>();
  for (const raw of visitRows ?? []) {
    const row = raw as VisitStatsRow;
    const clientId = row.client_id as string;
    const completedAt = row.completed_at as string;
    const existing = stats.get(clientId);
    if (existing) {
      existing.count += 1;
      // Rows are ordered by completed_at desc, so the FIRST time we see a
      // client_id already holds their most recent visit — no comparison
      // needed on subsequent (older) rows.
    } else {
      stats.set(clientId, { count: 1, lastVisitAt: completedAt });
    }
  }

  if (stats.size === 0) {
    return NextResponse.json({ clients: [] });
  }

  const { data: clientRows, error: clientErr } = await admin
    .from("clients")
    .select("id, name, phone")
    .in("id", [...stats.keys()]);

  if (clientErr) {
    return NextResponse.json(
      { error: "server_error", message: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  // Optional q: name-substring or phone-prefix match, same case-insensitive
  // technique as searchClients.ts, but filtered client-side over this
  // staff member's already-scoped served-client set (no 2-char minimum —
  // unlike global search, this is a real list to browse, not an
  // open-ended query over the whole clients table).
  const q = (request.nextUrl.searchParams.get("q") ?? "").trim();
  const qLower = q.toLowerCase();
  const filtered =
    q.length === 0
      ? (clientRows ?? [])
      : (clientRows ?? []).filter((c) => {
          const name = (c.name as string).toLowerCase();
          const phone = c.phone as string;
          return name.includes(qLower) || phone.startsWith(q);
        });

  const clients = filtered
    .map((c) => {
      const id = c.id as string;
      const s = stats.get(id)!;
      return {
        id,
        name: c.name as string,
        phone: c.phone as string,
        visitCount: s.count,
        lastVisitAt: s.lastVisitAt,
      };
    })
    .sort((a, b) => (a.lastVisitAt < b.lastVisitAt ? 1 : a.lastVisitAt > b.lastVisitAt ? -1 : 0));

  return NextResponse.json({ clients });
}

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
