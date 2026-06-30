import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";

export async function seedOwner(): Promise<void> {
  const email = process.env.OWNER_EMAIL;
  const password = process.env.OWNER_PASSWORD;
  const name = process.env.OWNER_NAME ?? "Owner";

  if (!email || !password) return;

  const admin = createAdminClient();

  // Check if an owner staff row already has an auth user linked.
  const { data: existing } = await admin
    .from("staff")
    .select("id, auth_user_id")
    .eq("email", email)
    .eq("role", "owner")
    .maybeSingle();

  if (existing?.auth_user_id) {
    // Already provisioned — nothing to do.
    return;
  }

  // Create the Supabase Auth user (idempotent: catch duplicate error).
  const { data: created, error: createError } =
    await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });

  let authUserId: string;

  if (createError) {
    if (!createError.message.toLowerCase().includes("already")) {
      console.error("[owner-seed] Failed to create auth user:", createError.message);
      return;
    }
    // Auth user exists but staff row isn't linked — look up by email.
    const { data: users } = await admin.auth.admin.listUsers();
    const found = users?.users?.find((u) => u.email === email);
    if (!found) {
      console.error("[owner-seed] Auth user not found after duplicate error.");
      return;
    }
    authUserId = found.id;
  } else {
    authUserId = created.user.id;
  }

  if (existing) {
    // Staff row exists — just link the auth user.
    await admin
      .from("staff")
      .update({ auth_user_id: authUserId })
      .eq("id", existing.id);
  } else {
    // No staff row at all — create owner row and link.
    await admin.from("staff").insert({
      name,
      role: "owner",
      email,
      status: "active",
      auth_user_id: authUserId,
    });
  }

  console.log(`[owner-seed] Owner provisioned: ${email}`);
}
