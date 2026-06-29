// Typed fetch helper for the owner dashboard.

export interface NewVsReturningBucket {
  new: number;
  returning: number;
}

export interface DashboardStats {
  kpis: {
    newVsReturning: {
      today: NewVsReturningBucket;
      week: NewVsReturningBucket;
      month: NewVsReturningBucket;
    };
    revenue: { today: number; week: number };
    atRiskClients: number;
  };
  week: {
    perBarber: { barberId: string; barberName: string; visits: number; revenue: number }[];
    topServices: { serviceId: string; serviceName: string; count: number }[];
    channelMix: { channel: string; count: number }[];
    noShowRate: number;
  };
}

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

export async function fetchDashboardStats(): Promise<DashboardStats> {
  return apiFetch<DashboardStats>("/api/dashboard/stats");
}
