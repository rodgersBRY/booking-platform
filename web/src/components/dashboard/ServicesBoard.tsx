"use client";

import { useEffect, useState } from "react";
import type { BookableRole, ServiceItem } from "@/lib/api/services";
import {
  fetchAllServices,
  createService,
  updateService,
} from "@/lib/api/services";

const ASSIGNABLE_ROLES: BookableRole[] = ["barber", "beautician", "masseuse"];
const ROLE_LABELS: Record<BookableRole, string> = {
  barber: "Barber",
  beautician: "Beautician",
  masseuse: "Masseuse",
};

type Draft = {
  name: string;
  category: string;
  durationMinutes: string;
  price: string;
  roles: BookableRole[];
};

function toDraft(s: ServiceItem): Draft {
  return {
    name: s.name,
    category: s.category ?? "",
    durationMinutes: String(s.durationMinutes),
    price: String(s.price),
    roles: s.roles,
  };
}

function sameRoles(a: BookableRole[], b: BookableRole[]): boolean {
  if (a.length !== b.length) return false;
  const setB = new Set(b);
  return a.every((r) => setB.has(r));
}

export default function ServicesBoard() {
  const [services, setServices] = useState<ServiceItem[]>([]);
  const [drafts, setDrafts] = useState<Record<string, Draft>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [savingId, setSavingId] = useState<string | null>(null);

  // New-service form.
  const [newName, setNewName] = useState("");
  const [newCategory, setNewCategory] = useState("");
  const [newDuration, setNewDuration] = useState("30");
  const [newPrice, setNewPrice] = useState("");
  const [newRoles, setNewRoles] = useState<BookableRole[]>(["barber"]);
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
    let cancelled = false;

    fetchAllServices()
      .then((data) => {
        if (cancelled) return;
        setServices(data);
        setDrafts(Object.fromEntries(data.map((s) => [s.id, toDraft(s)])));
        setError(null);
      })
      .catch((e: Error) => {
        if (!cancelled) setError(e.message);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, []);

  function isDirty(s: ServiceItem): boolean {
    const d = drafts[s.id];
    if (!d) return false;
    return (
      d.name.trim() !== s.name ||
      (d.category.trim() || null) !== s.category ||
      Number(d.durationMinutes) !== s.durationMinutes ||
      Number(d.price) !== s.price ||
      !sameRoles(d.roles, s.roles)
    );
  }

  function toggleDraftRole(id: string, role: BookableRole) {
    setDrafts((prev) => {
      const current = prev[id];
      if (!current) return prev;
      const has = current.roles.includes(role);
      const roles = has
        ? current.roles.filter((r) => r !== role)
        : [...current.roles, role];
      return { ...prev, [id]: { ...current, roles } };
    });
  }

  function toggleNewRole(role: BookableRole) {
    setNewRoles((prev) =>
      prev.includes(role) ? prev.filter((r) => r !== role) : [...prev, role],
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
    if (d.roles.length === 0)
      return alert("Select at least one assignable role.");
    setSavingId(s.id);
    try {
      await updateService(s.id, {
        name: d.name.trim(),
        category: d.category.trim() || null,
        durationMinutes: duration,
        price,
        roles: d.roles,
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
    if (newRoles.length === 0)
      return alert("Select at least one assignable role.");
    setCreating(true);
    try {
      await createService({
        name: newName.trim(),
        category: newCategory.trim() || undefined,
        durationMinutes: duration,
        price,
        roles: newRoles,
      });
      setNewName("");
      setNewCategory("");
      setNewDuration("30");
      setNewPrice("");
      setNewRoles(["barber"]);
      await load();
    } catch (e) {
      alert((e as Error).message);
    } finally {
      setCreating(false);
    }
  }

  if (loading)
    return (
      <p className="text-sm opacity-40 py-12 text-center">Loading services…</p>
    );
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
      {/* Add new service */}
      <form
        onSubmit={handleCreate}
        className="flex flex-wrap items-end gap-3 p-5 border-t"
        style={{ borderColor: "#f3f4f6" }}
      >
        <div className="flex-1 min-w-45">
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
        <div className="flex-1 min-w-40">
          <label className="block text-xs font-medium opacity-60 mb-1">
            Category
          </label>

          <input
            className={inputCls}
            style={{ borderColor: "#d1d5db" }}
            placeholder="e.g. haircuts"
            value={newCategory}
            onChange={(e) => setNewCategory(e.target.value)}
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
        <div>
          <label className="block text-xs font-medium opacity-60 mb-1">
            Assignable roles
          </label>
          <div className="flex gap-3 py-1.5">
            {ASSIGNABLE_ROLES.map((role) => (
              <label
                key={role}
                className="flex items-center gap-1.5 text-sm cursor-pointer"
              >
                <input
                  type="checkbox"
                  checked={newRoles.includes(role)}
                  onChange={() => toggleNewRole(role)}
                />
                {ROLE_LABELS[role]}
              </label>
            ))}
          </div>
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

      <hr className="text-gray-200" />

      <table className="w-full text-sm">
        <thead>
          <tr className="text-left border-b" style={{ borderColor: "#f3f4f6" }}>
            {[
              "Service",
              "Category",
              "Duration (min)",
              "Price (KES)",
              "Assignable roles",
              "Status",
              "",
            ].map((h) => (
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
                <td className="px-5 py-3">
                  <input
                    className={inputCls}
                    style={{ borderColor: "#d1d5db" }}
                    value={d.category}
                    onChange={(e) =>
                      editDraft(s.id, { category: e.target.value })
                    }
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
                  <div className="flex gap-2.5">
                    {ASSIGNABLE_ROLES.map((role) => (
                      <label
                        key={role}
                        className="flex items-center gap-1 text-xs cursor-pointer opacity-80"
                      >
                        <input
                          type="checkbox"
                          checked={d.roles.includes(role)}
                          onChange={() => toggleDraftRole(s.id, role)}
                        />
                        {ROLE_LABELS[role]}
                      </label>
                    ))}
                  </div>
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
              <td colSpan={7} className="px-5 py-8 text-center opacity-40">
                No services yet.
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
