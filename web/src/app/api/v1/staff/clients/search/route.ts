import { getStaffFromRequest } from "@/lib/staffAuth";
import { isBookableRole } from "@/lib/staff/roles";
import { searchClients } from "@/lib/clients/searchClients";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

// Token-authed sibling of /api/clients/search for the mobile barber app: a
// barber creating a booking for someone who called needs to find them by
// name/phone, same as reception does. No ownership filtering — any staff
// member can search any client, matching the cookie-authed receptionist
// search this delegates its core query logic to (searchClients()).

export async function GET(request: NextRequest) {
  const staff = await getStaffFromRequest(request);
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  if (!isBookableRole(staff.role)) {
    return NextResponse.json(
      {
        error: "not_bookable_role",
        message: "This account doesn't have access to the barber app.",
      },
      { status: 403 },
    );
  }

  const q = request.nextUrl.searchParams.get("q") ?? "";
  const admin = createAdminClient();
  const clients = await searchClients(q, admin);

  return NextResponse.json({ clients });
}
