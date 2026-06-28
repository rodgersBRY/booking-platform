'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import type { Barber, Service, WalkinResult, ClientSearchResult } from '@/lib/api/console';
import { addWalkin, searchClients } from '@/lib/api/console';

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

function relativeDate(iso: string | null): string {
  if (!iso) return 'never';
  const days = Math.floor((Date.now() - new Date(iso).getTime()) / 86_400_000);
  if (days === 0) return 'today';
  if (days === 1) return 'yesterday';
  if (days < 30) return `${days} days ago`;
  const months = Math.floor(days / 30);
  return months === 1 ? '1 month ago' : `${months} months ago`;
}

export default function AddWalkinModal({
  barbers,
  services,
  onClose,
  onAdded,
}: Props) {
  const dialogRef = useRef<HTMLDialogElement>(null);

  // Search state
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<ClientSearchResult[]>([]);
  const [searching, setSearching] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Selected returning client
  const [selectedClient, setSelectedClient] = useState<ClientSearchResult | null>(null);
  const [forceNew, setForceNew] = useState(false);

  // Form fields (used in new-customer mode)
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [acquisitionSource, setAcquisitionSource] = useState('');

  // Shared fields
  const [preferredBarberId, setPreferredBarberId] = useState('');
  const [serviceId, setServiceId] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    dialogRef.current?.showModal();
  }, []);

  // Debounced search
  const handleSearchChange = useCallback((value: string) => {
    setSearchQuery(value);
    if (debounceRef.current) clearTimeout(debounceRef.current);
    if (value.trim().length < 2) {
      setSearchResults([]);
      return;
    }
    debounceRef.current = setTimeout(async () => {
      setSearching(true);
      try {
        const results = await searchClients(value.trim());
        setSearchResults(results);
      } catch {
        setSearchResults([]);
      } finally {
        setSearching(false);
      }
    }, 250);
  }, []);

  function selectClient(client: ClientSearchResult) {
    setSelectedClient(client);
    setForceNew(false);
    setPreferredBarberId(client.preferredBarberId ?? '');
    setSearchResults([]);
  }

  function handleForceNew() {
    setSelectedClient(null);
    setForceNew(true);
    setSearchResults([]);
    // Pre-fill phone/name from the search query if it looks like a number
    const q = searchQuery.trim();
    if (/^\+?\d/.test(q)) {
      setPhone(q);
    } else {
      setName(q);
    }
  }

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
      let result: WalkinResult;
      if (selectedClient) {
        result = await addWalkin({
          clientId: selectedClient.id,
          preferredBarberId: preferredBarberId || undefined,
          serviceId,
        });
      } else {
        result = await addWalkin({
          name: name.trim(),
          phone: phone.trim(),
          preferredBarberId: preferredBarberId || undefined,
          serviceId,
          acquisitionSource: acquisitionSource || undefined,
        });
      }
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

  // Determine which mode to render
  const isReturningConfirm = selectedClient !== null;
  const isNewForm = forceNew || (!selectedClient && searchQuery.trim().length === 0);
  const isSearching = !selectedClient && !forceNew;

  return (
    <dialog
      ref={dialogRef}
      onClick={handleBackdropClick}
      className="rounded-2xl p-0 max-w-lg w-full shadow-2xl backdrop:bg-black/40 m-auto"
      style={{ background: 'var(--card)', color: 'var(--navy)' }}
    >
      <form onSubmit={handleSubmit} className="flex flex-col gap-5 p-7">
        {/* Header */}
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

        {/* Search field — always visible unless we're in confirmed returning mode */}
        {!isReturningConfirm && (
          <div className="relative">
            <label className={labelClass} htmlFor="wk-search">
              Search by name or phone
            </label>
            <input
              id="wk-search"
              type="text"
              value={searchQuery}
              onChange={(e) => handleSearchChange(e.target.value)}
              placeholder="e.g. James or +254 7…"
              autoComplete="off"
              className={inputClass}
              style={inputStyle}
            />
            {searching && (
              <p className="text-xs opacity-50 mt-1">Searching…</p>
            )}

            {/* Search results dropdown */}
            {searchResults.length > 0 && (
              <ul
                className="absolute z-10 left-0 right-0 mt-1 rounded-xl shadow-lg overflow-hidden"
                style={{ background: 'var(--card)', border: '1.5px solid #e5e7eb' }}
              >
                {searchResults.map((client) => (
                  <li key={client.id}>
                    <button
                      type="button"
                      onClick={() => selectClient(client)}
                      className="w-full text-left px-4 py-3 hover:opacity-80 transition-opacity flex items-start gap-3"
                      style={{ borderBottom: '1px solid #f3f4f6' }}
                    >
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span className="font-semibold text-sm truncate" style={{ color: 'var(--navy)' }}>
                            {client.name}
                          </span>
                          {client.isRegular && (
                            <span
                              className="shrink-0 text-xs font-semibold px-2 py-0.5 rounded-full"
                              style={{ background: 'var(--brass)', color: '#fff' }}
                            >
                              Regular
                            </span>
                          )}
                        </div>
                        <p className="text-xs opacity-60 truncate mt-0.5">
                          {client.phone}
                          {client.preferredBarberName && (
                            <> &middot; Prefers {client.preferredBarberName}</>
                          )}
                          {' '}&middot; {client.totalVisits} visit{client.totalVisits !== 1 ? 's' : ''} &middot; last seen {relativeDate(client.lastVisitAt)}
                        </p>
                      </div>
                    </button>
                  </li>
                ))}
                <li>
                  <button
                    type="button"
                    onClick={handleForceNew}
                    className="w-full text-left px-4 py-3 text-sm font-medium hover:opacity-80 transition-opacity"
                    style={{ color: 'var(--brass)' }}
                  >
                    + New customer
                  </button>
                </li>
              </ul>
            )}

            {/* No results state — show new customer option */}
            {!searching && searchQuery.trim().length >= 2 && searchResults.length === 0 && (
              <div
                className="mt-1 rounded-xl px-4 py-3"
                style={{ background: 'var(--canvas)', border: '1.5px solid #e5e7eb' }}
              >
                <p className="text-sm opacity-60 mb-2">No match found.</p>
                <button
                  type="button"
                  onClick={handleForceNew}
                  className="text-sm font-semibold hover:opacity-80 transition-opacity"
                  style={{ color: 'var(--brass)' }}
                >
                  + Add as new customer
                </button>
              </div>
            )}
          </div>
        )}

        {/* ── Returning customer confirm step ─────────────────────────── */}
        {isReturningConfirm && selectedClient && (
          <div
            className="rounded-xl px-4 py-4 flex items-start gap-3"
            style={{ background: 'var(--canvas)', border: '1.5px solid #e5e7eb' }}
          >
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-1">
                <span className="font-semibold" style={{ color: 'var(--navy)' }}>
                  {selectedClient.name}
                </span>
                {selectedClient.isRegular && (
                  <span
                    className="text-xs font-semibold px-2 py-0.5 rounded-full"
                    style={{ background: 'var(--brass)', color: '#fff' }}
                  >
                    Regular
                  </span>
                )}
              </div>
              <p className="text-sm opacity-60">
                {selectedClient.phone}
                {selectedClient.preferredBarberName && (
                  <> &middot; Prefers {selectedClient.preferredBarberName}</>
                )}
              </p>
              <p className="text-sm opacity-60">
                {selectedClient.totalVisits} visit{selectedClient.totalVisits !== 1 ? 's' : ''} &middot; last seen {relativeDate(selectedClient.lastVisitAt)}
              </p>
            </div>
            <button
              type="button"
              onClick={() => {
                setSelectedClient(null);
                setForceNew(false);
                setSearchQuery('');
                setPreferredBarberId('');
              }}
              className="text-xs opacity-50 hover:opacity-80 transition-opacity shrink-0 mt-0.5"
            >
              Change
            </button>
          </div>
        )}

        {/* ── New customer fields ──────────────────────────────────────── */}
        {(isNewForm || (isSearching && !selectedClient && searchQuery.trim().length === 0)) && (
          <>
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

            <div>
              <label className={labelClass} htmlFor="wk-source">
                How did you hear about us?{' '}
                <span className="opacity-40">(optional)</span>
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
          </>
        )}

        {/* ── Shared fields — service + barber ────────────────────────── */}
        {(isReturningConfirm || isNewForm) && (
          <>
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
          </>
        )}
      </form>
    </dialog>
  );
}
