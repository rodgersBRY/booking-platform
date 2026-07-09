export interface StaffListItem {
  id: string;
  name: string;
  role: "owner" | "receptionist" | "barber" | "beautician" | "masseuse";
  email: string | null;
  phone: string | null;
  status: "active" | "inactive" | "blocked";
  authUserId: string | null;
  avatarUrl: string | null;
  createdAt: string;
}

async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(path, init);
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    const b = body as { error?: string; message?: string };
    const err = new Error(
      b.message ?? b.error ?? "Something went wrong. Please try again.",
    );
    (err as Error & { status: number }).status = res.status;
    throw err;
  }
  return res.json() as Promise<T>;
}

export async function fetchStaff(): Promise<StaffListItem[]> {
  const data = await apiFetch<{ staff: StaffListItem[] }>("/api/staff");
  return data.staff;
}

export async function createStaff(p: {
  name: string; role: string; email: string; phone?: string; password: string;
}): Promise<StaffListItem> {
  const data = await apiFetch<{ staff: StaffListItem }>("/api/staff", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(p),
  });
  return data.staff;
}

export async function setStaffStatus(id: string, status: "active" | "inactive"): Promise<void> {
  await apiFetch(`/api/staff/${id}`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ action: "setStatus", status }),
  });
}

export async function resetStaffPassword(id: string, password: string): Promise<void> {
  await apiFetch(`/api/staff/${id}`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ action: "resetPassword", password }),
  });
}

export async function uploadStaffAvatar(id: string, file: File): Promise<string> {
  const formData = new FormData();
  formData.append("file", file);
  const data = await apiFetch<{ avatarUrl: string }>(`/api/staff/${id}/avatar`, {
    method: "POST",
    body: formData,
  });
  return data.avatarUrl;
}
