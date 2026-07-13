"use client";

import { useState } from "react";

// ── Types ──────────────────────────────────────────────────────────────────

interface Service {
  id: string;
  name: string;
  durationMinutes: number;
  price: number;
}

type StaffRole = "barber" | "beautician" | "masseuse";

interface Barber {
  id: string;
  name: string;
  role: StaffRole;
  avatarUrl: string | null;
}

const ROLE_LABELS: Record<StaffRole, string> = {
  barber: "barber",
  beautician: "beautician",
  masseuse: "masseuse",
};

/** "Any barber" if the service maps to a single role, else a generic label. */
function anyLabel(roles: StaffRole[]): string {
  if (roles.length === 1) return `Any ${ROLE_LABELS[roles[0]]}`;
  return "Any available staff";
}

interface Slot {
  start: string;
  end: string;
  label: string;
  staffId: string;
}

interface BookingConfirmation {
  staffName: string;
  serviceName: string;
  date: string;
  timeLabel: string;
}

type Step = 1 | 2 | 3 | 4;

// ── Helpers ────────────────────────────────────────────────────────────────

function formatPrice(price: number): string {
  return `KSh ${Math.round(price).toLocaleString()}`;
}

function initials(name: string): string {
  return name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]!.toUpperCase())
    .join("");
}

function formatDuration(minutes: number): string {
  if (minutes < 60) return `${minutes} min`;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return m > 0 ? `${h} hr ${m} min` : `${h} hr`;
}

/** Generate the next N calendar dates as YYYY-MM-DD strings, starting today. */
function getNextDates(count: number): string[] {
  const dates: string[] = [];
  const now = new Date();
  for (let i = 0; i < count; i++) {
    const d = new Date(now);
    d.setDate(now.getDate() + i);
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, "0");
    const day = String(d.getDate()).padStart(2, "0");
    dates.push(`${y}-${m}-${day}`);
  }
  return dates;
}

function friendlyDate(dateStr: string): string {
  // Parse without timezone shift.
  const [y, m, d] = dateStr.split("-").map(Number);
  const date = new Date(y, m - 1, d);
  return date.toLocaleDateString("en-KE", {
    weekday: "long",
    day: "numeric",
    month: "long",
  });
}

// ── Step indicator ────────────────────────────────────────────────────────

function StepIndicator({ current }: { current: Step }) {
  const steps = ["Service", "Specialist", "Date & time", "Your details"];
  return (
    <div className="flex items-center gap-1 mb-8">
      {steps.map((label, i) => {
        const num = (i + 1) as Step;
        const done = num < current;
        const active = num === current;
        return (
          <div key={label} className="flex items-center gap-1 flex-1">
            <div className="flex flex-col items-center flex-1">
              <div
                className="w-8 h-8 rounded-full flex items-center justify-center text-sm font-semibold"
                style={{
                  background: done || active ? "var(--brass)" : "var(--canvas)",
                  color: done || active ? "#fff" : "var(--navy)",
                  border: `2px solid ${done || active ? "var(--brass)" : "#c9cdd6"}`,
                }}
              >
                {done ? "✓" : num}
              </div>
              <span
                className="text-xs mt-1 text-center leading-tight"
                style={{ color: active ? "var(--brass)" : "#6b7280" }}
              >
                {label}
              </span>
            </div>
            {i < steps.length - 1 && (
              <div
                className="h-px flex-1 mb-5"
                style={{
                  background: done ? "var(--brass)" : "#c9cdd6",
                }}
              />
            )}
          </div>
        );
      })}
    </div>
  );
}

// ── Step 1: Pick service ───────────────────────────────────────────────────

