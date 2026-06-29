'use client';

import { useEffect, useState } from 'react';
import type { MyDayData } from '@/lib/api/me';
import { fetchMyDay, arriveMyBooking, startMyBooking } from '@/lib/api/me';
import NextClientCard from './NextClientCard';
import ScheduleList from './ScheduleList';

const POLL_INTERVAL_MS = 10_000;

interface Props {
  staffId: string;
}

export default function MyDayBoard({ staffId: _staffId }: Props) {
  const [data, setData] = useState<MyDayData | null>(null);
  const [loading, setLoading] = useState(true);
  const [fetchError, setFetchError] = useState<string | null>(null);
  const [refreshTick, setRefreshTick] = useState(0);

  useEffect(() => {
    let cancelled = false;

    function poll() {
      fetchMyDay()
        .then((d) => {
          if (!cancelled) {
            setData(d);
            setFetchError(null);
            setLoading(false);
          }
        })
        .catch(() => {
          if (!cancelled) {
            setFetchError('Could not reach the server. Retrying…');
            setLoading(false);
          }
        });
    }

    poll();
    const id = setInterval(poll, POLL_INTERVAL_MS);
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, [refreshTick]);

  function refresh() {
    setRefreshTick((t) => t + 1);
  }

  async function handleArrive(id: string) {
    await arriveMyBooking(id);
    refresh();
  }

  async function handleStart(id: string) {
    await startMyBooking(id);
    refresh();
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <p className="text-sm opacity-40">Loading your day…</p>
      </div>
    );
  }

  if (fetchError && !data) {
    return (
      <div className="flex items-center justify-center py-24">
        <p className="text-sm" style={{ color: 'var(--late)' }}>
          {fetchError}
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-8">
      {/* Next client hero card */}
      <NextClientCard next={data?.nextClient ?? null} />

      {/* Queue waiting badge */}
      {(data?.queueWaitingCount ?? 0) > 0 && (
        <div
          className="rounded-xl px-4 py-3 flex items-center gap-2"
          style={{ background: 'var(--canvas)', border: '1.5px solid #e5e7eb' }}
        >
          <span
            className="text-sm font-semibold px-2.5 py-0.5 rounded-full"
            style={{ background: 'var(--brass)', color: '#fff' }}
          >
            {data!.queueWaitingCount}
          </span>
          <span className="text-sm opacity-60">
            {data!.queueWaitingCount === 1
              ? 'client waiting for you'
              : 'clients waiting for you'}
          </span>
        </div>
      )}

      {/* Full schedule */}
      <div>
        <h2 className="text-lg font-semibold mb-4" style={{ color: 'var(--navy)' }}>
          Today&apos;s schedule
        </h2>
        <ScheduleList
          schedule={data?.schedule ?? []}
          onArrive={handleArrive}
          onStart={handleStart}
          onComplete={refresh}
        />
      </div>

      {/* Stale data warning */}
      {fetchError && data && (
        <p className="text-xs text-center opacity-50" style={{ color: 'var(--late)' }}>
          {fetchError}
        </p>
      )}
    </div>
  );
}
