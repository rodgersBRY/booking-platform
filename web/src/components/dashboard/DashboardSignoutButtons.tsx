"use client";

interface DashboardSignoutButtonsProps {
  signOut: () => void;
}

export function DashboardSignoutButtons({signOut}: DashboardSignoutButtonsProps) {
  return (
    <div className="flex items-center gap-4">
      <a
        href="/dashboard"
        className="text-sm text-zinc-500 hover:text-zinc-900 transition-colors underline underline-offset-2"
      >
        ← Dashboard
      </a>

      <form action={signOut}>
        <button
          type="submit"
          className="text-sm text-zinc-500 hover:text-zinc-900 underline underline-offset-2 transition-colors"
        >
          Sign out
        </button>
      </form>
    </div>
  );
}
