import { getCurrentStaff } from "@/lib/auth";
import { searchClients } from "@/lib/clients/searchClients";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

export type { ClientSearchResult } from "@/lib/clients/searchClients";

export async function GET(request: NextRequest) {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  if (staff.role !== "owner" && staff.role !== "receptionist") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const q = request.nextUrl.searchParams.get("q") ?? "";
  const admin = createAdminClient();
  const clients = await searchClients(q, admin);

  return NextResponse.json({ clients });
}
