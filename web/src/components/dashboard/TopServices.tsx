"use client";

interface ServiceRow {
  serviceId: string;
  serviceName: string;
  count: number;
}

interface TopServicesProps {
  services: ServiceRow[];
}

export function TopServices({ services }: TopServicesProps) {
  if (services.length === 0) {
    return <p className="text-sm text-zinc-400">No data yet this week.</p>;
  }

  const max = services[0].count;

  return (
    <ol className="space-y-3">
      {services.map((s, i) => {
        const pct = max > 0 ? Math.round((s.count / max) * 100) : 0;
        return (
          <li key={s.serviceId} className="flex items-center gap-3">
            <span className="text-xs font-bold text-zinc-300 w-4 shrink-0">{i + 1}</span>
            <div className="flex-1 min-w-0">
              <div className="flex justify-between items-baseline mb-1">
                <span className="text-sm font-medium text-[var(--navy)] truncate">{s.serviceName}</span>
                <span className="text-sm text-zinc-500 ml-2 shrink-0">{s.count}</span>
              </div>
              <div className="h-1.5 rounded-full bg-zinc-100">
                <div
                  className="h-1.5 rounded-full bg-[var(--brass)]"
                  style={{ width: `${pct}%` }}
                />
              </div>
            </div>
          </li>
        );
      })}
    </ol>
  );
}
