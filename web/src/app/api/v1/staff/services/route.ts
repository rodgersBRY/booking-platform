import { getStaffFromRequest } from "@/lib/staffAuth";
import { isBookableRole } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

// Token-authed sibling of /v1/public/services, filtered to only the services
// this staff member's role can perform. The authoritative source for that
// eligibility is the service_roles table (service_id -> role rows) — the
// same table createBooking.ts's own defensive role check queries.
// rolesForCategory() (src/lib/services/roleMapping.ts) is a category-based
// fallback heuristic used elsewhere and is NOT used here.

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

  const admin = createAdminClient();
  const { data, error } = await admin
    .from("services")
    .select("id, name, category, duration_minutes, price, service_roles!inner(role)")
    .eq("active", true)
    .eq("service_roles.role", staff.role)
    .order("category")
    .order("name");

  if (error) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  const services = (data ?? []).map(
    (s: {
      id: string;
      name: string;
      category: string | null;
      duration_minutes: number;
      price: number;
    }) => ({
      id: s.id,
      name: s.name,
      category: s.category,
      durationMinutes: s.duration_minutes,
      price: s.price,
    }),
  );

  return NextResponse.json({ services });
}
