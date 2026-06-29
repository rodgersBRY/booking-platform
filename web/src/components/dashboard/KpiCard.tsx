"use client";

interface KpiCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  accent?: "default" | "warning" | "brass";
}

export function KpiCard({ title, value, subtitle, accent = "default" }: KpiCardProps) {
  const valueColor =
    accent === "warning"
      ? "text-[var(--late)]"
      : accent === "brass"
      ? "text-[var(--brass)]"
      : "text-[var(--navy)]";

  return (
    <div className="bg-white rounded-xl shadow-sm p-5 flex flex-col gap-1">
      <p className="text-xs font-medium uppercase tracking-wide text-zinc-400">{title}</p>
      <p className={`text-3xl font-bold leading-none ${valueColor}`}>{value}</p>
      {subtitle && <p className="text-sm text-zinc-500 mt-1">{subtitle}</p>}
    </div>
  );
}
