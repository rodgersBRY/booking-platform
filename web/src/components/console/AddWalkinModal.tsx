'use client';

import { useEffect, useRef, useState } from 'react';
import type { Barber, Service, WalkinResult } from '@/lib/api/console';
import { addWalkin } from '@/lib/api/console';

interface Props {
  barbers: Barber[];
  services: Service[];
  onClose: () => void;
  onAdded: (result: WalkinResult) => void;
}

const ACQUISITION_SOURCES = [
  { value: 'social', label: 'Social media' },
  { value: 'website', label: 'Website' },
  { value: 'referral', label: 'Referral' },
  { value: 'walkby', label: 'Walked by' },
  { value: 'other', label: 'Other' },
];

export default function AddWalkinModal({
  barbers,
  services,
  onClose,
  onAdded,
}: Props) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [preferredBarberId, setPreferredBarberId] = useState('');
  const [serviceId, setServiceId] = useState('');
  const [acquisitionSource, setAcquisitionSource] = useState('');
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
    if (!serviceId) {
      setError('Please select a service.');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const result = await addWalkin({
        name: name.trim(),
        phone: phone.trim(),
        preferredBarberId: preferredBarberId || undefined,
        serviceId,
        acquisitionSource: acquisitionSource || undefined,
      });
      onAdded(result);
      onClose();
    } catch (err) {
      setError((err as Error).message ?? 'Something went wrong. Try again.');
    } finally {
      setSubmitting(false);
    }
  }

  const labelClass = 'block text-sm font-medium mb-1.5';
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
      className="rounded-2xl p-0 max-w-lg w-full shadow-2xl backdrop:bg-black/40"
      style={{ background: 'var(--card)', color: 'var(--navy)' }}
    >
      <form onSubmit={handleSubmit} className="flex flex-col gap-5 p-7">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold">Add walk-in</h2>
          <button
            type="button"
            onClick={onClose}
            className="text-2xl leading-none opacity-40 hover:opacity-70 transition-opacity"
            aria-label="Close"
          >
            ×
          </button>
        </div>

        {/* Name */}
        <div>
          <label className={labelClass} htmlFor="wk-name">
            Client name
          </label>
          <input
            id="wk-name"
            type="text"
            required
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="First name"
            className={inputClass}
            style={inputStyle}
          />
        </div>

        {/* Phone */}
        <div>
          <label className={labelClass} htmlFor="wk-phone">
            Phone number
          </label>
          <input
            id="wk-phone"
            type="tel"
            required
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="+254 7xx xxx xxx"
            className={inputClass}
            style={inputStyle}
          />
        </div>

        {/* Service */}
        <div>
          <label className={labelClass} htmlFor="wk-service">
            Service
          </label>
          <select
            id="wk-service"
            required
            value={serviceId}
            onChange={(e) => setServiceId(e.target.value)}
            className={inputClass}
            style={inputStyle}
          >
            <option value="">Choose a service…</option>
            {services.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name} — {s.durationMinutes} min
              </option>
            ))}
          </select>
        </div>

        {/* Preferred barber */}
        <div>
          <label className={labelClass} htmlFor="wk-barber">
            Preferred barber
          </label>
          <select
            id="wk-barber"
            value={preferredBarberId}
            onChange={(e) => setPreferredBarberId(e.target.value)}
            className={inputClass}
            style={inputStyle}
          >
            <option value="">Any barber</option>
            {barbers.map((b) => (
              <option key={b.id} value={b.id}>
                {b.name}
              </option>
            ))}
          </select>
        </div>

        {/* Acquisition source */}
        <div>
          <label className={labelClass} htmlFor="wk-source">
            How did you hear about us? <span className="opacity-40">(optional)</span>
          </label>
          <select
            id="wk-source"
            value={acquisitionSource}
            onChange={(e) => setAcquisitionSource(e.target.value)}
            className={inputClass}
            style={inputStyle}
          >
            <option value="">Skip</option>
            {ACQUISITION_SOURCES.map((src) => (
              <option key={src.value} value={src.value}>
                {src.label}
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
          {submitting ? 'Adding…' : 'Add walk-in'}
        </button>
      </form>
    </dialog>
  );
}
