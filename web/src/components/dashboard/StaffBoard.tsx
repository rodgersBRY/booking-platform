"use client";

import { useEffect, useRef, useState } from "react";
import type { StaffListItem } from "@/lib/api/staff";
import { fetchStaff, setStaffStatus } from "@/lib/api/staff";
import AddStaffModal from "./AddStaffModal";
import ResetPasswordModal from "./ResetPasswordModal";

const POLL_INTERVAL_MS = 15_000;

const ROLE_COLORS: Record<string, { bg: string; color: string }> = {
  owner: { bg: "#e4e4e7", color: "#3f3f46" },
  receptionist: { bg: "var(--navy)", color: "#fff" },
  barber: { bg: "var(--brass)", color: "#fff" },
};

const STATUS_COLORS: Record<string, { bg: string; color: string }> = {
  active: { bg: "var(--free)", color: "#fff" },
  inactive: { bg: "#e4e4e7", color: "#6b7280" },
  blocked: { bg: "var(--late)", color: "#fff" },
};

export default function StaffBoard() {
  const [staff, setStaff] = useState<StaffListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showAdd, setShowAdd] = useState(false);
  const [resetTarget, setResetTarget] = useState<StaffListItem | null>(null);
  const [refreshTick, setRefreshTick] = useState(0);
  const [busyId, setBusyId] = useState<string | null>(null);

  function refresh() {
    setRefreshTick((t) => t + 1);
  }

  useEffect(() => {
    let cancelled = false;
    function poll() {
      fetchStaff()
        .then((data) => {
          if (!cancelled) {
            setStaff(data);
            setError(null);
            setLoading(false);
          }
        })
        .catch((e: Error) => {
          if (!cancelled) {
            setError(e.message);
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

  async function handleToggleStatus(member: StaffListItem) {
    const next = member.status === "active" ? "inactive" : "active";
    setBusyId(member.id);
    try {
      await setStaffStatus(member.id, next);
      refresh();
    } catch (e) {
      alert((e as Error).message);
    } finally {
      setBusyId(null);
    }
  }

  if (loading)
    return (
      <p className="text-sm opacity-40 py-12 text-center">Loading staff…</p>
    );
  if (error)
    return (
      <p className="text-sm py-12 text-center" style={{ color: "var(--late)" }}>
        {error}
      </p>
    );

  return (
    <>
      <div className="flex justify-end mb-4">
        <button
          onClick={() => setShowAdd(true)}
          className="px-6 py-3 rounded-xl text-sm font-semibold transition-opacity hover:opacity-90"
          style={{ background: "var(--brass)", color: "#fff" }}
        >
          + Add staff
        </button>
      </div>

      <div
        className="rounded-2xl shadow-sm overflow-hidden"
        style={{ background: "var(--card, #fff)" }}
      >
        <table className="w-full text-sm">
          <thead>
            <tr
              className="text-left border-b"
              style={{ borderColor: "#f3f4f6" }}
            >
              {["Name", "Role", "Email", "Status", "Actions"].map((h) => (
                <th
                  key={h}
                  className="px-5 py-3 font-semibold opacity-60"
                  style={{ color: "var(--navy)" }}
                >
                  {h}
                </th>
              ))}
            </tr>
          </thead>

          <tbody>
            {staff.map((m) => {
              // const rc = ROLE_COLORS[m.role] ?? ROLE_COLORS.owner;
              const sc = STATUS_COLORS[m.status] ?? STATUS_COLORS.inactive;
              return (
                <tr
                  key={m.id}
                  className="border-b last:border-0"
                  style={{ borderColor: "#f9fafb" }}
                >
                  <td
                    className="px-5 py-4 font-medium"
                    style={{ color: "var(--navy)" }}
                  >
                    {m.name}
                  </td>
                  <td className="px-5 py-4">
                    <span className="px-2.5 py-1 rounded-full text-xs font-semibold">
                      {m.role}
                    </span>
                  </td>
                  <td className="px-5 py-4 opacity-70">{m.email ?? "—"}</td>
                  <td className="px-5 py-4">
                    <span
                      className="px-2.5 py-1 rounded-full text-xs font-semibold"
                      style={sc}
                    >
                      {m.status}
                    </span>
                  </td>
                  <td className="px-5 py-4">
                    {m.role !== "owner" && (
                      <div className="flex gap-2">
                        <button
                          onClick={() => handleToggleStatus(m)}
                          disabled={busyId === m.id}
                          className="text-xs px-3 py-1.5 rounded-lg border font-medium transition-opacity hover:opacity-70 disabled:opacity-50 disabled:cursor-wait"
                          style={{
                            borderColor: "#d1d5db",
                            color: "var(--navy)",
                          }}
                        >
                          {busyId === m.id
                            ? "Saving…"
                            : m.status === "active"
                              ? "Deactivate"
                              : "Reactivate"}
                        </button>
                        <button
                          onClick={() => setResetTarget(m)}
                          className="text-xs px-3 py-1.5 rounded-lg border font-medium transition-opacity hover:opacity-70"
                          style={{
                            borderColor: "#d1d5db",
                            color: "var(--navy)",
                          }}
                        >
                          Reset password
                        </button>
                      </div>
                    )}
                  </td>
                </tr>
              );
            })}
            {staff.length === 0 && (
              <tr>
                <td colSpan={5} className="px-5 py-8 text-center opacity-40">
                  No staff yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {showAdd && (
        <AddStaffModal
          onClose={() => setShowAdd(false)}
          onAdded={() => {
            setShowAdd(false);
            refresh();
          }}
        />
      )}
      {resetTarget && (
        <ResetPasswordModal
          staff={resetTarget}
          onClose={() => setResetTarget(null)}
          onDone={() => {
            setResetTarget(null);
            refresh();
          }}
        />
      )}
    </>
  );
}
