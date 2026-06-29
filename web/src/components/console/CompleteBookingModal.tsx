'use client';

import { useEffect, useRef, useState } from 'react';

interface Props {
  bookingId: string;
  clientName: string;
  serviceName: string | null;
  servicePrice: number | null;
  onClose: () => void;
  onDone: () => void;
}

const PAYMENT_METHODS = [
  { value: 'cash', label: 'Cash' },
  { value: 'mpesa', label: 'M-Pesa' },
  { value: 'card', label: 'Card' },
];

const labelClass = 'block text-sm font-medium mb-1.5';
const inputClass =
  'w-full rounded-lg px-4 py-3 text-base border outline-none focus:ring-2 transition-shadow';
const inputStyle = {
  border: '1.5px solid #d1d5db',
  background: 'var(--canvas)',
  color: 'var(--navy)',
};

export default function CompleteBookingModal({
  bookingId,
  clientName,
  serviceName,
  servicePrice,
  onClose,
  onDone,
}: Props) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [amountCharged, setAmountCharged] = useState<number>(servicePrice ?? 0);
  const [paymentMethod, setPaymentMethod] = useState('cash');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    dialogRef.current?.showModal();
  }, []);

  function handleBackdropClick(e: React.MouseEvent<HTMLDialogElement>) {
    if (e.target === dialogRef.current) onClose();
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const res = await fetch(`/api/bookings/${bookingId}/complete`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amountCharged, paymentMethod }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        throw new Error((body as { error?: string }).error ?? `HTTP ${res.status}`);
      }
      onDone();
    } catch (err) {
      setError((err as Error).message ?? 'Something went wrong. Try again.');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <dialog
      ref={dialogRef}
      onClick={handleBackdropClick}
      className="rounded-2xl p-0 max-w-md w-full shadow-2xl backdrop:bg-black/50 m-auto"
      style={{ background: 'var(--card)', color: 'var(--navy)' }}
    >
      <form onSubmit={handleSubmit} className="flex flex-col gap-5 p-7">
        {/* Header */}
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold">Complete booking</h2>
          <button
            type="button"
            onClick={onClose}
            className="text-2xl leading-none opacity-40 hover:opacity-70 transition-opacity"
            aria-label="Close"
          >
            ×
          </button>
        </div>

        {/* Client + service summary */}
        <div
          className="rounded-xl px-4 py-3"
          style={{ background: 'var(--canvas)', border: '1.5px solid #e5e7eb' }}
        >
          <p className="font-semibold" style={{ color: 'var(--navy)' }}>{clientName}</p>
          {serviceName && (
            <p className="text-sm opacity-60 mt-0.5">{serviceName}</p>
          )}
        </div>

        {/* Amount */}
        <div>
          <label className={labelClass} htmlFor="cb-amount">
            Amount charged (KES)
          </label>
          <input
            id="cb-amount"
            type="number"
            min={0}
            step={1}
            required
            value={amountCharged}
            onChange={(e) => setAmountCharged(Number(e.target.value))}
            className={inputClass}
            style={inputStyle}
          />
        </div>

        {/* Payment method */}
        <div>
          <label className={labelClass} htmlFor="cb-method">
            Payment method
          </label>
          <select
            id="cb-method"
            value={paymentMethod}
            onChange={(e) => setPaymentMethod(e.target.value)}
            className={inputClass}
            style={inputStyle}
          >
            {PAYMENT_METHODS.map((m) => (
              <option key={m.value} value={m.value}>
                {m.label}
              </option>
            ))}
          </select>
        </div>

        {error && (
          <p className="text-sm font-medium" style={{ color: 'var(--late)' }}>
            {error}
          </p>
        )}

        <button
          type="submit"
          disabled={submitting}
          className="w-full py-4 rounded-xl text-base font-semibold transition-opacity hover:opacity-90 disabled:opacity-50"
          style={{ background: 'var(--brass)', color: '#fff' }}
        >
          {submitting ? 'Saving…' : 'Mark as done'}
        </button>
      </form>
    </dialog>
  );
}
