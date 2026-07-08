import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";
import type { Client } from "@/lib/db/types";
import type { NextRequest } from "next/server";

// Client accounts authenticate via a Bearer token (mobile app has no cookie
// jar), unlike staff which use cookie-based Supabase Auth sessions
// (lib/auth.ts). Keep these two entirely separate — never resolve a staff
// session with this file, or a client session with lib/auth.ts.
export type ClientWithAuthId = Client & { auth_user_id: string | null };

export function shapeClient(c: ClientWithAuthId) {
  return {
    id: c.id,
    name: c.name,
    phone: c.phone,
    email: c.email,
    loyaltyPoints: c.loyalty_points,
    totalVisits: c.total_visits,
  };
}

function bearerToken(request: NextRequest): string | null {
  const header = request.headers.get("authorization");
  if (!header?.startsWith("Bearer ")) return null;
  const token = header.slice("Bearer ".length).trim();
  return token || null;
}

/**
 * Resolves the client row for the Authorization: Bearer <token> header, or
 * null if missing/invalid/no linked client/inactive.
 */
export async function getClientFromRequest(
  request: NextRequest,
): Promise<ClientWithAuthId | null> {
  const token = bearerToken(request);
  if (!token) return null;

  const admin = createAdminClient();
  const { data: userData, error: userErr } = await admin.auth.getUser(token);
  if (userErr || !userData.user) return null;

  const { data, error } = await admin
    .from("clients")
    .select("*")
    .eq("auth_user_id", userData.user.id)
    .single();

  if (error || !data) return null;

  const row = data as ClientWithAuthId;
  if (row.status !== "active") return null;
  return row;
}
