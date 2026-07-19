import { getStaffFromRequest } from "@/lib/staffAuth";
import { isBookableRole } from "@/lib/staff/roles";
import { getAvailability } from "@/lib/booking/availability";
import { NextRequest, NextResponse } from "next/server";

// Token-authed sibling of /v1/public/availability, scoped to the caller's
// own staffId (never "any" — this staff member's own free slots for
// building a booking on their own schedule). getAvailability() requires a
// serviceId (slot length is duration-dependent), so this endpoint takes a
// `service` query param too, same as the public route's `service` param.

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

  const { searchParams } = request.nextUrl;
  const service = searchParams.get("service");
  const date = searchParams.get("date");

  if (!service) {
    return NextResponse.json(
      { error: "missing_service", message: "service query param is required." },
      { status: 400 },
    );
  }

  if (!date) {
    return NextResponse.json(
      { error: "missing_date", message: "date query param is required." },
      { status: 400 },
    );
  }

  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return NextResponse.json(
      { error: "invalid_date", message: "date must be in YYYY-MM-DD format." },
      { status: 400 },
    );
  }

  const slots = await getAvailability({
    staffId: staff.id,
    serviceId: service,
    date,
  });

  return NextResponse.json({ date, slots });
}
