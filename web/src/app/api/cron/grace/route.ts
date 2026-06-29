import { NextRequest, NextResponse } from "next/server";
import { assertAutomationKey } from "@/lib/auth/automation";
import { createAdminClient } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const authErr = assertAutomationKey(request);
  if (authErr) return authErr;

  const admin = createAdminClient();
  const cutoff = new Date(Date.now() - 15 * 60 * 1000).toISOString();

  const { data, error } = await admin
    .from("bookings")
    .update({ status: "late" })
    .eq("status", "booked")
    .lt("scheduled_start", cutoff)
    .select("id");

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ updated: data?.length ?? 0, cutoff });
}
