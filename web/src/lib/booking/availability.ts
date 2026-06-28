import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";
import type { Slot } from "@/lib/booking/types";

const TZ = "Africa/Nairobi";

/** Parse a "YYYY-MM-DD" string and return the EAT weekday (0=Sun … 6=Sat). */
function eatWeekday(date: string): number {
  // Build a Date at midnight EAT for the given date string.
  const [year, month, day] = date.split("-").map(Number);
  // Use Intl to determine the local weekday in EAT.
  const d = new Date(Date.UTC(year, month - 1, day, 0, 0, 0));
  // Get the weekday in EAT (getDay() is UTC; we must use Intl).
  const formatter = new Intl.DateTimeFormat("en-US", {
    timeZone: TZ,
    weekday: "short",
  });
  const parts = formatter.formatToParts(d);
  const weekdayStr = parts.find((p) => p.type === "weekday")?.value ?? "Sun";
  const map: Record<string, number> = {
    Sun: 0,
    Mon: 1,
    Tue: 2,
    Wed: 3,
    Thu: 4,
    Fri: 5,
    Sat: 6,
  };
  return map[weekdayStr] ?? 0;
}

/** Convert "HH:MM" time-of-day + a YYYY-MM-DD date string → UTC Date (interpreting the time as EAT). */
function eatTimeToUtc(date: string, time: string): Date {
  const [year, month, day] = date.split("-").map(Number);
  const [hour, minute] = time.split(":").map(Number);
  // Build the ISO string for that moment in EAT (UTC+3).
  const eatIso = `${String(year).padStart(4, "0")}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}T${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}:00+03:00`;
  return new Date(eatIso);
}

/** Format a UTC Date as a local EAT time label like "1:00 PM". */
function toLabel(d: Date): string {
  return d.toLocaleTimeString("en-US", {
    timeZone: TZ,
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  });
}

/** Format a UTC Date as an ISO string with EAT offset ("+03:00"). */
function toEatIso(d: Date): string {
  // Shift to EAT then format manually to preserve the +03:00 offset.
  const eat = new Date(d.getTime() + 3 * 60 * 60 * 1000);
  const y = eat.getUTCFullYear();
  const mo = String(eat.getUTCMonth() + 1).padStart(2, "0");
  const dy = String(eat.getUTCDate()).padStart(2, "0");
  const hr = String(eat.getUTCHours()).padStart(2, "0");
  const mn = String(eat.getUTCMinutes()).padStart(2, "0");
  const sc = String(eat.getUTCSeconds()).padStart(2, "0");
  return `${y}-${mo}-${dy}T${hr}:${mn}:${sc}+03:00`;
}

interface GetAvailabilityParams {
  barberId: string | "any";
  serviceId: string;
  date: string; // YYYY-MM-DD
}

/**
 * Returns available 15-minute-grid slots for a given barber (or "any") on a date.
 *
 * Rules:
 *  - Working window from barber_availability for that EAT weekday.
 *  - Subtract barber_time_off blocks.
 *  - Subtract bookings with status in (booked, arrived, in_chair).
 *  - 15-min start grid, slot length = service.duration_minutes, no buffer.
 *  - For today: drop slots starting before now + 30 min (EAT lead time).
 *  - "any": compute per active barber; return a slot if ANY barber is free;
 *    include the chosen barberId on each returned slot.
 */
