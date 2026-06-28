import { redirect } from "next/navigation";
import { getCurrentStaff, roleHome } from "@/lib/auth";

/**
 * Root route: redirect authenticated users to their role home,
 * unauthenticated users to /login (proxy also handles this, but
 * an explicit redirect here keeps the logic in one place).
 */
export default async function RootPage() {
  const staff = await getCurrentStaff();
  if (staff) redirect(roleHome(staff.role));
  redirect("/login");
}
