"use client";

import { useState } from "react";
import type { QueueItem } from "@/lib/booking/types";

interface Props {
  queue: QueueItem[];
  onSeat: (id: string) => Promise<void>;
  onNotify: (id: string) => Promise<void>;
}

interface RowProps {
  item: QueueItem;
  onSeat: (id: string) => Promise<void>;
  onNotify: (id: string) => Promise<void>;
}

function QueueRow({ item, onSeat, onNotify }: RowProps) {
  const [seatError, setSeatError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const isNotified = item.status === "notified";

  async function handleSeat() {
    setBusy(true);
    setSeatError(null);
    try {
      await onSeat(item.id);
    } catch (err) {
      const e = err as Error & { status?: number };
      if (e.status === 409) {
        setSeatError("No barber is free right now.");
      } else {
        setSeatError("Something went wrong. Try again.");
      }
    } finally {
      setBusy(false);
    }
  }

  async function handleNotify() {
    setBusy(true);
    try {
      await onNotify(item.id);
    } finally {
      setBusy(false);
    }
  }

  return (
    <li
      className="flex items-center gap-4 px-5 py-4 rounded-xl"
      style={{
        background: isNotified ? "var(--notified-bg)" : "var(--card)",
        border: `1.5px solid ${isNotified ? "var(--notified)" : "#e5e7eb"}`,
      }}
    >
      {/* Waited time pill */}
      <div
        className="shrink-0 w-12 h-12 rounded-full flex items-center justify-center text-xs font-bold"
        style={{
          background: isNotified ? "var(--notified)" : "var(--canvas)",
          color: isNotified ? "#fff" : "var(--navy)",
        }}
      >
        {Math.round(item.waitedMinutes)}m
      </div>

      {/* Client info */}
      <div className="flex-1 min-w-0">
        <p
          className="font-semibold text-base truncate"
          style={{ color: "var(--navy)" }}
        >
          {item.clientName}
        </p>
        <p className="text-sm opacity-60 truncate">
          {item.preferredBarberName
            ? `Prefers ${item.preferredBarberName}`
            : "Any barber"}
          {item.estimatedWaitMinutes != null && (
            <> &middot; ~{Math.round(item.estimatedWaitMinutes)} min wait</>
          )}
        </p>
        {seatError && (
          <p
            className="text-xs mt-1 font-medium"
            style={{ color: "var(--late)" }}
          >
            {seatError}
          </p>
        )}
      </div>

      {/* Status badge for notified */}
      {isNotified && (
        <span
          className="shrink-0 text-xs font-semibold px-2.5 py-1 rounded-full"
          style={{ background: "var(--notified)", color: "#fff" }}
        >
          Notified
        </span>
      )}

      {/* Actions */}
      <div className="shrink-0 flex gap-2">
        {!isNotified && (
          <button
            onClick={handleNotify}
            disabled={busy}
            className="px-4 py-2 rounded-lg text-sm font-medium transition-opacity hover:opacity-80 disabled:opacity-40"
            style={{ background: "var(--waiting-bg)", color: "var(--waiting)" }}
          >
            Notify
          </button>
        )}
        <button
          onClick={handleSeat}
          disabled={busy}
          className="px-4 py-2 rounded-lg text-sm font-semibold transition-opacity hover:opacity-80 disabled:opacity-40"
          style={{ background: "var(--in-chair-bg)", color: "var(--in-chair)" }}
        >
          Seat now
        </button>
      </div>
    </li>
  );
}

export default function LiveQueue({ queue, onSeat, onNotify }: Props) {
  if (queue.length === 0) {
    return (
      <p className="text-sm opacity-50 py-4">
        No one waiting — the queue&apos;s clear.
      </p>
    );
  }

  return (
    <ul className="flex flex-col gap-3">
      {queue.map((item) => (
        <QueueRow
          key={item.id}
          item={item}
          onSeat={onSeat}
          onNotify={onNotify}
        />
      ))}
    </ul>
  );
}
