import { requireRole } from "@/lib/auth";
import { signOut } from "@/app/login/actions";
import StaffBoard from "@/components/dashboard/StaffBoard";
import { DashboardSignoutButtons } from "@/components/dashboard/DashboardSignoutButtons";

export const metadata = { title: "Staff — Barberia Cuts" };

export default async function StaffPage() {
  const staff = await requireRole("owner");
  return (
    <div className="min-h-screen bg-zinc-50 p-8">
      <div className="max-w-4xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-2xl font-semibold text-zinc-900">Staff</h1>
            <p className="text-sm text-zinc-500 mt-1">
              Signed in as {staff.name} · owner
            </p>
          </div>

          <DashboardSignoutButtons signOut={signOut} />
        </div>
        <StaffBoard />
      </div>
    </div>
  );
}
