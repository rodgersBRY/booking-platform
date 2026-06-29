"use client";

import { useState } from "react";
import type { ChairStatus } from "@/lib/booking/types";
import CompleteBookingModal from "./CompleteBookingModal";

interface Props {
  chairs: ChairStatus[];
  onRefresh: () => void;
}

interface ChairCardProps {
  chair: ChairStatus;
  onDoneClick: () => void;
}

function ChairCard({ chair, onDoneClick }: ChairCardProps) {
  const isFree = chair.status === "free";
  const isOverdue =
    !isFree && chair.minutesLeft != null && chair.minutesLeft <= 0;

  const borderColor = isFree
    ? "var(--free)"
    : isOverdue
    ? "var(--late)"
    : "var(--in-chair)";
  const badgeBg = isFree
    ? "var(--free-bg)"
    : isOverdue
    ? "var(--late-bg, #fee2e2)"
    : "var(--in-chair-bg)";
  const badgeColor = isFree
    ? "var(--free)"
    : isOverdue
    ? "var(--late)"
    : "var(--in-chair)";
  const badgeLabel = isFree ? "Free" : isOverdue ? "Overdue" : "In chair";

  return (
    <div
      className="rounded-2xl p-5 flex flex-col gap-3"
      style={{
        background: "var(--card)",
        border: `2px solid ${borderColor}`,
        minHeight: 160,
      }}
    >
      {/* Barber name + status badge */}
      <div className="flex items-center justify-between">
        <h3
          className="font-semibold text-base"
          style={{ color: "var(--navy)" }}
        >
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
          <p className="text-lg font-medium" style={{ color: "var(--navy)" }}>
            {chair.currentClientName ?? "—"}
          </p>
          {chair.serviceName && (
            <p className="text-sm opacity-60">{chair.serviceName}</p>
          )}
          {chair.minutesLeft != null && (
            isOverdue ? (
              <p className="text-sm font-medium" style={{ color: "var(--late)" }}>
                Overdue
              </p>
            ) : (
              <p className="text-sm" style={{ color: "var(--in-chair)" }}>
                ~{Math.round(chair.minutesLeft)} min left
              </p>
            )
          )}
        </div>
      )}

      {isFree && <p className="text-sm opacity-40 flex-1">Chair is open</p>}

      {/* Done action */}
      {!isFree && chair.bookingId && (
        <button
          onClick={onDoneClick}
          className="w-full py-2.5 rounded-xl text-sm font-semibold transition-opacity hover:opacity-80 active:opacity-70"
          style={{ background: "var(--free-bg)", color: "var(--free)" }}
        >
          Done
        </button>
      )}
    </div>
  );
}

export default function ChairsBoard({ chairs, onRefresh }: Props) {
  const [completingChair, setCompletingChair] = useState<ChairStatus | null>(null);

  if (chairs.length === 0) {
    return <p className="text-sm opacity-50">No barbers configured yet.</p>;
  }

  return (
    <>
      <div
        className="grid gap-4"
        style={{
          gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))",
        }}
      >
        {chairs.map((chair) => (
          <ChairCard
            key={chair.barberId}
            chair={chair}
            onDoneClick={() => setCompletingChair(chair)}
          />
        ))}
      </div>

      {completingChair && completingChair.bookingId && (
        <CompleteBookingModal
          bookingId={completingChair.bookingId}
          clientName={completingChair.currentClientName ?? "Unknown"}
          serviceName={completingChair.serviceName ?? null}
          servicePrice={completingChair.servicePrice ?? null}
          onClose={() => setCompletingChair(null)}
          onDone={() => {
            setCompletingChair(null);
            onRefresh();
          }}
        />
      )}
    </>
  );
}
