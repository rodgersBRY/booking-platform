'use client';

import { useState } from 'react';
import type { ScheduleItem } from '@/lib/api/me';
import CompleteModal from './CompleteModal';

interface Props {
  item: ScheduleItem;
  onArrive: (id: string) => Promise<void>;
  onStart: (id: string) => Promise<void>;
  onComplete: () => void;
}

const STATUS_COLORS: Record<ScheduleItem['status'], string> = {
  booked: 'var(--amber, #f59e0b)',
  arrived: 'var(--in-chair, #3b82f6)',
  in_chair: 'var(--navy, #1e3a5f)',
  late: 'var(--late, #ef4444)',
};

const STATUS_LABELS: Record<ScheduleItem['status'], string> = {
  booked: 'Booked',
  arrived: 'Arrived',
  in_chair: 'In chair',
  late: 'Late',
};

function formatTime(iso: string): string {
  return new Intl.DateTimeFormat('en-KE', {
    timeZone: 'Africa/Nairobi',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  }).format(new Date(iso));
}

export default function ScheduleRow({ item, onArrive, onStart, onComplete }: Props) {
  const [busy, setBusy] = useState(false);
  const [showComplete, setShowComplete] = useState(false);

  async function handleAction() {
    setBusy(true);
    try {
      if (item.status === 'booked') await onArrive(item.bookingId);
      else if (item.status === 'arrived') await onStart(item.bookingId);
    } finally {
      setBusy(false);
    }
  }

  const actionLabel =
    item.status === 'booked'
      ? 'Mark arrived'
      : item.status === 'arrived'
      ? 'Start'
      : item.status === 'in_chair'
      ? 'Complete'
      : null;

  function handleActionClick() {
    if (item.status === 'in_chair') {
      setShowComplete(true);
    } else {
      handleAction();
    }
  }

  return (
    <>
      <div
        className="flex items-center justify-between gap-4 px-4 py-3 rounded-xl"
        style={{ background: 'var(--card)', border: '1.5px solid #e5e7eb' }}
      >
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-0.5">
            <span className="font-semibold text-sm" style={{ color: 'var(--navy)' }}>
              {item.clientName}
            </span>
            <span
              className="shrink-0 text-xs font-semibold px-2 py-0.5 rounded-full"
              style={{ background: STATUS_COLORS[item.status], color: '#fff' }}
            >
              {STATUS_LABELS[item.status]}
            </span>
          </div>
          <p className="text-xs opacity-60">
            {formatTime(item.scheduledStart)}
            {item.serviceName ? ` · ${item.serviceName}` : ''}
          </p>
        </div>

        {actionLabel && (
          <button
            type="button"
            onClick={handleActionClick}
            disabled={busy}
            className="shrink-0 px-4 py-2 rounded-lg text-sm font-semibold transition-opacity hover:opacity-90 disabled:opacity-50"
            style={{ background: 'var(--brass)', color: '#fff' }}
          >
            {busy ? '…' : actionLabel}
          </button>
        )}
      </div>

      {showComplete && (
        <CompleteModal
          bookingId={item.bookingId}
          clientName={item.clientName}
          onClose={() => setShowComplete(false)}
          onComplete={onComplete}
        />
      )}
    </>
  );
}
