import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";

// Core client-search logic (phone-prefix + name-substring merge/dedupe),
// shared by the cookie-authed web receptionist console
// (/api/clients/search) and the token-authed mobile barber app
// (/api/v1/staff/clients/search).
//
// NO auth or role logic lives here — callers resolve identity and
// permissions themselves before calling this, same as createBooking.ts /
// seatBooking.ts do for their own flows.

export interface ClientSearchResult {
  id: string;
  name: string;
  phone: string;
  preferredStaffId: string | null;
  preferredStaffName: string | null;
  totalVisits: number;
  lastVisitAt: string | null;
  isRegular: boolean;
}

export async function searchClients(
  query: string,
  admin: ReturnType<typeof createAdminClient>,
): Promise<ClientSearchResult[]> {
  const q = query.trim();
  if (q.length < 2) return [];

  // Case-insensitive: phone starts with q OR name contains q.
  // Supabase doesn't support OR across columns with ilike in a single filter
  // call, so we run two queries and merge, deduping by id.
  const [byPhone, byName] = await Promise.all([
    admin
      .from("clients")
      .select("id, name, phone, preferred_staff_id, total_visits, last_visit_at")
      .ilike("phone", `${q}%`)
      .limit(8),
    admin
      .from("clients")
      .select("id, name, phone, preferred_staff_id, total_visits, last_visit_at")
      .ilike("name", `%${q}%`)
      .limit(8),
  ]);

  // Merge and dedupe by id, preserving order (phone matches first).
  const seen = new Set<string>();
  const rows: {
    id: string;
    name: string;
    phone: string;
    preferred_staff_id: string | null;
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
      preferred_staff_id: row.preferred_staff_id as string | null,
      total_visits: (row.total_visits as number) ?? 0,
      last_visit_at: row.last_visit_at as string | null,
    });

    if (rows.length >= 8) break;
  }

  // Resolve preferred barber names in one query.
  const staffIds = [...new Set(rows.map((r) => r.preferred_staff_id).filter(Boolean))] as string[];
  const staffMap = new Map<string, string>();
  if (staffIds.length > 0) {
    const { data: barbers } = await admin
      .from("staff")
      .select("id, name")
      .in("id", staffIds);
    for (const b of barbers ?? []) {
      staffMap.set(b.id as string, b.name as string);
    }
  }

  return rows.map((r) => ({
    id: r.id,
    name: r.name,
    phone: r.phone,
    preferredStaffId: r.preferred_staff_id,
    preferredStaffName: r.preferred_staff_id ? (staffMap.get(r.preferred_staff_id) ?? null) : null,
    totalVisits: r.total_visits,
    lastVisitAt: r.last_visit_at,
    isRegular: r.total_visits >= 5,
  }));
}
