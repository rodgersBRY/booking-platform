import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";
import type { StaffWithAuthId } from "@/lib/auth";
import type { NextRequest } from "next/server";

// Staff accounts on the mobile app authenticate via a Bearer token (mobile
// has no cookie jar), unlike the web console which uses cookie-based
// Supabase Auth sessions (lib/auth.ts). This is the TOKEN path; lib/auth.ts
// is the COOKIE path. Keep these two entirely separate — never resolve a web
// console session with this file, or a mobile staff session with lib/auth.ts.
export type { StaffWithAuthId };

export function shapeStaff(s: StaffWithAuthId) {
  return {
    id: s.id,
    name: s.name,
    role: s.role,
    phone: s.phone,
    email: s.email,
    avatarUrl: s.avatar_url,
    status: s.status,
  };
}

function bearerToken(request: NextRequest): string | null {
  const header = request.headers.get("authorization");
  if (!header?.startsWith("Bearer ")) return null;
  const token = header.slice("Bearer ".length).trim();
  return token || null;
}

/**
 * Resolves the staff row for the Authorization: Bearer <token> header, or
 * null if missing/invalid/no linked staff/inactive.
 */
export async function getStaffFromRequest(
  request: NextRequest,
): Promise<StaffWithAuthId | null> {
  const token = bearerToken(request);
  if (!token) return null;

  const admin = createAdminClient();
  const { data: userData, error: userErr } = await admin.auth.getUser(token);
  if (userErr || !userData.user) return null;

  const { data, error } = await admin
    .from("staff")
    .select("*")
    .eq("auth_user_id", userData.user.id)
    .single();

  if (error || !data) return null;

  const row = data as StaffWithAuthId;
  if (row.status !== "active") return null;
  return row;
}
