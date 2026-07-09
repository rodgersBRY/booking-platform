import { createAdminClient } from "@/lib/supabase/admin";
import { NextResponse } from "next/server";

export async function GET() {
  const admin = createAdminClient();
  const { data, error } = await admin
    .from("services")
    .select("id, name, category, duration_minutes, price")
    .eq("active", true)
    .order("category")
    .order("name");

  if (error) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  const services = (data ?? []).map(
    (s: {
      id: string;
      name: string;
      category: string | null;
      duration_minutes: number;
      price: number;
    }) => ({
      id: s.id,
      name: s.name,
      category: s.category,
      durationMinutes: s.duration_minutes,
      price: s.price,
    }),
  );

  return NextResponse.json({ services });
}
