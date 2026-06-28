import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextResponse } from "next/server";

export async function GET() {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const admin = createAdminClient();
  const { data, error } = await admin
    .from("services")
    .select("id, name, duration_minutes, price")
    .eq("active", true)
    .order("name");

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  const services = (data ?? []).map(
    (s: { id: string; name: string; duration_minutes: number; price: number }) => ({
      id: s.id,
      name: s.name,
      durationMinutes: s.duration_minutes,
      price: s.price,
    }),
  );

  return NextResponse.json({ services });
}
