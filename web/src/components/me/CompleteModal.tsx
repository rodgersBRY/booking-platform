'use client';

import { useEffect, useRef, useState } from 'react';
import { completeMyBooking } from '@/lib/api/me';

interface Props {
  bookingId: string;
  clientName: string;
  onClose: () => void;
  onComplete: () => void;
}

const PAYMENT_METHODS = [
  { value: 'cash', label: 'Cash' },
  { value: 'mpesa', label: 'M-Pesa' },
  { value: 'card', label: 'Card' },
];

export default function CompleteModal({ bookingId, clientName, onClose, onComplete }: Props) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [amount, setAmount] = useState('');
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
      await completeMyBooking(bookingId, Number(amount) || 0, paymentMethod);
      onComplete();
      onClose();
    } catch (err) {
      setError((err as Error).message ?? 'Something went wrong. Try again.');
    } finally {
      setSubmitting(false);
    }
  }

  const inputClass =
    'w-full rounded-lg px-4 py-3 text-base border outline-none focus:ring-2 transition-shadow';
  const inputStyle = {
    border: '1.5px solid #d1d5db',
    background: 'var(--canvas)',
    color: 'var(--navy)',
  };

  return (
    <dialog
      ref={dialogRef}
      onClick={handleBackdropClick}
      className="rounded-2xl p-0 max-w-sm w-full shadow-2xl backdrop:bg-black/50 m-auto"
      style={{ background: 'var(--card)', color: 'var(--navy)' }}
    >
      <form onSubmit={handleSubmit} className="flex flex-col gap-5 p-7">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold">Complete visit</h2>
          <button
            type="button"
            onClick={onClose}
            className="text-2xl leading-none opacity-40 hover:opacity-70 transition-opacity"
            aria-label="Close"
          >
            ×
          </button>
        </div>

        <p className="text-sm opacity-60">{clientName}</p>

        <div>
          <label className="block text-sm font-medium mb-1.5" htmlFor="cm-amount">
            Amount charged (KES)
          </label>
          <input
            id="cm-amount"
            type="number"
            min="0"
            step="1"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0"
            className={inputClass}
            style={inputStyle}
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1.5" htmlFor="cm-method">
            Payment method
          </label>
          <select
            id="cm-method"
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
          {submitting ? 'Saving…' : 'Complete visit'}
        </button>
      </form>
    </dialog>
  );
}
