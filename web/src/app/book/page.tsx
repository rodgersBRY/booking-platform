import { createAdminClient } from "@/lib/supabase/admin";
import { BOOKABLE_ROLES } from "@/lib/staff/roles";
import BookingFlow from "@/components/book/BookingFlow";

export const metadata = {
  title: "Book an appointment",
  description: "Book your barbershop appointment online — quick, easy, free.",
};

// Narrowed to the roles BOOKABLE_ROLES/service_roles ever actually contain —
// BookingFlow's props don't need the full StaffRole union (owner/receptionist
// never appear here).
type BookableStaffRole = "barber" | "beautician" | "masseuse";

async function getServicesAndStaff() {
  const admin = createAdminClient();

  const [{ data: servicesRaw }, { data: staffRaw }] = await Promise.all([
    admin
      .from("services")
      .select("id, name, category, duration_minutes, price")
      .eq("active", true)
      .order("category")
      .order("name"),
    admin
      .from("staff")
      .select("id, name, role, avatar_url")
      .in("role", BOOKABLE_ROLES)
      .eq("status", "active")
      .order("name"),
  ]);

  const services = (servicesRaw ?? []).map(
    (s: {
      id: string;
      name: string;
      category: string | null;
      duration_minutes: number;
      price: number;
    }) => ({
      id: s.id,
      name: s.name,
      category: s.category,
      durationMinutes: s.duration_minutes,
      price: s.price,
    }),
  );

  const staff = (staffRaw ?? []).map(
    (s: { id: string; name: string; role: string; avatar_url: string | null }) => ({
      id: s.id,
      name: s.name,
      role: s.role as BookableStaffRole,
      avatarUrl: s.avatar_url,
    }),
  );

  const serviceIds = services.map((s) => s.id);
  const serviceRoles: Record<string, BookableStaffRole[]> = {};
  if (serviceIds.length > 0) {
    const { data: roleRows } = await admin
      .from("service_roles")
      .select("service_id, role")
      .in("service_id", serviceIds);
    for (const r of roleRows ?? []) {
      const list = serviceRoles[r.service_id as string] ?? [];
      list.push(r.role as BookableStaffRole);
      serviceRoles[r.service_id as string] = list;
    }
  }

  return { services, staff, serviceRoles };
}

export default async function BookPage() {
  const { services, staff, serviceRoles } = await getServicesAndStaff();

  return (
    <main
      className="min-h-screen flex flex-col items-center justify-start py-8 px-4"
      style={{ background: "var(--canvas)" }}
    >
      {/* Header */}
      <div className="w-full max-w-md mb-6 text-center">
        <div
          className="inline-flex items-center gap-2 mb-3"
          style={{ color: "var(--brass)" }}
        >
          <span className="text-2xl">✂</span>
          <span
            className="text-lg font-bold tracking-wide"
            style={{ color: "var(--navy)" }}
          >
            Barberia Cuts
          </span>
        </div>
        <h1 className="text-2xl font-bold" style={{ color: "var(--navy)" }}>
          Book an appointment
        </h1>
        <p className="text-sm mt-1" style={{ color: "#6b7280" }}>
          Takes less than a minute.
        </p>
      </div>

      {/* Card */}
      <div
        className="w-full max-w-md rounded-2xl p-6 shadow-sm"
        style={{ background: "var(--card)" }}
      >
        {services.length === 0 ? (
          <p className="text-center py-8 text-sm" style={{ color: "#9ca3af" }}>
            No services available right now. Please call us to book.
          </p>
        ) : (
          <BookingFlow services={services} staff={staff} serviceRoles={serviceRoles} />
        )}
      </div>

      {/* Footer */}
      <p className="text-xs mt-6" style={{ color: "#9ca3af" }}>
        Need help? Call us directly.
      </p>
    </main>
  );
}
