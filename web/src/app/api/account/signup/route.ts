import { createClient } from "@supabase/supabase-js";
import { createAdminClient } from "@/lib/supabase/admin";
import { shapeClient, type ClientWithAuthId } from "@/lib/clientAuth";
import { NextRequest, NextResponse } from "next/server";

// Client self-registration for the mobile app. Finds an existing guest
// client row by phone and links it (preserving their booking/loyalty
// history) instead of creating a duplicate — mirrors the find-or-create
// pattern createBooking() already uses for guest bookings.
export async function POST(request: NextRequest) {
  let body: { name?: string; phone?: string; email?: string; password?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { name, phone, email, password } = body;
  if (!name || !phone || !email || !password) {
    return NextResponse.json(
      { error: "name, phone, email, and password are required" },
      { status: 400 },
    );
  }
  if (password.length < 8) {
    return NextResponse.json(
      { error: "password must be at least 8 characters" },
      { status: 400 },
    );
  }

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    return NextResponse.json({ error: "Server misconfigured" }, { status: 500 });
  }

  const admin = createAdminClient();

  const { data: existing, error: existingErr } = await admin
    .from("clients")
    .select("id, auth_user_id")
    .eq("phone", phone)
    .maybeSingle();

  if (existingErr) {
    return NextResponse.json({ error: existingErr.message }, { status: 500 });
  }
  if (existing?.auth_user_id) {
    return NextResponse.json(
      {
        error: "phone_already_registered",
        message: "This phone number is already linked to an account.",
      },
      { status: 409 },
    );
  }

  // Self-serve signup — anon-key client, not admin, matches the login route.
  const supabase = createClient(url, anonKey, { auth: { persistSession: false } });
  const { data: signUpData, error: signUpErr } = await supabase.auth.signUp({
    email,
    password,
  });

  if (signUpErr || !signUpData.user) {
    const msg = signUpErr?.message ?? "";
    if (msg.toLowerCase().includes("already")) {
      return NextResponse.json(
        {
          error: "email_already_registered",
          message: "An account with this email already exists.",
        },
        { status: 409 },
      );
    }
    return NextResponse.json(
      { error: "signup_failed", message: msg || "Failed to create your account." },
      { status: 500 },
    );
  }

  const authUserId = signUpData.user.id;
  let clientRow: ClientWithAuthId;

  if (existing) {
    const { data: updated, error: updateErr } = await admin
      .from("clients")
      .update({ auth_user_id: authUserId, name, email })
      .eq("id", existing.id)
      .select("*")
      .single();
    if (updateErr || !updated) {
      return NextResponse.json(
        { error: updateErr?.message ?? "Failed to link account" },
        { status: 500 },
      );
    }
    clientRow = updated as ClientWithAuthId;
  } else {
    const { data: inserted, error: insertErr } = await admin
      .from("clients")
      .insert({ name, phone, email, auth_user_id: authUserId, acquisition_source: "website" })
      .select("*")
      .single();
    if (insertErr || !inserted) {
      return NextResponse.json(
        { error: insertErr?.message ?? "Failed to create client" },
        { status: 500 },
      );
    }
    clientRow = inserted as ClientWithAuthId;
  }

  // Depending on the project's email-confirmation setting, signUp() may not
  // return a session yet.
  if (!signUpData.session) {
    return NextResponse.json({
      pendingConfirmation: true,
      message: "Account created — check your email to confirm before signing in.",
    });
  }

  return NextResponse.json(
    { token: signUpData.session.access_token, client: shapeClient(clientRow) },
    { status: 201 },
  );
}
