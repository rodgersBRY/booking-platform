import { getStaffFromRequest, shapeStaff } from "@/lib/staffAuth";
import { isBookableRole } from "@/lib/staff/roles";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const staff = await getStaffFromRequest(request);
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  // The login route already gates on this, but a token minted elsewhere (the
  // web console's Supabase session) resolves here too. Every /v1/staff route
  // re-checks the role rather than trusting how the token was issued.
  if (!isBookableRole(staff.role)) {
    return NextResponse.json(
      {
        error: "not_bookable_role",
        message: "This account doesn't have access to the barber app.",
      },
      { status: 403 },
    );
  }

  return NextResponse.json({ staff: shapeStaff(staff) });
}
