import { requireRole } from "@/lib/auth";
import ServicesBoard from "@/components/dashboard/ServicesBoard";
import { NavHeader } from "@/components/layout/NavHeader";

export const metadata = { title: "Services — Baberia Cuts" };

export default async function ServicesPage() {
  const staff = await requireRole("owner");
  return (
    <div className="min-h-screen bg-zinc-50">
      <NavHeader
        staffId={staff.id}
        staffName={staff.name}
        staffRole={staff.role}
        staffAvatarUrl={staff.avatar_url}
        section="Services"
        links={[
          { href: "/dashboard", label: "Dashboard" },
          { href: "/dashboard/staff", label: "Staff" },
          { href: "/dashboard/services", label: "Services" },
          { href: "/console", label: "Reception" },
          { href: "/me", label: "My day" },
        ]}
      />

      <div className="max-w-4xl mx-auto px-8 py-8">
        <div className="mb-8">
          <h1 className="text-2xl font-semibold text-zinc-900">
            Services &amp; prices
          </h1>
          <p className="text-sm text-zinc-500 mt-1">
            Edit the menu clients and staff use when booking.
          </p>
        </div>

        <p className="text-sm text-zinc-500 mb-4">
          Edit a price or name and hit Save. Deactivating a service hides it
          from booking (online, WhatsApp, and the front desk).
        </p>
        <ServicesBoard />
      </div>
    </div>
  );
}
