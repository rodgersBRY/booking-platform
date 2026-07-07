"use client";

import { useEffect, useRef, useState } from "react";
import { createStaff } from "@/lib/api/staff";
import type { StaffListItem } from "@/lib/api/staff";

interface Props {
  onClose: () => void;
  onAdded: (s: StaffListItem) => void;
}

export default function AddStaffModal({ onClose, onAdded }: Props) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [name, setName] = useState("");
  const [role, setRole] = useState("barber");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
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
      const s = await createStaff({ name, role, email, phone, password });
      onAdded(s);
    } catch (err) {
      setError((err as Error).message ?? "Something went wrong.");
    } finally {
      setSubmitting(false);
    }
  }

  const labelClass = "block text-sm font-medium mb-1.5";
  const inputClass = "w-full rounded-lg px-4 py-3 text-base border outline-none focus:ring-2 transition-shadow";
  const inputStyle = { border: "1.5px solid #d1d5db", background: "var(--canvas)", color: "var(--navy)" };

  return (
    <dialog
      ref={dialogRef}
      onClick={handleBackdropClick}
      className="rounded-2xl p-0 max-w-lg w-full shadow-2xl backdrop:bg-black/50 m-auto"
      style={{ background: "var(--card, #fff)", color: "var(--navy)" }}
    >
      <form onSubmit={handleSubmit} className="flex flex-col gap-5 p-7">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold">Add staff member</h2>
          <button type="button" onClick={onClose} className="text-2xl leading-none opacity-40 hover:opacity-70 transition-opacity" aria-label="Close">×</button>
        </div>

        <div>
          <label className={labelClass} htmlFor="sf-name">Full name</label>
          <input id="sf-name" type="text" required value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. James Kamau" className={inputClass} style={inputStyle} />
        </div>

        <div>
          <label className={labelClass} htmlFor="sf-role">Role</label>
          <select id="sf-role" value={role} onChange={(e) => setRole(e.target.value)} className={inputClass} style={inputStyle}>
            <option value="barber">Barber</option>
            <option value="beautician">Beautician</option>
            <option value="masseuse">Masseuse</option>
            <option value="receptionist">Receptionist</option>
          </select>
        </div>

        <div>
          <label className={labelClass} htmlFor="sf-email">Email</label>
          <input id="sf-email" type="email" required value={email} onChange={(e) => setEmail(e.target.value)} placeholder="james@example.com" className={inputClass} style={inputStyle} />
        </div>

        <div>
          <label className={labelClass} htmlFor="sf-phone">Phone</label>
          <input id="sf-phone" type="tel" required value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+254 7xx xxx xxx — needed for WhatsApp notifications" className={inputClass} style={inputStyle} />
        </div>

        <div>
          <label className={labelClass} htmlFor="sf-password">Temporary password</label>
          <input id="sf-password" type="password" required value={password} onChange={(e) => setPassword(e.target.value)} placeholder="They can change this after login" className={inputClass} style={inputStyle} />
        </div>

        {error && <p className="text-sm font-medium" style={{ color: "var(--late)" }}>{error}</p>}

        <button
          type="submit"
          disabled={submitting}
          className="w-full py-4 rounded-xl text-base font-semibold transition-opacity hover:opacity-90 disabled:opacity-50"
          style={{ background: "var(--brass)", color: "#fff" }}
        >
          {submitting ? "Creating…" : "Add staff member"}
        </button>
      </form>
    </dialog>
  );
}
