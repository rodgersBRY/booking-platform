import type { StaffRole } from "@/lib/db/types";

/**
 * Which staff role(s) can perform a service, by its category. Mirrored in SQL
 * in supabase/migrations/0006_service_roles.sql — keep both in sync if the
 * category list ever changes.
 */
export const CATEGORY_ROLE_MAP: Record<string, StaffRole[]> = {
  haircuts: ["barber"],
  beards: ["barber"],
  hair_dyes: ["barber"],
  hair_relaxing: ["barber"],
  hair_treatments: ["barber"],
  nail_care: ["beautician"],
  facials: ["beautician"],
  waxing: ["beautician"],
  massage: ["masseuse"],
  body_treatments: ["masseuse"],
  spa_packages: ["masseuse", "beautician"],
};

/** Defaults to barber for an unknown/null category, matching the SQL backfill. */
export function rolesForCategory(category: string | null): StaffRole[] {
  if (!category) return ["barber"];
  return CATEGORY_ROLE_MAP[category] ?? ["barber"];
}
