import { createAdminClient } from "@/lib/supabase/admin";
import BookingFlow from "@/components/book/BookingFlow";

export const metadata = {
  title: "Book an appointment",
  description: "Book your barbershop appointment online — quick, easy, free.",
};

async function getServicesAndBarbers() {
  const admin = createAdminClient();

  const [{ data: servicesRaw }, { data: barbersRaw }] = await Promise.all([
    admin
      .from("services")
      .select("id, name, duration_minutes, price")
      .eq("active", true)
      .order("name"),
    admin
      .from("staff")
      .select("id, name")
      .eq("role", "barber")
      .eq("status", "active")
      .order("name"),
  ]);

  const services = (servicesRaw ?? []).map(
    (s: {
      id: string;
      name: string;
      duration_minutes: number;
      price: number;
    }) => ({
      id: s.id,
      name: s.name,
      durationMinutes: s.duration_minutes,
      price: s.price,
    }),
  );

  const barbers = (barbersRaw ?? []).map((b: { id: string; name: string }) => ({
    id: b.id,
    name: b.name,
  }));

  return { services, barbers };
}

export default async function BookPage() {
  const { services, barbers } = await getServicesAndBarbers();

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
            Fade &amp; Sharp
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
          <BookingFlow services={services} barbers={barbers} />
        )}
      </div>

      {/* Footer */}
      <p className="text-xs mt-6" style={{ color: "#9ca3af" }}>
        Need help? Call us directly.
      </p>
    </main>
  );
}