function ServiceStep({
  services,
  selected,
  onSelect,
}: {
  services: Service[];
  selected: Service | null;
  onSelect: (s: Service) => void;
}) {
  return (
    <div>
      <h2 className="text-xl font-semibold mb-1" style={{ color: "var(--navy)" }}>
        What would you like?
      </h2>
      <p className="text-sm mb-5" style={{ color: "#6b7280" }}>
        Pick a service to get started.
      </p>
      <div className="flex flex-col gap-3">
        {services.map((s) => {
          const isSelected = selected?.id === s.id;
          return (
            <button
              key={s.id}
              onClick={() => onSelect(s)}
              className="w-full text-left rounded-xl p-4 border-2 transition-all"
              style={{
                borderColor: isSelected ? "var(--brass)" : "#e5e7eb",
                background: isSelected ? "#fffbf2" : "var(--card)",
                boxShadow: isSelected
                  ? "0 0 0 1px var(--brass)"
                  : "0 1px 3px rgba(0,0,0,0.06)",
              }}
            >
              <div className="flex justify-between items-start">
                <span className="font-medium" style={{ color: "var(--navy)" }}>
                  {s.name}
                </span>
                <span
                  className="text-sm font-semibold ml-3 shrink-0"
                  style={{ color: "var(--brass)" }}
                >
                  {formatPrice(s.price)}
                </span>
              </div>
              <span className="text-xs" style={{ color: "#9ca3af" }}>
                {formatDuration(s.durationMinutes)}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ── Step 2: Pick barber ────────────────────────────────────────────────────

function StaffStep({
  barbers,
  anyOptionLabel,
  selected,
  onSelect,
}: {
  barbers: Barber[];
  anyOptionLabel: string;
  selected: string | "any" | null;
  onSelect: (id: string | "any") => void;
}) {
  const options: Array<{
    id: string | "any";
    name: string;
    sub: string;
    avatarUrl: string | null;
  }> = [
    { id: "any", name: anyOptionLabel, sub: "We'll pick whoever is free", avatarUrl: null },
    ...barbers.map((b) => ({
      id: b.id,
      name: b.name,
      sub: ROLE_LABELS[b.role][0].toUpperCase() + ROLE_LABELS[b.role].slice(1),
      avatarUrl: b.avatarUrl,
    })),
  ];

  return (
    <div>
      <h2 className="text-xl font-semibold mb-1" style={{ color: "var(--navy)" }}>
        Who would you like?
      </h2>
      <p className="text-sm mb-5" style={{ color: "#6b7280" }}>
        Pick a specialist or let us choose for you.
      </p>
      <div className="flex flex-col gap-3">
        {options.map((o) => {
          const isSelected = selected === o.id;
          return (
            <button
              key={o.id}
              onClick={() => onSelect(o.id)}
              className="w-full text-left rounded-xl p-4 border-2 transition-all"
              style={{
                borderColor: isSelected ? "var(--brass)" : "#e5e7eb",
                background: isSelected ? "#fffbf2" : "var(--card)",
                boxShadow: isSelected
                  ? "0 0 0 1px var(--brass)"
                  : "0 1px 3px rgba(0,0,0,0.06)",
              }}
            >
              <div className="flex items-center gap-3">
                <div
                  className="w-10 h-10 rounded-full overflow-hidden shrink-0 flex items-center justify-center text-xs font-semibold"
                  style={
                    o.avatarUrl
                      ? undefined
                      : { background: "var(--navy)", color: "#fff" }
                  }
                >
                  {o.avatarUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={o.avatarUrl}
                      alt={o.name}
                      className="w-full h-full object-cover"
                    />
                  ) : o.id === "any" ? (
                    "?"
                  ) : (
                    initials(o.name)
                  )}
                </div>
                <div>
                  <div className="font-medium" style={{ color: "var(--navy)" }}>
                    {o.name}
                  </div>
                  <div className="text-xs" style={{ color: "#9ca3af" }}>
                    {o.sub}
                  </div>
                </div>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ── Step 3: Pick date + slot ───────────────────────────────────────────────

function DateSlotStep({
  serviceId,
  staffId,
  selectedSlot,
  onSelect,
}: {
  serviceId: string;
  staffId: string | "any";
  selectedSlot: Slot | null;
  onSelect: (slot: Slot) => void;
}) {
  const dates = getNextDates(14);
  const [activeDate, setActiveDate] = useState(dates[0]);
  const [slots, setSlots] = useState<Slot[] | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function loadSlots(date: string) {
    setActiveDate(date);
    setSlots(null);
    setError(null);
    setLoading(true);
    try {
      const res = await fetch(
        `/api/v1/public/availability?staff=${encodeURIComponent(staffId)}&service=${encodeURIComponent(serviceId)}&date=${date}`,
      );
      if (!res.ok) {
        setError("Couldn't load times. Please try again.");
        return;
      }
      const data = await res.json();
      setSlots(data.slots ?? []);
    } catch {
      setError("Couldn't load times. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  // Load initial date on first render.
  if (slots === null && !loading && !error) {
    loadSlots(dates[0]);
  }

  return (
    <div>
      <h2 className="text-xl font-semibold mb-1" style={{ color: "var(--navy)" }}>
        Pick a date and time
      </h2>
      <p className="text-sm mb-4" style={{ color: "#6b7280" }}>
        Choose a day, then a slot that works for you.
      </p>

      {/* Date strip */}
      <div className="flex gap-2 overflow-x-auto pb-2 mb-5 -mx-1 px-1">
        {dates.map((d) => {
          const [, , day] = d.split("-");
          const [yy, mm] = d.split("-");
          const dateObj = new Date(Number(yy), Number(mm) - 1, Number(day));
          const weekday = dateObj.toLocaleDateString("en-KE", { weekday: "short" });
          const isActive = d === activeDate;
          return (
            <button
              key={d}
              onClick={() => loadSlots(d)}
              className="flex flex-col items-center shrink-0 rounded-xl px-3 py-2 border-2 min-w-[52px] transition-all"
              style={{
                borderColor: isActive ? "var(--brass)" : "#e5e7eb",
                background: isActive ? "var(--brass)" : "var(--card)",
                color: isActive ? "#fff" : "var(--navy)",
              }}
            >
              <span className="text-xs">{weekday}</span>
              <span className="text-base font-bold leading-tight">{day}</span>
            </button>
          );
        })}
      </div>

      {/* Slots */}
      {loading && (
        <p className="text-sm text-center py-6" style={{ color: "#9ca3af" }}>
          Loading times…
        </p>
      )}
      {error && (
        <p className="text-sm text-center py-4" style={{ color: "var(--late)" }}>
          {error}
        </p>
      )}
      {!loading && !error && slots !== null && slots.length === 0 && (
        <p className="text-sm text-center py-6" style={{ color: "#9ca3af" }}>
          No times left on that day — try another date.
        </p>
      )}
      {!loading && !error && slots !== null && slots.length > 0 && (
        <div className="grid grid-cols-3 gap-2">
          {slots.map((slot) => {
            const isSelected = selectedSlot?.start === slot.start;
            return (
              <button
                key={slot.start}
                onClick={() => onSelect(slot)}
                className="rounded-xl py-2 px-1 text-sm font-medium border-2 transition-all"
                style={{
                  borderColor: isSelected ? "var(--brass)" : "#e5e7eb",
                  background: isSelected ? "var(--brass)" : "var(--card)",
                  color: isSelected ? "#fff" : "var(--navy)",
                  boxShadow: isSelected ? "0 0 0 1px var(--brass)" : undefined,
                }}
              >
                {slot.label}
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}

// ── Step 4: Enter details ──────────────────────────────────────────────────

function DetailsStep({
  name,
  phone,
  onChange,
}: {
  name: string;
  phone: string;
  onChange: (field: "name" | "phone", value: string) => void;
}) {
  return (
    <div>
      <h2 className="text-xl font-semibold mb-1" style={{ color: "var(--navy)" }}>
        Your details
      </h2>
      <p className="text-sm mb-5" style={{ color: "#6b7280" }}>
        We&apos;ll send your booking confirmation to this number.
      </p>
      <div className="flex flex-col gap-4">
        <div>
          <label
            className="block text-sm font-medium mb-1"
            style={{ color: "var(--navy)" }}
          >
            First name
          </label>
          <input
            type="text"
            value={name}
            onChange={(e) => onChange("name", e.target.value)}
            placeholder="James"
            className="w-full rounded-xl px-4 py-3 border-2 text-sm outline-none transition-all"
            style={{
              borderColor: "#e5e7eb",
              color: "var(--navy)",
              background: "var(--card)",
            }}
            onFocus={(e) =>
              (e.currentTarget.style.borderColor = "var(--brass)")
            }
            onBlur={(e) => (e.currentTarget.style.borderColor = "#e5e7eb")}
          />
        </div>
        <div>
          <label
            className="block text-sm font-medium mb-1"
            style={{ color: "var(--navy)" }}
          >
            Phone number
          </label>
          <input
            type="tel"
            value={phone}
            onChange={(e) => onChange("phone", e.target.value)}
            placeholder="07XX XXX XXX"
            className="w-full rounded-xl px-4 py-3 border-2 text-sm outline-none transition-all"
            style={{
              borderColor: "#e5e7eb",
              color: "var(--navy)",
              background: "var(--card)",
            }}
            onFocus={(e) =>
              (e.currentTarget.style.borderColor = "var(--brass)")
            }
            onBlur={(e) => (e.currentTarget.style.borderColor = "#e5e7eb")}
          />
        </div>
      </div>
    </div>
  );
}

// ── Confirmation screen ────────────────────────────────────────────────────

function ConfirmationScreen({ confirmation }: { confirmation: BookingConfirmation }) {
  return (
    <div className="text-center py-8">
      <div
        className="w-16 h-16 rounded-full flex items-center justify-center text-3xl mx-auto mb-5"
        style={{ background: "#dcfce7" }}
      >
        ✓
      </div>
      <h2 className="text-2xl font-bold mb-2" style={{ color: "var(--navy)" }}>
        You&apos;re booked!
      </h2>
      <p className="text-sm mb-6" style={{ color: "#6b7280" }}>
        We&apos;ll send a reminder before your appointment.
      </p>
      <div
        className="rounded-2xl p-5 text-left space-y-3"
        style={{ background: "var(--card)", border: "1px solid #e5e7eb" }}
      >
        <div className="flex justify-between">
          <span className="text-sm" style={{ color: "#6b7280" }}>
            Service
          </span>
          <span className="text-sm font-medium" style={{ color: "var(--navy)" }}>
            {confirmation.serviceName}
          </span>
        </div>
        <div className="flex justify-between">
          <span className="text-sm" style={{ color: "#6b7280" }}>
            With
          </span>
          <span className="text-sm font-medium" style={{ color: "var(--navy)" }}>
            {confirmation.staffName}
          </span>
        </div>
        <div className="flex justify-between">
          <span className="text-sm" style={{ color: "#6b7280" }}>
            Date
          </span>
          <span className="text-sm font-medium" style={{ color: "var(--navy)" }}>
            {confirmation.date}
          </span>
        </div>
        <div className="flex justify-between">
          <span className="text-sm" style={{ color: "#6b7280" }}>
            Time
          </span>
          <span className="text-sm font-medium" style={{ color: "var(--navy)" }}>
            {confirmation.timeLabel}
          </span>
        </div>
      </div>
    </div>
  );
}

// ── Main flow component ────────────────────────────────────────────────────

interface BookingFlowProps {
  services: Service[];
  staff: Barber[];
  /** serviceId -> roles eligible to perform it */
  serviceRoles: Record<string, StaffRole[]>;
}

export default function BookingFlow({
  services,
  staff,
  serviceRoles,
}: BookingFlowProps) {
  const [step, setStep] = useState<Step>(1);
  const [selectedService, setSelectedService] = useState<Service | null>(null);
  const [selectedStaffId, setSelectedStaffId] = useState<string | "any" | null>(null);
  const [selectedSlot, setSelectedSlot] = useState<Slot | null>(null);
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [slotTakenSlots, setSlotTakenSlots] = useState<Slot[] | null>(null);
  const [confirmation, setConfirmation] = useState<BookingConfirmation | null>(null);

  const eligibleRoles = selectedService
    ? serviceRoles[selectedService.id] ?? []
    : [];
  const eligibleStaff = staff.filter((s) => eligibleRoles.includes(s.role));

  function canAdvance(): boolean {
    if (step === 1) return selectedService !== null;
    if (step === 2) return selectedStaffId !== null;
    if (step === 3) return selectedSlot !== null;
    if (step === 4) return name.trim().length > 0 && phone.trim().length > 0;
    return false;
  }

  async function handleSubmit() {
    if (!selectedService || !selectedStaffId || !selectedSlot) return;
    setSubmitting(true);
    setSubmitError(null);
    setSlotTakenSlots(null);

    // The slot always carries a concrete staffId (even in "any" mode).
    const concreteStaffId = selectedSlot.staffId;

    try {
      const res = await fetch("/api/v1/public/bookings", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          client: { name: name.trim(), phone: phone.trim() },
          staffId: concreteStaffId,
          serviceId: selectedService.id,
          scheduledStart: selectedSlot.start,
        }),
      });

      const data = await res.json();

      if (res.status === 409 && data.error === "slot_taken") {
        setSubmitError(
          "Sorry, that time was just taken. Pick another slot below.",
        );
        setSlotTakenSlots(data.slots ?? []);
        return;
      }

      if (!res.ok) {
        setSubmitError(data.error ?? "Something went wrong. Please try again.");
        return;
      }

      // Success — find the staff name for the confirmation screen.
      const staffName =
        staff.find((b) => b.id === concreteStaffId)?.name ?? "Your barber";

      setConfirmation({
        staffName,
        serviceName: selectedService.name,
        date: friendlyDate(selectedSlot.start.slice(0, 10)),
        timeLabel: selectedSlot.label,
      });
    } catch {
      setSubmitError("Something went wrong. Please try again.");
    } finally {
      setSubmitting(false);
    }
  }

  if (confirmation) {
    return <ConfirmationScreen confirmation={confirmation} />;
  }

  return (
    <div>
      <StepIndicator current={step} />

      {step === 1 && (
        <ServiceStep
          services={services}
          selected={selectedService}
          onSelect={(s) => {
            setSelectedService(s);
            setSelectedStaffId(null);
          }}
        />
      )}

      {step === 2 && (
        <StaffStep
          barbers={eligibleStaff}
          anyOptionLabel={anyLabel(eligibleRoles)}
          selected={selectedStaffId}
          onSelect={(id) => setSelectedStaffId(id)}
        />
      )}

      {step === 3 && selectedService && selectedStaffId && (
        <DateSlotStep
          serviceId={selectedService.id}
          staffId={selectedStaffId}
          selectedSlot={selectedSlot}
          onSelect={(slot) => {
            setSelectedSlot(slot);
            setSlotTakenSlots(null);
            setSubmitError(null);
          }}
        />
      )}

      {step === 4 && (
        <DetailsStep
          name={name}
          phone={phone}
          onChange={(field, value) => {
            if (field === "name") setName(value);
            else setPhone(value);
          }}
        />
      )}

      {/* Slot-taken refresh */}
      {slotTakenSlots !== null && step === 4 && (
        <div className="mt-4">
          <p className="text-sm font-medium mb-2" style={{ color: "var(--late)" }}>
            Pick a new time:
          </p>
          {slotTakenSlots.length === 0 ? (
            <p className="text-sm" style={{ color: "#9ca3af" }}>
              No times left on that day — go back and try another date.
            </p>
          ) : (
            <div className="grid grid-cols-3 gap-2">
              {slotTakenSlots.map((slot) => {
                const isSelected = selectedSlot?.start === slot.start;
                return (
                  <button
                    key={slot.start}
                    onClick={() => {
                      setSelectedSlot(slot);
                      setSlotTakenSlots(null);
                      setSubmitError(null);
                    }}
                    className="rounded-xl py-2 px-1 text-sm font-medium border-2 transition-all"
                    style={{
                      borderColor: isSelected ? "var(--brass)" : "#e5e7eb",
                      background: isSelected ? "var(--brass)" : "var(--card)",
                      color: isSelected ? "#fff" : "var(--navy)",
                    }}
                  >
                    {slot.label}
                  </button>
                );
              })}
            </div>
          )}
        </div>
      )}

      {submitError && !slotTakenSlots && (
        <p
          className="text-sm mt-4 p-3 rounded-lg"
          style={{ background: "#fee2e2", color: "var(--late)" }}
        >
          {submitError}
        </p>
      )}
      {submitError && slotTakenSlots && (
        <p className="text-sm mt-2" style={{ color: "var(--late)" }}>
          {submitError}
        </p>
      )}

      {/* Navigation */}
      <div className="flex gap-3 mt-8">
        {step > 1 && (
          <button
            onClick={() => setStep((s) => (s - 1) as Step)}
            className="flex-1 py-3 rounded-xl border-2 font-medium text-sm transition-all"
            style={{
              borderColor: "#e5e7eb",
              color: "var(--navy)",
              background: "var(--card)",
            }}
          >
            Back
          </button>
        )}

        {step < 4 && (
          <button
            onClick={() => setStep((s) => (s + 1) as Step)}
            disabled={!canAdvance()}
            className="flex-1 py-3 rounded-xl font-semibold text-sm transition-all"
            style={{
              background: canAdvance() ? "var(--navy)" : "#c9cdd6",
              color: "#fff",
              cursor: canAdvance() ? "pointer" : "default",
            }}
          >
            Continue
          </button>
        )}

        {step === 4 && (
          <button
            onClick={handleSubmit}
            disabled={!canAdvance() || submitting}
            className="flex-1 py-3 rounded-xl font-semibold text-sm transition-all"
            style={{
              background:
                canAdvance() && !submitting ? "var(--brass)" : "#c9cdd6",
              color: "#fff",
              cursor: canAdvance() && !submitting ? "pointer" : "default",
            }}
          >
            {submitting ? "Booking…" : "Confirm booking"}
          </button>
        )}
      </div>
    </div>
  );
}
