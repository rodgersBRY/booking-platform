import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

type ServiceRow = {
  id: string;
  name: string;
  description: string | null;
  duration_minutes: number;
  price: number;
  active: boolean;
};

function shape(s: ServiceRow) {
  return {
    id: s.id,
    name: s.name,
    description: s.description,
    durationMinutes: s.duration_minutes,
    price: s.price,
    active: s.active,
  };
}

export async function GET(request: NextRequest) {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  // Owner management view: ?all=1 returns every service (incl. inactive).
  const all = request.nextUrl.searchParams.get("all") === "1";
  if (all && staff.role !== "owner") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const admin = createAdminClient();
  let query = admin
    .from("services")
    .select("id, name, description, duration_minutes, price, active")
    .order("name");
  if (!all) query = query.eq("active", true);

  const { data, error } = await query;
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({
    services: (data ?? []).map((s) => shape(s as ServiceRow)),
  });
}

export async function POST(request: NextRequest) {
  const caller = await getCurrentStaff();
  if (!caller)
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  if (caller.role !== "owner")
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });

  let body: {
    name?: string;
    description?: string;
    durationMinutes?: number;
    price?: number;
    active?: boolean;
  };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const { name, description, durationMinutes, price, active } = body;
  if (!name || !name.trim()) {
    return NextResponse.json({ error: "name is required" }, { status: 400 });
  }
  if (typeof durationMinutes !== "number" || durationMinutes <= 0) {
    return NextResponse.json(
      { error: "durationMinutes must be a positive number" },
      { status: 400 },
    );
  }
  if (typeof price !== "number" || price < 0) {
    return NextResponse.json(
      { error: "price must be zero or a positive number" },
      { status: 400 },
    );
  }

  const admin = createAdminClient();
  const { data, error } = await admin
    .from("services")
    .insert({
      name: name.trim(),
      description: description?.trim() || null,
      duration_minutes: durationMinutes,
      price,
      active: active ?? true,
    })
    .select("id, name, description, duration_minutes, price, active")
    .single();

  if (error)
    return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json(
    { service: shape(data as ServiceRow) },
    { status: 201 },
  );
}
