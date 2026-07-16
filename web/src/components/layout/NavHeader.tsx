import { signOut } from "@/app/login/actions";
import { HeaderAvatar } from "@/components/layout/HeaderAvatar";
import { HeaderClock } from "@/components/layout/HeaderClock";
import type { StaffRole } from "@/lib/db/types";
import Image from "next/image";
import Link from "next/link";

type NavLink = {
  href: string;
  label: string;
};

type NavHeaderProps = {
  staffId: string;
  staffName: string;
  staffRole: StaffRole;
  staffAvatarUrl: string | null;
  section: string;
  links?: NavLink[];
};

function roleLabel(role: StaffRole): string {
  switch (role) {
    case "owner":
      return "Owner";
    case "receptionist":
      return "Reception";
    case "barber":
      return "Barber";
    case "beautician":
      return "Beautician";
    case "masseuse":
      return "Masseuse";
  }
}

export function NavHeader({
  staffId,
  staffName,
  staffRole,
  staffAvatarUrl,
  section,
  links = [],
}: NavHeaderProps) {
  return (
    <header style={{ background: "var(--navy)", color: "#fff" }}>
      <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4 px-6 py-4">
        <div className="flex min-w-0 items-center gap-3">
          <Link
            href="/"
            className="flex items-center gap-2 text-xl font-semibold tracking-tight transition-opacity hover:opacity-85"
          >
            <Image
              src="/baberia-cuts-logo.png"
              alt=""
              width={32}
              height={32}
              className="rounded-full"
            />
            Baberia Cuts
          </Link>
          <span
            className="shrink-0 rounded-full px-2.5 py-1 text-xs font-semibold"
            style={{ background: "var(--brass)", color: "#fff" }}
          >
            {section || roleLabel(staffRole)}
          </span>
        </div>

        {links.length > 0 && (
          <nav className="order-3 flex w-full items-center gap-2 overflow-x-auto text-sm md:order-2 md:w-auto">
            {links.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className="whitespace-nowrap rounded-lg px-3 py-1.5 font-medium opacity-75 transition hover:bg-white/10 hover:opacity-100"
              >
                {link.label}
              </Link>
            ))}
          </nav>
        )}

        <div className="order-2 flex items-center gap-4 md:order-3">
          <HeaderClock />

          <div className="hidden text-right sm:block">
            <p className="text-sm font-medium">{staffName}</p>
            <p className="text-xs capitalize opacity-60">{staffRole}</p>
          </div>

          <HeaderAvatar staffId={staffId} name={staffName} avatarUrl={staffAvatarUrl} />

          <form action={signOut}>
            <button
              type="submit"
              className="rounded-lg px-3 py-1.5 text-xs font-semibold opacity-70 transition hover:bg-white/10 hover:opacity-100"
            >
              Sign out
            </button>
          </form>
        </div>
      </div>
    </header>
  );
}
