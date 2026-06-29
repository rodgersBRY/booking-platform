import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const caller = await getCurrentStaff();
  if (!caller) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  if (caller.role !== "owner") return NextResponse.json({ error: "Forbidden" }, { status: 403 });

  const { id } = await params;
  let body: { action?: string; status?: string; password?: string };
  try { body = await request.json(); } catch { return NextResponse.json({ error: "Invalid JSON" }, { status: 400 }); }

  const admin = createAdminClient();

  const { data: target, error: fetchErr } = await admin
    .from("staff")
    .select("id,role,auth_user_id,status")
    .eq("id", id)
    .single();

  if (fetchErr || !target) return NextResponse.json({ error: "Staff not found" }, { status: 404 });

  const t = target as Record<string, unknown>;

  if (body.action === "setStatus") {
    if (t.role === "owner") return NextResponse.json({ error: "Cannot change owner status" }, { status: 400 });
    if (id === caller.id) return NextResponse.json({ error: "Cannot deactivate yourself" }, { status: 400 });

    const { data: updated, error: updateErr } = await admin
      .from("staff")
      .update({ status: body.status })
      .eq("id", id)
      .select("id,name,role,email,phone,status,auth_user_id,created_at")
      .single();

    if (updateErr) return NextResponse.json({ error: updateErr.message }, { status: 500 });
    const r = updated as Record<string, unknown>;
    return NextResponse.json({ staff: { id: r.id, name: r.name, role: r.role, email: r.email, phone: r.phone, status: r.status, authUserId: r.auth_user_id, createdAt: r.created_at } });
  }

  if (body.action === "resetPassword") {
    if (!t.auth_user_id) return NextResponse.json({ error: "No auth account linked to this staff member" }, { status: 409 });
    if (!body.password) return NextResponse.json({ error: "password is required" }, { status: 400 });

    const { error: pwErr } = await admin.auth.admin.updateUser(t.auth_user_id as string, { password: body.password });
    if (pwErr) return NextResponse.json({ error: pwErr.message }, { status: 500 });
    return NextResponse.json({ ok: true });
  }

  return NextResponse.json({ error: "Unknown action" }, { status: 400 });
}
