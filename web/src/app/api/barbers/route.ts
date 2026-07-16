import { getCurrentStaff } from "@/lib/auth";
import { BOOKABLE_ROLES } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextResponse } from "next/server";

export async function GET() {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const admin = createAdminClient();
  const { data, error } = await admin
    .from("staff")
    .select("id, name, role, avatar_url")
    .in("role", BOOKABLE_ROLES)
    .eq("status", "active")
    .order("name");

  if (error) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  const barbers = (data ?? []).map((staff) => ({
    id: staff.id,
    name: staff.name,
    role: staff.role,
    avatarUrl: staff.avatar_url,
  }));

  return NextResponse.json({ barbers });
}
