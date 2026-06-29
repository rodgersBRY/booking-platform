"use client";

import { useEffect, useRef, useState } from "react";
import { resetStaffPassword } from "@/lib/api/staff";
import type { StaffListItem } from "@/lib/api/staff";

interface Props {
  staff: StaffListItem;
  onClose: () => void;
  onDone: () => void;
}

export default function ResetPasswordModal({ staff, onClose, onDone }: Props) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => { dialogRef.current?.showModal(); }, []);

  function handleBackdropClick(e: React.MouseEvent<HTMLDialogElement>) {
    if (e.target === dialogRef.current) onClose();
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      await resetStaffPassword(staff.id, password);
      setSuccess(true);
      setTimeout(onDone, 1500);
    } catch (err) {
      setError((err as Error).message ?? "Something went wrong.");
    } finally {
      setSubmitting(false);
    }
  }

  const inputClass = "w-full rounded-lg px-4 py-3 text-base border outline-none focus:ring-2 transition-shadow";
  const inputStyle = { border: "1.5px solid #d1d5db", background: "var(--canvas)", color: "var(--navy)" };

  return (
    <dialog
      ref={dialogRef}
      onClick={handleBackdropClick}
      className="rounded-2xl p-0 max-w-md w-full shadow-2xl backdrop:bg-black/50 m-auto"
      style={{ background: "var(--card, #fff)", color: "var(--navy)" }}
    >
      <form onSubmit={handleSubmit} className="flex flex-col gap-5 p-7">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold">Reset password</h2>
          <button type="button" onClick={onClose} className="text-2xl leading-none opacity-40 hover:opacity-70 transition-opacity" aria-label="Close">×</button>
        </div>
        <p className="text-sm opacity-60">Set a new temporary password for <strong>{staff.name}</strong>. They should change it after logging in.</p>

        {success ? (
          <p className="text-sm font-medium py-4 text-center" style={{ color: "var(--free)" }}>Password updated successfully.</p>
        ) : (
          <>
            <div>
              <label className="block text-sm font-medium mb-1.5" htmlFor="rp-password">New password</label>
              <input id="rp-password" type="password" required value={password} onChange={(e) => setPassword(e.target.value)} placeholder="New temporary password" className={inputClass} style={inputStyle} />
            </div>
            {error && <p className="text-sm font-medium" style={{ color: "var(--late)" }}>{error}</p>}
            <button
              type="submit"
              disabled={submitting}
              className="w-full py-4 rounded-xl text-base font-semibold transition-opacity hover:opacity-90 disabled:opacity-50"
              style={{ background: "var(--brass)", color: "#fff" }}
            >
              {submitting ? "Saving…" : "Save new password"}
            </button>
          </>
        )}
      </form>
    </dialog>
  );
}