export async function getAvailability({
  barberId,
  serviceId,
  date,
}: GetAvailabilityParams): Promise<Slot[]> {
  const admin = createAdminClient();

  // Fetch service duration.
  const { data: service, error: svcErr } = await admin
    .from("services")
    .select("id, duration_minutes")
    .eq("id", serviceId)
    .eq("active", true)
    .single();
  if (svcErr || !service) return [];

  const duration = service.duration_minutes as number;
  const weekday = eatWeekday(date);

  // Resolve barber list.
  let barberIds: string[];
  if (barberId === "any") {
    const { data: barbers, error: bErr } = await admin
      .from("staff")
      .select("id")
      .eq("role", "barber")
      .eq("status", "active");
    if (bErr || !barbers) return [];
    barberIds = barbers.map((b: { id: string }) => b.id);
  } else {
    barberIds = [barberId];
  }

  // Day boundaries in UTC for DB queries (EAT date = UTC date + offsets).
  const dayStartUtc = eatTimeToUtc(date, "00:00");
  const dayEndUtc = eatTimeToUtc(date, "23:59");

  // Now in UTC (for lead-time check).
  const nowUtc = new Date();
  const leadCutoff = new Date(nowUtc.getTime() + 30 * 60 * 1000);

  // Is this date today (in EAT)?
  const todayEat = new Date(nowUtc.toLocaleString("en-US", { timeZone: TZ }));
  const todayStr = `${todayEat.getFullYear()}-${String(todayEat.getMonth() + 1).padStart(2, "0")}-${String(todayEat.getDate()).padStart(2, "0")}`;
  const isToday = date === todayStr;

  // Collect slots across all candidate barbers, deduplicated by start time if "any".
  const slotMap = new Map<string, Slot>(); // key = ISO start

  for (const bid of barberIds) {
    // 1. Get availability window for this barber+weekday.
    const { data: avails } = await admin
      .from("barber_availability")
      .select("start_time, end_time")
      .eq("barber_id", bid)
      .eq("weekday", weekday);
    if (!avails || avails.length === 0) continue;

    // There may be multiple rows (split shifts) but typically one.
    for (const avail of avails) {
      const windowStart = eatTimeToUtc(
        date,
        (avail.start_time as string).slice(0, 5),
      );
      const windowEnd = eatTimeToUtc(
        date,
        (avail.end_time as string).slice(0, 5),
      );

      // 2. Get time-off blocks for this barber that overlap the day.
      const { data: timeOffs } = await admin
        .from("barber_time_off")
        .select("start_at, end_at")
        .eq("barber_id", bid)
        .lt("start_at", dayEndUtc.toISOString())
        .gt("end_at", dayStartUtc.toISOString());

      const offBlocks: Array<{ start: Date; end: Date }> = (timeOffs ?? []).map(
        (t: { start_at: string; end_at: string }) => ({
          start: new Date(t.start_at),
          end: new Date(t.end_at),
        }),
      );

      // 3. Get active bookings for this barber on this day.
      const { data: bookings } = await admin
        .from("bookings")
        .select("scheduled_start, scheduled_end")
        .eq("barber_id", bid)
        .in("status", ["booked", "arrived", "in_chair"])
        .lt("scheduled_start", dayEndUtc.toISOString())
        .gt("scheduled_end", dayStartUtc.toISOString());

      const bookedBlocks: Array<{ start: Date; end: Date }> = (
        bookings ?? []
      ).map((b: { scheduled_start: string; scheduled_end: string }) => ({
        start: new Date(b.scheduled_start),
        end: new Date(b.scheduled_end),
      }));

      // 4. Walk the 15-min grid.
      let cursor = new Date(windowStart.getTime());
      while (cursor.getTime() + duration * 60 * 1000 <= windowEnd.getTime()) {
        const slotEnd = new Date(cursor.getTime() + duration * 60 * 1000);

        // Lead-time filter for today.
        if (isToday && cursor < leadCutoff) {
          cursor = new Date(cursor.getTime() + 15 * 60 * 1000);
          continue;
        }

        // Check time-off overlap.
        const blockedByOff = offBlocks.some(
          (b) => cursor < b.end && slotEnd > b.start,
        );
        if (!blockedByOff) {
          // Check booking overlap.
          const blockedByBooking = bookedBlocks.some(
            (b) => cursor < b.end && slotEnd > b.start,
          );
          if (!blockedByBooking) {
            const isoStart = toEatIso(cursor);
            // For "any": only add if not already added (keep first barber that's free).
            if (!slotMap.has(isoStart)) {
              slotMap.set(isoStart, {
                start: isoStart,
                end: toEatIso(slotEnd),
                label: toLabel(cursor),
                barberId: bid,
              });
            }
          }
        }

        cursor = new Date(cursor.getTime() + 15 * 60 * 1000);
      }
    }
  }

  // Return sorted by start time.
  return Array.from(slotMap.values()).sort((a, b) =>
    a.start.localeCompare(b.start),
  );
}
