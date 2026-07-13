import { getCurrentStaff } from "@/lib/auth";
import { getAvailability } from "@/lib/booking/availability";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { searchParams } = request.nextUrl;
  const barber = searchParams.get("staff");
  const service = searchParams.get("service");
  const date = searchParams.get("date");

  if (!barber || !service || !date) {
    return NextResponse.json(
      { error: "Missing required query params: staff, service, date" },
      { status: 400 },
    );
  }

  // Validate date format YYYY-MM-DD
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return NextResponse.json(
      { error: "date must be YYYY-MM-DD" },
      { status: 400 },
    );
  }

  const slots = await getAvailability({
    staffId: barber,
    serviceId: service,
    date,
  });

  return NextResponse.json({ date, slots });
}
