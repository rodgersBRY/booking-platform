import { requireRole } from "@/lib/auth";
import { DashboardBoard } from "@/components/dashboard/DashboardBoard";
import { NavHeader } from "@/components/layout/NavHeader";

export const metadata = { title: "Owner dashboard — Baberia Cuts" };

export default async function DashboardPage() {
  const staff = await requireRole("owner");

  return (
    <div className="min-h-screen bg-zinc-50">
      <NavHeader
        staffId={staff.id}
        staffName={staff.name}
        staffRole={staff.role}
        staffAvatarUrl={staff.avatar_url}
        section="Dashboard"
        links={[
          { href: "/dashboard", label: "Dashboard" },
          { href: "/dashboard/staff", label: "Staff" },
          { href: "/dashboard/services", label: "Services" },
          { href: "/console", label: "Reception" },
          { href: "/me", label: "My day" },
        ]}
      />

      <div className="max-w-5xl mx-auto px-8 py-8">
        <div className="mb-8">
          <h1 className="text-2xl font-semibold text-zinc-900">Dashboard</h1>
          <p className="text-sm text-zinc-500 mt-1">
            Today&apos;s shop performance and live operations.
          </p>
        </div>
        <DashboardBoard />
      </div>
    </div>
  );
}
