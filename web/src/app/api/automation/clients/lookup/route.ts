import { assertAutomationKey } from "@/lib/auth/automation";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const authError = assertAutomationKey(request);
  if (authError) return authError;

  const phone = new URL(request.url).searchParams.get("phone");
  if (!phone) {
    return NextResponse.json({ error: "phone query param is required" }, { status: 400 });
  }

  const admin = createAdminClient();

  const { data, error } = await admin
    .from("clients")
    .select("id, name, phone, total_visits, last_visit_at, preferred_staff_id")
    .eq("phone", phone)
    .maybeSingle();

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  if (!data) {
    return NextResponse.json({ found: false });
  }

  type Row = {
    id: string;
    name: string;
    phone: string;
    total_visits: number | null;
    last_visit_at: string | null;
    preferred_staff_id: string | null;
  };
  const row = data as Row;

  return NextResponse.json({
    found: true,
    client: {
      id: row.id,
      name: row.name,
      phone: row.phone,
      totalVisits: row.total_visits ?? 0,
      lastVisitAt: row.last_visit_at,
      preferredStaffId: row.preferred_staff_id,
    },
  });
}
