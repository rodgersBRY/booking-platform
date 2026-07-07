import type { StaffRole } from "@/lib/db/types";

/** Staff roles that perform bookable services and get a personal schedule (`/me`). */
export const BOOKABLE_ROLES: StaffRole[] = ["barber", "beautician", "masseuse"];

export function isBookableRole(role: StaffRole): boolean {
  return BOOKABLE_ROLES.includes(role);
}

/** Roles creatable via the owner's "add staff" form (excludes "owner" — there is only one). */
export const CREATABLE_ROLES: StaffRole[] = [
  "receptionist",
  ...BOOKABLE_ROLES,
];
