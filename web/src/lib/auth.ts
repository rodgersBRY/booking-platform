import "server-only";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import type { Staff, StaffRole } from "@/lib/db/types";

// Staff row augmented with auth_user_id (added in migration 0002).
export type StaffWithAuthId = Staff & { auth_user_id: string | null };

/** Map a role to its home route. */
export function roleHome(role: StaffRole): string {
  switch (role) {
    case "owner":
      return "/dashboard";
    case "receptionist":
      return "/console";
    case "barber":
      return "/me";
  }
}

/**
 * Returns the signed-in user's staff row (joined via auth_user_id), or null
 * if the user is not authenticated or has no matching staff record.
 */
export async function getCurrentStaff(): Promise<StaffWithAuthId | null> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) return null;

  // Use the admin client so RLS doesn't block the lookup.
  const admin = createAdminClient();
  const { data, error } = await admin
    .from("staff")
    .select("*")
    .eq("auth_user_id", user.id)
    .single();

  if (error || !data) return null;

  const row = data as StaffWithAuthId;
  if (row.status !== "active") return null;
  return row;
}

/**
 * Returns the signed-in staff or redirects to /login.
 * Use this in pages/actions that require any authenticated staff member.
 */
export async function requireStaff(): Promise<StaffWithAuthId> {
  const staff = await getCurrentStaff();
  if (!staff) redirect("/login");
  return staff;
}

/**
 * Returns the signed-in staff if they have one of the allowed roles, or
 * redirects appropriately:
 *   - not signed in  → /login
 *   - wrong role     → their own role home
 */
export async function requireRole(
  ...roles: StaffRole[]
): Promise<StaffWithAuthId> {
  const staff = await getCurrentStaff();
  if (!staff) redirect("/login");
  if (!roles.includes(staff.role)) redirect(roleHome(staff.role));
  return staff;
}
