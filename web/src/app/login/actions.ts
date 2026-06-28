"use server";

import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { getCurrentStaff, roleHome } from "@/lib/auth";

export async function signIn(
  _prevState: string | null,
  formData: FormData,
): Promise<string | null> {
  const email = formData.get("email") as string;
  const password = formData.get("password") as string;

  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    return "That email or password didn't match. Check your details and try again.";
  }

  // Fetch the staff row to determine where to send the user.
  const staff = await getCurrentStaff();
  if (!staff) {
    // Signed in to Supabase Auth but no matching staff row — sign out and report.
    await supabase.auth.signOut();
    return "Your account isn't set up yet. Ask your owner to link your staff record.";
  }

  redirect(roleHome(staff.role));
}

export async function signOut(): Promise<never> {
  const supabase = await createSupabaseServerClient();
  await supabase.auth.signOut();
  redirect("/login");
}
