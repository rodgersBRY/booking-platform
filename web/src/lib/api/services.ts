export interface ServiceItem {
  id: string;
  name: string;
  description: string | null;
  durationMinutes: number;
  price: number;
  active: boolean;
}

async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(path, init);
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    const err = new Error((body as { error?: string }).error ?? `HTTP ${res.status}`);
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
  durationMinutes: number;
  price: number;
  description?: string;
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
    description: string | null;
    active: boolean;
  }>,
): Promise<ServiceItem> {
  const data = await apiFetch<{ service: ServiceItem }>(`/api/services/${id}`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(patch),
  });
  return data.service;
}
