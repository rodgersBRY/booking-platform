import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";
import { initialServices } from "@/lib/init/services";
import { rolesForCategory } from "@/lib/services/roleMapping";

export async function seedServices(): Promise<void> {
  const admin = createAdminClient();

  const { count, error: countError } = await admin
    .from("services")
    .select("id", { count: "exact", head: true });

  if (countError) {
    console.error(
      "[service-seed] Failed to count services:",
      countError.message,
    );
    return;
  }

  if ((count ?? 0) > 0) return;

  const { data: inserted, error } = await admin
    .from("services")
    .insert(initialServices)
    .select("id, category");
  if (error) {
    console.error("[service-seed] Failed to seed services:", error.message);
    return;
  }

  const roleRows = (inserted ?? []).flatMap((row) =>
    rolesForCategory(row.category as string | null).map((role) => ({
      service_id: row.id as string,
      role,
    })),
  );
  if (roleRows.length > 0) {
    const { error: rolesError } = await admin
      .from("service_roles")
      .insert(roleRows);
    if (rolesError) {
      console.error(
        "[service-seed] Failed to seed service_roles:",
        rolesError.message,
      );
    }
  }

  console.log(`[service-seed] Seeded ${initialServices.length} services.`);
}
