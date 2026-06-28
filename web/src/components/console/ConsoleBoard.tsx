"use client";

import { useEffect, useRef, useState } from "react";
import type {
  BoardData,
  Barber,
  Service,
  WalkinResult,
} from "@/lib/api/console";
import {
  fetchBoard,
  fetchBarbers,
  fetchServices,
  seatQueueItem,
  notifyQueueItem,
  completeBooking,
  arriveBooking,
  seatBooking,
  cancelBooking,
} from "@/lib/api/console";
import ChairsBoard from "./ChairsBoard";
import LiveQueue from "./LiveQueue";
import QuickStats from "./QuickStats";
import AddWalkinModal from "./AddWalkinModal";
import Appointments from "./Appointments";

const POLL_INTERVAL_MS = 8_000;

type WalkinToast = { message: string; type: "seated" | "queued" };

export default function ConsoleBoard() {
  const [board, setBoard] = useState<BoardData | null>(null);
  const [barbers, setBarbers] = useState<Barber[]>([]);
  const [services, setServices] = useState<Service[]>([]);
  const [loading, setLoading] = useState(true);
  const [fetchError, setFetchError] = useState<string | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [toast, setToast] = useState<WalkinToast | null>(null);
  // Incrementing this triggers a manual board refresh via the polling effect.
  const [refreshTick, setRefreshTick] = useState(0);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Load barbers + services once — state set only inside .then()
  useEffect(() => {
    Promise.all([fetchBarbers(), fetchServices()])
      .then(([b, s]) => {
        setBarbers(b);
        setServices(s);
      })
      .catch(() => {
        // Non-critical; modal shows empty dropdowns if this fails
      });
  }, []);

  // Polling effect — state set only inside async callbacks, not synchronously
  // TODO: swap polling for Supabase realtime
  useEffect(() => {
    let cancelled = false;

    function poll() {
      fetchBoard()
        .then((data) => {
          if (!cancelled) {
            setBoard(data);
            setFetchError(null);
            setLoading(false);
          }
        })
        .catch(() => {
          if (!cancelled) {
            setFetchError("Could not reach the server. Retrying…");
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

  function showToast(msg: WalkinToast) {
    setToast(msg);
    if (toastTimer.current) clearTimeout(toastTimer.current);
    toastTimer.current = setTimeout(() => setToast(null), 4_000);
  }

  function handleWalkinAdded(result: WalkinResult) {
    if (result.seated) {
      showToast({ message: "Walk-in seated straight away.", type: "seated" });
    } else {
      showToast({ message: "Walk-in added to the queue.", type: "queued" });
    }
    refresh();
  }

  async function handleComplete(bookingId: string) {
    await completeBooking(bookingId);
    refresh();
  }

  async function handleArrive(id: string) {
    await arriveBooking(id);
    refresh();
  }

  async function handleSeatBooking(id: string) {
    await seatBooking(id);
    refresh();
  }

  async function handleCancelBooking(id: string) {
    await cancelBooking(id);
    refresh();
  }

  async function handleSeat(id: string) {
    await seatQueueItem(id);
    refresh();
  }

  async function handleNotify(id: string) {
    await notifyQueueItem(id);
    refresh();
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <p className="text-sm opacity-40">Loading the board…</p>
      </div>
    );
  }

  if (fetchError && !board) {
    return (
      <div className="flex items-center justify-center py-24">
        <p className="text-sm" style={{ color: "var(--late)" }}>
          {fetchError}
        </p>
      </div>
    );
  }

  return (
    <>
      <div className="flex flex-col gap-8">
        {/* Quick stats */}
        {board && <QuickStats stats={board.stats} />}

        {/* Chairs heading + Add walk-in */}
        <div className="flex items-center justify-between">
          <h2
            className="text-lg font-semibold"
            style={{ color: "var(--navy)" }}
          >
            Chairs
          </h2>
          <button
            onClick={() => setShowModal(true)}
            className="px-6 py-3 rounded-xl text-sm font-semibold transition-opacity hover:opacity-90"
            style={{ background: "var(--brass)", color: "#fff" }}
          >
            Add walk-in
          </button>
        </div>

        {/* Chairs board */}
        {board && (
          <ChairsBoard chairs={board.chairs} onComplete={handleComplete} />
        )}

        {/* Today's appointments */}
        <div>
          <h2
            className="text-lg font-semibold mb-4"
            style={{ color: "var(--navy)" }}
          >
            Today&apos;s appointments
          </h2>
          {board && (
            <Appointments
              appointments={board.appointments ?? []}
              onArrive={handleArrive}
              onSeat={handleSeatBooking}
              onCancel={handleCancelBooking}
            />
          )}
        </div>

        {/* Live queue */}
        <div>
          <h2
            className="text-lg font-semibold mb-4"
            style={{ color: "var(--navy)" }}
          >
            Queue
          </h2>
          {board && (
            <LiveQueue
              queue={board.queue}
              onSeat={handleSeat}
              onNotify={handleNotify}
            />
          )}
        </div>

        {/* Stale-data warning when we have board data but refresh failed */}
        {fetchError && board && (
          <p
            className="text-xs text-center opacity-50"
            style={{ color: "var(--late)" }}
          >
            {fetchError}
          </p>
        )}
      </div>

      {/* Walk-in modal */}
      {showModal && (
        <AddWalkinModal
          barbers={barbers}
          services={services}
          onClose={() => setShowModal(false)}
          onAdded={handleWalkinAdded}
        />
      )}

      {/* Toast notification */}
      {toast && (
        <div
          className="fixed bottom-6 right-6 px-5 py-3 rounded-xl text-sm font-medium shadow-lg"
          style={{
            background:
              toast.type === "seated" ? "var(--free)" : "var(--in-chair)",
            color: "#fff",
          }}
        >
          {toast.message}
        </div>
      )}
    </>
  );
}
