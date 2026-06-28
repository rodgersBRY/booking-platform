import { requireRole } from "@/lib/auth";
import { signOut } from "@/app/login/actions";

export const metadata = { title: "Owner dashboard — Fade & Sharp" };

export default async function DashboardPage() {
  const staff = await requireRole("owner");

  return (
    <div className="min-h-screen bg-zinc-50 p-8">
      <div className="max-w-2xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-2xl font-semibold text-zinc-900">
              Owner dashboard
            </h1>
            <p className="text-sm text-zinc-500 mt-1">
              Signed in as {staff.name} &middot; {staff.role}
            </p>
          </div>
          <form action={signOut}>
            <button
              type="submit"
              className="text-sm text-zinc-500 hover:text-zinc-900 underline underline-offset-2 transition-colors"
            >
              Sign out
            </button>
          </form>
        </div>
        <p className="text-zinc-400 text-sm">
          Dashboard content coming soon.
        </p>
      </div>
    </div>
  );
}
