'use client';

import type { ChairStatus } from '@/lib/booking/types';

interface Props {
  chairs: ChairStatus[];
  onComplete: (bookingId: string) => Promise<void>;
}

interface ChairCardProps {
  chair: ChairStatus;
  onComplete: (bookingId: string) => Promise<void>;
}

function ChairCard({ chair, onComplete }: ChairCardProps) {
  const isFree = chair.status === 'free';

  const borderColor = isFree ? 'var(--free)' : 'var(--in-chair)';
  const badgeBg = isFree ? 'var(--free-bg)' : 'var(--in-chair-bg)';
  const badgeColor = isFree ? 'var(--free)' : 'var(--in-chair)';
  const badgeLabel = isFree ? 'Free' : 'In chair';

  async function handleDone() {
    if (chair.bookingId) {
      await onComplete(chair.bookingId);
    }
  }

  return (
    <div
      className="rounded-2xl p-5 flex flex-col gap-3"
      style={{
        background: 'var(--card)',
        border: `2px solid ${borderColor}`,
        minHeight: 160,
      }}
    >
      {/* Barber name + status badge */}
      <div className="flex items-center justify-between">
        <h3 className="font-semibold text-base" style={{ color: 'var(--navy)' }}>
          {chair.barberName}
        </h3>
        <span
          className="text-xs font-semibold px-2.5 py-1 rounded-full"
          style={{ background: badgeBg, color: badgeColor }}
        >
          {badgeLabel}
        </span>
      </div>

      {/* Client details when in chair */}
      {!isFree && (
        <div className="flex-1 flex flex-col gap-1">
          <p className="text-lg font-medium" style={{ color: 'var(--navy)' }}>
            {chair.currentClientName ?? '—'}
          </p>
          {chair.serviceName && (
            <p className="text-sm opacity-60">{chair.serviceName}</p>
          )}
          {chair.minutesLeft != null && (
            <p className="text-sm" style={{ color: 'var(--in-chair)' }}>
              ~{Math.round(chair.minutesLeft)} min left
            </p>
          )}
        </div>
      )}

      {isFree && (
        <p className="text-sm opacity-40 flex-1">Chair is open</p>
      )}

      {/* Done action */}
      {!isFree && chair.bookingId && (
        <button
          onClick={handleDone}
          className="w-full py-2.5 rounded-xl text-sm font-semibold transition-opacity hover:opacity-80 active:opacity-70"
          style={{ background: 'var(--free-bg)', color: 'var(--free)' }}
        >
          Done
        </button>
      )}
    </div>
  );
}

export default function ChairsBoard({ chairs, onComplete }: Props) {
  if (chairs.length === 0) {
    return (
      <p className="text-sm opacity-50">No barbers configured yet.</p>
    );
  }

  return (
    <div
      className="grid gap-4"
      style={{
        gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))',
      }}
    >
      {chairs.map((chair) => (
        <ChairCard key={chair.barberId} chair={chair} onComplete={onComplete} />
      ))}
    </div>
  );
}
