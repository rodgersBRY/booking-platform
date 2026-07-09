import { requireRole } from "@/lib/auth";
import { BOOKABLE_ROLES } from "@/lib/staff/roles";
import MyDayBoard from "@/components/me/MyDayBoard";
import { NavHeader } from "@/components/layout/NavHeader";

export const metadata = { title: "My day — Baberia Cuts" };

export default async function MePage() {
  const staff = await requireRole("owner", ...BOOKABLE_ROLES);

  return (
    <div className="min-h-screen bg-zinc-50">
      <NavHeader
        staffId={staff.id}
        staffName={staff.name}
        staffRole={staff.role}
        staffAvatarUrl={staff.avatar_url}
        section="My day"
        links={
          staff.role === "owner"
            ? [
                { href: "/dashboard", label: "Dashboard" },
                { href: "/dashboard/staff", label: "Staff" },
                { href: "/dashboard/services", label: "Services" },
                { href: "/console", label: "Reception" },
                { href: "/me", label: "My day" },
              ]
            : [{ href: "/me", label: "My day" }]
        }
      />

      <div className="max-w-2xl mx-auto px-8 py-8">
        <div className="mb-8">
          <h1 className="text-2xl font-semibold text-zinc-900">My day</h1>
          <p className="text-sm text-zinc-500 mt-1">
            Your assigned appointments and current chair.
          </p>
        </div>
        <MyDayBoard staffId={staff.id} />
      </div>
    </div>
  );
}
