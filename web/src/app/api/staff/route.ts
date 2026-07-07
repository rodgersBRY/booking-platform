import { getCurrentStaff } from "@/lib/auth";
import { defaultAvailabilityForBarber } from "@/lib/staff/availability";
import { CREATABLE_ROLES, isBookableRole } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import type { StaffRole } from "@/lib/db/types";
import { NextRequest, NextResponse } from "next/server";

export async function GET() {
  const caller = await getCurrentStaff();
  if (!caller) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  if (caller.role !== "owner") return NextResponse.json({ error: "Forbidden" }, { status: 403 });

  const admin = createAdminClient();
  const { data, error } = await admin
    .from("staff")
    .select("id,name,role,email,phone,status,auth_user_id,created_at")
    .order("created_at");

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  const staff = (data ?? []).map((r: Record<string, unknown>) => ({
    id: r.id,
    name: r.name,
    role: r.role,
    email: r.email,
    phone: r.phone,
    status: r.status,
    authUserId: r.auth_user_id,
    createdAt: r.created_at,
  }));

  return NextResponse.json({ staff });
}

export async function POST(request: NextRequest) {
  const caller = await getCurrentStaff();
  if (!caller) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  if (caller.role !== "owner") return NextResponse.json({ error: "Forbidden" }, { status: 403 });

  let body: { name?: string; role?: string; email?: string; phone?: string; password?: string };
  try { body = await request.json(); } catch { return NextResponse.json({ error: "Invalid JSON" }, { status: 400 }); }

  const { name, role, email, phone, password } = body;
  if (!name || !email || !password) return NextResponse.json({ error: "name, email, and password are required" }, { status: 400 });
  if (!phone) return NextResponse.json({ error: "phone is required for WhatsApp notifications" }, { status: 400 });
  if (!CREATABLE_ROLES.includes(role as StaffRole)) {
    return NextResponse.json(
      { error: `Role must be one of: ${CREATABLE_ROLES.join(", ")}` },
      { status: 400 },
    );
  }

  const admin = createAdminClient();

  const { data: created, error: authErr } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });

  if (authErr || !created?.user) {
    const msg = authErr?.message ?? "";
    if (msg.toLowerCase().includes("already") || (authErr as { status?: number })?.status === 422) {
      return NextResponse.json({ error: "A user with this email already exists" }, { status: 409 });
    }
    return NextResponse.json({ error: msg || "Failed to create auth user" }, { status: 500 });
  }

  const { data: row, error: insertErr } = await admin
    .from("staff")
    .insert({ name, role, email, phone: phone || null, auth_user_id: created.user.id, status: "active" })
    .select("id,name,role,email,phone,status,auth_user_id,created_at")
    .single();

  if (insertErr || !row) {
    await admin.auth.admin.deleteUser(created.user.id);
    return NextResponse.json({ error: insertErr?.message ?? "Failed to create staff" }, { status: 500 });
  }

  const r = row as Record<string, unknown>;
  if (isBookableRole(role as StaffRole)) {
    const { error: availabilityErr } = await admin
      .from("barber_availability")
      .insert(defaultAvailabilityForBarber(String(r.id)));

    if (availabilityErr) {
      await admin.from("staff").delete().eq("id", r.id);
      await admin.auth.admin.deleteUser(created.user.id);
      return NextResponse.json(
        { error: availabilityErr.message },
        { status: 500 },
      );
    }
  }

  return NextResponse.json({
    staff: { id: r.id, name: r.name, role: r.role, email: r.email, phone: r.phone, status: r.status, authUserId: r.auth_user_id, createdAt: r.created_at }
  }, { status: 201 });
}
