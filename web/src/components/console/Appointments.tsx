"use client";

import { useState } from "react";
import type { Appointment } from "@/lib/booking/types";

interface Props {
  appointments: Appointment[];
  onArrive: (id: string) => Promise<void>;
  onSeat: (id: string) => Promise<void>;
  onCancel: (id: string) => Promise<void>;
}

interface RowProps {
  item: Appointment;
  onArrive: (id: string) => Promise<void>;
  onSeat: (id: string) => Promise<void>;
  onCancel: (id: string) => Promise<void>;
}

const CHANNEL_LABELS: Record<string, string> = {
  online: "Online",
  whatsapp: "WhatsApp",
  phone: "Phone",
  walkin: "Walk-in",
};

function formatTime(iso: string): string {
  return new Intl.DateTimeFormat("en-KE", {
    timeZone: "Africa/Nairobi",
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  }).format(new Date(iso));
}

function AppointmentRow({ item, onArrive, onSeat, onCancel }: RowProps) {
  const [busy, setBusy] = useState(false);
  const [seatError, setSeatError] = useState<string | null>(null);

  const isArrived = item.status === "arrived";

  async function handleArrive() {
    setBusy(true);
    setSeatError(null);
    try {
      await onArrive(item.id);
    } catch {
      setSeatError("Something went wrong. Try again.");
    } finally {
      setBusy(false);
    }
  }

  async function handleSeat() {
    setBusy(true);
    setSeatError(null);
    try {
      await onSeat(item.id);
    } catch (err) {
      const e = err as Error & { status?: number };
      if (e.status === 409) {
        setSeatError("That barber is busy right now.");
      } else {
        setSeatError("Something went wrong. Try again.");
      }
    } finally {
      setBusy(false);
    }
  }

  async function handleCancel() {
    setBusy(true);
    setSeatError(null);
    try {
      await onCancel(item.id);
    } catch {
      setSeatError("Something went wrong. Try again.");
    } finally {
      setBusy(false);
    }
  }

  const channelLabel = CHANNEL_LABELS[item.channel] ?? item.channel;

  return (
    <li
      className="flex items-center gap-4 px-5 py-4 rounded-xl"
      style={{
        background: isArrived ? "var(--in-chair-bg)" : "var(--card)",
        border: `1.5px solid ${isArrived ? "var(--in-chair)" : "#e5e7eb"}`,
      }}
    >
      {/* Scheduled time pill */}
      <div
        className="shrink-0 w-16 text-center"
      >
        <p
          className="text-sm font-bold"
          style={{ color: isArrived ? "var(--in-chair)" : "var(--navy)" }}
        >
          {formatTime(item.scheduledStart)}
        </p>
      </div>

      {/* Client + details */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 flex-wrap">
          <p
            className="font-semibold text-base truncate"
            style={{ color: "var(--navy)" }}
          >
            {item.clientName}
          </p>
          {item.isRegular && (
            <span
              className="text-xs font-semibold px-2 py-0.5 rounded-full shrink-0"
              style={{ background: "var(--brass)", color: "#fff" }}
            >
              Regular
            </span>
          )}
        </div>
        <p className="text-sm opacity-60 truncate">
          {item.barberName ?? "Any barber"}
          {item.serviceName && <> &middot; {item.serviceName}</>}
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

      {/* Channel tag */}
      <span
        className="shrink-0 text-xs font-semibold px-2.5 py-1 rounded-full"
        style={{ background: "var(--canvas)", color: "var(--navy)" }}
      >
        {channelLabel}
      </span>

      {/* Status badge for arrived */}
      {isArrived && (
        <span
          className="shrink-0 text-xs font-semibold px-2.5 py-1 rounded-full"
          style={{ background: "var(--in-chair)", color: "#fff" }}
        >
          Arrived
        </span>
      )}

      {/* Actions */}
      <div className="shrink-0 flex gap-2">
        {!isArrived && (
          <button
            onClick={handleArrive}
            disabled={busy}
            className="px-4 py-2 rounded-lg text-sm font-medium transition-opacity hover:opacity-80 disabled:opacity-40"
            style={{ background: "var(--free-bg)", color: "var(--free)" }}
          >
            Arrived
          </button>
        )}
        {isArrived && (
          <button
            onClick={handleSeat}
            disabled={busy}
            className="px-4 py-2 rounded-lg text-sm font-semibold transition-opacity hover:opacity-80 disabled:opacity-40"
            style={{ background: "var(--in-chair-bg)", color: "var(--in-chair)" }}
          >
            Seat now
          </button>
        )}
        <button
          onClick={handleCancel}
          disabled={busy}
          className="px-4 py-2 rounded-lg text-sm font-medium transition-opacity hover:opacity-80 disabled:opacity-40"
          style={{ background: "var(--late-bg)", color: "var(--late)" }}
        >
          Cancel
        </button>
      </div>
    </li>
  );
}

export default function Appointments({ appointments, onArrive, onSeat, onCancel }: Props) {
  if (appointments.length === 0) {
    return (
      <p className="text-sm opacity-50 py-4">No appointments booked for today.</p>
    );
  }

  return (
    <ul className="flex flex-col gap-3">
      {appointments.map((item) => (
        <AppointmentRow
          key={item.id}
          item={item}
          onArrive={onArrive}
          onSeat={onSeat}
          onCancel={onCancel}
        />
      ))}
    </ul>
  );
}
