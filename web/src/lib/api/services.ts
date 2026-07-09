export type BookableRole = "barber" | "beautician" | "masseuse";

export interface ServiceItem {
  id: string;
  name: string;
  category: string | null;
  description: string | null;
  durationMinutes: number;
  price: number;
  active: boolean;
  roles: BookableRole[];
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

/** Owner view: every service, including inactive ones. */
export async function fetchAllServices(): Promise<ServiceItem[]> {
  const data = await apiFetch<{ services: ServiceItem[] }>("/api/services?all=1");
  return data.services;
}

export async function createService(p: {
  name: string;
  category?: string;
  durationMinutes: number;
  price: number;
  description?: string;
  roles?: BookableRole[];
}): Promise<ServiceItem> {
  const data = await apiFetch<{ service: ServiceItem }>("/api/services", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(p),
  });
  return data.service;
}

export async function updateService(
  id: string,
  patch: Partial<{
    name: string;
    durationMinutes: number;
    price: number;
    category: string | null;
    description: string | null;
    active: boolean;
    roles: BookableRole[];
  }>,
): Promise<ServiceItem> {
  const data = await apiFetch<{ service: ServiceItem }>(`/api/services/${id}`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(patch),
  });
  return data.service;
}
