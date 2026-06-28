// Typed fetch helpers for the receptionist console.
// All functions are called from client components.
// TODO: swap polling for Supabase realtime

import type { ChairStatus, QueueItem, BoardStats } from "@/lib/booking/types";

export interface BoardData {
  chairs: ChairStatus[];
  queue: QueueItem[];
  stats: BoardStats;
}

export interface Barber {
  id: string;
  name: string;
}

export interface Service {
  id: string;
  name: string;
  durationMinutes: number;
  price: number;
}

export interface WalkinPayload {
  name: string;
  phone: string;
  preferredBarberId?: string;
  serviceId: string;
  acquisitionSource?: string;
}

export type WalkinResult =
  | { seated: true; booking: unknown }
  | { seated: false; queueEntry: unknown };

async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(path, init);
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    const err = new Error(
      (body as { error?: string }).error ?? `HTTP ${res.status}`
    );
    (err as Error & { status: number }).status = res.status;
    throw err;
  }
  return res.json() as Promise<T>;
}

export async function fetchBoard(): Promise<BoardData> {
  return apiFetch<BoardData>("/api/board");
}

export async function fetchBarbers(): Promise<Barber[]> {
  const data = await apiFetch<{ barbers: Barber[] }>("/api/barbers");
  return data.barbers;
}

export async function fetchServices(): Promise<Service[]> {
  const data = await apiFetch<{ services: Service[] }>("/api/services");
  return data.services;
}

export async function seatQueueItem(id: string): Promise<void> {
  await apiFetch(`/api/queue/${id}/seat`, { method: "POST" });
}

export async function notifyQueueItem(id: string): Promise<void> {
  await apiFetch(`/api/queue/${id}/notify`, { method: "POST" });
}

export async function completeBooking(bookingId: string): Promise<void> {
  await apiFetch(`/api/bookings/${bookingId}/complete`, { method: "POST" });
}

export async function addWalkin(payload: WalkinPayload): Promise<WalkinResult> {
  return apiFetch<WalkinResult>("/api/walkins", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
}
