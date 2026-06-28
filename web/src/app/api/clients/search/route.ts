import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

export interface ClientSearchResult {
  id: string;
  name: string;
  phone: string;
  preferredBarberId: string | null;
  preferredBarberName: string | null;
  totalVisits: number;
  lastVisitAt: string | null;
  isRegular: boolean;
}

export async function GET(request: NextRequest) {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  if (staff.role !== "owner" && staff.role !== "receptionist") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const q = (request.nextUrl.searchParams.get("q") ?? "").trim();
  if (q.length < 2) {
    return NextResponse.json({ clients: [] });
  }

  const admin = createAdminClient();

  // Case-insensitive: phone starts with q OR name contains q.
  // Supabase doesn't support OR across columns with ilike in a single filter
  // call, so we run two queries and merge, deduping by id.
  const [byPhone, byName] = await Promise.all([
    admin
      .from("clients")
      .select("id, name, phone, preferred_barber_id, total_visits, last_visit_at")
      .ilike("phone", `${q}%`)
      .limit(8),
    admin
      .from("clients")
      .select("id, name, phone, preferred_barber_id, total_visits, last_visit_at")
      .ilike("name", `%${q}%`)
      .limit(8),
  ]);

  // Merge and dedupe by id, preserving order (phone matches first).
  const seen = new Set<string>();
  const rows: {
    id: string;
    name: string;
    phone: string;
    preferred_barber_id: string | null;
    total_visits: number;
    last_visit_at: string | null;
  }[] = [];

  for (const row of [...(byPhone.data ?? []), ...(byName.data ?? [])]) {
    const id = row.id as string;
    if (seen.has(id)) continue;
    seen.add(id);
    rows.push({
      id,
      name: row.name as string,
      phone: row.phone as string,
      preferred_barber_id: row.preferred_barber_id as string | null,
      total_visits: (row.total_visits as number) ?? 0,
      last_visit_at: row.last_visit_at as string | null,
    });
    if (rows.length >= 8) break;
  }

  // Resolve preferred barber names in one query.
  const barberIds = [...new Set(rows.map((r) => r.preferred_barber_id).filter(Boolean))] as string[];
  const barberMap = new Map<string, string>();
  if (barberIds.length > 0) {
    const { data: barbers } = await admin
      .from("staff")
      .select("id, name")
      .in("id", barberIds);
    for (const b of barbers ?? []) {
      barberMap.set(b.id as string, b.name as string);
    }
  }

  const clients: ClientSearchResult[] = rows.map((r) => ({
    id: r.id,
    name: r.name,
    phone: r.phone,
    preferredBarberId: r.preferred_barber_id,
    preferredBarberName: r.preferred_barber_id ? (barberMap.get(r.preferred_barber_id) ?? null) : null,
    totalVisits: r.total_visits,
    lastVisitAt: r.last_visit_at,
    isRegular: r.total_visits >= 5,
  }));

  return NextResponse.json({ clients });
}
