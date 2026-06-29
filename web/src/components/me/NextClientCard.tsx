'use client';

import type { NextClientItem } from '@/lib/api/me';

interface Props {
  next: NextClientItem | null;
}

const STATUS_LABELS: Record<NextClientItem['status'], string> = {
  booked: 'Booked',
  arrived: 'Arrived',
};

function formatTime(iso: string): string {
  return new Intl.DateTimeFormat('en-KE', {
    timeZone: 'Africa/Nairobi',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  }).format(new Date(iso));
}

export default function NextClientCard({ next }: Props) {
  if (!next) {
    return (
      <div
        className="rounded-2xl px-6 py-8 text-center"
        style={{ background: 'var(--free, #22c55e)', color: '#fff' }}
      >
        <p className="text-3xl font-bold mb-1">You&apos;re clear ✂</p>
        <p className="text-sm opacity-80">No upcoming appointments.</p>
      </div>
    );
  }

  return (
    <div
      className="rounded-2xl px-6 py-6"
      style={{ background: 'var(--card)', border: '2px solid var(--brass)' }}
    >
      <p className="text-xs font-semibold uppercase tracking-wide opacity-50 mb-3">
        Next client
      </p>
      <p className="text-2xl font-bold mb-1" style={{ color: 'var(--navy)' }}>
        {next.clientName}
      </p>
      <p className="text-sm opacity-60 mb-3">
        {formatTime(next.scheduledStart)}
        {next.serviceName ? ` · ${next.serviceName}` : ''}
      </p>
      <span
        className="inline-block text-xs font-semibold px-3 py-1 rounded-full"
        style={{
          background:
            next.status === 'arrived'
              ? 'var(--in-chair, #3b82f6)'
              : 'var(--amber, #f59e0b)',
          color: '#fff',
        }}
      >
        {STATUS_LABELS[next.status]}
      </span>
    </div>
  );
}
