import { requireRole } from "@/lib/auth";
import ConsoleHeader from "@/components/console/ConsoleHeader";
import ConsoleBoard from "@/components/console/ConsoleBoard";

export const metadata = { title: "Reception — Fade & Sharp" };

export default async function ConsolePage() {
  // Role gate — redirects to /login or role home if unauthorized.
  const staff = await requireRole("owner", "receptionist");

  return (
    <div className="min-h-screen" style={{ background: "var(--canvas)" }}>
      <ConsoleHeader staffName={staff.name} staffRole={staff.role} />

      <main className="max-w-4xl mx-auto px-6 py-8">
        <ConsoleBoard />
      </main>
    </div>
  );
}
