"use client";

import { useEffect, useState, useCallback } from "react";
import { fetchDashboardStats, type DashboardStats } from "@/lib/api/dashboard";
import { KpiCard } from "./KpiCard";
import { BarberTable } from "./BarberTable";
import { TopServices } from "./TopServices";
import { ChannelMix } from "./ChannelMix";

type Tab = "today" | "week" | "month";

export function DashboardBoard() {
  const [data, setData] = useState<DashboardStats | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [tab, setTab] = useState<Tab>("week");

  const load = useCallback(async () => {
    try {
      const stats = await fetchDashboardStats();
      setData(stats);
      setError(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load dashboard.");
    }
  }, []);

  useEffect(() => {
    load();
    const id = setInterval(load, 60_000);
    return () => clearInterval(id);
  }, [load]);

  if (error) {
    return (
      <div className="rounded-xl bg-[var(--late-bg)] border border-[var(--late)] p-4 text-sm text-[var(--late)]">
        {error}
      </div>
    );
  }

  if (!data) {
    return (
      <div className="text-sm text-zinc-400 animate-pulse">Loading dashboard…</div>
    );
  }

  const nvr = data.kpis.newVsReturning[tab];
  const totalVisits = nvr.new + nvr.returning;

  const tabLabels: { key: Tab; label: string }[] = [
    { key: "today", label: "Today" },
    { key: "week", label: "This week" },
    { key: "month", label: "This month" },
  ];

  return (
    <div className="space-y-6">
      {/* ── KPI cards ─────────────────────────────────────────────── */}
      <div>
        {/* Tab switcher for new vs returning */}
        <div className="flex gap-1 mb-3">
          {tabLabels.map(({ key, label }) => (
            <button
              key={key}
              type="button"
              onClick={() => setTab(key)}
              className={`text-xs px-3 py-1 rounded-full font-medium transition-colors ${
                tab === key
                  ? "bg-[var(--navy)] text-white"
                  : "bg-zinc-100 text-zinc-500 hover:bg-zinc-200"
              }`}
            >
              {label}
            </button>
          ))}
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <KpiCard
            title="Total visits"
            value={totalVisits}
            subtitle={`${nvr.new} new · ${nvr.returning} returning`}
          />
          <KpiCard
            title={tab === "today" ? "Revenue today" : "Revenue this week"}
            value={`KES ${(tab === "today" ? data.kpis.revenue.today : data.kpis.revenue.week).toLocaleString()}`}
            accent="brass"
          />
          <KpiCard
            title="At-risk clients"
            value={data.kpis.atRiskClients}
            subtitle="Inactive 21+ days, no upcoming booking"
            accent={data.kpis.atRiskClients > 0 ? "warning" : "default"}
          />
        </div>
      </div>

      {/* ── Below fold ────────────────────────────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Per-barber table */}
        <div className="bg-white rounded-xl shadow-sm p-5">
          <h2 className="text-xs font-medium uppercase tracking-wide text-zinc-400 mb-4">
            Barbers this week
          </h2>
          <BarberTable rows={data.week.perBarber} />
        </div>

        {/* Top services */}
        <div className="bg-white rounded-xl shadow-sm p-5">
          <h2 className="text-xs font-medium uppercase tracking-wide text-zinc-400 mb-4">
            Top services this week
          </h2>
          <TopServices services={data.week.topServices} />
        </div>

        {/* Channel mix */}
        <div className="bg-white rounded-xl shadow-sm p-5">
          <h2 className="text-xs font-medium uppercase tracking-wide text-zinc-400 mb-4">
            Channel mix this week
          </h2>
          <ChannelMix channels={data.week.channelMix} />
        </div>

        {/* No-show rate */}
        <div className="bg-white rounded-xl shadow-sm p-5">
          <h2 className="text-xs font-medium uppercase tracking-wide text-zinc-400 mb-4">
            No-show rate this week
          </h2>
          <div className="flex items-end gap-3">
            <span
              className={`text-4xl font-bold leading-none ${
                data.week.noShowRate > 0.15
                  ? "text-[var(--late)]"
                  : "text-[var(--free)]"
              }`}
            >
              {Math.round(data.week.noShowRate * 100)}%
            </span>
            <span className="text-sm text-zinc-400 mb-1">of terminal bookings</span>
          </div>
          <div className="mt-3 h-2 rounded-full bg-zinc-100">
            <div
              className={`h-2 rounded-full transition-all ${
                data.week.noShowRate > 0.15 ? "bg-[var(--late)]" : "bg-[var(--free)]"
              }`}
              style={{ width: `${Math.min(100, Math.round(data.week.noShowRate * 100))}%` }}
            />
          </div>
        </div>
      </div>

      <p className="text-xs text-zinc-300 text-right">Auto-refreshes every 60 s</p>
    </div>
  );
}
