'use client';

import type { ScheduleItem } from '@/lib/api/me';
import ScheduleRow from './ScheduleRow';

interface Props {
  schedule: ScheduleItem[];
  onArrive: (id: string) => Promise<void>;
  onStart: (id: string) => Promise<void>;
  onComplete: () => void;
}

export default function ScheduleList({ schedule, onArrive, onStart, onComplete }: Props) {
  if (schedule.length === 0) {
    return (
      <p className="text-sm opacity-40 text-center py-6">
        No appointments scheduled for today.
      </p>
    );
  }

  return (
    <div className="flex flex-col gap-3">
      {schedule.map((item) => (
        <ScheduleRow
          key={item.bookingId}
          item={item}
          onArrive={onArrive}
          onStart={onStart}
          onComplete={onComplete}
        />
      ))}
    </div>
  );
}
