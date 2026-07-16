import { redirect } from "next/navigation";
import { getCurrentStaff, roleHome } from "@/lib/auth";
import Image from "next/image";
import LoginForm from "./LoginForm";

export const metadata = { title: "Sign in — Baberia Cuts" };

export default async function LoginPage() {
  // Already signed in? Go home.
  const staff = await getCurrentStaff();
  if (staff) redirect(roleHome(staff.role));

  return (
    <div className="min-h-screen flex items-center justify-center bg-zinc-50 px-4">
      <div className="w-full max-w-sm">
        <div className="mb-8 flex items-center gap-3">
          <Image
            src="/baberia-cuts-logo.png"
            alt="Baberia Cuts"
            width={48}
            height={48}
            className="rounded-full"
          />
          <div>
            <h1 className="text-2xl font-semibold text-zinc-900 tracking-tight">
              Baberia Cuts
            </h1>
            <p className="mt-1 text-sm text-zinc-500">Sign in to your account</p>
          </div>
        </div>
        <LoginForm />
      </div>
    </div>
  );
}
