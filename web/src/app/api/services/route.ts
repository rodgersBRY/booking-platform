import { getCurrentStaff } from "@/lib/auth";
import { rolesForCategory } from "@/lib/services/roleMapping";
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
    .select("id, name, category, description, duration_minutes, price, active")
    .order("category")
    .order("name");
  if (!all) query = query.eq("active", true);

  const { data, error } = await query;
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  const rows = (data ?? []) as ServiceRow[];
  const ids = rows.map((r) => r.id);
  const rolesByService = new Map<string, StaffRole[]>();
  if (ids.length > 0) {
    const { data: roleRows, error: rolesErr } = await admin
      .from("service_roles")
      .select("service_id, role")
      .in("service_id", ids);
    if (rolesErr) {
      return NextResponse.json({ error: rolesErr.message }, { status: 500 });
    }
    for (const r of roleRows ?? []) {
      const list = rolesByService.get(r.service_id as string) ?? [];
      list.push(r.role as StaffRole);
      rolesByService.set(r.service_id as string, list);
    }
  }

  return NextResponse.json({
    services: rows.map((s) => shape(s, rolesByService.get(s.id) ?? [])),
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
    category?: string;
    description?: string;
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

  const { name, category, description, durationMinutes, price, active, roles } = body;
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
  if (roles !== undefined && roles.length === 0) {
    return NextResponse.json(
      { error: "roles cannot be empty — use active:false to disable a service instead" },
      { status: 400 },
    );
  }

  const trimmedCategory = category?.trim() || null;
  const finalRoles = roles ?? rolesForCategory(trimmedCategory);

  const admin = createAdminClient();
  const { data, error } = await admin
    .from("services")
    .insert({
      name: name.trim(),
      category: trimmedCategory,
      description: description?.trim() || null,
      duration_minutes: durationMinutes,
      price,
      active: active ?? true,
    })
    .select("id, name, category, description, duration_minutes, price, active")
    .single();

  if (error)
    return NextResponse.json({ error: error.message }, { status: 500 });

  const { error: rolesErr } = await admin
    .from("service_roles")
    .insert(finalRoles.map((role) => ({ service_id: data.id, role })));
  if (rolesErr) {
    await admin.from("services").delete().eq("id", data.id);
    return NextResponse.json({ error: rolesErr.message }, { status: 500 });
  }

  return NextResponse.json(
    { service: shape(data as ServiceRow, finalRoles) },
    { status: 201 },
  );
}
