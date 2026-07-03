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

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const caller = await getCurrentStaff();
  if (!caller)
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  if (caller.role !== "owner")
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });

  const { id } = await params;
  let body: {
    name?: string;
    description?: string | null;
    durationMinutes?: number;
    price?: number;
    active?: boolean;
  };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const update: Record<string, unknown> = {};

  if (body.name !== undefined) {
    if (!body.name.trim())
      return NextResponse.json(
        { error: "name cannot be empty" },
        { status: 400 },
      );
    update.name = body.name.trim();
  }
  if (body.description !== undefined) {
    update.description = body.description?.trim() || null;
  }
  if (body.durationMinutes !== undefined) {
    if (typeof body.durationMinutes !== "number" || body.durationMinutes <= 0)
      return NextResponse.json(
        { error: "durationMinutes must be a positive number" },
        { status: 400 },
      );
    update.duration_minutes = body.durationMinutes;
  }
  if (body.price !== undefined) {
    if (typeof body.price !== "number" || body.price < 0)
      return NextResponse.json(
        { error: "price must be zero or a positive number" },
        { status: 400 },
      );
    update.price = body.price;
  }
  if (body.active !== undefined) {
    update.active = body.active;
  }

  if (Object.keys(update).length === 0) {
    return NextResponse.json({ error: "No fields to update" }, { status: 400 });
  }

  const admin = createAdminClient();
  const { data, error } = await admin
    .from("services")
    .update(update)
    .eq("id", id)
    .select("id, name, description, duration_minutes, price, active")
    .single();

  if (error)
    return NextResponse.json({ error: error.message }, { status: 500 });
  if (!data)
    return NextResponse.json({ error: "Service not found" }, { status: 404 });
  return NextResponse.json({ service: shape(data as ServiceRow) });
}
