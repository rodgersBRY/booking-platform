import { BOOKABLE_ROLES } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const admin = createAdminClient();
  const serviceId = request.nextUrl.searchParams.get("serviceId");

  let eligibleRoles: string[] = BOOKABLE_ROLES;
  if (serviceId) {
    const { data: roleRows, error: rolesErr } = await admin
      .from("service_roles")
      .select("role")
      .eq("service_id", serviceId);
    if (rolesErr) {
      return NextResponse.json(
        { error: "Something went wrong. Please try again." },
        { status: 500 },
      );
    }
    eligibleRoles = (roleRows ?? []).map((r) => r.role as string);
  }

  const { data, error } = await admin
    .from("staff")
    .select("id, name, role, avatar_url")
    .in("role", eligibleRoles)
    .eq("status", "active")
    .order("name");

  if (error) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  const barbers = (data ?? []).map((r) => ({
    id: r.id,
    name: r.name,
    role: r.role,
    avatarUrl: r.avatar_url,
  }));

  return NextResponse.json({ barbers });
}
