'use client';

import type { BoardStats } from '@/lib/booking/types';

interface Props {
  stats: BoardStats;
}

interface StatCardProps {
  label: string;
  value: number;
  color: string;
  bg: string;
}

function StatCard({ label, value, color, bg }: StatCardProps) {
  return (
    <div
      className="flex-1 rounded-xl px-5 py-4 flex flex-col gap-1"
      style={{ background: bg, border: `1.5px solid ${color}22` }}
    >
      <span className="text-3xl font-bold tabular-nums" style={{ color }}>
        {Math.round(value)}
      </span>
      <span className="text-sm font-medium" style={{ color: 'var(--navy)' }}>
        {label}
      </span>
    </div>
  );
}

export default function QuickStats({ stats }: Props) {
  return (
    <div className="flex gap-4">
      <StatCard
        label="Waiting"
        value={stats.waiting}
        color="var(--waiting)"
        bg="var(--waiting-bg)"
      />
      <StatCard
        label="Served today"
        value={stats.servedToday}
        color="var(--free)"
        bg="var(--free-bg)"
      />
      <StatCard
        label="No-shows"
        value={stats.noShows}
        color="var(--late)"
        bg="var(--late-bg)"
      />
    </div>
  );
}
