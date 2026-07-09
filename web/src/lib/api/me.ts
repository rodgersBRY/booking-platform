// Typed fetch helpers for the barber "My Day" view.
// All functions called from client components.

export interface ScheduleItem {
  bookingId: string;
  clientName: string;
  serviceName: string | null;
  scheduledStart: string;
  status: "booked" | "arrived" | "in_chair" | "late";
}

export interface NextClientItem {
  bookingId: string;
  clientName: string;
  serviceName: string | null;
  scheduledStart: string;
  status: "booked" | "arrived";
}

export interface MyDayData {
  barberId: string;
  nextClient: NextClientItem | null;
  schedule: ScheduleItem[];
  queueWaitingCount: number;
}

async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(path, init);
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    const b = body as { error?: string; message?: string };
    const err = new Error(
      b.message ?? b.error ?? "Something went wrong. Please try again.",
    );
    (err as Error & { status: number }).status = res.status;
    throw err;
  }
  return res.json() as Promise<T>;
}

export async function fetchMyDay(): Promise<MyDayData> {
  return apiFetch<MyDayData>("/api/me/day");
}

export async function arriveMyBooking(id: string): Promise<void> {
  await apiFetch(`/api/bookings/${id}/arrive`, { method: "POST" });
}

export async function startMyBooking(id: string): Promise<void> {
  await apiFetch(`/api/bookings/${id}/seat`, { method: "POST" });
}

export async function completeMyBooking(
  id: string,
  amountCharged: number,
  paymentMethod: string
): Promise<void> {
  await apiFetch(`/api/bookings/${id}/complete`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ amountCharged, paymentMethod }),
  });
}
