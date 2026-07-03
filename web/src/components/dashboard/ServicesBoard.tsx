"use client";

import { useEffect, useState } from "react";
import type { ServiceItem } from "@/lib/api/services";
import {
  fetchAllServices,
  createService,
  updateService,
} from "@/lib/api/services";

type Draft = { name: string; durationMinutes: string; price: string };

function toDraft(s: ServiceItem): Draft {
  return {
    name: s.name,
    durationMinutes: String(s.durationMinutes),
    price: String(s.price),
  };
}

export default function ServicesBoard() {
  const [services, setServices] = useState<ServiceItem[]>([]);
  const [drafts, setDrafts] = useState<Record<string, Draft>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [savingId, setSavingId] = useState<string | null>(null);

  // New-service form.
  const [newName, setNewName] = useState("");
  const [newDuration, setNewDuration] = useState("30");
  const [newPrice, setNewPrice] = useState("");
  const [creating, setCreating] = useState(false);

  async function load() {
    try {
      const data = await fetchAllServices();
      setServices(data);
      setDrafts(Object.fromEntries(data.map((s) => [s.id, toDraft(s)])));
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  function isDirty(s: ServiceItem): boolean {
    const d = drafts[s.id];
    if (!d) return false;
    return (
      d.name.trim() !== s.name ||
      Number(d.durationMinutes) !== s.durationMinutes ||
      Number(d.price) !== s.price
    );
  }

  function editDraft(id: string, patch: Partial<Draft>) {
    setDrafts((prev) => ({ ...prev, [id]: { ...prev[id], ...patch } }));
  }

  async function handleSave(s: ServiceItem) {
    const d = drafts[s.id];
    const duration = Number(d.durationMinutes);
    const price = Number(d.price);
    if (!d.name.trim()) return alert("Name cannot be empty.");
    if (!Number.isFinite(duration) || duration <= 0)
      return alert("Duration must be a positive number of minutes.");
    if (!Number.isFinite(price) || price < 0)
      return alert("Price must be zero or more.");
    setSavingId(s.id);
    try {
      await updateService(s.id, {
        name: d.name.trim(),
        durationMinutes: duration,
        price,
      });
      await load();
    } catch (e) {
      alert((e as Error).message);
    } finally {
      setSavingId(null);
    }
  }

  async function handleToggleActive(s: ServiceItem) {
    setSavingId(s.id);
    try {
      await updateService(s.id, { active: !s.active });
      await load();
    } catch (e) {
      alert((e as Error).message);
    } finally {
      setSavingId(null);
    }
  }

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    const duration = Number(newDuration);
    const price = Number(newPrice);
    if (!newName.trim()) return alert("Name is required.");
    if (!Number.isFinite(duration) || duration <= 0)
      return alert("Duration must be a positive number of minutes.");
    if (!Number.isFinite(price) || price < 0)
      return alert("Price must be zero or more.");
    setCreating(true);
    try {
      await createService({
        name: newName.trim(),
        durationMinutes: duration,
        price,
      });
      setNewName("");
      setNewDuration("30");
      setNewPrice("");
      await load();
    } catch (e) {
      alert((e as Error).message);
    } finally {
      setCreating(false);
    }
  }

  if (loading)
    return <p className="text-sm opacity-40 py-12 text-center">Loading services…</p>;
  if (error)
    return (
      <p className="text-sm py-12 text-center" style={{ color: "var(--late)" }}>
        {error}
      </p>
    );

  const inputCls =
    "w-full px-2.5 py-1.5 rounded-lg border text-sm bg-white focus:outline-none focus:ring-2";

  return (
    <div
      className="rounded-2xl shadow-sm overflow-hidden"
      style={{ background: "var(--card, #fff)" }}
    >
      <table className="w-full text-sm">
        <thead>
          <tr className="text-left border-b" style={{ borderColor: "#f3f4f6" }}>
            {["Service", "Duration (min)", "Price (KES)", "Status", ""].map((h) => (
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
          {services.map((s) => {
            const d = drafts[s.id] ?? toDraft(s);
            const dirty = isDirty(s);
            const busy = savingId === s.id;
            return (
              <tr
                key={s.id}
                className="border-b last:border-0"
                style={{
                  borderColor: "#f9fafb",
                  opacity: s.active ? 1 : 0.55,
                }}
              >
                <td className="px-5 py-3">
                  <input
                    className={inputCls}
                    style={{ borderColor: "#d1d5db" }}
                    value={d.name}
                    onChange={(e) => editDraft(s.id, { name: e.target.value })}
                  />
                </td>
                <td className="px-5 py-3" style={{ width: 120 }}>
                  <input
                    type="number"
                    min={1}
                    className={inputCls}
                    style={{ borderColor: "#d1d5db" }}
                    value={d.durationMinutes}
                    onChange={(e) =>
                      editDraft(s.id, { durationMinutes: e.target.value })
                    }
                  />
                </td>
                <td className="px-5 py-3" style={{ width: 140 }}>
                  <input
                    type="number"
                    min={0}
                    step="50"
                    className={inputCls}
                    style={{ borderColor: "#d1d5db" }}
                    value={d.price}
                    onChange={(e) => editDraft(s.id, { price: e.target.value })}
                  />
                </td>
                <td className="px-5 py-3">
                  <button
                    onClick={() => handleToggleActive(s)}
                    disabled={busy}
                    className="px-2.5 py-1 rounded-full text-xs font-semibold transition-opacity hover:opacity-80 disabled:opacity-50"
                    style={
                      s.active
                        ? { background: "var(--free)", color: "#fff" }
                        : { background: "#e4e4e7", color: "#6b7280" }
                    }
                  >
                    {s.active ? "Active" : "Inactive"}
                  </button>
                </td>
                <td className="px-5 py-3 text-right" style={{ width: 110 }}>
                  <button
                    onClick={() => handleSave(s)}
                    disabled={!dirty || busy}
                    className="text-xs px-3 py-1.5 rounded-lg font-semibold transition-opacity hover:opacity-90 disabled:opacity-30"
                    style={{ background: "var(--brass)", color: "#fff" }}
                  >
                    {busy ? "Saving…" : "Save"}
                  </button>
                </td>
              </tr>
            );
          })}
          {services.length === 0 && (
            <tr>
              <td colSpan={5} className="px-5 py-8 text-center opacity-40">
                No services yet.
              </td>
            </tr>
          )}
        </tbody>
      </table>

      {/* Add new service */}
      <form
        onSubmit={handleCreate}
        className="flex flex-wrap items-end gap-3 p-5 border-t"
        style={{ borderColor: "#f3f4f6" }}
      >
        <div className="flex-1 min-w-[180px]">
          <label className="block text-xs font-medium opacity-60 mb-1">
            New service name
          </label>
          <input
            className={inputCls}
            style={{ borderColor: "#d1d5db" }}
            placeholder="e.g. Kids Haircut"
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
          />
        </div>
        <div style={{ width: 120 }}>
          <label className="block text-xs font-medium opacity-60 mb-1">
            Duration (min)
          </label>
          <input
            type="number"
            min={1}
            className={inputCls}
            style={{ borderColor: "#d1d5db" }}
            value={newDuration}
            onChange={(e) => setNewDuration(e.target.value)}
          />
        </div>
        <div style={{ width: 140 }}>
          <label className="block text-xs font-medium opacity-60 mb-1">
            Price (KES)
          </label>
          <input
            type="number"
            min={0}
            step="50"
            className={inputCls}
            style={{ borderColor: "#d1d5db" }}
            placeholder="0"
            value={newPrice}
            onChange={(e) => setNewPrice(e.target.value)}
          />
        </div>
        <button
          type="submit"
          disabled={creating}
          className="px-6 py-2 rounded-xl text-sm font-semibold transition-opacity hover:opacity-90 disabled:opacity-50"
          style={{ background: "var(--navy)", color: "#fff" }}
        >
          {creating ? "Adding…" : "+ Add service"}
        </button>
      </form>
    </div>
  );
}
