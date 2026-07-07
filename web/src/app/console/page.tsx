import { requireRole } from "@/lib/auth";
import { NavHeader } from "@/components/layout/NavHeader";
import ConsoleBoard from "@/components/console/ConsoleBoard";

export const metadata = { title: "Reception — Barberia Cuts" };

export default async function ConsolePage() {
  // Role gate — redirects to /login or role home if unauthorized.
  const staff = await requireRole("owner", "receptionist");

  return (
    <div className="min-h-screen" style={{ background: "var(--canvas)" }}>
      <NavHeader
        staffName={staff.name}
        staffRole={staff.role}
        section="Reception"
        links={[{ href: "/console", label: "Reception" }]}
      />

      <main className="max-w-4xl mx-auto px-6 py-8">
        <ConsoleBoard />
      </main>
    </div>
  );
}
