"use client";
import { createBrowserClient } from "@supabase/ssr";

/**
 * Browser Supabase client (client components). Uses the anon key and is subject
 * to RLS. Handy for realtime subscriptions (e.g. the live queue board).
 */
export function createSupabaseBrowserClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
