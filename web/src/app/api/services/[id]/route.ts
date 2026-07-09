import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
import type { StaffRole } from "@/lib/db/types";
import { NextRequest, NextResponse } from "next/server";

type ServiceRow = {
  id: string;
  name: string;
  category: string | null;
  description: string | null;
  duration_minutes: number;
  price: number;
  active: boolean;
};

function shape(s: ServiceRow, roles: StaffRole[]) {
  return {
    id: s.id,
    name: s.name,
    category: s.category,
    description: s.description,
    durationMinutes: s.duration_minutes,
    price: s.price,
    active: s.active,
    roles,
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
    category?: string | null;
    description?: string | null;
    durationMinutes?: number;
    price?: number;
    active?: boolean;
    roles?: StaffRole[];
  };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  if (body.roles !== undefined && body.roles.length === 0) {
    return NextResponse.json(
      { error: "roles cannot be empty — use active:false to disable a service instead" },
      { status: 400 },
    );
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
  if (body.category !== undefined) {
    update.category = body.category?.trim() || null;
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
    .select("id, name, category, description, duration_minutes, price, active")
    .single();

  if (error)
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  if (!data)
    return NextResponse.json({ error: "Service not found" }, { status: 404 });

  let roles: StaffRole[];
  if (body.roles !== undefined) {
    await admin.from("service_roles").delete().eq("service_id", id);
    const { error: rolesErr } = await admin
      .from("service_roles")
      .insert(body.roles.map((role) => ({ service_id: id, role })));
    if (rolesErr) {
      return NextResponse.json(
        { error: "Something went wrong. Please try again." },
        { status: 500 },
      );
    }
    roles = body.roles;
  } else {
    const { data: roleRows } = await admin
      .from("service_roles")
      .select("role")
      .eq("service_id", id);
    roles = (roleRows ?? []).map((r) => r.role as StaffRole);
  }

  return NextResponse.json({ service: shape(data as ServiceRow, roles) });
}
