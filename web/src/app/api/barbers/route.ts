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
    .select("id, name, role")
    .in("role", BOOKABLE_ROLES)
    .eq("status", "active")
    .order("name");

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ barbers: data });
}
