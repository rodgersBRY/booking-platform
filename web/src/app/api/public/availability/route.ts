import { getAvailability } from "@/lib/booking/availability";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const barber = searchParams.get("barber");
  const service = searchParams.get("service");
  const date = searchParams.get("date");

  if (!barber || !service || !date) {
    return NextResponse.json(
      { error: "Missing required query params: barber, service, date" },
      { status: 400 },
    );
  }

  // Validate date format YYYY-MM-DD.
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return NextResponse.json(
      { error: "date must be in YYYY-MM-DD format" },
      { status: 400 },
    );
  }

  const slots = await getAvailability({
    barberId: barber === "any" ? "any" : barber,
    serviceId: service,
    date,
  });

  return NextResponse.json({ date, slots });
}
