// One-off demo data seeder. Run: node demo/seed-demo-data.mjs
// Reads web/.env.local for Supabase credentials. Safe to re-run (skips if demo clients exist).
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

// EDIT THIS: the WhatsApp number that receives demo messages (E.164, no +)
const TEST_PHONE = process.env.TEST_PHONE || "+254712345678";

const db = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

const rand = (arr) => arr[Math.floor(Math.random() * arr.length)];
const day = 24 * 60 * 60 * 1000;

const FIRST = ["Brian","Kevin","Aisha","Josphat","Wanjiku","Otieno","Fatuma","Mwangi","Njeri","Kiptoo","Achieng","Baraka","Zawadi","Juma","Wafula","Nyambura","Omar","Chebet","Kamau","Halima","Sifa","Mutua"];
const LAST = ["Mwirigi","Odhiambo","Kariuki","Hassan","Kimani","Auma","Njoroge","Barasa","Cherono","Abdi","Wekesa","Moraa"];
const SOURCES = ["social","website","referral","walkby","whatsapp","other"];
const CHANNELS = ["walkin","walkin","walkin","online","whatsapp","phone"]; // walk-in weighted
const PAY = ["cash","mpesa","mpesa","mpesa","card"]; // mpesa weighted

async function main() {
  const { data: existing } = await db.from("clients").select("id").eq("phone", TEST_PHONE).maybeSingle();
  if (existing) {
    console.log("Demo data already seeded (test phone exists). Aborting.");
    return;
  }

  const { data: barbers } = await db.from("staff").select("id, name").eq("role", "barber");
  const { data: services } = await db.from("services").select("id, name, duration_minutes, price").eq("active", true);
  if (!barbers?.length || !services?.length) throw new Error("Run migrations/seed first: no barbers or services.");

  // ── clients ──────────────────────────────────────────────────────────────
  const clientRows = [];
  for (let i = 0; i < 22; i++) {
    clientRows.push({
      name: `${rand(FIRST)} ${rand(LAST)}`,
      phone: `+2547${String(10000000 + Math.floor(Math.random() * 89999999))}`,
      acquisition_source: rand(SOURCES),
      preferred_barber_id: Math.random() < 0.6 ? rand(barbers).id : null,
    });
  }
  // Test client (receives real WhatsApp messages)
  clientRows.push({ name: "Brian Mawira", phone: TEST_PHONE, acquisition_source: "referral", preferred_barber_id: barbers[0].id });

  const { data: clients, error: cErr } = await db.from("clients").insert(clientRows).select("id, name, phone");
  if (cErr) throw cErr;
  const testClient = clients.find((c) => c.phone === TEST_PHONE);
  console.log(`Inserted ${clients.length} clients (test client: ${testClient.id})`);

  // Include the 3 pre-seeded clients in the visit pool
  const { data: allClients } = await db.from("clients").select("id");

  // ── historical bookings + visits over the past 28 days ──────────────────
  // Regular: first client gets 6 visits; 2 quiet clients get one old visit each; rest random.
  const bookings = [];
  const now = Date.now();
  const mkSlot = (daysAgo, svc) => {
    const d = new Date(now - daysAgo * day);
    d.setUTCHours(6 + Math.floor(Math.random() * 10), rand([0, 15, 30, 45]), 0, 0); // 9am–7pm EAT
    return { start: d, end: new Date(d.getTime() + svc.duration_minutes * 60000) };
  };
  const pushBooking = (clientId, daysAgo, status) => {
    const svc = rand(services);
    const barber = rand(barbers);
    const { start, end } = mkSlot(daysAgo, svc);
    bookings.push({
      client_id: clientId, barber_id: barber.id, service_id: svc.id,
      scheduled_start: start.toISOString(), scheduled_end: end.toISOString(),
      channel: rand(CHANNELS), status,
      _svc: svc, _completed: status === "completed",
    });
  };

  const regular = allClients[0].id;
  for (let i = 0; i < 6; i++) pushBooking(regular, 2 + i * 4, "completed");
  const quiet1 = allClients[1].id, quiet2 = allClients[2].id;
  pushBooking(quiet1, 25, "completed");
  pushBooking(quiet2, 27, "completed");
  const pool = allClients.slice(3).map((c) => c.id);
  for (let i = 0; i < 52; i++) pushBooking(rand(pool), 1 + Math.floor(Math.random() * 21), "completed");
  for (let i = 0; i < 5; i++) pushBooking(rand(pool), 1 + Math.floor(Math.random() * 21), "no_show");
  for (let i = 0; i < 3; i++) pushBooking(rand(pool), 1 + Math.floor(Math.random() * 21), "late");
  for (let i = 0; i < 3; i++) pushBooking(rand(pool), 1 + Math.floor(Math.random() * 21), "cancelled");

  const { data: insertedBookings, error: bErr } = await db
    .from("bookings")
    .insert(bookings.map(({ _svc, _completed, ...b }) => b))
    .select("id, client_id, barber_id, service_id, scheduled_end, status");
  if (bErr) throw bErr;
  console.log(`Inserted ${insertedBookings.length} bookings`);

  // ── visits for completed bookings ────────────────────────────────────────
  const priceOf = Object.fromEntries(services.map((s) => [s.id, Number(s.price)]));
  const visitRows = insertedBookings
    .filter((b) => b.status === "completed")
    .map((b) => ({
      booking_id: b.id, client_id: b.client_id, barber_id: b.barber_id, service_id: b.service_id,
      completed_at: b.scheduled_end, amount_charged: priceOf[b.service_id] ?? 500,
      payment_method: rand(PAY), loyalty_points_earned: 10,
    }));
  const { error: vErr } = await db.from("visits").insert(visitRows);
  if (vErr) throw vErr;
  console.log(`Inserted ${visitRows.length} visits`);

  // ── denormalized client stats ────────────────────────────────────────────
  for (const c of allClients) {
    const mine = visitRows.filter((v) => v.client_id === c.id);
    if (!mine.length) continue;
    const last = mine.map((v) => v.completed_at).sort().at(-1);
    await db.from("clients").update({ total_visits: mine.length, last_visit_at: last }).eq("id", c.id);
  }
  console.log("Updated client stats");

  // ── demo-day rows for the test client ────────────────────────────────────
  const svc = services[0];
  const barber = barbers[0];
  // 1) booking ~20h out → 24h-reminder candidate (won't fire until within 23–25h... use 24h)
  const remStart = new Date(now + 24 * 3600000);
  remStart.setUTCMinutes(0, 0, 0);
  const { error: rbErr } = await db.from("bookings").insert({
    client_id: testClient.id, barber_id: barber.id, service_id: svc.id,
    scheduled_start: remStart.toISOString(),
    scheduled_end: new Date(remStart.getTime() + svc.duration_minutes * 60000).toISOString(),
    channel: "whatsapp", status: "booked",
  });
  if (rbErr) throw rbErr;
  // 2) completed booking today → review-request candidate
  const doneStart = new Date(now - 2 * 3600000);
  const { data: doneBooking, error: dbErr } = await db.from("bookings").insert({
    client_id: testClient.id, barber_id: barbers[1]?.id ?? barber.id, service_id: svc.id,
    scheduled_start: doneStart.toISOString(),
    scheduled_end: new Date(doneStart.getTime() + svc.duration_minutes * 60000).toISOString(),
    channel: "walkin", status: "completed",
  }).select("id").single();
  if (dbErr) throw dbErr;
  await db.from("visits").insert({
    booking_id: doneBooking.id, client_id: testClient.id, barber_id: barbers[1]?.id ?? barber.id,
    service_id: svc.id, completed_at: new Date(now - 3600000).toISOString(),
    amount_charged: Number(svc.price), payment_method: "mpesa", loyalty_points_earned: 10,
  });
  await db.from("clients").update({ total_visits: 1, last_visit_at: new Date(now - 3600000).toISOString() }).eq("id", testClient.id);
  console.log("Inserted demo-day reminder + review-request candidates for test client");
  console.log("DONE");
}

main().catch((e) => { console.error(e); process.exit(1); });
