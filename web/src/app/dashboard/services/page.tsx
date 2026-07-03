import { requireRole } from "@/lib/auth";
import { signOut } from "@/app/login/actions";
import ServicesBoard from "@/components/dashboard/ServicesBoard";

export const metadata = { title: "Services — Barberia Cuts" };

export default async function ServicesPage() {
  const staff = await requireRole("owner");
  return (
    <div className="min-h-screen bg-zinc-50 p-8">
      <div className="max-w-4xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-2xl font-semibold text-zinc-900">Services &amp; prices</h1>
            <p className="text-sm text-zinc-500 mt-1">Signed in as {staff.name} · owner</p>
          </div>
          <div className="flex items-center gap-4">
            <a href="/dashboard" className="text-sm text-zinc-500 hover:text-zinc-900 transition-colors">← Dashboard</a>
            <form action={signOut}>
              <button type="submit" className="text-sm text-zinc-500 hover:text-zinc-900 underline underline-offset-2 transition-colors">Sign out</button>
            </form>
          </div>
        </div>
        <p className="text-sm text-zinc-500 mb-4">
          Edit a price or name and hit Save. Deactivating a service hides it from booking
          (online, WhatsApp, and the front desk) without deleting its history.
        </p>
        <ServicesBoard />
      </div>
    </div>
  );
}
