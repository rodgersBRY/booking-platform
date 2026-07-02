// One-off: repoint demo-day bookings to the real test client and give barbers phones.
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { createRequire } from "node:module";

const root = dirname(fileURLToPath(import.meta.url));
const require = createRequire(join(root, "../web/package.json"));
const { createClient } = require("@supabase/supabase-js");

const env = Object.fromEntries(
  readFileSync(join(root, "../web/.env.local"), "utf8")
    .split("\n")
    .filter((l) => l.includes("=") && !l.trim().startsWith("#"))
    .map((l) => [l.slice(0, l.indexOf("=")).trim(), l.slice(l.indexOf("=") + 1).trim()]),
);
const db = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, { auth: { persistSession: false } });

const PLACEHOLDER = "ca485556-7d8c-498d-8d14-4ae0480735cb"; // +254712345678 seed client
const REAL = "d5752f34-1439-4c70-8c1c-1ce78d6b1918"; // Brian Mawira 254712413243
const TEST_PHONE = "254712413243";

// 1. Repoint placeholder's bookings + visits to the real client
const { data: moved } = await db.from("bookings").update({ client_id: REAL }).eq("client_id", PLACEHOLDER).select("id");
await db.from("visits").update({ client_id: REAL }).eq("client_id", PLACEHOLDER);
console.log(`Repointed ${moved?.length ?? 0} bookings to real test client`);

// 2. Delete the placeholder client
const { error: delErr } = await db.from("clients").delete().eq("id", PLACEHOLDER);
console.log(delErr ? `Delete failed: ${delErr.message}` : "Placeholder client deleted");

// 3. Barber phones (needed by /bookings/upcoming which drops phoneless barbers).
// All point to the test phone so demo alerts land on one device.
const { data: barbers } = await db.from("staff").select("id, name, phone").eq("role", "barber");
for (const b of barbers) {
  if (!b.phone) {
    await db.from("staff").update({ phone: TEST_PHONE }).eq("id", b.id);
    console.log(`Set phone for ${b.name}`);
  }
}

// 4. Owner phone for the daily digest
const { data: owner } = await db.from("staff").select("id, phone").eq("role", "owner").maybeSingle();
if (owner && !owner.phone) {
  await db.from("staff").update({ phone: TEST_PHONE }).eq("id", owner.id);
  console.log("Set owner phone");
}
console.log("DONE");
