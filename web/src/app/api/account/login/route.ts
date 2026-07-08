import { createClient } from "@supabase/supabase-js";
import { createAdminClient } from "@/lib/supabase/admin";
import { shapeClient, type ClientWithAuthId } from "@/lib/clientAuth";
import { NextRequest, NextResponse } from "next/server";

// Client-facing login for the mobile app. Returns a Supabase access token the
// app stores and sends back as `Authorization: Bearer <token>` on future
// requests — there's no cookie jar on mobile, so this can't use the
// cookie-based session pattern lib/auth.ts uses for staff.
export async function POST(request: NextRequest) {
  let body: { email?: string; password?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { email, password } = body;
  if (!email || !password) {
    return NextResponse.json(
      { error: "email and password are required" },
      { status: 400 },
    );
  }

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    return NextResponse.json({ error: "Server misconfigured" }, { status: 500 });
  }

  // Stateless client — no cookies to persist, this call only needs the
  // resulting access token.
  const supabase = createClient(url, anonKey, {
    auth: { persistSession: false },
  });
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error || !data.session || !data.user) {
    return NextResponse.json(
      { error: "invalid_credentials", message: "Incorrect email or password." },
      { status: 401 },
    );
  }

  const admin = createAdminClient();
  const { data: clientRow, error: clientErr } = await admin
    .from("clients")
    .select("*")
    .eq("auth_user_id", data.user.id)
    .maybeSingle();

  if (clientErr) {
    return NextResponse.json({ error: clientErr.message }, { status: 500 });
  }
  if (!clientRow) {
    return NextResponse.json(
      {
        error: "no_client_account",
        message: "This login isn't linked to a client account yet.",
      },
      { status: 404 },
    );
  }

  const client = clientRow as ClientWithAuthId;
  if (client.status !== "active") {
    return NextResponse.json(
      { error: "account_inactive", message: "This account is not active." },
      { status: 403 },
    );
  }

  return NextResponse.json({
    token: data.session.access_token,
    client: shapeClient(client),
  });
}
