import { createClient } from "@supabase/supabase-js";
import { createAdminClient } from "@/lib/supabase/admin";
import { shapeStaff, type StaffWithAuthId } from "@/lib/staffAuth";
import { isBookableRole } from "@/lib/staff/roles";
import { NextRequest, NextResponse } from "next/server";

// Staff-facing login for the mobile app (barbers, beauticians, masseuses
// only). Returns a Supabase access token the app stores and sends back as
// `Authorization: Bearer <token>` on future requests — there's no cookie jar
// on mobile, so this can't use the cookie-based session pattern lib/auth.ts
// uses for the web console. Owners and receptionists authenticate via the
// web console only and never get a mobile session from this endpoint.
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
  const { data: staffRow, error: staffErr } = await admin
    .from("staff")
    .select("*")
    .eq("auth_user_id", data.user.id)
    .maybeSingle();

  if (staffErr) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }
  if (!staffRow) {
    return NextResponse.json(
      {
        error: "no_staff_account",
        message: "This login isn't linked to a staff account yet.",
      },
      { status: 403 },
    );
  }

  const staff = staffRow as StaffWithAuthId;
  if (staff.status !== "active") {
    return NextResponse.json(
      { error: "account_inactive", message: "This account is not active." },
      { status: 403 },
    );
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

  return NextResponse.json({
    token: data.session.access_token,
    staff: shapeStaff(staff),
  });
}
